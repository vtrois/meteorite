#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function install_redis(){
    [ -f "${METEORITE_DIR}/tmp/install_redis.lock" ] && echo -e "${RGB_INFO}Notice: Redis installation script has already been run!${RGB_END}" && return
    touch ${METEORITE_DIR}/tmp/install_redis.lock

    check_yum

    # 创建用户和组
    id -g redis
    [ $? -ne 0 ] && groupadd redis
    id -u redis
    [ $? -ne 0 ] && useradd -g redis -M -s /sbin/nologin redis

    # 检测目录
    [ ! -d "${LOGS_DIR}/redis" ] && mkdir -p ${LOGS_DIR}/redis
    for REDIS_DIR_NAME in config var; do
        [ ! -d "${REDIS_DIR}/${REDIS_DIR_NAME}" ] && mkdir -p ${REDIS_DIR}/${REDIS_DIR_NAME}
    done

    cd ${METEORITE_DIR}/src

    if [ ! -f "redis-${REDIS_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/redis-${REDIS_VER}.tar.gz
    fi

    if [ ! -f "redis-${PECL_REDIS_VER}.tgz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/redis-${PECL_REDIS_VER}.tgz
    fi

    tar zxvf redis-${REDIS_VER}.tar.gz
    tar zxvf redis-${PECL_REDIS_VER}.tgz

    # 编译 redis
    cd ${METEORITE_DIR}/src/redis-${REDIS_VER}
    make -j${PROCESSOR} && make PREFIX=${REDIS_DIR} install

    ln -s ${REDIS_DIR}/bin/* /usr/bin/

    cp ${METEORITE_DIR}/src/redis-${REDIS_VER}/redis.conf ${REDIS_DIR}/config/redis.conf
    sed -i "s@^port 6379@port ${REDIS_PORT}@" ${REDIS_DIR}/config/redis.conf
    sed -i "s@^daemonize no@daemonize yes@" ${REDIS_DIR}/config/redis.conf
    sed -i "s@^supervised no@supervised systemd@" ${REDIS_DIR}/config/redis.conf
    sed -i "s@/var/run/redis_6379.pid@/run/redis.pid@" ${REDIS_DIR}/config/redis.conf
    sed -i "s@^loglevel notice@loglevel warning@" ${REDIS_DIR}/config/redis.conf
    sed -i "s@^logfile \"\"@logfile ${LOGS_DIR}/redis/redis.log@" ${REDIS_DIR}/config/redis.conf
    sed -i "s@^dir ./@dir ${REDIS_DIR}/var@" ${REDIS_DIR}/config/redis.conf
    sed -i "s@# requirepass foobared@requirepass ${SET_REDIS_PSW}@" ${REDIS_DIR}/config/redis.conf
    sed -i "s@# maxmemory <bytes>@maxmemory ${MAXMEMORY}000000@" ${REDIS_DIR}/config/redis.conf
    sed -i "s@# rename-command CONFIG \"\"@rename-command FLUSHALL \"\" \nrename-command CONFIG   \"\" \nrename-command EVAL     \"\" \nrename-command FLUSHDB  \"\"@" ${REDIS_DIR}/config/redis.conf

    chown -R redis:redis ${REDIS_DIR}/{var,config} ${LOGS_DIR}/redis

    # 配置开机启动
    cat > /lib/systemd/system/redis.service << "EOF"
[Unit]
Description=The Redis data structure server
After=syslog.target network-online.target remote-fs.target nss-lookup.target

[Service]
User=redis
Group=redis

Type=forking
PIDFile=/run/redis.pid

PermissionsStartOnly=true
ExecStartPost=/bin/sleep 0.1
ExecStartPre=/bin/touch /run/redis.pid
ExecStartPre=/bin/chown -R redis:redis /run/redis.pid
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/config/redis.conf
ExecStop=/bin/kill -s TERM $MAINPID
Restart=always
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    sed -i "s@/usr/local/redis@${REDIS_DIR}@g" /lib/systemd/system/redis.service

    echo never >> /sys/kernel/mm/transparent_hugepage/enabled
    echo never >> /sys/kernel/mm/transparent_hugepage/defrag

    echo -e "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then\necho never > /sys/kernel/mm/transparent_hugepage/enabled\nfi" >> /etc/rc.local
    echo -e "if test -f /sys/kernel/mm/transparent_hugepage/defrag; then\necho never > /sys/kernel/mm/transparent_hugepage/defrag\nfi" >> /etc/rc.local

    systemctl enable redis.service
    systemctl start redis.service

    # 编译 pecl-redis
    cd ${METEORITE_DIR}/src/redis-${PECL_REDIS_VER}

    ${PHP_DIR}/bin/phpize
    ./configure --with-php-config=${PHP_DIR}/bin/php-config
    make -j${PROCESSOR} && make install

    echo 'extension=redis.so' > ${PHP_DIR}/etc/php.d/redis.ini

    if [[ $( netstat -anp | grep redis | wc -l ) -ne 0 ]]; then
        echo -e "${RGB_SUCCESS}Notice: Redis installed successfully!${RGB_END}"
        cd ${METEORITE_DIR}/src
        rm -rf redis-${REDIS_VER} redis-${PECL_REDIS_VER}
    else
        echo -e "${RGB_ERROR}Error: Redis installation failed!${RGB_END}"
        kill -9 $$
    fi
}