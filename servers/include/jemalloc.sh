#!/bin/bash
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
# Project home page: http://oneinstack.com

Install_jemalloc() {
cd $oneinstack_dir/src
tar xjf jemalloc-$jemalloc_version.tar.bz2
cd jemalloc-$jemalloc_version
LDFLAGS="${LDFLAGS} -lrt" ./configure
make && make install

if [ -f "/usr/local/lib/libjemalloc.so" ];then
    if [ "$OS_BIT" == '64' -a "$OS" == 'CentOS' ];then
        ln -s /usr/local/lib/libjemalloc.so.2 /usr/lib64/libjemalloc.so.1
    else
        ln -s /usr/local/lib/libjemalloc.so.2 /usr/lib/libjemalloc.so.1
    fi
    echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
    ldconfig
    echo "${CSUCCESS}jemalloc module install successfully! ${CEND}"
    cd ..
    rm -rf jemalloc-$jemalloc_version
else
    echo "${CFAILURE}jemalloc install failed, Please contact the author! ${CEND}"
    kill -9 $$
fi
cd ..
}
