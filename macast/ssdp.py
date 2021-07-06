# Licensed under the MIT license
# http://opensource.org/licenses/mit-license.php

# Copyright 2005, Tim Potter <tpot@samba.org>
# Copyright 2006 John-Mark Gurney <gurney_j@resnet.uroegon.edu>
# Copyright (C) 2006 Fluendo, S.A. (www.fluendo.com).
# Copyright 2006,2007,2008,2009 Frank Scholz <coherence@beebits.net>
# Copyright 2016 Erwan Martin <public@fzwte.net>
# Copyright 2021 FangYuecheng <github.com/xfangfang>
#
# Implementation of a SSDP server.
#

import random
import time
import socket
import logging
import threading
from email.utils import formatdate
from errno import ENOPROTOOPT


SSDP_PORT = 1900
SSDP_ADDR = '239.255.255.250'
SERVER_ID = 'SSDP Server'
logger = logging.getLogger("SSDPServer")


class SSDPServer:
    """A class implementing a SSDP server.  The notify_received and
    searchReceived methods are called when the appropriate type of
    datagram is received by the server."""
    known = {}

    def __init__(self):
        self.sock = None
        self.running = False

    def start(self):
        """Start ssdp background thread
        """
        if not self.running:
            self.running = True
            self.ssdpThread = threading.Thread(target=self.run, args=())
            self.ssdpThread.start()

    def stop(self):
        """Stop ssdp background thread
        """
        self.running = False
        # Wake up the socket, this will speed up exiting ssdp thread.
        socket.socket(socket.AF_INET,
                      socket.SOCK_DGRAM).sendto(b'', (SSDP_ADDR, SSDP_PORT))
        self.ssdpThread.join()

    def run(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        if hasattr(socket, "SO_REUSEPORT"):
            try:
                self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
            except socket.error as le:
                # RHEL6 defines SO_REUSEPORT but it doesn't work
                if le.errno == ENOPROTOOPT:
                    pass
                else:
                    raise

        addr = socket.inet_aton(SSDP_ADDR)
        interface = socket.inet_aton('0.0.0.0')
        cmd = socket.IP_ADD_MEMBERSHIP
        self.sock.setsockopt(socket.IPPROTO_IP, cmd, addr + interface)
        self.sock.bind(('0.0.0.0', SSDP_PORT))
        self.sock.settimeout(1)

        while self.running:
            try:
                data, addr = self.sock.recvfrom(1024)
                self.datagram_received(data, addr)
            except socket.timeout:
                continue
        self.shutdown()
        self.sock.close()

    def shutdown(self):
        for st in self.known:
            if self.known[st]['MANIFESTATION'] == 'local':
                self.do_byebye(st)
        usn = [st for st in self.known]
        for st in usn:
            self.unregister(st)

    def datagram_received(self, data, host_port):
        """Handle a received multicast datagram."""

        (host, port) = host_port

        try:
            header, payload = data.decode().split('\r\n\r\n')[:2]
        except ValueError as err:
            logger.error(err)
            return

        lines = header.split('\r\n')
        cmd = lines[0].split(' ')
        lines = map(lambda x: x.replace(': ', ':', 1), lines[1:])
        lines = filter(lambda x: len(x) > 0, lines)

        headers = [x.split(':', 1) for x in lines]
        headers = dict(map(lambda x: (x[0].lower(), x[1]), headers))

        if cmd[0] != 'NOTIFY':
            logger.info('SSDP command %s %s - from %s:%d' %
                        (cmd[0], cmd[1], host, port))
        logger.debug('with headers: {}.'.format(headers))
        if cmd[0] == 'M-SEARCH' and cmd[1] == '*':
            # SSDP discovery
            self.discovery_request(headers, (host, port))
        elif cmd[0] == 'NOTIFY' and cmd[1] == '*':
            # SSDP presence
            logger.debug('NOTIFY *')
        else:
            logger.warning('Unknown SSDP command %s %s' % (cmd[0], cmd[1]))

    def register(self, manifestation, usn, st, location, server=SERVER_ID,
                 cache_control='max-age=1800', silent=False,
                 host=None):
        """Register a service or device that this SSDP server will
        respond to."""

        logging.info('Registering %s (%s)' % (st, location))

        self.known[usn] = {}
        self.known[usn]['USN'] = usn
        self.known[usn]['LOCATION'] = location
        self.known[usn]['ST'] = st
        self.known[usn]['EXT'] = ''
        self.known[usn]['SERVER'] = server
        self.known[usn]['CACHE-CONTROL'] = cache_control

        self.known[usn]['MANIFESTATION'] = manifestation
        self.known[usn]['SILENT'] = silent
        self.known[usn]['HOST'] = host
        self.known[usn]['last-seen'] = time.time()

        if manifestation == 'local' and self.sock:
            self.do_notify(usn)

    def unregister(self, usn):
        logger.info("Un-registering %s" % usn)
        del self.known[usn]

    def is_known(self, usn):
        return usn in self.known

    def send_it(self, response, destination, delay, usn):
        logger.debug('send discovery response delayed by %ds for %s to %r' %
                     (delay, usn, destination))
        try:
            self.sock.sendto(response.encode(), destination)
        except (AttributeError, socket.error) as msg:
            logger.warning("failure sending out byebye notification: %r" % msg)

    def discovery_request(self, headers, host_port):
        """Process a discovery request.  The response must be sent to
        the address specified by (host, port)."""

        (host, port) = host_port

        logger.info('Discovery request from (%s,%d) for %s' % (host, port,
                                                               headers['st']))
        logger.info('Discovery request for %s' % headers['st'])

        # Do we know about this service?
        for i in self.known.values():
            if i['MANIFESTATION'] == 'remote':
                continue
            if headers['st'] == 'ssdp:all' and i['SILENT']:
                continue
            if i['ST'] == headers['st'] or headers['st'] == 'ssdp:all':
                response = ['HTTP/1.1 200 OK']

                usn = None
                for k, v in i.items():
                    if k == 'USN':
                        usn = v
                    if k not in ('MANIFESTATION', 'SILENT', 'HOST'):
                        response.append('%s: %s' % (k, v))

                if usn:
                    response.append('DATE: %s' % formatdate(timeval=None,
                                                            localtime=False,
                                                            usegmt=True))

                    response.extend(('', ''))
                    delay = random.randint(0, int(headers['mx']))

                    self.send_it('\r\n'.join(response),
                                 (host, port), delay, usn)

    def do_notify(self, usn):
        """Do notification"""

        if self.known[usn]['SILENT']:
            return
        logger.debug('Sending alive notification for %s' % usn)

        resp = [
            'NOTIFY * HTTP/1.1',
            'HOST: %s:%d' % (SSDP_ADDR, SSDP_PORT),
            'NTS: ssdp:alive',
        ]
        stcpy = dict(self.known[usn].items())
        stcpy['NT'] = stcpy['ST']
        del stcpy['ST']
        del stcpy['MANIFESTATION']
        del stcpy['SILENT']
        del stcpy['HOST']
        del stcpy['last-seen']

        resp.extend(map(lambda x: ': '.join(x), stcpy.items()))
        resp.extend(('', ''))
        logger.debug('do_notify content')
        logger.debug(resp)
        try:
            self.sock.sendto('\r\n'.join(resp).encode(),
                             (SSDP_ADDR, SSDP_PORT))
        except (AttributeError, socket.error) as msg:
            logger.warning("failure sending out alive notification: %r" % msg)

    def do_byebye(self, usn):
        """Do byebye"""

        logger.info('Sending byebye notification for %s' % usn)

        resp = [
            'NOTIFY * HTTP/1.1',
            'HOST: %s:%d' % (SSDP_ADDR, SSDP_PORT),
            'NTS: ssdp:byebye',
        ]
        try:
            stcpy = dict(self.known[usn].items())
            stcpy['NT'] = stcpy['ST']
            del stcpy['ST']
            del stcpy['MANIFESTATION']
            del stcpy['SILENT']
            del stcpy['HOST']
            del stcpy['last-seen']
            resp.extend(map(lambda x: ': '.join(x), stcpy.items()))
            resp.extend(('', ''))
            logger.debug('do_byebye content')
            logger.debug(resp)
            if self.sock:
                try:
                    self.sock.sendto('\r\n'.join(resp).encode(),
                                     (SSDP_ADDR, SSDP_PORT))
                except (AttributeError, socket.error) as msg:
                    logger.error("error sending byebye notification: %r" % msg)
        except KeyError as msg:
            logger.error("error building byebye notification: %r" % msg)
