#!/usr/bin/env bash
#
# Github:    https://github.com/vtrois/meteorite
# Author:    Seaton Jiang <seaton@vtrois.com>
# License:   MIT
# Date:      2021-02-09

function init_system(){
    [ -f "/root/.meteorite/tmp/init_system.lock" ] && echo -e "${RGB_INFO}Notice: Init system script has already been run!${RGB_END}" && return
    touch /root/.meteorite/tmp/init_system.lock

    TENCENTCLOUD=$( wget -qO- -t1 -T2 metadata.tencentyun.com )
    ALICLOUD=$( wget -qO- -t1 -T2 100.100.100.200 )

    if [ ! -z "${TENCENTCLOUD}" ]; then
        INSTANCEID=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/instance-id )
        INSTANCENAME=$( wget -qO- -t1 -T2 metadata.tencentyun.com/latest/meta-data/instance-name )
    elif [ ! -z "${ALICLOUD}" ]; then
        INSTANCEID=$( wget -qO- -t1 -T2 100.100.100.200/latest/meta-data/instance-id )
        INSTANCENAME=$( wget -qO- -t1 -T2 100.100.100.200/latest/meta-data/hostname )
    fi

    # 配置开机启动 haveged
    systemctl enable haveged.service
    systemctl start haveged.service

    # 自定义配置文件
    cat > /etc/profile.d/meteorite.sh << "EOF"
PS1="\[\e[37;40m\][\[\e[32;40m\]\u\[\e[37;40m\]@\h \[\e[35;40m\]\W\[\e[0m\]]\\$ "
GREP_OPTIONS="--color=auto"
alias grep='grep --color'
alias egrep='egrep --color'
alias fgrep='fgrep --color'
EOF

    # 清理 systemd 日志
    cat > /etc/systemd/journald.conf << "EOF"
[Journal]
SystemMaxUse=10M
SystemKeepFree=10M
SystemMaxFileSize=1M
RuntimeMaxUse=10M
RuntimeKeepFree=10M
RuntimeMaxFileSize=1M
MaxRetentionSec=10day
MaxFileSec=0
ForwardToSyslog=no
ForwardToKMsg=no
ForwardToConsole=no
ForwardToWall=no
EOF
    systemctl restart systemd-journald

    # 优化 PATH
    cat > ~/.bash_profile << "EOF"
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

export PATH="/usr/local/bin:$PATH:$HOME/bin"
EOF
    source ~/.bash_profile

    # 设置时区
    rm -rf /etc/localtime
    timedatectl set-timezone ${TIMEZONE}

    # 关闭 SELinux
    sed -i 's@^SELINUX=.*$@SELINUX=disabled@' /etc/selinux/config

    # 关闭 firewalld
    systemctl disable firewalld.service
    systemctl stop firewalld.service

    # 禁用 Ctrl+Alt+Del 重启服务器
    systemctl mask ctrl-alt-del.target

    # 调整目录权限
    chmod 644 /etc/passwd
    chmod 644 /etc/group
    chmod 000 /etc/shadow
    chmod 000 /etc/gshadow

    # 删除无用的用户和组
    for u in adm lp sync shutdown halt operator games ftp; do
        userdel ${u}
    done

    for g in adm lp games ftp; do
        groupdel ${g}
    done

    if [ ! -z "${TENCENTCLOUD}" ]; then
        if [[ "${INSTANCENAME}" =~ "lhins" ]]; then
            userdel -r lighthouse
        fi
    fi

    # 设置会话超时时间
    echo "export TMOUT=1800" >> /etc/profile.d/time_out.sh

    # 设置口令有效期
    sed -i 's@^INACTIVE.*$@INACTIVE=365@' /etc/default/useradd

    # 设置口令策略
    sed -i 's@^PASS_MAX_DAYS.*$@PASS_MAX_DAYS   90@' /etc/login.defs
    sed -i 's@^PASS_MIN_DAYS.*$@PASS_MIN_DAYS   0@' /etc/login.defs
    sed -i 's@^PASS_WARN_AGE.*$@PASS_WARN_AGE   7@' /etc/login.defs

    # updatedb 优化
    sed -i 's@media@media /data@' /etc/updatedb.conf

    # 设置账户登录失败锁定策略
    cat > /etc/pam.d/system-auth << "EOF"
auth        required                                     pam_env.so
auth        required                                     pam_faillock.so preauth silent audit deny=3 unlock_time=300
auth        required                                     pam_faildelay.so delay=2000000
auth        [default=1 ignore=ignore success=ok]         pam_succeed_if.so uid >= 1000 quiet
auth        [default=1 ignore=ignore success=ok]         pam_localuser.so
auth        sufficient                                   pam_unix.so nullok try_first_pass
auth        [default=die]                                pam_faillock.so  authfail  audit  deny=3  unlock_time=300
auth        requisite                                    pam_succeed_if.so uid >= 1000 quiet_success
auth        sufficient                                   pam_sss.so forward_pass
auth        required                                     pam_deny.so

account     required                                     pam_unix.so
account     sufficient                                   pam_localuser.so
account     sufficient                                   pam_succeed_if.so uid < 1000 quiet
account     [default=bad success=ok user_unknown=ignore] pam_sss.so
account     required                                     pam_permit.so
account     required                                     pam_faillock.so

password    requisite                                    pam_pwquality.so try_first_pass local_users_only
password    sufficient                                   pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    sufficient                                   pam_sss.so use_authtok
password    required                                     pam_deny.so

session     optional                                     pam_keyinit.so revoke
session     required                                     pam_limits.so
-session    optional                                     pam_systemd.so
session     [success=1 default=ignore]                   pam_succeed_if.so service in crond quiet use_uid
session     required                                     pam_unix.so
session     optional                                     pam_sss.so
EOF

    cat > /etc/pam.d/password-auth << "EOF"
auth        required                                     pam_env.so
auth        required                                     pam_faillock.so preauth silent audit deny=3 unlock_time=300
auth        required                                     pam_faildelay.so delay=2000000
auth        [default=1 ignore=ignore success=ok]         pam_succeed_if.so uid >= 1000 quiet
auth        [default=1 ignore=ignore success=ok]         pam_localuser.so
auth        sufficient                                   pam_unix.so nullok try_first_pass
auth        [default=die]                                pam_faillock.so  authfail  audit  deny=3  unlock_time=300
auth        requisite                                    pam_succeed_if.so uid >= 1000 quiet_success
auth        sufficient                                   pam_sss.so forward_pass
auth        required                                     pam_deny.so

account     required                                     pam_unix.so
account     sufficient                                   pam_localuser.so
account     sufficient                                   pam_succeed_if.so uid < 1000 quiet
account     [default=bad success=ok user_unknown=ignore] pam_sss.so
account     required                                     pam_permit.so
account     required                                     pam_faillock.so

password    requisite                                    pam_pwquality.so try_first_pass local_users_only
password    sufficient                                   pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    sufficient                                   pam_sss.so use_authtok
password    required                                     pam_deny.so

session     optional                                     pam_keyinit.so revoke
session     required                                     pam_limits.so
-session    optional                                     pam_systemd.so
session     [success=1 default=ignore]                   pam_succeed_if.so service in crond quiet use_uid
session     required                                     pam_unix.so
session     optional                                     pam_sss.so
EOF
    systemctl restart sshd.service

    # 配置 SSH
    cat > /etc/ssh/sshd_config << EOF
Port ${SSH_PORT}
AddressFamily any
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
SyslogFacility AUTHPRIV
LoginGraceTime 60
PermitRootLogin yes
MaxAuthTries 3
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
PasswordAuthentication no
ChallengeResponseAuthentication no
GSSAPIAuthentication no
GSSAPICleanupCredentials no
UsePAM yes
X11Forwarding no
PrintMotd no
UseDNS no

AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

Subsystem sftp /usr/libexec/openssh/sftp-server
EOF
    systemctl restart sshd.service

    # 设置资源限制
    cat > /etc/security/limits.conf << "EOF"
*       soft    nofile  655350
*       hard    nofile  655350
*       soft    nproc   unlimited
*       hard    nproc   unlimited
*       soft    core    unlimited
*       hard    core    unlimited
root    soft    nofile  655350
root    hard    nofile  655350
root    soft    nproc   unlimited
root    hard    nproc   unlimited
root    soft    core    unlimited
root    hard    core    unlimited
EOF

    cat > /etc/systemd/system.conf << "EOF"
[Manager]
DefaultLimitNOFILE=655350
EOF

    # 优化内核
    cat > /etc/sysctl.conf << "EOF"
# 禁用包过滤功能
net.ipv4.ip_forward=0
# 启用源路由核查功能
net.ipv4.conf.default.rp_filter=1
# 禁用所有 IP 源路由
net.ipv4.conf.default.accept_source_route=0
# 控制 core 文件的文件名是否添加 pid 作为扩展
kernel.core_uses_pid=1
# 开启 SYN Cookies，当出现 SYN 等待队列溢出时，启用 cookies 来处理
net.ipv4.tcp_syncookies=1
# 每个消息队列的大小（单位：字节）限制
kernel.msgmnb=65536
# 整个系统最大消息队列数量限制
kernel.msgmax=65536
# 使用 sysrq 组合键是了解系统目前运行情况，为安全起见设为 0 关闭
kernel.sysrq=0
# 单个共享内存段的大小（单位：字节）限制，计算公式 64G*1024*1024*1024(字节)
kernel.shmmax=68719476736
# 对外连接端口范围
net.ipv4.ip_local_port_range=10000 65535
# 系统中最多有多少个 TCP 套接字不被关联到任何一个用户文件句柄上。这个限制仅仅是为了防止简单的 DoS 攻击，不能过分依靠它或者人为地减小这个值，更应该增加这个值(如果增加了内存之后)
net.ipv4.tcp_max_orphans=4000000
# 时间戳可以避免序列号的卷绕。一个 1Gbps 的链路肯定会遇到以前用过的序列号。时间戳能够让内核接受这种“异常” 的数据包。
net.ipv4.tcp_timestamps=0
# 服务端所能accept即处理数据的最大客户端数量，即完成连接上限
net.core.somaxconn=1024
# 当接口的主IP地址被移除时，将次IP地址提升为主IP地址
net.ipv4.conf.all.promote_secondaries=1
# 当接口的主IP地址被移除时，将次IP地址提升为主IP地址
net.ipv4.conf.default.promote_secondaries=1
# 设置产生softlockup时是否抛出一个panic。Softlockup用于检测CPU可以响应中断，但是在长时间内不能调度（比如禁止抢占时间太长）的死锁情况。这个机制运行在一个hrtimer的中断上下文，每隔一段时间检测一下是否发生了调度，如果过长时间没发生调度，说明系统被死锁。
kernel.softlockup_panic = 1
# 控制内核的脏数据刷新线程pdflush的运行间隔时间
vm.dirty_writeback_centisecs=100
# 控制内核写缓冲区的旧数据比列，建议500，5s的数据就算旧数据，dpflush进程将这些旧数据写到磁盘
vm.dirty_expire_centisecs=500
# 接收套接字缓冲区大小的最大值
net.core.rmem_max = 16777216
# 发送套接字缓冲区大小的最大值（以字节为单位）
net.core.wmem_max = 16777216
# 配置读缓冲的大小，三个值，第一个是这个读缓冲的最小值，第三个是最大值，中间的是默认值
net.ipv4.tcp_rmem = 4096 87380 16777216
# 配置写缓冲的大小，三个值，第一个是这个写缓冲的最小值，第三个是最大值，中间的是默认值
net.ipv4.tcp_wmem = 4096 65536 16777216
# 表示系统同时保持TIME_WAIT套接字的最大数量
net.ipv4.tcp_max_tw_buckets = 360000
# 保存在ARP高速缓存中的最多记录的硬限制，一旦高速缓存中的数目高于此，垃圾收集器gc将马上运行
net.ipv6.neigh.default.gc_thresh3 = 4096
net.ipv4.neigh.default.gc_thresh3 = 4096
# 禁用自动化 NUMA 平衡
kernel.numa_balancing = 0
# 控制台的日志级别
kernel.printk = 5
# Redis 配置
vm.overcommit_memory=1
EOF
    sysctl -p

    # 配置 swap
    if [ ${CHECK_RAM} -le 2 ]; then
        dd if=/dev/zero of=/swapfile bs=1024 count=1048576
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
        echo '# 控制如何使用 swap 分区' >> /etc/sysctl.conf
        echo 'vm.swappiness = 10' >> /etc/sysctl.conf
        sysctl -p
        sysctl -n vm.swappiness
    fi

    # 开启 IPV6
    if [ "${CHECK_IPV6}" == "true" ]; then
        echo '# 开启 IPV6' >> /etc/sysctl.conf
        echo 'net.ipv6.conf.all.disable_ipv6=0' >> /etc/sysctl.conf
        echo 'net.ipv6.conf.default.disable_ipv6=0' >> /etc/sysctl.conf
        echo 'net.ipv6.conf.lo.disable_ipv6=0' >> /etc/sysctl.conf
        sysctl -p

        echo 'DHCPV6C=yes' >> /etc/sysconfig/network-scripts/ifcfg-eth0
        echo 'IPV6INIT=yes' >> /etc/sysconfig/network-scripts/ifcfg-eth0
        systemctl restart network.service
        dhclient
    fi

    # 开启 BBR
    if [ ${CHECK_UNAME} -ge 5 ]; then
        echo '# 开启 BBR' >> /etc/sysctl.conf
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
    fi

    # 更改服务器名称
    if [ ! -z "${TENCENTCLOUD}" ] || [ ! -z "${ALICLOUD}" ]; then
        if [ $( echo ${INSTANCENAME} | awk '{print gensub(/[!-~]/,"","g",$0)}' ) ]; then
            NEWNAME=${INSTANCEID}
        else
            NEWNAME=${INSTANCENAME}
        fi
        OLDNAME=$( hostname )
        hostnamectl set-hostname --static ${NEWNAME}
        sed -i "s@${OLDNAME}@${NEWNAME}@g" /etc/hosts
        sed -i '/update_hostname/d' /etc/cloud/cloud.cfg
    fi

    # 安装新内核工具
    if [ -f "/root/.meteorite/tmp/upgrade_kernel.lock" ]; then
        yum remove $( rpm -qa | grep kernel | grep -v $(uname -r) ) -y
        yum -y --enablerepo=elrepo-kernel install ${KERNEL_VER}-{devel,doc,headers,tools,tools-libs,tools-libs-devel}
        echo "exclude=kernel* redhat-release* centos-release* fedora-release*" >> /etc/yum.conf
    fi

    # 更新源
    replace_source
}