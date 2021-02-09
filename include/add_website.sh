#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-02-09

function add_website(){
    clear
    check_info
    [ ! -e "${OPENRESTY_DIR}/nginx/sbin/nginx" ] && echo -e "${RGB_ERROR}Error: Nginx service is not installed!${RGB_END}" && exit 1
    [ ! -e "${OPENRESTY_DIR}/nginx/conf/ssl/dhparam.pem" ] && echo -e "${RGB_ERROR}Error: The first time you use the script, you need to run the following code to generate the dhparam.pem file first:${RGB_END}" && echo -e "${RGB_WARNING}openssl dhparam -out ${OPENRESTY_DIR}/nginx/conf/ssl/dhparam.pem 4096${RGB_END}\n" && exit 1

    echo -en "${RGB_INFO}Please enter the domain name to be configured [e.g. www.example.com]:${RGB_END}"
    while :; do
        read DOMAIN_NAME
        if [ -z "$(echo ${DOMAIN_NAME} | grep '.*\..*')" ]; then
            echo -en "${RGB_ERROR}The domain name you entered is wrong, please try again:${RGB_END}"
        else
            ALL_DOMAIN="${DOMAIN_NAME}"
            break
        fi
    done

    echo -en "\n${RGB_INFO}Do you want to add more domain name? [y/n]:${RGB_END}"
    while :; do
        read ADD_MORE_DOMAIN_NAME
        if [[ ! "${ADD_MORE_DOMAIN_NAME}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please try again:${RGB_END}"
        else
            break
        fi
    done

    if [ "${ADD_MORE_DOMAIN_NAME}" == 'y' ] || [ "${ADD_MORE_DOMAIN_NAME}" == 'Y' ]; then
        echo -en "\n${RGB_INFO}Please enter another domain name that needs to be configured [e.g. example.com]:${RGB_END}"
        while :; do
            read MORE_DOMAIN_NAME
            if [ -z "$(echo ${MORE_DOMAIN_NAME} | grep '.*\..*')" ]; then
                echo -en "${RGB_ERROR}The domain name you entered is wrong, please try again:${RGB_END}"
            else
                [ "${MORE_DOMAIN_NAME}" == "${DOMAIN_NAME}" ] && echo "${RGB_ERROR}Domain name already exists!${RGB_END}" && continue
                ALL_DOMAIN="${DOMAIN_NAME} ${MORE_DOMAIN_NAME}"
                OTHER_DOMAIN=$(echo -e "\n\nserver {\n    listen 80;\n    listen [::]:80;\n    server_name ${MORE_DOMAIN_NAME};\n\n    return 301 http://${DOMAIN_NAME}\$request_uri;\n}\n")
                break
            fi
        done
    fi

    echo -en "\n${RGB_INFO}Enable encrypted SSL connections? [y/n]:${RGB_END}"
    while :; do
        read USE_HTTPS
        if [[ ! "${USE_HTTPS}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please try again:${RGB_END}"
        elif [ "${USE_HTTPS}" == 'y' ] || [ "${USE_HTTPS}" == 'Y' ];then
            openssl genrsa -out ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.key 2048 >/dev/null 2>&1
            openssl req -new -x509 -days 3650 -key ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.key -out ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.crt -subj "/C=CN/ST=Beijing/L=Beijing/O=Meteorite/OU=LNMP/CN=${DOMAIN_NAME}" >/dev/null 2>&1
            HTTPS_CONFIG=$(echo -e "listen 443 ssl http2;\n    listen [::]:443 ssl http2;")
            SSL_CONFIG=$(echo -e "ssl_certificate ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.crt;\n    ssl_certificate_key ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.key;\n")
            break
        else
            break
        fi
    done

    if [ "${USE_HTTPS}" == 'y' ] || [ "${USE_HTTPS}" == 'Y' ]; then
        echo -en "\n${RGB_INFO}Do you need to force HTTPS? [y/n]:${RGB_END}"
        while :; do
            read USE_REDIRECT
            if [[ ! "${USE_REDIRECT}" =~ ^[y,Y,n,N]$ ]]; then
                echo -en "${RGB_ERROR}There is an error in your input, please try again:${RGB_END}"
            elif [ "${USE_REDIRECT}" == 'y' ] || [ "${USE_REDIRECT}" == 'Y' ];then
                REDIRECT_CONF=$(echo -e "\n\nserver {\n    listen 80;\n    listen [::]:80;\n    server_name ${ALL_DOMAIN};\n\n    location / {\n        return 301 https://${DOMAIN_NAME}\$request_uri;\n    }\n}\n")
                if [ "${ADD_MORE_DOMAIN_NAME}" == 'y' ] || [ "${ADD_MORE_DOMAIN_NAME}" == 'Y' ]; then
                    OTHER_DOMAIN=$(echo -e "\n\nserver {\n    listen 443 ssl http2;\n    listen [::]:443 ssl http2;\n    server_name ${MORE_DOMAIN_NAME};\n\n    ssl_certificate ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.crt;\n    ssl_certificate_key ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.key;\n\n    return 301 https://${DOMAIN_NAME}\$request_uri;\n}\n")
                fi
                break
            else
                break
            fi
        done
    fi

    echo -en "\n${RGB_INFO}Enable rewrite rules? [y/n]:${RGB_END}"
    while :; do
        read USE_REWRITE
        if [[ ! "${USE_REWRITE}" =~ ^[y,Y,n,N]$ ]]; then
            echo -en "${RGB_ERROR}There is an error in your input, please try again:${RGB_END}"
        else
            break
        fi
    done

    if [ "${USE_REWRITE}" == 'y' ] || [ "${USE_REWRITE}" == 'Y' ]; then
        REWRITE_RULES='laravel wordpress'
        echo -e "\n${RGB_INFO}Default rules list:${RGB_END} ${REWRITE_RULES}"
        echo -en "\n${RGB_INFO}Please select or customize the rules you need [e.g. laravel]:${RGB_END}"
        read REWRITE_NAME
        if [ -e "${METEORITE_DIR}/config/${REWRITE_NAME}.conf" ]; then
            cp ${METEORITE_DIR}/config/${REWRITE_NAME}.conf ${OPENRESTY_DIR}/nginx/conf/rewrite/${REWRITE_NAME}.conf
        else
            touch "${OPENRESTY_DIR}/nginx/conf/rewrite/${REWRITE_NAME}.conf"
        fi
        REWRITE_RULE=$(echo -e "\n    include rewrite/${REWRITE_NAME}.conf;")
    fi

        cat > ${OPENRESTY_DIR}/nginx/conf/conf.d/${DOMAIN_NAME}.conf << EOF
server {
    listen 80;
    listen [::]:80;
    ${HTTPS_CONFIG}
    server_name ${DOMAIN_NAME};
    root ${WWW_DIR}/${DOMAIN_NAME};
    index index.html index.htm index.php;
    ${SSL_CONFIG}
    access_log ${LOGS_DIR}/nginx/${DOMAIN_NAME}_access.log;
    error_log ${LOGS_DIR}/nginx/${DOMAIN_NAME}_error.log warn;

    location ~ \.php\$ {
        fastcgi_pass unix:/dev/shm/php-fpm.sock;
        fastcgi_index index.php;
        include fastcgi.conf;
    }

    include rewrite/general.conf;
    include rewrite/security.conf;${REWRITE_RULE}
}${OTHER_DOMAIN}${REDIRECT_CONF}
EOF
    if [ "${USE_REDIRECT}" == 'y' ] || [ "${USE_REDIRECT}" == 'Y' ]; then
        sed -i '2,3d' ${OPENRESTY_DIR}/nginx/conf/conf.d/${DOMAIN_NAME}.conf
    fi
    mkdir -p ${WWW_DIR}/${DOMAIN_NAME}
    chown -R www:www ${WWW_DIR}/${DOMAIN_NAME}
    ${OPENRESTY_DIR}/nginx/sbin/nginx -t >/dev/null 2>&1
    systemctl reload nginx.service >/dev/null 2>&1
    NGINX_STATUS=$(systemctl status nginx.service | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [ "$NGINX_STATUS" == "running" ];then
        clear
        check_info
        echo -e "${RGB_INFO}Domain Name         ${RGB_END}: ${DOMAIN_NAME}"
        echo -e "${RGB_INFO}Domain Directory    ${RGB_END}: ${WWW_DIR}/${DOMAIN_NAME}"
        echo -e "${RGB_INFO}Config File         ${RGB_END}: ${OPENRESTY_DIR}/nginx/conf/conf.d/${DOMAIN_NAME}.conf"
        echo -e "${RGB_INFO}Access Log          ${RGB_END}: ${LOGS_DIR}/nginx/${DOMAIN_NAME}_access.log"
        echo -e "${RGB_INFO}Error Log           ${RGB_END}: ${LOGS_DIR}/nginx/${DOMAIN_NAME}_error.log"
        if [ "${USE_REWRITE}" == 'y' ] || [ "${USE_REWRITE}" == 'Y' ];then
            echo -e "${RGB_INFO}Rewrite File        ${RGB_END}: ${OPENRESTY_DIR}/nginx/conf/rewrite/${REWRITE_NAME}.conf"
        fi
        if [ "${USE_HTTPS}" == 'y' ] || [ "${USE_HTTPS}" == 'Y' ];then
            echo -e "${RGB_INFO}SSL Certificate     ${RGB_END}: ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.crt"
            echo -e "${RGB_INFO}SSL Certificate Key ${RGB_END}: ${OPENRESTY_DIR}/nginx/conf/ssl/${DOMAIN_NAME}.key\n"
            echo -e "${RGB_SUCCESS}The website has been completed, please upload the SSL related files to the specified location.${RGB_END}"
            echo -e "${RGB_SUCCESS}Finally, please execute the command to make it effective:${RGB_END}${RGB_WARNING} systemctl reload nginx.service${RGB_END}"
        fi
    fi
}