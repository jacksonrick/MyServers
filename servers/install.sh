#!/bin/bash 
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
# Project home page: http://oneinstack.com

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear
printf "
#######################################################################
#       Nginx/Tomcat/Jdk/MySQL/PHP/Redis/Subversion/FastDFS           #
#       By OneinStack & Jackson Rick                                  #
#       For more information please visit http://oneinstack.com       #
#######################################################################
"

# get pwd
sed -i "s@^oneinstack_dir.*@oneinstack_dir=`pwd`@" ./options.conf

. ./apps.conf
. ./options.conf
. ./include/color.sh
. ./include/check_os.sh
. ./include/check_db.sh
. ./include/check_web.sh
. ./include/download.sh
. ./include/get_char.sh

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; } 

mkdir -p $wwwroot_dir/default $wwwlogs_dir
[ -d /data ] && chmod 755 /data

# Use default SSH port 22

# Web server
while :; do echo
    read -p "Do you want to install Nginx Web server? [y/n]: " Web_yn
    if [[ ! $Web_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        if [ "$Web_yn" == 'y' ];then
            # Nginx
            Nginx_version=1
            [ "$Nginx_version" == '1' -a -e "$nginx_install_dir/sbin/nginx" ] && { echo "${CWARNING}Nginx already installed! ${CEND}"; Nginx_version=Other; }
        fi
        break
    fi
done

# Tomcat
while :; do echo
    read -p "Do you want to install tomcat server? [y/n]: " Tomcat_yn
    if [[ ! $Tomcat_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        if [ "$Tomcat_yn" == 'y' ];then
            Tomcat_version=1
            JDK_version=1
            [ "$Tomcat_version" == '1' -a -e "$tomcat_install_dir/conf/server.xml" ] && { echo "${CWARNING}Tomcat already installed! ${CEND}" ; Tomcat_version=Other; }
        fi
        break
    fi
done

# Jdk
if [ "$Tomcat_yn" == 'n' ];then
    while :; do echo
        read -p "Do you want to install jdk? [y/n]: " JDK_yn
        if [[ ! $JDK_yn =~ ^[y,n]$ ]];then
            echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
        else
            if [ "$JDK_yn" == 'y' ];then
                JDK_version=1
            fi
            break
        fi
    done
fi

# Mysql
while :; do echo
    read -p "Do you want to install Database? [y/n]: " DB_yn
    if [[ ! $DB_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        if [ "$DB_yn" == 'y' ];then
            [ -d "$mysql_install_dir/support-files" ] && { echo "${CWARNING}Database already installed! ${CEND}"; DB_yn=Other; break; }
            DB_version=2
            while :; do
                read -p "Please input the root password of database: " dbrootpwd
                [ -n "`echo $dbrootpwd | grep '[+|&]'`" ] && { echo "${CWARNING}input error,not contain a plus sign (+) and & ${CEND}"; continue; }
                (( ${#dbrootpwd} >= 5 )) && sed -i "s+^dbrootpwd.*+dbrootpwd='$dbrootpwd'+" ./options.conf && break || echo "${CWARNING}database root password least 5 characters! ${CEND}"
            done
            break
        fi
        break
    fi
done

# Redis
while :; do echo
    read -p "Do you want to install redis? [y/n]: " redis_yn
    if [[ ! $redis_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break
    fi
done

# PHP
while :; do echo
  read -p "Do you want to install PHP? [y/n]: " PHP_yn
  if [[ ! $PHP_yn =~ ^[y,n]$ ]]; then
    echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
  else
    if [ "$PHP_yn" == 'y' ]; then
      [ -e "$php_install_dir/bin/phpize" ] && { echo "${CWARNING}PHP already installed! ${CEND}"; PHP_yn=Other; break; }
      PHP_version=4
    fi
    break
  fi
done

# Subversion
while :; do echo
    read -p "Do you want to install Subversion? [y/n]: " Svn_yn
    if [[ ! $Svn_yn =~ ^[y,n]$ ]]; then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        if [ "$Svn_yn" == 'y' ]; then
          SVN_version=1
        fi
        break
    fi
done

# FastDFS
while :; do echo
    read -p "Do you want to install FastDFS? [y/n]: " dfs_yn
    if [[ ! $dfs_yn =~ ^[y,n]$ ]]; then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        if [ "$dfs_yn" == 'y' ]; then
          DFS_version=1
        fi
        break
    fi
done

# check *jemalloc or tcmalloc 
if [ "$DB_yn" == 'y' ];then
    je_tc_malloc=1
fi

############## Init ##############
. ./include/memory.sh
if [ "$OS" == 'CentOS' ];then
    . include/init_CentOS.sh 2>&1 | tee $oneinstack_dir/install.log
    [ -n "`gcc --version | head -n1 | grep '4\.1\.'`" ] && export CC="gcc44" CXX="g++44"
elif [ "$OS" == 'Debian' ];then
    . include/init_Debian.sh 2>&1 | tee $oneinstack_dir/install.log
elif [ "$OS" == 'Ubuntu' ];then
    . include/init_Ubuntu.sh 2>&1 | tee $oneinstack_dir/install.log
fi

# jemalloc
if [ "$je_tc_malloc" == '1' -a ! -e "/usr/local/lib/libjemalloc.so" ];then
    . include/jemalloc.sh
    Install_jemalloc | tee -a $oneinstack_dir/install.log
fi

# Database
if [ "$DB_version" == '1' ];then
    . include/mysql-5.7.sh 
    Install_MySQL-5-7 2>&1 | tee -a $oneinstack_dir/install.log 
elif [ "$DB_version" == '2' ];then
    . include/mysql-5.6.sh 
    Install_MySQL-5-6 2>&1 | tee -a $oneinstack_dir/install.log 
fi

# Web server
if [ "$Nginx_version" == '1' ];then
    . include/nginx.sh
    Install_Nginx 2>&1 | tee -a $oneinstack_dir/install.log
fi

# JDK
if [ "$JDK_version" == '1' ];then
    . include/jdk-1.8.sh
    Install-JDK-1-8 2>&1 | tee -a $oneinstack_dir/install.log
elif [ "$JDK_version" == '2' ];then
    . include/jdk-1.7.sh
    Install-JDK-1-7 2>&1 | tee -a $oneinstack_dir/install.log
elif [ "$JDK_version" == '3' ];then
    . include/jdk-1.6.sh
    Install-JDK-1-6 2>&1 | tee -a $oneinstack_dir/install.log
fi

# Tomcat
if [ "$Tomcat_version" == '1' ];then
    . include/tomcat-8.sh
    Install_Tomcat-8 2>&1 | tee -a $oneinstack_dir/install.log
elif [ "$Tomcat_version" == '2' ];then
    . include/tomcat-7.sh
    Install_Tomcat-7 2>&1 | tee -a $oneinstack_dir/install.log
fi

# Redis
if [ "$redis_yn" == 'y' ];then
    . include/redis.sh
    [ ! -d "$redis_install_dir" ] && Install_redis-server 2>&1 | tee -a $oneinstack_dir/install.log
    [ -e "$php_install_dir/bin/phpize" ] && [ ! -e "`$php_install_dir/bin/php-config --extension-dir`/redis.so" ] && Install_php-redis 2>&1 | tee -a $oneinstack_dir/install.log
fi

# PHP
if [ "$PHP_version" == '1' ];then
    . include/php-5.3.sh
    Install_PHP-5-3 2>&1 | tee -a $oneinstack_dir/install.log
elif [ "$PHP_version" == '2' ];then
    . include/php-5.4.sh
    Install_PHP-5-4 2>&1 | tee -a $oneinstack_dir/install.log
elif [ "$PHP_version" == '3' ];then
    . include/php-5.5.sh
    Install_PHP-5-5 2>&1 | tee -a $oneinstack_dir/install.log
elif [ "$PHP_version" == '4' ];then
    . include/php-5.6.sh
    Install_PHP-5-6 2>&1 | tee -a $oneinstack_dir/install.log
elif [ "$PHP_version" == '5' ];then
    . include/php-7.sh
    Install_PHP-7 2>&1 | tee -a $oneinstack_dir/install.log
fi

# Subversion
if [ "$SVN_version" == '1' ];then
    . include/subversion.sh
    Install_Subversion 2>&1 | tee -a $oneinstack_dir/install.log
fi

# FastDFS
if [ "$DFS_version" == '1' ];then
    . include/fdfs.sh
    Install_DFS 2>&1 | tee -a $oneinstack_dir/install.log
fi

# index.html
if [ ! -e "$wwwroot_dir/default/index.html" -a "$Web_yn" == 'y' ];then
    . include/demo.sh
    DEMO 2>&1 | tee -a $oneinstack_dir/install.log 
fi

# get web_install_dir and mysql_install_dir
#. include/check_db.sh
#. include/check_web.sh

# Starting DB 
#[ -d "/etc/mysql" ] && /bin/mv /etc/mysql{,_bk}
#[ -d "$mysql_install_dir/support-files" -a -z "`ps -ef | grep -v grep | grep mysql`" ] && /etc/init.d/mysqld start

echo "####################Congratulations########################"
[ "$Web_yn" == 'y' -a "$Nginx_version" == '1' ] && echo -e "\n`printf "%-32s" "Nginx install dir":`${CMSG}$nginx_install_dir${CEND}"
[ "$Tomcat_version" == '1' ] && echo -e "\n`printf "%-32s" "Tomcat install dir":`${CMSG}$tomcat_install_dir${CEND}"
[ "$JDK_version" == '1' ] && echo -e "\n`printf "%-32s" "Jdk install dir":`${CMSG}$jdk_install_dir${CEND}"
[ "$DB_yn" == 'y' ] && echo -e "\n`printf "%-32s" "Database install dir:"`${CMSG}$mysql_install_dir${CEND}"
[ "$DB_yn" == 'y' ] && echo "`printf "%-32s" "Database data dir:"`${CMSG}$db_data_dir${CEND}"
[ "$DB_yn" == 'y' ] && echo "`printf "%-32s" "Database user:"`${CMSG}root${CEND}"
[ "$DB_yn" == 'y' ] && echo "`printf "%-32s" "Database password:"`${CMSG}${dbrootpwd}${CEND}"
[ "$redis_yn" == 'y' ] && echo -e "\n`printf "%-32s" "redis install dir:"`${CMSG}$redis_install_dir${CEND}"
[ "$PHP_yn" == 'y' ] && echo -e "\n`printf "%-32s" "PHP install dir:"`${CMSG}$php_install_dir${CEND}"
[ "$Svn_yn" == 'y' ] && echo -e "\n`printf "%-32s" "Subversion install dir:"`${CMSG}$svn_dir${CEND}"

while :; do echo
    echo "${CMSG}Please restart the server and see if the services start up fine.${CEND}"
    read -p "Do you want to restart OS ? [y/n]: " restart_yn
    if [[ ! $restart_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break
    fi
done
[ "$restart_yn" == 'y' ] && reboot