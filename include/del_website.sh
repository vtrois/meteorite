#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-02-02

function del_website(){
    clear
    check_info
    [ ! -e "${OPENRESTY_DIR}/nginx/sbin/nginx" ] && echo -e "${RGB_ERROR}Error: Nginx service is not installed!${RGB_END}" && exit 1
    WEBSITE_LIST=$( ls ${OPENRESTY_DIR}/nginx/conf/conf.d | sed "s@.conf@@g" )
    [ ! -n "${WEBSITE_LIST}" ] && echo -e "${RGB_ERROR}Error: No website found!${RGB_END}" && exit 1

    echo -e "${RGB_INFO}Website list:${RGB_END}"
    echo -e "${WEBSITE_LIST}"
    echo -en "\n${RGB_INFO}Please enter the domain name of the website to be deleted:${RGB_END}"
    while :; do
        read DOMAIN_NAME
        if [ "${DOMAIN_NAME}" == "default" ]; then
            rm -rf ${WWW_DIR}/default
            rm -rf ${OPENRESTY_DIR}/nginx/conf/conf.d/default.conf
            rm -rf ${LOGS_DIR}/nginx/default*.log
            sed -i 's/#//' ${OPENRESTY_DIR}/nginx/conf/nginx.conf
            systemctl reload nginx.service >/dev/null 2>&1
            echo -e "\n${RGB_SUCCESS}Notice: Website deletion completed!${RGB_END}"
            break
        elif [ -z "$(echo ${DOMAIN_NAME} | grep '.*\..*')" ]; then
            echo -en "${RGB_ERROR}The domain name you entered is wrong, please try again:${RGB_END}"
        else
            if [ -e "${OPENRESTY_DIR}/nginx/conf/conf.d/${DOMAIN_NAME}.conf" ];then
                rm -rf ${OPENRESTY_DIR}/nginx/conf/conf.d/${DOMAIN_NAME}.conf
                if [ -e "${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.key" ];then
                    rm -rf ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.{key,crt}
                fi
                ${OPENRESTY_DIR}/nginx/sbin/nginx -t >/dev/null 2>&1
                systemctl reload nginx.service >/dev/null 2>&1
                echo -en "\n${RGB_INFO}Do you want to delete website file directory? [y/n]:${RGB_END}"
                while :; do
                    read DEL_DIR
                    if [[ ! "${DEL_DIR}" =~ ^[y,Y,n,N]$ ]]; then
                        echo -en "${RGB_ERROR}There is an error in your input, please try again:${RGB_END}"
                    else
                        break
                    fi
                done
                if [ "${DEL_DIR}" == 'y' ] || [ "${DEL_DIR}" == 'Y' ]; then
                    rm -rf ${WWW_DIR}/${DOMAIN_NAME}
                fi
                echo -en "\n${RGB_INFO}Do you want to delete log files? [y/n]:${RGB_END}"
                while :; do
                    read DEL_LOG
                    if [[ ! "${DEL_LOG}" =~ ^[y,Y,n,N]$ ]]; then
                        echo -en "${RGB_ERROR}There is an error in your input, please try again:${RGB_END}"
                    else
                        break
                    fi
                done
                if [ "${DEL_LOG}" == 'y' ] || [ "${DEL_LOG}" == 'Y' ]; then
                    rm -rf ${LOGS_DIR}/nginx/${DOMAIN_NAME}*.log
                fi
                echo -e "\n${RGB_SUCCESS}Notice: Website deletion completed!${RGB_END}"
            else
                echo -e "\n${RGB_ERROR}Error: Website was not exist!${RGB_END}"
            fi
            break
        fi
    done
}