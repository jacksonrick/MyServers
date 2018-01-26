#!/bin/bash
# Notes: svn install

Install_Subversion() {
echo "installing subversion... ${CEND}"
yum -y install subversion
[ ! -d "$svn_dir/default" ] && mkdir -p $svn_dir/default
svnadmin create $svn_dir/default

/bin/cp init.d/Svn-init /etc/init.d/subversion
sed -i "s@SVN_DIR=.*@SVN_DIR=$svn_dir@" /etc/init.d/subversion
sed -i "s/# anon-access = read/anon-access = none/g" $svn_dir/default/conf/svnserve.conf
sed -i "s/# auth-access = write/auth-access = write/g" $svn_dir/default/conf/svnserve.conf
sed -i "s/# password-db = passwd/password-db = passwd/g" $svn_dir/default/conf/svnserve.conf
sed -i "s/# authz-db = authz/authz-db = authz/g" $svn_dir/default/conf/svnserve.conf
sed -i "s@# realm = My First Repository@realm = $svn_dir/default@" $svn_dir/default/conf/svnserve.conf
echo -e '[/]\ntest = rw'>>$svn_dir/default/conf/authz
echo -e 'test = 12345678'>>$svn_dir/default/conf/passwd

[ "$OS" == 'CentOS' ] && { chkconfig --add subversion; chkconfig subversion on; } 

echo "${CSUCCESS}subversion install successfully! ${CEND}"
service subversion start
}