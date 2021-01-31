#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function install_openssl(){
    [ -f "/root/.meteorite/tmp/install_openssl.lock" ] && echo -e "${RGB_INFO}Notice: OpenSSL installation script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/install_openssl.lock

    check_sources
    check_yum

    [ ! -d '/etc/bak/openssl' ] && mkdir -p /etc/bak/openssl
    mv /usr/bin/openssl /etc/bak/openssl

    [ ! -d "${OPENSSL_DIR}" ] && mkdir -p ${OPENSSL_DIR}

    cd ${METEORITE_DIR}/src

    if [ ! -f "openssl-${OPENSSL_VER}.tar.gz" ]; then
        wget https://mirrors.cloud.tencent.com/openssl/source/openssl-${OPENSSL_VER}.tar.gz
    fi

    tar zxvf openssl-${OPENSSL_VER}.tar.gz

    # 检测安装 openssl
    [ ! -d ${OPENSSL_DIR} ] && install_openssl

    cd ${METEORITE_DIR}/src/openssl-${OPENSSL_VER}

    ./config shared --prefix=${OPENSSL_DIR} --openssldir=${OPENSSL_DIR}

    make -j${PROCESSOR} && make install

    ln -sf ${OPENSSL_DIR}/bin/openssl /usr/bin/openssl

    [ -z "`grep ${OPENSSL_DIR}/lib /etc/ld.so.conf.d/*.conf`" ] && echo "${OPENSSL_DIR}/lib" > /etc/ld.so.conf.d/meteorite-openssl.conf
    ldconfig -v

    if [[ "$( openssl version )" =~ "${OPENSSL_VER}" ]]; then
        echo -e "${RGB_SUCCESS}Notice: OpenSSL installed successfully!${RGB_END}"
        cp ${METEORITE_DIR}/config/cacert.pem ${OPENSSL_DIR}/cacert.pem
        rm -rf ${METEORITE_DIR}/src/openssl-${OPENSSL_VER}
    else
        echo -e "${RGB_ERROR}Error: OpenSSL installation failed!${RGB_END}"
        kill -9 $$
    fi
}