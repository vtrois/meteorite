#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-02-09

function ssh_port(){
    clear
    check_info

    [ ! -e "/etc/ssh/sshd_config" ] && echo -e "${RGB_ERROR}Error: Can't find sshd config file!${RGB_END}" && exit 1
    OLD_SSH_PORT=$( cat /etc/ssh/sshd_config | grep ^Port | awk '{print $2}' | head -1 )
    echo -en "${RGB_INFO}1/2 : Please enter SSH port (Range of 10000 to 65535, current is ${OLD_SSH_PORT}):${RGB_END}"
    while :; do
        read NEW_SSH_PORT
        NPTSTATUS=$( netstat -lnp | grep ${NEW_SSH_PORT} )
        if [ -n "${NPTSTATUS}" ];then
            echo -en "${RGB_ERROR}The port is already occupied, Please try again (Range of 10000 to 65535):${RGB_END}"
        elif [ "${NEW_SSH_PORT}" -lt 10000 ] || [ "${NEW_SSH_PORT}" -gt 65535 ];then
            echo -en "${RGB_ERROR}Please try again (Range of 10000 to 65535):${RGB_END}"
        else
            break
        fi
    done
    echo -en "${RGB_WAIT}Checking...${RGB_END}"
    if [ ${OLD_SSH_PORT} -ne 22 ]; then
        sed -i "s@^Port.*@Port ${NEW_SSH_PORT}@" /etc/ssh/sshd_config
    else
        sed -i "s@^#Port.*@&\nPort ${NEW_SSH_PORT}@" /etc/ssh/sshd_config
        sed -i "s@^Port.*@Port ${NEW_SSH_PORT}@" /etc/ssh/sshd_config
    fi
    echo -e "\r${RGB_SUCCESS}Success, the SSH port modification completed!${RGB_END}\n"
    echo -e "${RGB_INFO}2/2 : Restart the service to take effect${RGB_END}"
    echo -en "${RGB_WAIT}Checking...${RGB_END}"
    systemctl restart sshd.service >/dev/null 2>&1
    echo -e "\r${RGB_SUCCESS}Success, the SSH service restart completed!${RGB_END}\n"
    echo -e "${RGB_WARNING}If you use elastic compute service, please enable [TCP:${NEW_SSH_PORT}] for the security group!${RGB_END}"
}