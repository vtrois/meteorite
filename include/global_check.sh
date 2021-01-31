#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-31

function check_info(){
    echo -e "${RGB_SUCCESS}            __  ___       __                      _  __                 ${RGB_END}"
    echo -e "${RGB_SUCCESS}           /  |/  /___   / /_ ___   ____   _____ (_)/ /_ ___            ${RGB_END}"
    echo -e "${RGB_SUCCESS}          / /|_/ // _ \ / __// _ \ / __ \ / ___// // __// _ \           ${RGB_END}"
    echo -e "${RGB_SUCCESS}         / /  / //  __// /_ /  __// /_/ // /   / // /_ /  __/           ${RGB_END}"
    echo -e "${RGB_SUCCESS}        /_/  /_/ \___/ \__/ \___/ \____//_/   /_/ \__/ \___/            ${RGB_END}\n"
    echo -e "${RGB_SUCCESS}Please read the instructions carefully before using the Meteorite tool. ${RGB_END}"
    echo -e "${RGB_SUCCESS}If you encounter problems, please provide the files in the log folder.  ${RGB_END}\n"
    echo -e "${RGB_SUCCESS}• Follow us on Weibo: https://weibo.com/vtrois                          ${RGB_END}"
    echo -e "${RGB_SUCCESS}• For more information please visit: https://github.com/vtrois/meteorite${RGB_END}"
    echo -e "${RGB_SUCCESS}• Mail bug reports or suggestions: support@vtrois.com                   ${RGB_END}\n"
}

function check_root(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RGB_ERROR}Error: This script needs to be run as root!${RGB_END}"
        kill -9 $$
    fi
}

function check_os(){
    if [ "${CHECK_CENTOS}" != "true" ]; then
        echo -e "${RGB_ERROR}Error: This script only runs on CentOS 7!${RGB_END}"
        kill -9 $$
    fi
}

function check_ipv4(){
    local IPV4=$( wget -qO- -t1 -T2 api-ipv4.ip.sb/ip )
    [ -z "${IPV4}" ] && IPV4=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ ! -z "${IPV4}" ] && echo ${IPV4}
}

function check_yum(){
    yum install -y git automake autoconf libtool haveged libc-client deltarpm cmake3 perl lsof gcc gcc-c++ \
    zlib zlib-devel \
    openssl openssl-devel \
    pcre pcre-devel \
    pam pam-devel \
    libxml2 libxml2-devel \
    sqlite sqlite-devel \
    libcurl libcurl-devel \
    libpng libpng-devel \
    libjpeg libjpeg-devel \
    libicu libicu-devel \
    libargon2 libargon2-devel \
    libxslt libxslt-devel \
    bzip2 bzip2-devel \
    libevent libevent-devel \
    cyrus-sasl cyrus-sasl-devel \
    ncurses ncurses-devel \
    libaio libaio-devel \
    boost boost-devel \
    gnutls gnutls-devel \
    readline readline-devel \
    editline editline-devel \
    pcre2 pcre2-devel \
    glib2 glib2-devel \
    libtirpc libtirpc-devel \
    bison bison-devel \
    oniguruma oniguruma-devel \
    libarchive libarchive-devel
}

function check_demo(){
    echo "<?php phpinfo(); ?>" > ${WWW_DIR}/default/phpinfo.php
    cp ${METEORITE_DIR}/config/ocp.php ${WWW_DIR}/default/ocp.php
    chown -R www:www ${WWW_DIR}/default
}

function check_sources(){
    [ -f "${METEORITE_DIR}/tmp/check_sources.lock" ] && return
    touch ${METEORITE_DIR}/tmp/check_sources.lock

    cd ${METEORITE_DIR}/config

    # cacert.pem
    # https://curl.haxx.se/ca/cacert.pem
    if [ ! -f "cacert.pem" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/cacert.pem
    fi

    # nginx.conf
    if [ ! -f "nginx.conf" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/nginx.conf
    fi

    # default.conf
    if [ ! -f "default.conf" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/default.conf
    fi

    # general.conf
    if [ ! -f "general.conf" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/general.conf
    fi

    # security.conf
    if [ ! -f "security.conf" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/security.conf
    fi

    # fastcgi.conf
    if [ ! -f "fastcgi.conf" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/fastcgi.conf
    fi

    # memcached.conf
    if [ ! -f "memcached.conf" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/memcached.conf
    fi

    # mariadb.conf
    if [ ! -f "mariadb.conf" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/mariadb.conf
    fi

    # ocp.php
    if [ ! -f "ocp.php" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/ocp.php
    fi

    # wordpress.php
    if [ ! -f "wordpress.conf" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/wordpress.conf
    fi

    # laravel.php
    if [ ! -f "laravel.conf" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/config/laravel.conf
    fi
}