#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function install_mariadb(){
    [ -f "${METEORITE_DIR}/tmp/install_mariadb.lock" ] && echo -e "${RGB_INFO}Notice: MariaDB installation script has already been run!${RGB_END}" && return
    touch ${METEORITE_DIR}/tmp/install_mariadb.lock

    TENCENTCLOUD=$( wget -qO- -t1 -T2 metadata.tencentyun.com )
    ALICLOUD=$( wget -qO- -t1 -T2 100.100.100.200 )

    if [ ! -z "${TENCENTCLOUD}" ]; then
        MIRRORS_URL='http://mirrors.tencentyun.com'
    elif [ ! -z "${ALICLOUD}" ]; then
        MIRRORS_URL='http://mirrors.cloud.aliyuncs.com'
    fi

    check_sources
    check_yum
    rpm -e mariadb-libs --nodeps

    # 创建用户和组
    id -g mariadb
    [ $? -ne 0 ] && groupadd mariadb
    id -u mariadb
    [ $? -ne 0 ] && useradd -g mariadb -M -s /sbin/nologin mariadb

    # 检测目录
    [ ! -d "${MARIADB_DIR}" ] && mkdir -p ${MARIADB_DIR}
    [ ! -d "${MARIADB_DATA_DIR}" ] && mkdir -p ${MARIADB_DATA_DIR}
    [ ! -d "${LOGS_DIR}/mariadb" ] && mkdir -p ${LOGS_DIR}/mariadb

    cd ${METEORITE_DIR}/src

    if [ ! -f "jemalloc-${JEMALLOC_VER}.tar.bz2" ]; then
        wget ${METEORITE_MIRRORS}/meteorite/src/jemalloc-${JEMALLOC_VER}.tar.bz2
    fi

    if [ ! -f "mariadb-${MARIADB_VER}-linux-systemd-x86_64.tar.gz" ]; then
        wget ${MIRRORS_URL}/mariadb/mariadb-${MARIADB_VER}/bintar-linux-systemd-x86_64/mariadb-${MARIADB_VER}-linux-systemd-x86_64.tar.gz
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

    cd ${METEORITE_DIR}/src
    tar zxvf mariadb-${MARIADB_VER}-linux-systemd-x86_64.tar.gz
    mv mariadb-${MARIADB_VER}-linux-systemd-x86_64/* ${MARIADB_DIR}

    # 配置 PATH
    echo "export PATH=${MARIADB_DIR}/bin:\$PATH" > /etc/profile.d/mariadb.sh
    source /etc/profile.d/mariadb.sh

    # 配置 config
    sed -i 's@executing mysqld_safe@executing mysqld_safe\nexport LD_PRELOAD=/usr/local/lib/libjemalloc.so@' ${MARIADB_DIR}/bin/mariadbd-safe
    sed -i "s@/usr/local/mysql@${MARIADB_DIR}@g" ${MARIADB_DIR}/bin/mariadbd-safe
    sed -i "s@user='mysql'@user='mariadb'@" ${MARIADB_DIR}/bin/mariadbd-safe

    cp ${METEORITE_DIR}/config/mariadb.conf /etc/my.cnf
    sed -i "s@3306@${MARIADB_PORT}@g" /etc/my.cnf
    sed -i "s@/usr/local/mariadb@${MARIADB_DIR}@g" /etc/my.cnf
    sed -i "s@/data/mariadb@${MARIADB_DATA_DIR}@g" /etc/my.cnf
    sed -i "s@/data/logs@${LOGS_DIR}@g" /etc/my.cnf
    sed -i "s@max_connections.*@max_connections = $((${CHECK_MEM}/3))@" /etc/my.cnf
    if [ ${CHECK_MEM} -gt 1500 -a ${CHECK_MEM} -le 2500 ]; then
        sed -i 's@^thread_cache_size.*@thread_cache_size = 16@' /etc/my.cnf
        sed -i 's@^query_cache_size.*@query_cache_size = 16M@' /etc/my.cnf
        sed -i 's@^key_buffer_size.*@key_buffer_size = 16M@' /etc/my.cnf
        sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 128M@' /etc/my.cnf
        sed -i 's@^tmp_table_size.*@tmp_table_size = 32M@' /etc/my.cnf
        sed -i 's@^table_open_cache.*@table_open_cache = 256@' /etc/my.cnf
    elif [ ${CHECK_MEM} -gt 2500 -a ${CHECK_MEM} -le 3500 ]; then
        sed -i 's@^thread_cache_size.*@thread_cache_size = 32@' /etc/my.cnf
        sed -i 's@^query_cache_size.*@query_cache_size = 32M@' /etc/my.cnf
        sed -i 's@^key_buffer_size.*@key_buffer_size = 64M@' /etc/my.cnf
        sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 512M@' /etc/my.cnf
        sed -i 's@^tmp_table_size.*@tmp_table_size = 64M@' /etc/my.cnf
        sed -i 's@^table_open_cache.*@table_open_cache = 512@' /etc/my.cnf
    elif [ ${CHECK_MEM} -gt 3500 ]; then
        sed -i 's@^thread_cache_size.*@thread_cache_size = 64@' /etc/my.cnf
        sed -i 's@^query_cache_size.*@query_cache_size = 64M@' /etc/my.cnf
        sed -i 's@^key_buffer_size.*@key_buffer_size = 256M@' /etc/my.cnf
        sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 1024M@' /etc/my.cnf
        sed -i 's@^tmp_table_size.*@tmp_table_size = 128M@' /etc/my.cnf
        sed -i 's@^table_open_cache.*@table_open_cache = 1024@' /etc/my.cnf
    fi

    chown -R mariadb:mariadb ${MARIADB_DATA_DIR} ${LOGS_DIR}/mariadb

    # 初始化数据库
    ${MARIADB_DIR}/scripts/mysql_install_db --user=mariadb --basedir=${MARIADB_DIR} --datadir=${MARIADB_DATA_DIR} --defaults-file=/etc/my.cnf

    # 配置开机启动
    cp ${MARIADB_DIR}/support-files/mysql.server /etc/init.d/mariadb
    sed -i "s@^basedir=.*@basedir=${MARIADB_DIR}@" /etc/init.d/mariadb
    sed -i "s@^datadir=.*@datadir=${MARIADB_DATA_DIR}@" /etc/init.d/mariadb
    chmod +x /etc/init.d/mariadb
    chkconfig --add mariadb
    chkconfig mariadb on

	systemctl start mariadb.service

    ${MARIADB_DIR}/bin/mysql -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"${SET_MARIADB_PSW}\" with grant option;"
    ${MARIADB_DIR}/bin/mysql -e "grant all privileges on *.* to root@'localhost' identified by \"${SET_MARIADB_PSW}\" with grant option;"
    ${MARIADB_DIR}/bin/mysql -P${MARIADB_PORT} -uroot -p${SET_MARIADB_PSW} -e "delete from mysql.user where Password='';"
    ${MARIADB_DIR}/bin/mysql -P${MARIADB_PORT} -uroot -p${SET_MARIADB_PSW} -e "delete from mysql.db where User='';"
    ${MARIADB_DIR}/bin/mysql -P${MARIADB_PORT} -uroot -p${SET_MARIADB_PSW} -e "delete from mysql.proxies_priv where Host!='localhost';"
    ${MARIADB_DIR}/bin/mysql -P${MARIADB_PORT} -uroot -p${SET_MARIADB_PSW} -e "drop database test;"
    ${MARIADB_DIR}/bin/mysql -P${MARIADB_PORT} -uroot -p${SET_MARIADB_PSW} -e "reset master;"

    rm -rf /etc/ld.so.conf.d/{mysql,mariadb}*.conf
    [ -z "`grep ${MARIADB_DIR}/lib /etc/ld.so.conf.d/*.conf`" ] && echo "${MARIADB_DIR}/lib" > /etc/ld.so.conf.d/meteorite-mariadb.conf
	ldconfig -v

    if [[ $( netstat -anp | grep mariadb | wc -l ) -ne 0 ]]; then
        echo -e "${RGB_SUCCESS}Notice: Mariadb installed successfully!${RGB_END}"
        cd ${METEORITE_DIR}/src
        rm -rf jemalloc-${JEMALLOC_VER} mariadb-${MARIADB_VER}-linux-systemd-x86_64
    else
        echo -e "${RGB_ERROR}Error: Mariadb installation failed!${RGB_END}"
        kill -9 $$
    fi
}