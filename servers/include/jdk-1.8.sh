#!/bin/bash
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
# Project home page: http://oneinstack.com

Install-JDK-1-8() {
cd $oneinstack_dir/src

JDK_FILE="jdk-`echo $jdk_8_version | awk -F. '{print $2}'`u`echo $jdk_8_version | awk -F_ '{print $NF}'`-linux-$SYS_BIG_FLAG.tar.gz"
JDK_NAME="jdk$jdk_8_version"
JDK_PATH="$jdk_install_dir"


[ "$OS" == 'CentOS' ] && [ -n "`rpm -qa | grep jdk`" ] && rpm -e `rpm -qa | grep jdk`

tar xzf $JDK_FILE

if [ -d "$JDK_NAME" ];then
    rm -rf $JDK_PATH; mkdir -p $JDK_PATH
    mv $JDK_NAME/** $JDK_PATH
    [ -z "`grep ^'export JAVA_HOME=' /etc/profile`" ] && { [ -z "`grep ^'export PATH=' /etc/profile`" ] && echo  "export JAVA_HOME=$JDK_PATH" >> /etc/profile || sed -i "s@^export PATH=@export JAVA_HOME=$JDK_PATH\nexport PATH=@" /etc/profile; } || sed -i "s@^export JAVA_HOME=.*@export JAVA_HOME=$JDK_PATH@" /etc/profile
    [ -z "`grep ^'export CLASSPATH=' /etc/profile`" ] && sed -i "s@export JAVA_HOME=\(.*\)@export JAVA_HOME=\1\nexport CLASSPATH=\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib@" /etc/profile
    [ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep '$JAVA_HOME/bin' /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=\$JAVA_HOME/bin:\1@" /etc/profile
    [ -z "`grep ^'export PATH=' /etc/profile | grep '$JAVA_HOME/bin'`" ] && echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
    source /etc/profile
    echo "${CSUCCESS}$JDK_NAME install successfully! ${CEND}"
else
    rm -rf $JDK_PATH
    echo "${CFAILURE}JDK install failed, Please contact the author! ${CEND}"
    kill -9 $$
fi
cd ..
}
