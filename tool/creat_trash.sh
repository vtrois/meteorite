#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function creat_trash(){
    [ -f "/root/.meteorite/tmp/creat_trash.lock" ] && echo -e "${RGB_INFO}Notice: Trash creation script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/creat_trash.lock

    [ ! -d "~/.trash" ] && mkdir -p ~/.trash

    cat > ~/.meteorite_trash.sh << "EOF"
#!/usr/bin/env bash

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
export LANG="en_US.UTF-8"

TRASH_DIR='/root/.trash'

for i in $*; do
    [ -z "$i" ] && continue;
    case $i in
        -r|-f|-rf)
            continue
        ;;
        *)
            STAMP=$( date +%F-%T )
            FILENAME=$( basename $i )
            mv $i ${TRASH_DIR}/${FILENAME}_${STAMP}
            continue
        ;;
    esac
done
EOF

    echo "alias rm='sh ~/.meteorite_trash.sh'" >> ~/.bash_profile
    echo "alias trash='/bin/rm -rf ~/.trash'" >> ~/.bash_profile
    source ~/.bash_profile

    echo -e "${RGB_SUCCESS}Notice: Trash created successfully!${RGB_END}"
}