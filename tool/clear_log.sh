#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function clear_log(){
    if [ -f "/var/log/syslog" ]; then
        > /var/log/syslog
    fi
    if [ -f "/var/adm/btmp" ]; then
        > /var/adm/btmp
    fi
    if [ -f "/var/adm/lastlog" ]; then
        > /var/adm/lastlog
    fi
    if [ -f "/var/adm/utmp" ]; then
        > /var/adm/utmp
    fi
    if [ -f "/var/log/wtmp" ]; then
        > /var/log/wtmp
    fi
    if [ -f "/var/log/messages" ]; then
        > /var/log/messages
    fi
    if [ -f "/var/log/maillog" ]; then
        > /var/log/maillog
    fi
    if [ -f "/var/log/secure" ]; then
        > /var/log/secure
    fi

    yum autoremove -y
    yum clean all -y
    yum makecache

    history -w
    echo > /root/.bash_history
    history -c

    echo -e "${RGB_SUCCESS}Notice: Log cleanup completed!${RGB_END}"
}