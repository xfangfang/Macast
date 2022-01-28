import os
import sys

backend_name = os.environ.get('PYSTRAY_BACKEND', None)
if backend_name:
    modules = ['pystray._' + backend_name]
elif sys.platform == 'darwin':
    modules = ['pystray._darwin']
elif sys.platform == 'win32':
    modules = ['pystray._win32']
else:
    modules = ['pystray._appindicator', 'pystray._gtk', 'pystray._xorg']

hiddenimports = modules