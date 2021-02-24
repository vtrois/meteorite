#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-02-24

function install_php(){
    [ -f "/root/.meteorite/tmp/install_php.lock" ] && echo -e "${RGB_INFO}Notice: PHP installation script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/install_php.lock

    check_yum

    # 创建用户和组
    id -g www
    [ $? -ne 0 ] && groupadd www
    id -u www
    [ $? -ne 0 ] && useradd -g www -M -s /sbin/nologin www

    # 检测目录
    [ ! -d "${LOGS_DIR}/php" ] && mkdir -p ${LOGS_DIR}/php
    [ ! -d "${PHP_DIR}/etc/php.d" ] && mkdir -p ${PHP_DIR}/etc/php.d

    cd ${METEORITE_DIR}/src

    if [ ! -f "libzip-${LIBZIP_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/libzip-${LIBZIP_VER}.tar.gz
    fi

    if [ ! -f "freetype-${FREETYPE_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/freetype-${FREETYPE_VER}.tar.gz
    fi

    if [ ! -f "libsodium-${LIBSODIUM_VER}-stable.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/libsodium-${LIBSODIUM_VER}-stable.tar.gz
    fi

    if [ ! -f "php-${PHP_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/php-${PHP_VER}.tar.gz
    fi

    tar zxvf php-${PHP_VER}.tar.gz

    # 检测安装 openssl
    [ ! -d ${OPENSSL_DIR} ] && install_openssl

    # 检测安装 libzip
    if [ ! -e '/usr/lib64/libzip.so' ]; then
        cd ${METEORITE_DIR}/src
        tar zxvf libzip-${LIBZIP_VER}.tar.gz
        cd libzip-${LIBZIP_VER}
        mkdir build && cd build && cmake3 -DCMAKE_INSTALL_PREFIX=/usr .. && make -j${PROCESSOR} && make install
    fi

    # 检测安装 freetype
    if [ ! -e "${FREETYPE_DIR}/lib/libfreetype.la" ]; then
        pip3 install docwriter
        cd ${METEORITE_DIR}/src
        tar zxvf freetype-${FREETYPE_VER}.tar.gz
        cd freetype-${FREETYPE_VER}
        ./configure --prefix=${FREETYPE_DIR} --enable-freetype-config
        make -j${PROCESSOR} && make install
        ln -sf ${FREETYPE_DIR}/include/freetype2/* /usr/include/
        [ -d /usr/local/lib/pkgconfig/ ] && cp ${FREETYPE_DIR}/lib/pkgconfig/freetype2.pc /usr/local/lib/pkgconfig/
    fi

    # 检测安装 libsodium
    if [ ! -e '/usr/local/lib/libsodium.la' ]; then
        cd ${METEORITE_DIR}/src
        tar zxvf libsodium-${LIBSODIUM_VER}-stable.tar.gz
        cd libsodium-stable
        ./configure --disable-dependency-tracking --enable-minimal
        make -j${PROCESSOR} && make install
    fi

    [ -z "`grep /usr/local/lib /etc/ld.so.conf.d/*.conf`" ] && echo '/usr/local/lib' > /etc/ld.so.conf.d/meteorite-local.conf
    ldconfig -v

    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/:$PKG_CONFIG_PATH

    cd ${METEORITE_DIR}/src/php-${PHP_VER}

    # 编译安装
    ./configure --prefix=${PHP_DIR} \
    --with-config-file-path=${PHP_DIR}/etc \
    --with-config-file-scan-dir=${PHP_DIR}/etc/php.d \
    --with-fpm-user=www \
    --with-fpm-group=www \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-iconv \
    --with-freetype \
    --with-jpeg \
    --with-zlib \
    --with-curl \
    --with-password-argon2 \
    --with-sodium \
    --with-openssl=${OPENSSL_DIR} \
    --with-mhash \
    --with-xsl \
    --with-zip \
    --with-gettext \
    --disable-fileinfo \
    --disable-debug \
    --disable-rpath \
    --enable-gd \
    --enable-fpm \
    --enable-opcache \
    --enable-xml \
    --enable-bcmath \
    --enable-shmop \
    --enable-exif \
    --enable-sysvsem \
    --enable-mbregex \
    --enable-mbstring \
    --enable-pcntl \
    --enable-sockets \
    --enable-ftp \
    --enable-intl \
    --enable-soap \
    --enable-mysqlnd

    make -j${PROCESSOR} && make install

    # 配置 PATH
    echo "export PATH=${PHP_DIR}/bin:\$PATH" > /etc/profile.d/php.sh
    source /etc/profile.d/php.sh

    # 配置开机启动
    cat > /lib/systemd/system/php.service << "EOF"
[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network-online.target remote-fs.target nss-lookup.target

[Service]
Type=simple
PIDFile=/run/php.pid
ExecStart=/usr/local/php/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php/etc/php-fpm.conf
ExecStop=/bin/kill -INT $MAINPID
ExecReload=/bin/kill -USR2 $MAINPID

[Install]
WantedBy=multi-user.target
EOF
    sed -i "s@/usr/local/php@${PHP_DIR}@g" /lib/systemd/system/php.service
    systemctl enable php.service

    # 安装 Composer
    # wget -c https://mirrors.cloud.tencent.com/composer/composer.phar -O /usr/local/bin/composer
    # chmod +x /usr/local/bin/composer
    # composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
    # composer clearcache

    # 配置 config
    cp ${METEORITE_DIR}/src/php-${PHP_VER}/php.ini-production ${PHP_DIR}/etc/php.ini
    sed -i 's@^short_open_tag = Off@short_open_tag = On@' ${PHP_DIR}/etc/php.ini
    sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' ${PHP_DIR}/etc/php.ini
    sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,readlink,symlink,popepassthru,stream_socket_server,fsocket,openlog,syslog@' ${PHP_DIR}/etc/php.ini
    sed -i 's@^;realpath_cache_size.*@realpath_cache_size = 2M@' ${PHP_DIR}/etc/php.ini
    sed -i 's@^expose_php = On@expose_php = Off@' ${PHP_DIR}/etc/php.ini
    sed -i 's@^max_execution_time.*@max_execution_time = 600@' ${PHP_DIR}/etc/php.ini
    sed -i "s@^memory_limit.*@memory_limit = ${MEMORY_LIMIT}M@" ${PHP_DIR}/etc/php.ini
    sed -i 's@^request_order.*@request_order = "CGP"@' ${PHP_DIR}/etc/php.ini
    sed -i 's@^post_max_size.*@post_max_size = 100M@' ${PHP_DIR}/etc/php.ini
    sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' ${PHP_DIR}/etc/php.ini
    sed -i 's@^;sendmail_path.*@sendmail_path = /usr/sbin/sendmail -t -i@' ${PHP_DIR}/etc/php.ini
    sed -i "s@^;date.timezone.*@date.timezone = ${TIMEZONE}@" ${PHP_DIR}/etc/php.ini
    sed -i "s@^;curl.cainfo.*@curl.cainfo = \"${OPENSSL_DIR}/cert.pem\"@" ${PHP_DIR}/etc/php.ini
    sed -i "s@^;openssl.cafile.*@openssl.cafile = \"${OPENSSL_DIR}/cert.pem\"@" ${PHP_DIR}/etc/php.ini
    sed -i "s@^;openssl.capath.*@openssl.capath = \"${OPENSSL_DIR}/cert.pem\"@" ${PHP_DIR}/etc/php.ini
    sed -i "s@^;error_log = syslog.*@error_log = \"${LOGS_DIR}/php/php_error.log\"@" ${PHP_DIR}/etc/php.ini
    sed -i 's@^pdo_mysql.default_socket.*@pdo_mysql.default_socket = /data/mariadb/mariadb.sock@' ${PHP_DIR}/etc/php.ini
    sed -i 's@^mysqli.default_socket.*@mysqli.default_socket = /data/mariadb/mariadb.sock@' ${PHP_DIR}/etc/php.ini

    cat > ${PHP_DIR}/etc/php-fpm.conf << EOF
;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
pid = /run/php.pid
error_log = ${LOGS_DIR}/php/php_error.log
log_level = warning

emergency_restart_threshold = 30
emergency_restart_interval = 60s
process_control_timeout = 5s
daemonize = yes

;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;

[www]
listen = /dev/shm/php-fpm.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0660
user = www
group = www

pm = dynamic

pm.max_children = 50
pm.start_servers = 30
pm.min_spare_servers = 20
pm.max_spare_servers = 50

pm.max_requests = 2048
pm.process_idle_timeout = 10s
pm.status_path = /php-fpm_status

request_terminate_timeout = 120

request_slowlog_timeout = 0
slowlog = ${LOGS_DIR}/php/php_slow.log

rlimit_files = $( ulimit -n )
rlimit_core = 0

catch_workers_output = yes

env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF

    if [ ${CHECK_MEM} -le 3000 ]; then
      sed -i "s@^pm.max_children.*@pm.max_children = $((${CHECK_MEM}/3/20))@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.start_servers.*@pm.start_servers = $((${CHECK_MEM}/3/30))@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = $((${CHECK_MEM}/3/40))@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = $((${CHECK_MEM}/3/20))@" ${PHP_DIR}/etc/php-fpm.conf
    elif [ ${CHECK_MEM} -gt 3000 -a ${CHECK_MEM} -le 4500 ]; then
      sed -i "s@^pm.max_children.*@pm.max_children = 50@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.start_servers.*@pm.start_servers = 30@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 20@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 50@" ${PHP_DIR}/etc/php-fpm.conf
    elif [ ${CHECK_MEM} -gt 4500 -a ${CHECK_MEM} -le 6500 ]; then
      sed -i "s@^pm.max_children.*@pm.max_children = 60@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.start_servers.*@pm.start_servers = 40@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 30@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 60@" ${PHP_DIR}/etc/php-fpm.conf
    elif [ ${CHECK_MEM} -gt 6500 -a ${CHECK_MEM} -le 8500 ]; then
      sed -i "s@^pm.max_children.*@pm.max_children = 70@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.start_servers.*@pm.start_servers = 50@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 40@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 70@" ${PHP_DIR}/etc/php-fpm.conf
    elif [ ${CHECK_MEM} -gt 8500 ]; then
      sed -i "s@^pm.max_children.*@pm.max_children = 80@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.start_servers.*@pm.start_servers = 60@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 50@" ${PHP_DIR}/etc/php-fpm.conf
      sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 80@" ${PHP_DIR}/etc/php-fpm.conf
    fi

    cat > ${PHP_DIR}/etc/php.d/opcache.ini << EOF
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=${MEM_LEVEL}
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=100000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
opcache.consistency_checks=0
opcache.jit_buffer_size=128M
opcache.jit=1255
zend_extension=opcache.so
EOF

    systemctl start php.service

    # 配置日志分割
    cat > /etc/logrotate.d/php << "EOF"
/data/logs/php/*.log {
    daily
    compress
    rotate 30
    missingok
    notifempty
    dateext
    sharedscripts
    postrotate
        if [ -f /run/php.pid ]; then
            kill -USR1 `cat /run/php.pid`
        fi
    endscript
}
EOF
    sed -i "s@/data/logs@${LOGS_DIR}@g" /etc/logrotate.d/php

    if [[ $( netstat -anp | grep php | wc -l ) -ne 0 ]]; then
        echo -e "${RGB_SUCCESS}Notice: PHP installed successfully!${RGB_END}"
        cd ${METEORITE_DIR}/src
        rm -rf libzip-${LIBZIP_VER} freetype-${FREETYPE_VER} libsodium-stable php-${PHP_VER} redis-${PECL_REDIS_VER} ${PHP_DIR}/etc/php-fpm.d ${PHP_DIR}/etc/php-fpm.conf.default
    else
        echo -e "${RGB_ERROR}Error: PHP installation failed!${RGB_END}"
        kill -9 $$
    fi
}