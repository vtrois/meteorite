#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function install_imagemagick(){
    [ -f "/root/.meteorite/tmp/install_imagemagick.lock" ] && echo -e "${RGB_INFO}Notice: ImageMagick installation script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/install_imagemagick.lock

    check_yum

    # 检测目录
    [ ! -d "${IMAGEMAGICK_DIR}" ] && mkdir -p ${IMAGEMAGICK_DIR}

    cd ${METEORITE_DIR}/src

    if [ ! -f "ImageMagick-${IMAGEMAGICK_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/ImageMagick-${IMAGEMAGICK_VER}.tar.gz
    fi

    if [ ! -f "imagick-${PECL_IMAGICK_VER}.tgz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/imagick-${PECL_IMAGICK_VER}.tgz
    fi

    tar zxvf ImageMagick-${IMAGEMAGICK_VER}.tar.gz
    tar zxvf imagick-${PECL_IMAGICK_VER}.tgz

    # 编译 ImageMagick
    cd ImageMagick-${IMAGEMAGICK_VER}
    ./configure --prefix=${IMAGEMAGICK_DIR} --enable-shared --enable-static
    make -j${PROCESSOR} && make install

    ln -s ${IMAGEMAGICK_DIR}/bin/convert /usr/bin

    # 编译 pecl-imagick
    # PHP 8 暂不支持 imagick https://github.com/Imagick/imagick/issues/358
    cd ${METEORITE_DIR}/src/imagick-${PECL_IMAGICK_VER}

    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/:$PKG_CONFIG_PATH
    ${PHP_DIR}/bin/phpize
    ./configure --with-php-config=${PHP_DIR}/bin/php-config --with-imagick=${IMAGEMAGICK_DIR}
    make -j${PROCESSOR} && make install

    echo 'extension=imagick.so' > ${PHP_DIR}/etc/php.d/imagick.ini

    cd ${METEORITE_DIR}/src
    rm -rf ImageMagick-${IMAGEMAGICK_VER} imagick-${PECL_IMAGICK_VER}
}