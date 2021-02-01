#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-02-01

function ntp_service(){
    clear
    check_info

    [ -f "/root/.meteorite/tmp/ntp_service.lock" ] && echo -e "${RGB_INFO}Notice: NTP service script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/ntp_service.lock

    echo -e "${RGB_INFO}1/3 : Check and install the necessary module${RGB_END}"
    echo -en "${RGB_WAIT}Checking...${RGB_END}"
    yum install ntp -y >/dev/null 2>&1
    systemctl enable ntpd.service >/dev/null 2>&1
    systemctl start ntpd.service >/dev/null 2>&1
    echo -e "\r${RGB_SUCCESS}Success, the script is ready to be installed!${RGB_END}"
    echo -en "\n${RGB_INFO}2/3 : Please input the network address [Default: 0.0.0.0]:${RGB_END}"
    while :; do
        read NETWORKADDRESS
        NETWORKADDRESS=${NETWORKADDRESS:-"0.0.0.0"}
        if [ -z "`echo ${NETWORKADDRESS} | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]'`" ]; then
            echo -en "${RGB_ERROR}The network address you entered is wrong, please try again: [Default: 0.0.0.0]:${RGB_END}"
        else
            break
        fi
    done
    echo -e "${RGB_SUCCESS}Success, the network address is setup complete!${RGB_END}"
    echo -en "\n${RGB_INFO}3/3 : Please input the netmask [Default: 0.0.0.0]:${RGB_END}"
    while :; do
        read NETMASK
        NETMASK=${NETMASK:-"0.0.0.0"}
        if [ -z "`echo ${NETMASK} | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]'`" ]; then
            echo -en "${RGB_ERROR}The netmask you entered is wrong, please try again: [Default: 0.0.0.0]:${RGB_END}"
        else
            break
        fi
    done
    echo -e "${RGB_SUCCESS}Success, the netmask is setup complete!${RGB_END}"

    cat > /etc/ntp.conf << EOF
driftfile /var/lib/ntp/drift
logfile /var/log/ntp.log
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1
restrict ${NETWORKADDRESS} mask ${NETMASK} nomodify notrap
server time1.cloud.tencent.com iburst
server time2.cloud.tencent.com iburst
server time3.cloud.tencent.com iburst
server time4.cloud.tencent.com iburst
server time5.cloud.tencent.com iburst
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
interface ignore wildcard
interface listen eth0
EOF

    if [ ! -z "$( wget -qO- -t1 -T2 metadata.tencentyun.com )" ]; then
        sed -i "s@cloud.tencent.com@tencentyun.com@g" /etc/ntp.conf
    elif [ ! -z "$( wget -qO- -t1 -T2 100.100.100.200 )" ]; then
        sed -i "s@cloud.tencent.com@cloud.aliyuncs.com@g" /etc/ntp.conf
        sed -i "s@time@ntp@g" /etc/ntp.conf
    fi

    systemctl restart ntpd.service >/dev/null 2>&1
    echo -e "\n${RGB_WARNING}If you use elastic compute service, please enable [UDP:123] for the security group!${RGB_END}"
}