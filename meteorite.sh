#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-02-18

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
export LANG="en_US.UTF-8"

source options.conf

source include/global_config.sh
source include/global_check.sh
source include/init_system.sh
source include/install_fileinfo.sh
source include/install_openssl.sh
source include/install_openssh.sh
source include/install_openresty.sh
source include/install_php.sh
source include/install_mariadb.sh
source include/install_redis.sh
source include/install_memcached.sh
source include/install_imagemagick.sh
source include/add_website.sh
source include/del_website.sh

source tool/auto_fdisk.sh
source tool/clear_log.sh
source tool/creat_trash.sh
source tool/ntp_service.sh
source tool/replace_source.sh
source tool/service_overview.sh
source tool/ssh_port.sh
source tool/state_detection.sh
source tool/system_info.sh
source tool/upgrade_kernel.sh

check_root
check_os

function show_help(){
    echo -e "\nUsage: $0 [OPTION]"
    echo -e "\nOption:"
    echo -e "  --auto                         Automatically installs LNMP environment without manual intervention."
    echo -e "  --init_system                  Initialize and harden the system."
    echo -e "  --install_openssl              Install version ${OPENSSL_VER} of OpenSSL."
    echo -e "  --install_openssh              Install version ${OPENSSH_VER} of OpenSSH."
    echo -e "  --install_openresty            Install version ${OPENRESTY_VER} of OpenResty."
    echo -e "  --install_php                  Install version ${PHP_VER} of PHP."
    echo -e "  --install_mariadb              Install version ${MARIADB_VER} of MariaDB."
    echo -e "  --install_redis                Install version ${REDIS_VER} of Redis Server and version ${PECL_REDIS_VER} of pecl-redis for PHP."
    echo -e "  --install_memcached            Install version ${MEMCACHED_VER} of Memcached Server and version ${PECL_MEMCACHED_VER} of pecl-memcached for PHP."
    echo -e "  --install_imagemagick          Install version ${IMAGEMAGICK_VER} of ImageMagick Server and version ${PECL_IMAGICK_VER} of pecl-imagick for PHP."
    echo -e "  --install_fileinfo             Install fileinfo module for PHP."
    echo -e "  --add_website                  Add website and related files"
    echo -e "  --del_website                  Delete website and related files"
    echo -e "  --auto_fdisk                   Hard drive auto fdisk tool."
    echo -e "  --clear_log                    Clear all system logs."
    echo -e "  --creat_trash                  Give the root account the rm command to create a recycle bin."
    echo -e "  --replace_source               Optimize repo mirror sources."
    echo -e "  --ntp_service                  Setting up NTP timing server."
    echo -e "  --service_overview             Show initial information about installed services."
    echo -e "  --ssh_port                     Change SSH port."
    echo -e "  --state_detection              Show information about the version of the software that has been installed."
    echo -e "  --system_info                  Show system configuration information."
    echo -e "  --upgrade_kernel               Upgrade version ${KERNEL_VER} of the kernel."
    echo -e "  -v, --version                  Show the version info."
    echo -e "  -h, --help                     Print this help."
    echo -e "\nMail bug reports or suggestions to <support@vtrois.com>."
}

function show_version(){
    echo "Meteorite Tool Version: ${METEORITE_VER}"
}

function meteorite_manual(){
    clear
    check_info

    echo -en "${RGB_INFO}Do you need init system? [y/n]:${RGB_END}"
    while :; do
        read MANUAL_INIT
        if [[ ! "${MANUAL_INIT}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please enter 'y' or 'n':${RGB_END}"
        else
            MANUAL_INIT=$( echo ${MANUAL_INIT} | tr 'A-Z' 'a-z' )
            break
        fi
    done

    echo -en "\n${RGB_INFO}Do you need install OpenResty? [y/n]:${RGB_END}"
    while :; do
        read MANUAL_OPENRESTY
        if [[ ! "${MANUAL_OPENRESTY}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please enter 'y' or 'n':${RGB_END}"
        else
            MANUAL_OPENRESTY=$( echo ${MANUAL_OPENRESTY} | tr 'A-Z' 'a-z' )
            break
        fi
    done

    echo -en "\n${RGB_INFO}Do you need install PHP? [y/n]:${RGB_END}"
    while :; do
        read MANUAL_PHP
        if [[ ! "${MANUAL_PHP}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please enter 'y' or 'n':${RGB_END}"
        else
            MANUAL_PHP=$( echo ${MANUAL_PHP} | tr 'A-Z' 'a-z' )
            break
        fi
    done

    echo -en "\n${RGB_INFO}Do you need install MariaDB? [y/n]:${RGB_END}"
    while :; do
        read MANUAL_MARIADB
        if [[ ! "${MANUAL_MARIADB}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please enter 'y' or 'n':${RGB_END}"
        else
            MANUAL_MARIADB=$( echo ${MANUAL_MARIADB} | tr 'A-Z' 'a-z' )
            break
        fi
    done

    echo -en "\n${RGB_INFO}Do you need install Redis? [y/n]:${RGB_END}"
    while :; do
        read MANUAL_REDIS
        if [[ ! "${MANUAL_REDIS}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please enter 'y' or 'n':${RGB_END}"
        else
            MANUAL_REDIS=$( echo ${MANUAL_REDIS} | tr 'A-Z' 'a-z' )
            break
        fi
    done

    echo -en "\n${RGB_INFO}Do you need install Memcached? [y/n]:${RGB_END}"
    while :; do
        read MANUAL_MEMCACHED
        if [[ ! "${MANUAL_MEMCACHED}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please enter 'y' or 'n':${RGB_END}"
        else
            MANUAL_MEMCACHED=$( echo ${MANUAL_MEMCACHED} | tr 'A-Z' 'a-z' )
            break
        fi
    done

    if [ "${MANUAL_INIT}" == "n" ] && [ "${MANUAL_OPENRESTY}" == "n" ] && [ "${MANUAL_PHP}" == "n" ] && [ "${MANUAL_MARIADB}" == "n" ] && [ "${MANUAL_REDIS}" == "n" ] && [ "${MANUAL_MEMCACHED}" == "n" ];then
        echo -e "${RGB_INFO}Bye!${RGB_END}"
        exit 0
    fi

    yum update -y

    if [ "${MANUAL_INIT}" == "y" ]; then
        install_openssl 2>&1 | tee -a /root/.meteorite/log/install_openssl.log
        install_openssh 2>&1 | tee -a /root/.meteorite/log/install_openssh.log
        init_system
    fi

    if [ "${MANUAL_OPENRESTY}" == "y" ]; then
        install_openresty 2>&1 | tee -a /root/.meteorite/log/install_openresty.log
    fi

    if [ "${MANUAL_PHP}" == "y" ]; then
        install_php 2>&1 | tee -a /root/.meteorite/log/install_php.log
    fi

    if [ "${MANUAL_MARIADB}" == "y" ]; then
        install_mariadb 2>&1 | tee -a /root/.meteorite/log/install_mariadb.log
    fi

    if [ "${MANUAL_REDIS}" == "y" ]; then
        install_redis 2>&1 | tee -a /root/.meteorite/log/install_redis.log
    fi

    if [ "${MANUAL_MEMCACHED}" == "y" ]; then
        install_memcached 2>&1 | tee -a /root/.meteorite/log/install_memcached.log
    fi

    if [ "${MANUAL_OPENRESTY}" == "y" ] && [ "${MANUAL_PHP}" == "y" ]; then
        check_demo
    fi

    clear_log

    if [ "${MANUAL_INIT}" == "y" ] && [ "${MANUAL_OPENRESTY}" == "n" ] && [ "${MANUAL_PHP}" == "n" ] && [ "${MANUAL_MARIADB}" == "n" ] && [ "${MANUAL_REDIS}" == "n" ] && [ "${MANUAL_MEMCACHED}" == "n" ]; then
        clear
        check_info
        echo -e "${RGB_SUCCESS}System initialization completed.${RGB_END}"
    else
        service_overview
        echo -e "${RGB_SUCCESS}Notice:${RGB_END}"
        echo -e "${RGB_SUCCESS}1) Server needs to be reboot.${RGB_END}"
        echo -e "${RGB_SUCCESS}2) Please check if the service is running normally after the server is started.${RGB_END}"
        if [ "${MANUAL_OPENRESTY}" == "y" ];then 
            echo -e "${RGB_SUCCESS}3) If everything checks out, run the following command:${RGB_END}${RGB_WARNING} openssl dhparam -out ${OPENRESTY_DIR}/nginx/conf/ssl/dhparam.pem 4096${RGB_END}"
        fi
    fi

    echo -en "\n${RGB_INFO}Do you need to reboot the server now? [y/n]:${RGB_END}"
    while :; do
        read CHECK_REBOOT
        if [[ ! "${CHECK_REBOOT}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please enter 'y' or 'n':${RGB_END}"
        elif [ "${CHECK_REBOOT}" == 'y' ] || [ "${CHECK_REBOOT}" == 'Y' ]; then
            reboot
        else
            break
        fi
    done
}

function meteorite_auto(){
    clear
    check_info
    [ -f "/root/.meteorite/tmp/meteorite_auto.lock" ] && echo -e "${RGB_INFO}The Meteorite tool has already been run, please do not run the automatic tool repeatedly!${RGB_END}" && exit 0
    sleep 2
    yum update -y
    install_openssl 2>&1 | tee -a /root/.meteorite/log/install_openssl.log
    install_openssh 2>&1 | tee -a /root/.meteorite/log/install_openssh.log
    init_system
    install_openresty 2>&1 | tee -a /root/.meteorite/log/install_openresty.log
    install_php 2>&1 | tee -a /root/.meteorite/log/install_php.log
    install_mariadb 2>&1 | tee -a /root/.meteorite/log/install_mariadb.log
    install_redis 2>&1 | tee -a /root/.meteorite/log/install_redis.log
    install_memcached 2>&1 | tee -a /root/.meteorite/log/install_memcached.log
    check_demo
    touch /root/.meteorite/tmp/meteorite_auto.lock
    clear_log
    service_overview
    echo -e "${RGB_SUCCESS}Notice:${RGB_END}"
    echo -e "${RGB_SUCCESS}1) The server is being restarted. ${RGB_END}"
    echo -e "${RGB_SUCCESS}2) Please check if the service is running normally after the server is started.${RGB_END}"
    echo -e "${RGB_SUCCESS}3) If everything checks out, run the following command:${RGB_END}${RGB_WARNING} openssl dhparam -out ${OPENRESTY_DIR}/nginx/conf/ssl/dhparam.pem 4096${RGB_END}"
    reboot
}

if [ ${CHECK_NUM} -eq 0 ];then
    meteorite_manual
fi

while :; do
    [ -z "$1" ] && exit 0;
    case $1 in
        --auto)
            meteorite_auto
            exit 0
        ;;
        --init_system)
            init_system
            shift
        ;;
        --install_openssl)
            install_openssl 2>&1 | tee -a /root/.meteorite/log/install_openssl.log
            shift
        ;;
        --install_openssh)
            install_openssh 2>&1 | tee -a /root/.meteorite/log/install_openssh.log
            shift
        ;;
        --install_openresty)
            install_openresty 2>&1 | tee -a /root/.meteorite/log/install_openresty.log
            shift
        ;;
        --install_php)
            install_php 2>&1 | tee -a /root/.meteorite/log/install_php.log
            shift
        ;;
        --install_mariadb)
            install_mariadb 2>&1 | tee -a /root/.meteorite/log/install_mariadb.log
            shift
        ;;
        --install_redis)
            install_redis 2>&1 | tee -a /root/.meteorite/log/install_redis.log
            shift
        ;;
        --install_memcached)
            install_memcached 2>&1 | tee -a /root/.meteorite/log/install_memcached.log
            shift
        ;;
        --install_imagemagick)
            install_imagemagick 2>&1 | tee -a /root/.meteorite/log/install_imagemagick.log
            shift
        ;;
        --install_fileinfo)
            install_fileinfo 2>&1 | tee -a /root/.meteorite/log/install_fileinfo.log
            shift
        ;;
        --add_website)
            add_website
            exit 0
        ;;
        --del_website)
            del_website
            exit 0
        ;;
        --auto_fdisk)
            auto_fdisk
            exit 0
        ;;
        --clear_log)
            clear_log
            exit 0
        ;;
        --creat_trash)
            creat_trash
            exit 0
        ;;
        --ntp_service)
            ntp_service
            exit 0
        ;;
        --replace_source)
            replace_source
            exit 0
        ;;
        --service_overview)
            service_overview
            exit 0
        ;;
        --ssh_port)
            ssh_port
            exit 0
        ;;
        --state_detection)
            state_detection
            exit 0
        ;;
        --system_info)
            system_info
            exit 0
        ;;
        --upgrade_kernel)
            upgrade_kernel 2>&1 | tee -a /root/.meteorite/log/upgrade_kernel.log
            exit 0
        ;;
        -v|--version)
            show_version
            exit 0
        ;;
        -h|--help)
            show_version
            show_help
            exit 0
        ;;
        *)
            echo -e "Unknown option: $1"
            show_help
            exit 1
        ;;
    esac
done