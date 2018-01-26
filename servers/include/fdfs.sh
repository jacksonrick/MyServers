#!/bin/bash
# Notes: fastDFS install

Install_DFS() {
echo "installing fastDFS... ${CEND}"
ipaddr="36.7.83.59:22122"

cd $oneinstack_dir/src
unzip -o libfastcommon-master.zip
cd libfastcommon-master
./make.sh
./make.sh install

cd ..
tar -zxvf fastdfs-5.10.tar.gz
cd fastdfs-5.10
./make.sh
./make.sh install
cd /etc/fdfs
mv client.conf.sample client.conf
mv storage.conf.sample storage.conf
mv tracker.conf.sample tracker.conf

mkdir -p $fdfs_dir/data0
sed -i "s@base_path=.*@base_path=$fdfs_dir@" /etc/fdfs/tracker.conf
sed -i "s@base_path=.*@base_path=$fdfs_dir@" /etc/fdfs/storage.conf
sed -i "s@store_path0=.*@store_path0=$fdfs_dir/data0@" /etc/fdfs/storage.conf
sed -i "s@tracker_server=.*@tracker_server=$ipaddr@" /etc/fdfs/storage.conf
sed -i "s@base_path=.*@base_path=$fdfs_dir@" /etc/fdfs/client.conf
sed -i "s@tracker_server=.*@tracker_server=$ipaddr@" /etc/fdfs/client.conf

cd $oneinstack_dir/src
tar -zxvf pcre-$pcre_version.tar.gz
tar -zxvf nginx-$nginx_version.tar.gz
tar -zxvf openssl-1.0.1c.tar.gz
unzip -o fastdfs-nginx-module-master.zip
cd nginx-$nginx_version

./configure --add-module=../fastdfs-nginx-module-master/src/ --prefix=$nginx_install_dir --with-pcre=../pcre-$pcre_version --with-openssl=../openssl-$openssl_version --with-http_stub_status_module --with-http_ssl_module
make && make install

cd ../../
cp src/fastdfs-nginx-module-master/src/mod_fastdfs.conf /etc/fdfs/
cp src/fastdfs-5.10/conf/http.conf /etc/fdfs/
cp src/fastdfs-5.10/conf/mime.types /etc/fdfs/

mkdir -p $fdfs_dir/ngx
sed -i "s@base_path=.*@base_path=$fdfs_dir/ngx@" /etc/fdfs/mod_fastdfs.conf
sed -i "s@tracker_server=.*@tracker_server=$ipaddr@" /etc/fdfs/mod_fastdfs.conf
sed -i "s@store_path0=.*@store_path0 =$fdfs_dir/data0@" /etc/fdfs/mod_fastdfs.conf
sed -i "s@url_have_group_name = false@url_have_group_name = true@" /etc/fdfs/mod_fastdfs.conf
sed -i "s@# redirect.*@location /group1/M00 {\n\troot $fdfs_dir/data0/data;\n\tngx_fastdfs_module;\n\t}@" $nginx_install_dir/conf/nginx.conf

/bin/cp init.d/Fast-DFS-init /etc/init.d/fastdfs
sed -i "s@NG_DIR=.*@NG_DIR=$nginx_install_dir@" /etc/init.d/fastdfs
[ "$OS" == 'CentOS' ] && { chkconfig --add fastdfs; chkconfig fastdfs on; } 

echo "${CSUCCESS}fastDFS install successfully! ${CEND}"
service fastdfs start
}