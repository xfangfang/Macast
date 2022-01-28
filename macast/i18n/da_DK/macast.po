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

import sys
import time
import socket
import logging
import threading
import cherrypy
from email.utils import formatdate

from .utils import Setting, get_subnet_ip

SSDP_PORT = 1900
SSDP_ADDR = '239.255.255.250'
SERVER_ID = 'SSDP Server'
logger = logging.getLogger("SSDPServer")


class Sock:
    def __init__(self, ip):
        self.ip = ip
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.ssdp_addr = socket.inet_aton(SSDP_ADDR)
        self.interface = socket.inet_aton(self.ip)
        try:
            self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_IF, self.interface)
            self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, self.ssdp_addr + self.interface)
        except Exception as e:
            logger.error(e)
        self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_LOOP, 0)
        # self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 2)

    def send(self, response, destination):
        try:
            self.sock.sendto(response.format(self.ip).encode(), destination)
        except (AttributeError, socket.error) as msg:
            logger.error(f"failure sending out data{msg}: from {self.ip} to {destination}")

    def close(self):
        try:
            self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_DROP_MEMBERSHIP, self.ssdp_addr + self.interface)
        except Exception as e:
            logger.error(f'failure drop membership on {self.ip}: {e}')
        self.sock.close()


class SSDPServer:
    """A class implementing a SSDP server.  The notify_received and
    searchReceived methods are called when the appropriate type of
    datagram is received by the server."""
    known = {}

    def __init__(self):
        self.ip_list = []
        self.sock_list = []
        self.sock = None
        self.running = False
        self.ssdp_thread = None
        self.sending_byebye = True  # send byebye when shutdown ssdp thread
        self.ssdp_notify_thread = None
        self.ssdp_device_lock = threading.Lock()
        self.notify_internal = 3

    def start(self):
        """Start ssdp background thread
        """
        if self.running:
            logger.error('SSDP is already started.')
            return

        self.running = True
        self.sending_byebye = True
        self.ip_list = list(Setting.get_ip())
        if len(self.ip_list) == 0:
            logger.error("SSDP Thread Stopped because cannot get ip address")
            return
        if sys.platform == 'win32':
            self.ip_list.append(('192.168.137.1', '255.255.255.0'))
        if self.ssdp_thread is None:
            self.ssdp_thread = threading.Thread(target=self.ssdp_main_thread, name="SSDP_THREAD")
            self.ssdp_thread.start()
        if self.ssdp_notify_thread is None:
            self.ssdp_notify_thread = threading.Thread(target=self.ssdp_notify,
                                                       name="SSDP_NOTIFY_THREAD",
                                                       daemon=True)
            self.ssdp_notify_thread.start()

    def stop(self):
        """Stop ssdp background thread
        """
        if not self.running:
            logger.error('SSDP is already stopped.')
            return

        self.running = False
        # Wake up the socket, this will speed up exiting ssdp thread.
        try:
            socket.socket(socket.AF_INET, socket.SOCK_DGRAM).sendto(b'', (SSDP_ADDR, SSDP_PORT))
        except Exception as e:
            pass
        if self.ssdp_thread is not None:
            self.ssdp_thread.join()

    def ssdp_main_thread(self):
        logger.info('SSDP_MAIN_THREAD START')

        # create UDP server
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

        # set IP_MULTICAST_LOOP to false
        self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_LOOP, 0)

        # set SO_REUSEADDR or SO_REUSEPORT
        if sys.platform == 'win32':
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        elif sys.platform == 'darwin':
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        elif hasattr(socket, "SO_REUSEPORT"):
            try:
                self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
                logger.debug("SSDP set SO_REUSEPORT")
            except socket.error as e:
                logger.error("SSDP cannot set SO_REUSEPORT")
                logger.error(str(e))
        elif hasattr(socket, "SO_REUSEADDR"):
            try:
                self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                logger.debug("SSDP set SO_REUSEADDR")
            except socket.error as e:
                logger.error("SSDP cannot set SO_REUSEADDR")
                logger.error(str(e))

        # self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 10)

        self.sock_list = []
        for ip, mask in self.ip_list:
            try:
                logger.debug('add membership {}'.format(ip))
                mreq = socket.inet_aton(SSDP_ADDR) + socket.inet_aton(ip)
                self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
                self.sock_list.append(Sock(ip))
            except Exception as e:
                if 'WinError 10013' not in str(e):
                    logger.error(e)

        try:
            self.sock.bind(('0.0.0.0', SSDP_PORT))
        except Exception as e:
            logger.error(e)
            cherrypy.engine.publish("app_notify", "Macast", "SSDP Can't start")
            threading.Thread(target=lambda: Setting.stop_service(), name="SSDP_STOP_THREAD").start()
            return
        self.sock.settimeout(1)

        while self.running:
            try:
                data, addr = self.sock.recvfrom(1024)
                self.datagram_received(data, addr)
            except socket.timeout:
                continue
        self.ssdp_byebye()
        for ip, mask in self.ip_list:
            logger.debug(f"drop membership {ip}")
            mreq = socket.inet_aton(SSDP_ADDR) + socket.inet_aton(ip)
            try:
                self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_DROP_MEMBERSHIP, mreq)
            except Exception:
                continue
        self.sock.close()
        self.sock = None
        self.ssdp_thread = None
        logger.info('SSDP_MAIN_THREAD DONE')

    def ssdp_byebye(self):
        if not self.sending_byebye:
            return
        with self.ssdp_device_lock:
            byebye_list = [self.known[usn].get('BYE', '') for usn in self.known]
        try:
            if self.sock is not None:
                for byebye_device in byebye_list:
                    self.send_each(byebye_device, (SSDP_ADDR, SSDP_PORT))
        except (AttributeError, socket.error) as msg:
            logger.error(f"error sending bye bye notification: {msg}")
        self.unregister_all()

    def ssdp_notify(self):
        logger.info('SSDP_NOTIFY_THREAD START')
        while self.running:
            time.sleep(self.notify_internal)
            if not self.running:
                break
            with self.ssdp_device_lock:
                notify_list = [(usn, self.known[usn].get('NOTIFY', '')) for usn in self.known]
            try:
                if self.sock is None:
                    continue
                for usn, notify_device in notify_list:
                    logger.log(1, f'Sending notify for: {usn}')
                    self.send_each(notify_device, (SSDP_ADDR, SSDP_PORT))
                    self.send_each(notify_device, (SSDP_ADDR, SSDP_PORT))
            except (AttributeError, socket.error) as msg:
                logger.error(f"failure sending out alive notification: {msg}")

        logger.info('SSDP_NOTIFY_THREAD DONE')
        self.ssdp_notify_thread = None

    def datagram_received(self, data, host_port):
        """Handle a received multicast datagram."""

        (host, port) = host_port

        try:
            header = data.decode().split('\r\n\r\n')[0]
        except ValueError as err:
            logger.error(err)
            return
        if len(header) == 0:
            return

        lines = header.split('\r\n')
        cmd = lines[0].split(' ')
        lines = map(lambda x: x.replace(': ', ':', 1), lines[1:])
        lines = filter(lambda x: len(x) > 0, lines)

        headers = [x.split(':', 1) for x in lines]
        headers = dict(map(lambda x: (x[0].lower(), x[1]), headers))

        if cmd[0] != 'NOTIFY':
            logger.debug(f'SSDP command {cmd[0]} {cmd[1]} - from {host}:{port}')
        if cmd[0] == 'M-SEARCH' and cmd[1] == '*':
            # SSDP discovery
            logger.debug(f'M-SEARCH * {data}')
            self.discovery_request(headers, (host, port))
        elif cmd[0] == 'NOTIFY' and cmd[1] == '*':
            # SSDP presence
            # logger.debug('NOTIFY *')
            pass
        else:
            logger.error(f'Unknown SSDP command {cmd[0]} {cmd[1]}')

    def register(self, usn, nt, location, server=SERVER_ID, cache_control=1800):
        """
        Register a service or device that this SSDP server will respond to.
        :param usn: Unique Service Name
        :param nt: Notification Type
        :param location: Contains a URL to the UPnP description of the root device.
        :param server: Concatenation of OS name, OS version, UPnP/1.0, product name, and product version.
        :param cache_control: Must have max-age directive that specifies number of seconds the advertisement is valid.
        :return:
        """
        """"""

        logging.info(f'Registering {nt} ({location})')

        # notify
        resp_notify = [
            'NOTIFY * HTTP/1.1',
            f'HOST: {SSDP_ADDR}:{SSDP_PORT}',
            'NTS: ssdp:alive',
        ]

        # bye bye
        resp_byebye = [
            'NOTIFY * HTTP/1.1',
            f'HOST: {SSDP_ADDR}:{SSDP_PORT}',
            'NTS: ssdp:byebye']

        resp_ext = [
            f'USN: {usn}',
            f'LOCATION: {location}',
            f'NT: {nt}',
            'EXT: ',
            f'SERVER: {server}',
            f'CACHE-CONTROL: max-age={cache_control}',
            '',
            ''
        ]

        resp_notify.extend(resp_ext)
        resp_byebye.extend(resp_ext)

        with self.ssdp_device_lock:
            self.known[usn] = {
                'NOTIFY': '\r\n'.join(resp_notify),
                'BYE': '\r\n'.join(resp_byebye),
                'USN': usn,
                'LOCATION': location,
                'NT': nt,
                'EXT': '',
                'SERVER': server,
                'CACHE-CONTROL': f'max-age={cache_control}'
            }

    def unregister(self, usn):
        """
        Unregister a service or device that this SSDP server will respond to.
        :param usn: Unique Service Name
        :return:
        """
        logger.info(f"Un-registering {usn}")

        with self.ssdp_device_lock:
            if usn in self.known:
                del self.known[usn]

    def unregister_all(self):
        logger.info(f"Un-registering-all")

        with self.ssdp_device_lock:
            self.known = {}

    def send_each(self, response: str, destination: (str, int)):
        """
        Let each socket send multicast data to its own network interface
        :param response: data
        :param destination: Multicast address
        :return:
        """
        for sock in self.sock_list:
            sock.send(response, destination)

    def discovery_request(self, headers, host_port):
        """
        Process a discovery request.
        The response must be sent to the address specified by (host, port).
        :param headers:
        :param host_port:
        :return:
        """

        (host, port) = host_port

        logger.debug(f'Discovery request from ({host}:{port}) for {headers["st"]}')

        # Do we know about this service?
        with self.ssdp_device_lock:
            devices = list(self.known.values())

        for i in devices:
            if i['NT'] == headers['st'] or headers['st'] == 'ssdp:all':
                resp = [
                    'HTTP/1.1 200 OK',
                    f'USN: {i["USN"]}',
                    f'LOCATION: {i["LOCATION"]}',
                    f'NT: {i["NT"]}',
                    'EXT: ',
                    f'SERVER: {i["SERVER"]}',
                    f'CACHE-CONTROL: {i["CACHE-CONTROL"]}',
                    f'DATE: {formatdate(timeval=None, localtime=False, usegmt=True)}',
                    '',
                    ''
                ]
                destination = (host, port)
                logger.debug(f'send discovery {i["USN"]} response  to {destination}')
                logger.debug(resp)

                # Find which subnet the discovery is from
                # and send back the response
                for ip, mask in self.ip_list:
                    if get_subnet_ip(ip, mask) == get_subnet_ip(host, mask):
                        self.sock.sendto('\r\n'.join(resp).format(ip).encode(), destination)
                        break
