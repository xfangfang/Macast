# Macast Development

We use **pyinstaller** to build the application based on **pystray**, but in MacOS we use **py2app** and **rumps**, because it have better performance and smaller size.


## Development upder MacOS

### 1. download mpv

```shell
wget https://laboratory.stolendata.net/~djinn/mpv_osx/mpv-latest.tar.gz
mkdir -p bin && tar --strip-components 2 -C bin -xzvf mpv-latest.tar.gz mpv.app/Contents/MacOS
```

### 2. debug

```shell
pip install -r requirements/darwin.txt
python Macast.py
```

### 3. package

```shell
pip install py2app
pip install setuptools==44.0.0 # try this if you cannot run Macast.app
python setup.py py2app
cp -R bin dist/Macast.app/Contents/Resources/
open dist
```


## Development under Windows

### 1. download mpv

```powershell
$client = new-object System.Net.WebClient
$client.DownloadFile('https://nchc.dl.sourceforge.net/project/mpv-player-windows/stable/mpv-0.33.0-x86_64.7z','mpv.7z')
7z x -obin mpv.7z *.exe
```

### 2. debug

```powershell
pip install -r requirements/common.txt
python Macast.py
```

### 3. package

```powershell
pip install pyinstaller
pyinstaller --noconfirm -F -w --additional-hooks-dir=. --add-data=".version;." --add-data="macast/xml/*;macast/xml"  --add-data="i18n/zh_CN/LC_MESSAGES/*.mo;i18n/zh_CN/LC_MESSAGES" --add-data="assets/*;assets" --add-binary="bin/mpv.exe;bin" --icon=assets/icon.ico Macast.py
```


## Development under Linux (example: Ubuntu)

### 1. install mpv

```shell
sudo apt install mpv
```

### 2. debug

```shell
pip install -r requirements/common.txt
python Macast.py
# if there is something wrong, try this:
export PYSTRAY_BACKEND=gtk && python3 Macast.py
```

Tips: Make sure you can use **gi**:

```
$ python3
Python 3.7.10 (default, Jun  3 2021, 17:51:26)
Type "help", "copyright", "credits" or "license" for more information.
>>> import gi
>>>
```

if there is something wrong, try: **sudo apt-get install python3-gi**

if you use conda, check this https://stackoverflow.com/a/40303128

For details of GUI support, please refer to: https://pystray.readthedocs.io/en/latest/usage.html#selecting-a-backend


### 3. package

```shell
# build binary
pip install pyinstaller
pyinstaller --noconfirm -F -w --additional-hooks-dir=. --add-data=".version:." --add-data="macast/xml/*:macast/xml"  --add-data="i18n/zh_CN/LC_MESSAGES/*.mo:i18n/zh_CN/LC_MESSAGES" --add-data="assets/*:assets" Macast.py
# build deb
export VERSION=`cat .version`
mkdir -p dist/DEBIAN
mkdir -p dist/usr/bin
mkdir -p dist/usr/share/applications
mkdir -p dist/usr/share/icons
echo -e "Package: Macast\nVersion: ${VERSION}\nArchitecture: amd64\nMaintainer: xfangfang\nDescription: DLNA Media Renderer\nDepends: mpv" > dist/DEBIAN/control
echo -e "[Desktop Entry]\nName=Macast\nComment=DLNA Media Renderer\nExec=/usr/bin/macast\nIcon=/usr/share/icons/Macast.png\nTerminal=false\nType=Application\nCategories=Video" > dist/usr/share/applications/macast.desktop
mv dist/Macast dist/usr/bin/macast
cp assets/icon.png dist/usr/share/icons/Macast.png
dpkg -b dist Macast-v${VERSION}.deb
```
