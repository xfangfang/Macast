"""
This is a setup.py script

"""

import sys
from setuptools import setup, find_packages
from setuptools.command.sdist import sdist
from setuptools.command.install import install
from setuptools.command.develop import develop

exec(open('macast/__pkginfo__.py').read())

try:
    from wheel.bdist_wheel import bdist_wheel
except ImportError:
    bdist_wheel = None


class CompileCatalogMixin:
    def run(self):
        self.run_command('compile_catalog')
        super().run()


try:
    with open('README.md', 'r', encoding='utf-8') as f:
        LONG_DESCRIPTION = f.read()
except:
    LONG_DESCRIPTION = __description__
INSTALL = ["requests", "appdirs", "cherrypy", "lxml", "netifaces"]
PACKAGES = find_packages()

if sys.platform == 'darwin':
    INSTALL += ["rumps",
                "pyperclip"]
elif sys.platform == 'win32':
    INSTALL += ["pillow",
                "pyperclip",
                "pystray"]
else:
    INSTALL += ["pillow",
                "pystray @ git+https://github.com/xfangfang/pystray.git",
                "pyperclip @ git+https://github.com/xfangfang/pyperclip.git"]


class SDist(CompileCatalogMixin, sdist):
    pass


class Install(CompileCatalogMixin, install):
    pass


class Develop(CompileCatalogMixin, develop):
    pass


CMD_CLS = {'sdist': SDist,
           'install': Install,
           'develop': Develop}

if bdist_wheel:
    class BDistWheel(CompileCatalogMixin, bdist_wheel):
        pass


    CMD_CLS['bdist_wheel'] = BDistWheel

setup(
    name=__name__,
    version=__version__,
    author=__author__,
    author_email=__email__,
    description=__description__,
    license=__license__,
    url=__url__,
    long_description=LONG_DESCRIPTION,
    long_description_content_type="text/markdown",
    classifiers=["Topic :: Multimedia :: Sound/Audio",
                 "Topic :: Multimedia :: Video",
                 'Programming Language :: Python :: 3',
                 'Programming Language :: Python :: 3.6',
                 'Programming Language :: Python :: 3.7',
                 'Programming Language :: Python :: 3.8',
                 'Programming Language :: Python :: 3.9',
                 'Programming Language :: Python :: 3.10',
                 'Operating System :: MacOS :: MacOS X',
                 'Operating System :: Microsoft :: Windows :: Windows NT/2000',
                 'Operating System :: POSIX',
                 ],
    platforms=["MacOS X", "Windows", "POSIX"],
    keywords=["mpv", "dlna", "renderer"],
    install_requires=INSTALL,
    packages=PACKAGES,
    include_package_data=True,
    entry_points={
        'console_scripts': [
            'macast-cli = macast.macast:cli',
            'macast-gui = macast.macast:gui'
        ]
    },
    python_requires=">=3.6",
    setup_requires=['babel'],
    cmdclass=CMD_CLS,
    command_options={
        'compile_catalog': {
            "domain": ('setup.py', 'macast'),
            "directory": ('setup.py', 'macast/i18n'),
            "statistics": ('setup.py', 1),
            "use_fuzzy": ('setup.py', 1),
        }
    },
)
