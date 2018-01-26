#!/bin/bash
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
# Project home page: http://oneinstack.com

sed -i 's@^exclude@#exclude@' /etc/yum.conf
#yum clean all
#yum makecache
#yum check-update
#yum -y upgrade

# install & update package for centos
Pkg_Install=1

if [ "$Pkg_Install" == '1' ];then
    # Install needed packages
    for Package in deltarpm gcc gcc-c++ make cmake autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel libaio readline-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel openssl openssl-devel libxslt-devel libicu-devel libevent-devel libtool libtool-ltdl bison gd-devel vim-enhanced pcre-devel zip unzip ntpdate sysstat patch bc expect rsync git lsof lrzsz
    do
        yum -y install $Package
    done

    yum -y update bash openssl glibc

    # use gcc-4.4
    if [ -n "`gcc --version | head -n1 | grep '4\.1\.'`" ];then
        yum -y install gcc44 gcc44-c++ libstdc++44-devel
        export CC="gcc44" CXX="g++44"
    fi
fi

# closed Unnecessary services and remove obsolete rpm package
for Service in `chkconfig --list | grep 3:on | awk '{print $1}' | grep -vE 'nginx|httpd|tomcat|mysqld|php-fpm|pureftpd|redis-server|memcached|supervisord|aegis'`;do chkconfig --level 3 $Service off;done
for Service in sshd network crond iptables messagebus irqbalance rsyslog;do chkconfig --level 3 $Service on;done

# Close SELINUX
setenforce 0
sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config

# initdefault
sed -i 's/^id:.*$/id:3:initdefault:/' /etc/inittab
init q

# PS1
[ -z "`cat ~/.bashrc | grep ^PS1`" ] && echo 'PS1="\[\e[37;40m\][\[\e[32;40m\]\u\[\e[37;40m\]@\h \[\e[35;40m\]\W\[\e[0m\]]\\$ "' >> ~/.bashrc 

# history size 
sed -i 's/^HISTSIZE=.*$/HISTSIZE=100/' /etc/profile
[ -z "`cat ~/.bashrc | grep history-timestamp`" ] && echo "export PROMPT_COMMAND='{ msg=\$(history 1 | { read x y; echo \$y; });user=\$(whoami); echo \$(date \"+%Y-%m-%d %H:%M:%S\"):\$user:\`pwd\`/:\$msg ---- \$(who am i); } >> /tmp/\`hostname\`.\`whoami\`.history-timestamp'" >> ~/.bashrc

# /etc/security/limits.conf
[ -e /etc/security/limits.d/*nproc.conf ] && rename nproc.conf nproc.conf_bk /etc/security/limits.d/*nproc.conf
sed -i '/^# End of file/,$d' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
# End of file
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
[ -z "`grep 'ulimit -SH 65535' /etc/rc.local`" ] && echo "ulimit -SH 65535" >> /etc/rc.local

# /etc/hosts
[ "$(hostname -i | awk '{print $1}')" != "127.0.0.1" ] && sed -i "s@^127.0.0.1\(.*\)@127.0.0.1   `hostname` \1@" /etc/hosts

# Set timezone
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# sync time
ntpdate ntp.api.bz

# Set DNS
#cat > /etc/resolv.conf << EOF
#nameserver 114.114.114.114 
#nameserver 8.8.8.8 
#EOF

# alias vi
[ -z "`cat ~/.bashrc | grep 'alias vi='`" ] && sed -i "s@alias mv=\(.*\)@alias mv=\1\nalias vi=vim@" ~/.bashrc && echo 'syntax on' >> /etc/vimrc

# /etc/sysctl.conf
sed -i 's/net.ipv4.tcp_syncookies.*$/net.ipv4.tcp_syncookies = 1/g' /etc/sysctl.conf
[ -z "`cat /etc/sysctl.conf | grep 'fs.file-max'`" ] && cat >> /etc/sysctl.conf << EOF
fs.file-max=65535
fs.inotify.max_user_instances = 8192 
net.ipv4.tcp_fin_timeout = 30 
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 65536 
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 65535 
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 262144
EOF
sysctl -p

if [ "$CentOS_RHEL_version" == '5' ];then
    sed -i 's@^[3-6]:2345:respawn@#&@g' /etc/inittab
    sed -i 's@^ca::ctrlaltdel@#&@' /etc/inittab
    sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/sysconfig/i18n
elif [ "$CentOS_RHEL_version" == '6' ];then
    sed -i 's@^ACTIVE_CONSOLES.*@ACTIVE_CONSOLES=/dev/tty[1-2]@' /etc/sysconfig/init	
    sed -i 's@^start@#start@' /etc/init/control-alt-delete.conf
    sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/sysconfig/i18n
    [ -z "`grep net.netfilter.nf_conntrack_max /etc/sysctl.conf`" ] && cat >> /etc/sysctl.conf << EOF
net.netfilter.nf_conntrack_max = 1048576 
EOF
elif [ "$CentOS_RHEL_version" == '7' ];then
    sed -i 's@LANG=.*$@LANG="en_US.UTF-8"@g' /etc/locale.conf 
    [ -z "`grep net.netfilter.nf_conntrack_max /etc/sysctl.conf`" ] && cat >> /etc/sysctl.conf << EOF
net.netfilter.nf_conntrack_max = 1048576 
EOF
fi
init q

# install tmux
if [ ! -e "`which tmux`" ];then
    cd src
    tar xzf libevent-2.0.22-stable.tar.gz
    cd libevent-2.0.22-stable
    ./configure
    make && make install
    cd ..

    tar xzf tmux-2.2.tar.gz
    cd tmux-2.2
    CFLAGS="-I/usr/local/include" LDFLAGS="-L//usr/local/lib" ./configure
    make && make install
    cd ../../

    if [ "$OS_BIT" == '64' ];then
        ln -s /usr/local/lib/libevent-2.0.so.5 /usr/lib64/libevent-2.0.so.5
    else
        ln -s /usr/local/lib/libevent-2.0.so.5 /usr/lib/libevent-2.0.so.5
    fi
fi

# install htop
if [ ! -e "`which htop`" ];then
    cd src
    tar xzf htop-2.0.0.tar.gz
    cd htop-2.0.0
    ./configure
    make && make install
    cd ../../
fi
. /etc/profile
. ~/.bashrc
