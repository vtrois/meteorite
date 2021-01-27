#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function install_openresty(){
    [ -f "${METEORITE_DIR}/tmp/install_openresty.lock" ] && echo -e "${RGB_INFO}Notice: OpenResty installation script has already been run!${RGB_END}" && return
    touch ${METEORITE_DIR}/tmp/install_openresty.lock

    check_sources
    check_yum

    # 创建用户和组
    id -g www
    [ $? -ne 0 ] && groupadd www
    id -u www
    [ $? -ne 0 ] && useradd -g www -M -s /sbin/nologin www

    # 检测目录
    [ ! -d "${LOGS_DIR}/nginx" ] && mkdir -p ${LOGS_DIR}/nginx
    [ ! -d "${WWW_DIR}/default" ] && mkdir -p ${WWW_DIR}/default
    for OPENRESTY_DIR_NAME in conf.d rewrite ssl; do
        [ ! -d "${OPENRESTY_DIR}/nginx/conf/${OPENRESTY_DIR_NAME}" ] && mkdir -p ${OPENRESTY_DIR}/nginx/conf/${OPENRESTY_DIR_NAME}
    done

    chown -R www:www ${WWW_DIR}/default

    cd ${METEORITE_DIR}/src

    if [ ! -f "pcre-${PCRE_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/pcre-${PCRE_VER}.tar.gz
    fi

    if [ ! -f "openssl-${OPENSSL_VER}.tar.gz" ]; then
        wget https://mirrors.cloud.tencent.com/openssl/source/openssl-${OPENSSL_VER}.tar.gz
    fi

    if [ ! -f "openresty-${OPENRESTY_VER}.tar.gz" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/openresty-${OPENRESTY_VER}.tar.gz
    fi

    if [ ! -f "jemalloc-${JEMALLOC_VER}.tar.bz2" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/jemalloc-${JEMALLOC_VER}.tar.bz2
    fi

    tar zxvf pcre-${PCRE_VER}.tar.gz
    tar zxvf openssl-${OPENSSL_VER}.tar.gz
    tar zxvf openresty-${OPENRESTY_VER}.tar.gz

    # 检测安装 ngx_brotli
    if [ ! -d 'ngx_brotli' ]; then
        cd ${METEORITE_DIR}/src
        git clone https://e.coding.net/vtrois-inc/mirrors/ngx_brotli.git
        cd ngx_brotli
        git submodule update --init
        cd deps
        rm -rf brotli
        git clone https://e.coding.net/vtrois-inc/mirrors/brotli.git
    fi

    # 检测安装 jemalloc
    if [ ! -e '/usr/local/lib/libjemalloc.so' ]; then
        cd ${METEORITE_DIR}/src
        tar jxvf jemalloc-${JEMALLOC_VER}.tar.bz2
        cd jemalloc-${JEMALLOC_VER}
        ./configure
        make -j${PROCESSOR} && make install
        if [ -f '/usr/local/lib/libjemalloc.so' ]; then
            ln -s /usr/local/lib/libjemalloc.so.2 /usr/lib64/libjemalloc.so.1
        fi
    fi

    [ -z "`grep /usr/local/lib /etc/ld.so.conf.d/*.conf`" ] && echo '/usr/local/lib' > /etc/ld.so.conf.d/meteorite-local.conf
    ldconfig -v

    cd ${METEORITE_DIR}/src/openresty-${OPENRESTY_VER}

    # 关闭 debug
    sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' bundle/nginx-${OPENRESTY_VER%.*}/auto/cc/gcc

    # 替换 Nginx 版本名
    sed -i 's@^#define NGINX_VER .*$@#define NGINX_VER          "Meteorite"@' bundle/nginx-${OPENRESTY_VER%.*}/src/core/nginx.h
    sed -i 's@^static u_char ngx_http_server_string.*$@static u_char ngx_http_server_string[] = "Server: Meteorite" CRLF;@' bundle/nginx-${OPENRESTY_VER%.*}/src/http/ngx_http_header_filter_module.c
    sed -i 's@openresty@Meteorite@g' bundle/nginx-${OPENRESTY_VER%.*}/src/http/ngx_http_special_response.c

    # 编译安装
    ./configure --prefix=${OPENRESTY_DIR} \
    --user=www \
    --group=www \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-openssl=${METEORITE_DIR}/src/openssl-${OPENSSL_VER} \
    --with-pcre=${METEORITE_DIR}/src/pcre-${PCRE_VER} \
    --with-pcre-jit \
    --with-ld-opt='-ljemalloc -Wl,-u,pcre_version' \
    --add-module=${METEORITE_DIR}/src/ngx_brotli

    make -j${PROCESSOR} && make install

    # 配置 PATH
    echo "export PATH=${OPENRESTY_DIR}/nginx/sbin:\$PATH" > /etc/profile.d/openresty.sh
    source /etc/profile.d/openresty.sh

    # 配置开机启动
    cat > /lib/systemd/system/nginx.service << "EOF"
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPost=/bin/sleep 0.1
ExecStartPre=/usr/local/openresty/nginx/sbin/nginx -t
ExecStart=/usr/local/openresty/nginx/sbin/nginx
ExecReload=/usr/local/openresty/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    sed -i "s@/usr/local/openresty@${OPENRESTY_DIR}@g" /lib/systemd/system/nginx.service
    systemctl enable nginx.service

    # 配置 config
    cp ${METEORITE_DIR}/config/nginx.conf ${OPENRESTY_DIR}/nginx/conf/nginx.conf
    cp ${METEORITE_DIR}/config/default.conf ${OPENRESTY_DIR}/nginx/conf/conf.d/default.conf
    cp ${METEORITE_DIR}/config/general.conf ${OPENRESTY_DIR}/nginx/conf/rewrite/general.conf
    cp ${METEORITE_DIR}/config/security.conf ${OPENRESTY_DIR}/nginx/conf/rewrite/security.conf
    cp ${METEORITE_DIR}/config/fastcgi.conf ${OPENRESTY_DIR}/nginx/conf/fastcgi.conf

    sed -i "s@/usr/local/openresty@${OPENRESTY_DIR}@g" ${OPENRESTY_DIR}/nginx/conf/nginx.conf
    sed -i "s@/data/logs@${LOGS_DIR}@g" ${OPENRESTY_DIR}/nginx/conf/nginx.conf
    sed -i "s@/data/www@${WWW_DIR}@g" ${OPENRESTY_DIR}/nginx/conf/conf.d/default.conf
    sed -i "s@/data/logs@${LOGS_DIR}@g" ${OPENRESTY_DIR}/nginx/conf/conf.d/default.conf
    sed -i "s@Mver@${METEORITE_VER}@g" ${OPENRESTY_DIR}/nginx/conf/fastcgi.conf

    systemctl start nginx.service

    # 配置日志分割
    cat > /etc/logrotate.d/nginx << "EOF"
/data/logs/nginx/*.log {
    daily
    compress
    rotate 30
    missingok
    notifempty
    dateext
    sharedscripts
    postrotate
        if [ -f /run/nginx.pid ]; then
            kill -USR1 `cat /run/nginx.pid`
        fi
    endscript
}
EOF
    sed -i "s@/data/logs@${LOGS_DIR}@g" /etc/logrotate.d/nginx

    if [[ $( netstat -anput | grep nginx | wc -l ) -ne 0 ]]; then
        echo -e "${RGB_SUCCESS}Notice: OpenResty installed successfully!${RGB_END}"
        cd ${METEORITE_DIR}/src
        rm -rf pcre-${PCRE_VER} openssl-${OPENSSL_VER} openresty-${OPENRESTY_VER} jemalloc-${JEMALLOC_VER} ngx_brotli /usr/local/openresty/nginx/conf/*.default
    else
        echo -e "${RGB_ERROR}Error: OpenResty installation failed!${RGB_END}"
        kill -9 $$
    fi
}