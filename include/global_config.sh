#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

RGB_SUCCESS='\033[32m'
RGB_ERROR='\033[31;1m'
RGB_INFO='\033[36;1m'
RGB_WARNING='\033[33;1m'
RGB_WAIT='\033[37;2m'
RGB_END='\033[0m'

METEORITE_VER='1.0.0'
METEORITE_DIR=$( dirname $(readlink -f $0) )
METEORITE_MIRRORS='https://mirrors.vtrois.com'

CHECK_NUM=$#
CHECK_MEM=$( free -m | awk '/Mem:/{print $2}' )
CHECK_RAM=$( cat /proc/meminfo | grep "MemTotal" | awk -F" " '{ram=$2/1000000}{printf("%.0f",ram)}' )
CHECK_UNAME=$( uname -r | awk -F . '{print $1}' )
CHECK_REDIS_PSW=$( dd if=/dev/urandom bs=1 count=15 2>/dev/null | base64 -w 0 )
CHECK_MARIADB_PSW=$( dd if=/dev/urandom bs=1 count=15 2>/dev/null | base64 -w 0 )

PROCESSOR=$( grep 'processor' /proc/cpuinfo | sort -u | wc -l )
MAXMEMORY=$( expr $CHECK_MEM / 8 )

if [ "${MARIADB_PSW}" = "Meteorite-Mariadb" ]; then
    SET_MARIADB_PSW=${CHECK_MARIADB_PSW}
    sed -i "s@Meteorite-Mariadb@${CHECK_MARIADB_PSW}@" ${METEORITE_DIR}/options.conf
else
    SET_MARIADB_PSW=${MARIADB_PSW}
fi

if [ "${REDIS_PSW}" = "Meteorite-Redis" ]; then
    SET_REDIS_PSW=${CHECK_REDIS_PSW}
    sed -i "s@Meteorite-Redis@${CHECK_REDIS_PSW}@" ${METEORITE_DIR}/options.conf
else
    SET_REDIS_PSW=${REDIS_PSW}
fi

if [ ${CHECK_MEM} -le 640 ]; then
    MEM_LEVEL='512M'
    MEMORY_LIMIT='64'
    PROCESSOR='1'
elif [ ${CHECK_MEM} -gt 640 -a ${CHECK_MEM} -le 1280 ]; then
    MEM_LEVEL='1G'
    MEMORY_LIMIT='128'
elif [ ${CHECK_MEM} -gt 1280 -a ${CHECK_MEM} -le 2500 ]; then
    MEM_LEVEL='2G'
    MEMORY_LIMIT='192'
elif [ ${CHECK_MEM} -gt 2500 -a ${CHECK_MEM} -le 3500 ]; then
    MEM_LEVEL='3G'
    MEMORY_LIMIT='256'
elif [ ${CHECK_MEM} -gt 3500 -a ${CHECK_MEM} -le 4500 ]; then
    MEM_LEVEL='4G'
    MEMORY_LIMIT='320'
elif [ ${CHECK_MEM} -gt 4500 -a ${CHECK_MEM} -le 8000 ]; then
    MEM_LEVEL='6G'
    MEMORY_LIMIT='384'
elif [ ${CHECK_MEM} -gt 8000 ]; then
    MEM_LEVEL='8G'
    MEMORY_LIMIT='448'
fi

if [ -f "/etc/redhat-release" ]; then
    RELEASE=centos
elif cat /etc/issue | grep -Eqi "debian"; then
    RELEASE=debian
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    RELEASE=ubuntu
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    RELEASE=centos
elif cat /proc/version | grep -Eqi "debian"; then
    RELEASE=debian
elif cat /proc/version | grep -Eqi "ubuntu"; then
    RELEASE=ubuntu
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    RELEASE=centos
else
    RELEASE=unknown
fi

if [ "${RELEASE}" = "centos" ];then
    [ $( cat /etc/redhat-release | sed -r 's/.* ([0-9]+)\..*/\1/' ) -eq 7 ] && CHECK_CENTOS='true'
fi

for METEORITE_DIR_NAME in config src log tmp; do
    [ ! -d "${METEORITE_DIR}/${METEORITE_DIR_NAME}" ] && mkdir -p ${METEORITE_DIR}/${METEORITE_DIR_NAME}
done