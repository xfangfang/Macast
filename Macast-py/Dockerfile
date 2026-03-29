FROM python:3.7-slim-buster

ENV PYPI_URL=https://pypi.tuna.tsinghua.edu.cn
ENV PYPI_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

RUN \
    set -x &&\
    # install gi to python3.7/site-packages
    mkdir -p /usr/lib/python3 &&\
    ln -s /usr/local/lib/python3.7/site-packages /usr/lib/python3/dist-packages &&\
    # update system
    apt-get update &&\
    # install requirements
    apt-get install -y --no-install-recommends \
        binutils \
        python3-gi \
        libgtk-3-dev \
        libappindicator3-dev \
        upx \
        git


RUN \
    # specified a custom URL for PYPI
    mkdir -p /root/.pip &&\
    echo "[global]" > /root/.pip/pip.conf &&\
    echo "index = $PYPI_URL" >> /root/.pip/pip.conf &&\
    echo "index-url = $PYPI_INDEX_URL" >> /root/.pip/pip.conf &&\
    echo "trusted-host = $(echo $PYPI_URL | perl -pe 's|^.*?://(.*?)(:.*?)?/.*$|$1|')" >> /root/.pip/pip.conf &&\
    # install pyinstaller
    pip install pyinstaller && \
    mkdir /src/ &&\
    # build entrypoint.sh
    echo \#\!/bin/bash -i >> /entrypoint.sh &&\
    echo >> /entrypoint.sh &&\
    echo "set -e" >> /entrypoint.sh &&\
    echo "cd /src" >> /entrypoint.sh &&\
    echo "echo \"\$@\"" >> /entrypoint.sh &&\
    echo "sh -c \"\$@\"" >> /entrypoint.sh &&\
    chmod +x /entrypoint.sh

VOLUME /src/
WORKDIR /src/
SHELL ["/bin/bash", "-i", "-c"]
ENTRYPOINT ["/entrypoint.sh"]
