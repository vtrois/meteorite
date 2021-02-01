#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-02-01

function replace_source(){
    yum install epel-release -y

    rm -rf /etc/yum.repos.d/*

    cat > /etc/yum.repos.d/meteorite.repo << "EOF"
[extras]
name=Meteorite - extras
baseurl=https://mirrors.cloud.tencent.com/centos/$releasever/extras/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[os]
name=Meteorite - os
baseurl=https://mirrors.cloud.tencent.com/centos/$releasever/os/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[updates]
name=Meteorite - updates
baseurl=https://mirrors.cloud.tencent.com/centos/$releasever/updates/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

[epel]
name=Meteorite - epel
baseurl=https://mirrors.cloud.tencent.com/epel/$releasever/$basearch/
failovermethod=priority
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[elrepo]
name=Meteorite - elrepo
baseurl=http://mirrors.tuna.tsinghua.edu.cn/elrepo/elrepo/el7/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org

[elrepo-kernel]
name=Meteorite - elrepo kernel
baseurl=http://mirrors.tuna.tsinghua.edu.cn/elrepo/kernel/el7/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org
protect=0

[elrepo-extras]
name=Meteorite - elrepo extras
baseurl=http://mirrors.tuna.tsinghua.edu.cn/elrepo/extras/el7/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org
protect=0
EOF

    if [ ! -z "$( wget -qO- -t1 -T2 metadata.tencentyun.com )" ]; then
        MIRRORS_URL='http://mirrors.tencentyun.com'
    elif [ ! -z "$( wget -qO- -t1 -T2 100.100.100.200 )" ]; then
        MIRRORS_URL='http://mirrors.cloud.aliyuncs.com'
    fi

    sed -i "s@https://mirrors.cloud.tencent.com@${MIRRORS_URL}@g" /etc/yum.repos.d/meteorite.repo

    yum makecache
}