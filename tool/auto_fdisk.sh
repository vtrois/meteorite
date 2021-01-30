#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-30

function fdisk_mkfs(){
fdisk $1 << EOF
n
p
1


wq
EOF

sleep 3
partprobe
mkfs -t ext4 ${1}1
}

function fdisk_mounted(){
while mount | grep "${DISK}" >/dev/null 2>&1;do
    echo -e "\n${RGB_ERROR}This disk has been mounted:${RGB_END}"
    mount | grep "${DISK}"
    echo -en "\n${RGB_ERROR}Force Unloading the disk? [y/n]:${RGB_END}"
    while :; do
    read UMOUNT
    if [[ ! "${UMOUNT}" =~ ^[y,n,Y,N]$ ]]; then
        echo -en "${RGB_ERROR}Please try again [y/n]:${RGB_END}"
    else
        if [ "${UMOUNT}" == 'y' ] || [ "${UMOUNT}" == 'Y' ]; then
            echo -en "${RGB_WAIT}Unloading...${RGB_END}"
            for i in `mount | grep "${DISK}" | awk '{print $3}'`;do
                fuser -km $i >/dev/null
                umount $i >/dev/null
                TEMP=`echo ${DISK} | sed 's;/;\\\/;g'`
                sed -i -e "/^$TEMP/d" /etc/fstab
            done
            echo -e "\r${RGB_SUCCESS}Success, the disk is unloaded!${RGB_END}"
        else
            exit
        fi
        break
    fi
    done
    echo -en "\n${RGB_ERROR}Ready to format the disk? [y/n]:${RGB_END}"
    while :; do
    read CHOICE
    if [[ ! "${CHOICE}" =~ ^[y,n,Y,N]$ ]]; then
        echo -en "${RGB_ERROR}Please try again [y/n]:${RGB_END}"
    else
        if [ "${CHOICE}" == 'y' ] || ["${CHOICE}" == 'Y' ]; then
            echo -en "${RGB_WAIT}Formatting...${RGB_END}"
            dd if=/dev/zero of=${DISK} bs=512 count=1 &>/dev/null
            sync
            echo -e "\r${RGB_SUCCESS}Success, the disk has been formatted!${RGB_END}"
        else
            exit
        fi
        break
    fi
    done
done
}

function auto_fdisk(){
    clear
    check_info
    CHECK_DISK=`fdisk -l 2>/dev/null | grep -o "Disk /dev/.*vd[b-z]"`
    if [ -z "${CHECK_DISK}" ];then
        echo -e "${RGB_ERROR}No hard drive found for fdisk, please try again!${RGB_END}"
        exit 0
    fi
    echo -e "${RGB_INFO}1/6 : Check and install the Ext4 module${RGB_END}"
    echo -en "${RGB_WAIT}Checking...${RGB_END}"
    yum install e4fsprogs -y >/dev/null 2>&1
    echo -e "\r${RGB_SUCCESS}Success, the script is ready to be installed!${RGB_END}\n"
    echo -e "${RGB_INFO}2/6 : Show all active disks${RGB_END}"
    fdisk -l 2>/dev/null | grep -o "Disk /dev/.*vd[b-z]"
    echo -en "\n${RGB_INFO}3/6 : Please choose the disk (e.g., /dev/vdb):${RGB_END}"
    while :; do
    read DISK
    if [ -z "`echo ${DISK} | grep '^/dev/.*vd[b-z]'`" ]; then
        echo -en "${RGB_ERROR}Please try again (e.g., /dev/vdb):${RGB_END}"
    else
        until fdisk -l 2>/dev/null | grep -o "Disk /dev/.*vd[b-z]" | grep "Disk ${DISK}" &>/dev/null;do
            echo -en "${RGB_ERROR}Please try again (e.g., /dev/vdb):${RGB_END}"
            read DISK
        done
        fdisk_mounted
        break
    fi
    done
    echo -e "\n${RGB_INFO}4/6 : Partitioning and formatting the disk${RGB_END}"
    echo -en "${RGB_WAIT}Partitioning and formatting...${RGB_END}"
    fdisk_mkfs ${DISK} >/dev/null 2>&1
    echo -e "\r${RGB_SUCCESS}Success, the disk has been partitioned and formatted!${RGB_END}\n"
    echo -en "${RGB_INFO}5/6 : Please enter a location to mount (Default directory: /data):${RGB_END}"
    while :; do
    read MOUNT
    MOUNT=${MOUNT:-"/data"}
    if [ -z "`echo ${MOUNT} | grep '^/'`" ]; then
        echo -en "${RGB_ERROR}The directory must begin with /, please try again (Default directory: /data):${RGB_END}"
    else
        echo -en "${RGB_WAIT}Mounting...${RGB_END}"
        mkdir ${MOUNT} >/dev/null 2>&1
        mount ${DISK}1 ${MOUNT}
        echo -e "\r${RGB_SUCCESS}Success, the mount is completed!${RGB_END}"
        break
    fi
    done
    echo -e "\n${RGB_INFO}6/6 : Write the configuration to /etc/fstab and mount the device${RGB_END}"
    echo -en "${RGB_WAIT}Writing...${RGB_END}"
    TENCENTCLOUD=$( wget -qO- -t1 -T2 metadata.tencentyun.com )
    ALICLOUD=$( wget -qO- -t1 -T2 100.100.100.200 )
    if [ ! -z "${TENCENTCLOUD}" ]; then
        SDISK=$( echo ${DISK} | grep -o "/dev/.*vd[b-z]" | awk -F"/" '{print $(NF)}' )
        SOFTLINK=$( ls -l /dev/disk/by-id | grep "${SDISK}1" | awk -F" " '{print $(NF-2)}' )
        sed -i "/${SOFTLINK}/d" /etc/fstab >/dev/null 2>&1
        echo /dev/disk/by-id/${SOFTLINK} $MOUNT 'ext4 defaults 0 2' >> /etc/fstab
    else
        sed -i "/${DISK}1/d" /etc/fstab >/dev/null 2>&1
        echo ${DISK}1 $MOUNT 'ext4 defaults 0 2' >> /etc/fstab
    fi
    echo -e "\r${RGB_SUCCESS}Success, the /etc/fstab has been written!${RGB_END}"
    echo -e "\n${RGB_WARNING}Show the amount of free disk space on the system${RGB_END}"
    df -Th
    echo -e "\n${RGB_WARNING}Show the configuration file for /etc/fstab${RGB_END}"
    grep "^[^#.*]" /etc/fstab
}