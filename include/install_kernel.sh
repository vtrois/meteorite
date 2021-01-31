#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-01-28

function install_kernel(){
    [ -f "/root/.meteorite/tmp/install_kernel.lock" ] && echo -e "${RGB_INFO}Notice: Kernel installation script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/install_kernel.lock

    yum update -y
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm -y

    cat > /etc/yum.repos.d/elrepo.repo << "EOF"
[elrepo]
name=ELRepo.org Community Enterprise Linux Repository - el7
baseurl=http://mirrors.tuna.tsinghua.edu.cn/elrepo/elrepo/el7/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org
protect=0

[elrepo-testing]
name=ELRepo.org Community Enterprise Linux Testing Repository - el7
baseurl=http://mirrors.tuna.tsinghua.edu.cn/elrepo/testing/el7/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org
protect=0

[elrepo-kernel]
name=ELRepo.org Community Enterprise Linux Kernel Repository - el7
baseurl=http://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org
protect=0

[elrepo-extras]
name=ELRepo.org Community Enterprise Linux Extras Repository - el7
baseurl=http://mirrors.tuna.tsinghua.edu.cn/elrepo/extras/el7/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org
protect=0
EOF

    yum makecache
    yum -y --enablerepo=elrepo-kernel install ${KERNEL_VER}

    sed -i 's@^GRUB_DEFAULT=.*$@GRUB_DEFAULT=0@' /etc/default/grub

    grub2-mkconfig -o /boot/grub2/grub.cfg

    replace_source

    rm -rf `ls /etc/ld.so.conf.d/kernel-*.conf | egrep -v ${KERNEL_VER}-*.conf`

    echo -e "${RGB_SUCCESS}Notice: Kernel installation completed, rebooting server soon!${RGB_END}"

    reboot
}