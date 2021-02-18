#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-02-18

function install_fileinfo(){
    [ -f "/root/.meteorite/tmp/install_fileinfo.lock" ] && echo -e "${RGB_INFO}Notice: Fileinfo installation script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/install_fileinfo.lock

    check_yum

    cd ${METEORITE_DIR}/src

    if [ ! -f "php-${PHP_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/php-${PHP_VER}.tar.gz
    fi

    tar zxvf php-${PHP_VER}.tar.gz

    cd ${METEORITE_DIR}/src/php-${PHP_VER}/ext/fileinfo

    ${PHP_DIR}/bin/phpize
    ./configure CFLAGS="-std=c99 -g -O2" --with-php-config=${PHP_DIR}/bin/php-config
    make clean
    make -j${PROCESSOR} && make install

    echo 'extension=fileinfo.so' > ${PHP_DIR}/etc/php.d/fileinfo.ini

    rm -rf ${METEORITE_DIR}/src/php-${PHP_VER}
}