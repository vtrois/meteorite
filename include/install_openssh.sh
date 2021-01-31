#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function install_openssh(){
    [ -f "/root/.meteorite/tmp/install_openssh.lock" ] && echo -e "${RGB_INFO}Notice: OpenSSH installation script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/install_openssh.lock

    check_yum

    [ ! -d '/etc/bak/openssh' ] && mkdir -p /etc/bak/openssh
    mv /etc/ssh/* /etc/bak/openssh

    cd ${METEORITE_DIR}/src

    if [ ! -f "openssh-${OPENSSH_VER}.tar.gz" ]; then
        wget https://mirrors.cloud.tencent.com/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VER}.tar.gz
    fi

    tar zxvf openssh-${OPENSSH_VER}.tar.gz

    cd ${METEORITE_DIR}/src/openssh-${OPENSSH_VER}

    ./configure --prefix=/usr --sysconfdir=/etc/ssh --with-ssl-dir=${OPENSSL_DIR} --with-zlib --with-pam --with-md5-passwords --with-ssl-engine --without-hardening

    make -j${PROCESSOR} && make install

    mv /usr/lib/systemd/system/sshd.service /etc/bak/openssh/sshd.service
    mv /usr/lib/systemd/system/sshd.socket /etc/bak/openssh/sshd.socket

    cp -a contrib/redhat/sshd.init /etc/init.d/sshd
    chmod +x /etc/init.d/sshd

    systemctl enable sshd.service
    systemctl restart sshd.service

    if [[ "$( ssh -V 2>&1)" =~ "${OPENSSH_VER}" ]]; then
        echo -e "${RGB_SUCCESS}Notice: OpenSSH installed successfully!${RGB_END}"
        rm -rf ${METEORITE_DIR}/src/openssh-${OPENSSH_VER} /etc/bak
    else
        echo -e "${RGB_ERROR}Error: OpenSSH installation failed!${RGB_END}"
        kill -9 $$
    fi
}