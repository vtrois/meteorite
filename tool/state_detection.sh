#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-30

function state_detection(){
    clear
    check_info

    echo -e "\n${RGB_WARNING}============= System Version Detection =============${RGB_END}"
    cat /etc/redhat-release

    echo -e "\n${RGB_WARNING}============= Kernel Version Detection =============${RGB_END}"
    rpm -qa | grep -i kernel

    echo -e "\n${RGB_WARNING}============= Grub Config Detection =============${RGB_END}"
    cat /etc/default/grub

    echo -e "\n${RGB_WARNING}============= Git Version Detection =============${RGB_END}"
    git --version

    echo -e "\n${RGB_WARNING}============= OpenSSL Version Detection =============${RGB_END}"
    openssl version -a
    if [ -f "/root/.meteorite/tmp/init_system.lock" ];then
        ls -l ${OPENSSL_DIR}/cacert.pem
    fi

    echo -e "\n${RGB_WARNING}============= OpenSSH Version Detection =============${RGB_END}"
    ssh -V

    if [ -f "/root/.meteorite/tmp/init_system.lock" ];then
        echo -e "\n${RGB_WARNING}============= Custom Config Detection =============${RGB_END}"
        cat /etc/profile.d/meteorite.sh
    fi

    echo -e "\n${RGB_WARNING}============= Journald Config Detection =============${RGB_END}"
    grep "^[^#.*]" /etc/systemd/journald.conf

    echo -e "\n${RGB_WARNING}============= PATH Config Detection =============${RGB_END}"
    cat ~/.bash_profile

    echo -e "\n${RGB_WARNING}============= Timezone Detection =============${RGB_END}"
    ls -ln /etc/localtime

    echo -e "\n${RGB_WARNING}============= SELinux Service Detection =============${RGB_END}"
    sestatus

    echo -e "\n${RGB_WARNING}============= firewalld Service Detection =============${RGB_END}"
    systemctl status firewalld.service

    echo -e "\n${RGB_WARNING}============= Directory Permission Detection =============${RGB_END}"
    ls -la /etc/passwd
    ls -la /etc/group
    ls -la /etc/shadow
    ls -la /etc/gshadow

    echo -e "\n${RGB_WARNING}============= User & Group Detection =============${RGB_END}"
    cut -d : -f 1 /etc/passwd
    cat /etc/group

    if [ -f "/root/.meteorite/tmp/init_system.lock" ];then
        echo -e "\n${RGB_WARNING}============= Time-out Detection =============${RGB_END}"
        cat /etc/profile.d/time_out.sh
    fi

    echo -e "\n${RGB_WARNING}============= Password Validity Detection =============${RGB_END}"
    grep "^[^#.*]" /etc/default/useradd

    echo -e "\n${RGB_WARNING}============= Password Policy Detection =============${RGB_END}"
    grep "^[^#.*]" /etc/login.defs

    echo -e "\n${RGB_WARNING}============= Updatedb Detection =============${RGB_END}"
    cat /etc/updatedb.conf

    echo -e "\n${RGB_WARNING}============= PAM Detection =============${RGB_END}"
    grep "^[^#.*]" /etc/pam.d/system-auth

    grep "^[^#.*]" /etc/pam.d/password-auth

    echo -e "\n${RGB_WARNING}============= SSH Config Detection =============${RGB_END}"
    grep "^[^#.*]" /etc/ssh/sshd_config

    echo -e "\n${RGB_WARNING}============= Resource Limit Detection =============${RGB_END}"
    grep "^[^#.*]" /etc/security/limits.conf

    grep "^[^#.*]" /etc/systemd/system.conf

    echo -e "\n${RGB_WARNING}============= Sysctl Config Detection =============${RGB_END}"
    grep "^[^#.*]" /etc/sysctl.conf

    if [ ${CHECK_UNAME} -ge 5 ]; then
        echo -e "\n${RGB_WARNING}============= BBR Detection =============${RGB_END}"
        sysctl -n net.ipv4.tcp_congestion_control
        lsmod | grep bbr
    fi

    if [ "${CHECK_IPV6}" == "true" ]; then
        echo -e "\n${RGB_WARNING}============= IPV6 Detection =============${RGB_END}"
        grep "^[^#.*]" /etc/sysconfig/network-scripts/ifcfg-eth0
    fi

    echo -e "\n${RGB_WARNING}============= Hostname Detection =============${RGB_END}"
    cat /etc/hostname
    cat /etc/hosts

    echo -e "\n${RGB_WARNING}============= Repo List Detection =============${RGB_END}"
    yum repolist all

    if [ -f "/root/.meteorite/tmp/install_openresty.lock" ];then
        echo -e "\n${RGB_WARNING}============= Nginx Version Detection =============${RGB_END}"
        ${OPENRESTY_DIR}/nginx/sbin/nginx -V

        echo -e "\n${RGB_WARNING}============= Nginx Service Detection =============${RGB_END}"
        cat /lib/systemd/system/nginx.service

        echo -e "\n${RGB_WARNING}============= Nginx Config Detection =============${RGB_END}"
        cat ${OPENRESTY_DIR}/nginx/conf/nginx.conf
        cat ${OPENRESTY_DIR}/nginx/conf/conf.d/default.conf
        cat ${OPENRESTY_DIR}/nginx/conf/rewrite/general.conf
        cat ${OPENRESTY_DIR}/nginx/conf/rewrite/security.conf
        cat ${OPENRESTY_DIR}/nginx/conf/fastcgi.conf

        echo -e "\n${RGB_WARNING}============= Nginx Logrotate Detection =============${RGB_END}"
        cat /etc/logrotate.d/nginx
    fi

    if [ -f "/root/.meteorite/tmp/install_php.lock" ];then
        echo -e "\n${RGB_WARNING}============= PHP Version Detection =============${RGB_END}"
        ${PHP_DIR}/bin/php -v

        echo -e "\n${RGB_WARNING}============= PHP Service Detection =============${RGB_END}"
        cat /lib/systemd/system/php.service

        echo -e "\n${RGB_WARNING}============= PHP Config Detection =============${RGB_END}"
        grep "^[^;.*]" ${PHP_DIR}/etc/php.ini

        echo -e "\n${RGB_WARNING}============= PHP-FPM Config Detection =============${RGB_END}"
        grep "^[^;.*]" ${PHP_DIR}/etc/php-fpm.conf

        echo -e "\n${RGB_WARNING}============= Opcache PECL Detection =============${RGB_END}"
        cat ${PHP_DIR}/etc/php.d/opcache.ini

        echo -e "\n${RGB_WARNING}============= PHP Logrotate Detection =============${RGB_END}"
        cat /etc/logrotate.d/php
    fi

    if [ -f "/root/.meteorite/tmp/install_mariadb.lock" ];then
        echo -e "\n${RGB_WARNING}============= Mariadb Version Detection =============${RGB_END}"
        ${MARIADB_DIR}/bin/mysql -V

        echo -e "\n${RGB_WARNING}============= Mariadb Config Detection =============${RGB_END}"
        grep "^[^#.*]" /etc/my.cnf
    fi

    if [ -f "/root/.meteorite/tmp/install_redis.lock" ];then
        echo -e "\n${RGB_WARNING}============= Redis Version Detection =============${RGB_END}"
        ${REDIS_DIR}/bin/redis-server -v

        echo -e "\n${RGB_WARNING}============= Redis Service Detection =============${RGB_END}"
        cat /lib/systemd/system/redis.service

        echo -e "\n${RGB_WARNING}============= Redis Config Detection =============${RGB_END}"
        cat ${REDIS_DIR}/config/redis.conf | grep -v '^$' | grep -v '^#' | grep -v '^;'

        echo -e "\n${RGB_WARNING}============= Redis PECL Detection =============${RGB_END}"
        cat ${PHP_DIR}/etc/php.d/redis.ini

        echo -e "\n${RGB_WARNING}============= transparent_hugepage Detection =============${RGB_END}"
        cat /sys/kernel/mm/transparent_hugepage/enabled
        cat /sys/kernel/mm/transparent_hugepage/defrag
    fi

    if [ -f "/root/.meteorite/tmp/install_memcached.lock" ];then
        echo -e "\n${RGB_WARNING}============= Memcached Version Detection =============${RGB_END}"
        ${MEMCACHED_DIR}/bin/memcached -V

        echo -e "\n${RGB_WARNING}============= Memcached Service Detection =============${RGB_END}"
        cat /lib/systemd/system/memcached.service

        echo -e "\n${RGB_WARNING}============= Memcached Config Detection =============${RGB_END}"
        cat ${MEMCACHED_DIR}/etc/memcached

        echo -e "\n${RGB_WARNING}============= Memcached PECL Detection =============${RGB_END}"
        cat ${PHP_DIR}/etc/php.d/memcached.ini
    fi

    if [ -f "/root/.meteorite/tmp/install_imagemagick.lock" ];then
        echo -e "\n${RGB_WARNING}============= ImageMagick Version Detection =============${RGB_END}"
        /usr/local/imagemagick/bin/convert -version
    fi
}