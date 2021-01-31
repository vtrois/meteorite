#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function service_overview(){
    clear
    check_info

    if [ -f "/root/.meteorite/tmp/install_openresty.lock" ];then
    echo -e "${RGB_WARNING}OpenrResty Overview (Contains the Version, Directory, Config File and Log File)${RGB_END}"
    echo -e "${RGB_INFO}Server Version    ${RGB_END}: ${OPENRESTY_VER}"
    echo -e "${RGB_INFO}Install Directory ${RGB_END}: ${OPENRESTY_DIR}"
    echo -e "${RGB_INFO}Data Directory    ${RGB_END}: ${WWW_DIR}"
    echo -e "${RGB_INFO}Config Directory  ${RGB_END}: ${OPENRESTY_DIR}/nginx/conf"
    echo -e "${RGB_INFO}Service File      ${RGB_END}: /lib/systemd/system/nginx.service"
    echo -e "${RGB_INFO}Access Log        ${RGB_END}: ${LOGS_DIR}/nginx/access.log"
    echo -e "${RGB_INFO}Error Log         ${RGB_END}: ${LOGS_DIR}/nginx/error.log\n"
    fi

    if [ -f "/root/.meteorite/tmp/install_mariadb.lock" ];then
    echo -e "${RGB_WARNING}MariaDB Overview (Contains the Version, Port, Directory, Config File and Log File)${RGB_END}"
    echo -e "${RGB_INFO}Server Version    ${RGB_END}: ${MARIADB_VER}"
    echo -e "${RGB_INFO}Server Port       ${RGB_END}: ${MARIADB_PORT}"
    echo -e "${RGB_INFO}Password          ${RGB_END}: ${MARIADB_PSW}"
    echo -e "${RGB_INFO}Install Directory ${RGB_END}: ${MARIADB_DIR}"
    echo -e "${RGB_INFO}Data Directory    ${RGB_END}: ${MARIADB_DATA_DIR}"
    echo -e "${RGB_INFO}Service File      ${RGB_END}: /etc/init.d/mariadb"
    echo -e "${RGB_INFO}Config File       ${RGB_END}: /etc/my.cnf"
    echo -e "${RGB_INFO}Slow Query Log    ${RGB_END}: ${LOGS_DIR}/mariadb/mysql_error.log"
    echo -e "${RGB_INFO}Error Log         ${RGB_END}: ${LOGS_DIR}/mariadb/mysql_error.log\n"
    fi

    if [ -f "/root/.meteorite/tmp/install_php.lock" ];then
    echo -e "${RGB_WARNING}PHP Overview (Contains the Version, Directory, Config File and Log File)${RGB_END}"
    echo -e "${RGB_INFO}Server Version    ${RGB_END}: ${PHP_VER}"
    echo -e "${RGB_INFO}Install Directory ${RGB_END}: ${PHP_DIR}"
    echo -e "${RGB_INFO}Config Directory  ${RGB_END}: ${PHP_DIR}/etc/php.d"
    echo -e "${RGB_INFO}Service File      ${RGB_END}: /lib/systemd/system/php.service"
    echo -e "${RGB_INFO}Config File       ${RGB_END}: ${PHP_DIR}/etc/php.ini"
    echo -e "${RGB_INFO}Slow Log          ${RGB_END}: ${LOGS_DIR}/php/php_slow.log"
    echo -e "${RGB_INFO}Error Log         ${RGB_END}: ${LOGS_DIR}/php/php_error.log\n"
    fi

    if [ -f "/root/.meteorite/tmp/install_redis.lock" ];then
    echo -e "${RGB_WARNING}Redis Overview (Contains the Version, Directory, Port, Config File, Log File and Password)${RGB_END}"
    echo -e "${RGB_INFO}Server Version    ${RGB_END}: ${REDIS_VER}"
    echo -e "${RGB_INFO}Pecl Version      ${RGB_END}: ${PECL_REDIS_VER}"
    echo -e "${RGB_INFO}Password          ${RGB_END}: ${REDIS_PSW}"
    echo -e "${RGB_INFO}Server Port       ${RGB_END}: ${REDIS_PORT}"
    echo -e "${RGB_INFO}Install Directory ${RGB_END}: ${REDIS_DIR}"
    echo -e "${RGB_INFO}Service File      ${RGB_END}: /lib/systemd/system/redis.service"
    echo -e "${RGB_INFO}Config File       ${RGB_END}: ${REDIS_DIR}/config/redis.conf"
    echo -e "${RGB_INFO}Log File          ${RGB_END}: ${LOGS_DIR}/redis/redis.log\n"
    fi

    if [ -f "/root/.meteorite/tmp/install_memcached.lock" ];then
    echo -e "${RGB_WARNING}Memcached Overview (Contains the Version, Port and Directory)${RGB_END}"
    echo -e "${RGB_INFO}Server Version    ${RGB_END}: ${MEMCACHED_VER}"
    echo -e "${RGB_INFO}Pecl Version      ${RGB_END}: ${PECL_MEMCACHED_VER}"
    echo -e "${RGB_INFO}Lib Version       ${RGB_END}: ${LIBMEMCACHED_VER}"
    echo -e "${RGB_INFO}Server Port       ${RGB_END}: ${METEORITE_PORT}"
    echo -e "${RGB_INFO}Install Directory ${RGB_END}: ${MEMCACHED_DIR}\n"
    fi

    if [ -f "/root/.meteorite/tmp/install_imagemagick.lock" ];then
    echo -e "${RGB_WARNING}ImageMagick Overview (Contains the Version and Directory)${RGB_END}"
    echo -e "${RGB_INFO}Server Version    ${RGB_END}: ${IMAGEMAGICK_VER}"
    echo -e "${RGB_INFO}Pecl Version      ${RGB_END}: ${PECL_IMAGICK_VER}"
    echo -e "${RGB_INFO}Install Directory ${RGB_END}: ${IMAGEMAGICK_DIR}\n"
    fi

    if [ ! -f "/root/.meteorite/tmp/install_openresty.lock" ] && [ ! -f "/root/.meteorite/tmp/install_mariadb.lock" ] && [ ! -f "/root/.meteorite/tmp/install_php.lock" ] && [ ! -f "/root/.meteorite/tmp/install_redis.lock" ] && [ ! -f "/root/.meteorite/tmp/install_memcached.lock" ] && [ ! -f "/root/.meteorite/tmp/install_imagemagick.lock" ];then
        echo -e "${RGB_INFO}Maybe you haven't run the Meteorite tool yet!${RGB_END}"
    fi
}