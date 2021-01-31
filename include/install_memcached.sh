#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function install_memcached(){
    [ -f "/root/.meteorite/tmp/install_memcached.lock" ] && echo -e "${RGB_INFO}Notice: Memcached installation script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/install_memcached.lock

    check_sources
    check_yum

    # 创建用户和组
    id -g memcached
    [ $? -ne 0 ] && groupadd memcached
    id -u memcached
    [ $? -ne 0 ] && useradd -g memcached -M -s /sbin/nologin memcached

    # 检测目录
    [ ! -d "${MEMCACHED_DIR}/etc" ] && mkdir -p ${MEMCACHED_DIR}/etc

    cd ${METEORITE_DIR}/src

    if [ ! -f "memcached-${MEMCACHED_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/memcached-${MEMCACHED_VER}.tar.gz
    fi

    if [ ! -f "memcached-${PECL_MEMCACHED_VER}.tgz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/memcached-${PECL_MEMCACHED_VER}.tgz
    fi

    if [ ! -f "libmemcached-${LIBMEMCACHED_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/libmemcached-${LIBMEMCACHED_VER}.tar.gz
    fi

    tar zxvf memcached-${MEMCACHED_VER}.tar.gz
    tar zxvf memcached-${PECL_MEMCACHED_VER}.tgz
    tar zxvf libmemcached-${LIBMEMCACHED_VER}.tar.gz

    # 编译 memcached
    cd ${METEORITE_DIR}/src/memcached-${MEMCACHED_VER}
    ./configure --prefix=${MEMCACHED_DIR}
    make -j${PROCESSOR} && make install

    cp ${METEORITE_DIR}/config/memcached.conf ${MEMCACHED_DIR}/etc/memcached
    sed -i "s@11211@${METEORITE_PORT}@" ${MEMCACHED_DIR}/etc/memcached

    cp scripts/memcached-tool ${MEMCACHED_DIR}/bin/memcached-tool

    ln -s ${MEMCACHED_DIR}/bin/* /usr/bin

    # 配置开机启动
    cat > /lib/systemd/system/memcached.service << "EOF"
[Unit]
Description=Memcached daemon
After=syslog.target network-online.target remote-fs.target nss-lookup.target

[Service]
EnvironmentFile=/usr/local/memcached/etc/memcached
ExecStart=/usr/local/memcached/bin/memcached -p ${PORT} -u ${USER} -m ${CACHESIZE} -c ${MAXCONN} $OPTIONS
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
PrivateDevices=true
CapabilityBoundingSet=CAP_SETGID CAP_SETUID CAP_SYS_RESOURCE
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

[Install]
WantedBy=multi-user.target
EOF
    sed -i "s@/usr/local/memcached@${MEMCACHED_DIR}@g" /lib/systemd/system/memcached.service

    systemctl enable memcached.service
    systemctl start memcached.service

    # 编译 libmemcached
    cd ${METEORITE_DIR}/src/libmemcached-${LIBMEMCACHED_VER}
    ./configure --with-memcached=${MEMCACHED_DIR}
    make -j${PROCESSOR} && make install

    # 编译 pecl-memcached
    cd ${METEORITE_DIR}/src/memcached-${PECL_MEMCACHED_VER}

    ${PHP_DIR}/bin/phpize
    ./configure --with-php-config=${PHP_DIR}/bin/php-config
    make -j${PROCESSOR} && make install

    echo -e 'extension=memcached.so\nmemcached.use_sasl=1' > ${PHP_DIR}/etc/php.d/memcached.ini

    if [[ $( netstat -anp | grep memcached | wc -l ) -ne 0 ]]; then
        echo -e "${RGB_SUCCESS}Notice: Memcached installed successfully!${RGB_END}"
        cd ${METEORITE_DIR}/src
        rm -rf memcached-${MEMCACHED_VER} memcached-${PECL_MEMCACHED_VER} libmemcached-${LIBMEMCACHED_VER}
    else
        echo -e "${RGB_ERROR}Error: Memcached installation failed!${RGB_END}"
        kill -9 $$
    fi
}