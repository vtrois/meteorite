#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function operation_system(){
    [ -f "/etc/redhat-release" ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f "/etc/os-release" ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f "/etc/lsb-release" ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

function system_info(){
    INFO_MEMTOTAL=$( cat /proc/meminfo | grep "MemTotal" | awk -F" " '{total=$2/1000}{printf("%d MB",total)}' )
    INFO_MEMFREE=$( cat /proc/meminfo | grep "MemFree" | awk -F" " '{free=$2/1000}{printf("%d MB",free)}' )
    INFO_SWAPTOTAL=$( cat /proc/meminfo  | grep "SwapTotal" | awk -F" " '{total=$2/1000}{printf("%d MB",total)}' )
    INFO_SWAPFREE=$( cat /proc/meminfo  | grep "SwapFree" | awk -F" " '{free=$2/1000}{printf("%d MB",free)}' )
    INFO_CPUMODEL=$( cat /proc/cpuinfo | grep "model name" | awk 'END{print}' | awk -F": " '{print $2}' )
    INFO_CPUMHZ=$( cat /proc/cpuinfo | grep "cpu MHz" | awk 'END{print}' | awk -F": " '{print($2,"MHz")}' )
    INFO_CPUCORES=$( cat /proc/cpuinfo | awk -F: '/model name/ {core++} END {print core}' )
    INFO_CPUCACHE=$( cat /proc/cpuinfo | grep "cache size" | awk 'END{print}' | awk -F": " '{print $2}' )
    INFO_SYSOS=$( operation_system )
    INFO_SYSRISC=$( uname -m )
    INFO_SYSLBIT=$( getconf LONG_BIT )
    INFO_KERNEVERSIONL=$( cat /proc/version | awk -F" " '{print $3}' )
    INFO_IPV6=$( ifconfig | grep "inet6" | grep -v "fe80\|::1" | awk -F" " '{print $2}' )
    INFO_NAMESERVER=$( cat /etc/resolv.conf | awk '/^nameserver/{print $2}' | awk 'BEGIN{FS="\n";RS="";ORS=""}{for(x=1;x<=NF;x++){print $x"\t"} print "\n"}' )

    TENCENTCLOUD=$( wget -qO- -t1 -T2 metadata.tencentyun.com )
    ALICLOUD=$( wget -qO- -t1 -T2 100.100.100.200 )

    if [ ! -z "${TENCENTCLOUD}" ]; then
        INFO_IPV4=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/public-ipv4 )
        INFO_LOCALIP=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/local-ipv4 )
        INFO_MACADDRESS=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/mac )
        INFO_INSTANCEID=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/instance-id )
        INFO_INSTANCENAME=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/instance-name )
        INFO_UUID=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/uuid )
        INFO_REGIONZONE=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/placement/zone )
        INFO_CHARGETYPE=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/payment/charge-type )
        INFO_CREATETIME=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/payment/create-time )
        INFO_TERMINATIONTIME=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/payment/termination-time )
    else
        INFO_IPV4=$( check_ipv4 )
        INFO_LOCALIP=$( ifconfig | grep "inet" | grep -v "127.0" | xargs | awk -F '[ :]' '{print $2}' )
        INFO_MACADDRESS=$( ifconfig | grep "ether" | awk -F" " '{print $2}' )
    fi

    clear
    check_info

    echo -e "${RGB_WARNING}Hardware Overview (Contains the System, CPU and Memory)${RGB_END}"
    echo -e "${RGB_INFO}Operation System       ${RGB_END}: ${INFO_SYSOS}"
    echo -e "${RGB_INFO}Hardware Types         ${RGB_END}: ${INFO_SYSRISC} (${INFO_SYSLBIT} Bit)"
    echo -e "${RGB_INFO}Kernel Version         ${RGB_END}: ${INFO_KERNEVERSIONL}"
    echo -e "${RGB_INFO}CPU model              ${RGB_END}: ${INFO_CPUMODEL}"
    echo -e "${RGB_INFO}CPU Cores              ${RGB_END}: ${INFO_CPUCORES}"
    echo -e "${RGB_INFO}CPU Cache Size         ${RGB_END}: ${INFO_CPUCACHE}"
    echo -e "${RGB_INFO}CPU Basic Frequency    ${RGB_END}: ${INFO_CPUMHZ}"
    echo -e "${RGB_INFO}Total amount of Memory ${RGB_END}: ${INFO_MEMTOTAL} (${INFO_MEMFREE} Free)"
    echo -e "${RGB_INFO}Total amount of Swap   ${RGB_END}: ${INFO_SWAPTOTAL} (${INFO_SWAPFREE} Free)"
    echo -e "\n${RGB_WARNING}Network Overview (Contains the DNS, IP address and Nameserver)${RGB_END}"
    echo -e "${RGB_INFO}IPV4                   ${RGB_END}: ${INFO_IPV4}"
    if [ ! -z "${IPV6}" ]; then
        echo -e "${RGB_INFO}IPV6                   ${RGB_END}: ${INFO_IPV6}"
    fi
    echo -e "${RGB_INFO}Local IP               ${RGB_END}: ${INFO_LOCALIP}"
    echo -e "${RGB_INFO}MAC Address            ${RGB_END}: ${INFO_MACADDRESS}"
    echo -e "${RGB_INFO}Nameserver             ${RGB_END}: ${INFO_NAMESERVER}"
    if [ ! -z "${TENCENTCLOUD}" ]; then
        echo -e "\n${RGB_WARNING}Tencent Cloud Overview (Contains the UUID, Instance, Zone and Time)${RGB_END}"
        echo -e "${RGB_INFO}UUID                   ${RGB_END}: ${INFO_UUID}"
        echo -e "${RGB_INFO}Instance ID            ${RGB_END}: ${INFO_INSTANCEID}"
        echo -e "${RGB_INFO}Instance Name          ${RGB_END}: ${INFO_INSTANCENAME}"
        echo -e "${RGB_INFO}Region & Zone          ${RGB_END}: ${INFO_REGIONZONE}"
        echo -e "${RGB_INFO}Charge Type            ${RGB_END}: ${INFO_CHARGETYPE}"
        echo -e "${RGB_INFO}Create Time            ${RGB_END}: ${INFO_CREATETIME}"
        echo -e "${RGB_INFO}Termination Time       ${RGB_END}: ${INFO_TERMINATIONTIME}"
    fi
}