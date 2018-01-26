#!/bin/bash
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
# Project home page: http://oneinstack.com

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
clear
printf "
#######################################################################
#       OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+      #
#       For more information please visit http://oneinstack.com       #
#######################################################################
"

. ./options.conf
. ./include/color.sh
. ./include/check_web.sh
. ./include/get_char.sh

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; } 

Usage() {
printf "
Usage: $0 [ ${CMSG}add${CEND} | ${CMSG}del${CEND} ]
${CMSG}add${CEND}    --->Add Virtualhost
${CMSG}del${CEND}    --->Delete Virtualhost

"
}

Choose_env() {
while :
do
    echo
    echo 'Please choose to use environment:'
    echo -e "\t${CMSG}1${CEND}. Use php"
    echo -e "\t${CMSG}2${CEND}. Use java"
    read -p "Please input a number:(Default 2 press Enter) " Choose_number
    [ -z "$Choose_number" ] && Choose_number=2
    if [[ ! $Choose_number =~ ^[1-2]$ ]];then
        echo "${CWARNING}input error! Please only input number 1,2${CEND}"
    else
        break
    fi
done
[ "$Choose_number" == '1' ] && NGX_FLAG=php
[ "$Choose_number" == '2' ] && NGX_FLAG=java

if [ "$NGX_FLAG" == 'php' ];then
    NGX_CONF=$(echo -e "location ~ [^/]\.php(/|$) {\n    #fastcgi_pass remote_php_ip:9000;\n    fastcgi_pass unix:/dev/shm/php-cgi.sock;\n    fastcgi_index index.php;\n    include fastcgi.conf;\n    }")
elif [ "$NGX_FLAG" == 'java' ];then
    NGX_CONF=$(echo -e "location ~ {\n    proxy_pass http://127.0.0.1:8080;\n    include proxy.conf;\n    }")
fi
}

Nginx_ssl() {
printf "
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
"

echo
read -p "Country Name (2 letter code) [CN]: " SELFSIGNEDSSL_C
[ -z "$SELFSIGNEDSSL_C" ] && SELFSIGNEDSSL_C=CN

echo
read -p "State or Province Name (full name) [Shanghai]: " SELFSIGNEDSSL_ST
[ -z "$SELFSIGNEDSSL_ST" ] && SELFSIGNEDSSL_ST=Shanghai

echo
read -p "Locality Name (eg, city) [Shanghai]: " SELFSIGNEDSSL_L
[ -z "$SELFSIGNEDSSL_L" ] && SELFSIGNEDSSL_L=Shanghai

echo
read -p "Organization Name (eg, company) [LinuxEye Inc.]: " SELFSIGNEDSSL_O
[ -z "$SELFSIGNEDSSL_O" ] && SELFSIGNEDSSL_O='LinuxEye Inc.'

echo
read -p "Organizational Unit Name (eg, section) [IT Dept.]: " SELFSIGNEDSSL_OU
[ -z "$SELFSIGNEDSSL_OU" ] && SELFSIGNEDSSL_OU='IT Dept.'

if [[ "$($web_install_dir/sbin/nginx -V 2>&1 | grep -Eo 'with-http_v2_module')" = 'with-http_v2_module' ]]; then
  LISTENOPT='443 ssl http2'
else
  LISTENOPT='443 ssl spdy'
fi

[ ! -d "$web_install_dir/conf/ssl" ] && mkdir $web_install_dir/conf/ssl
openssl req -new -newkey rsa:2048 -sha256 -nodes -out $web_install_dir/conf/ssl/${domain}.csr -keyout $web_install_dir/conf/ssl/${domain}.key -subj "/C=${SELFSIGNEDSSL_C}/ST=${SELFSIGNEDSSL_ST}/L=${SELFSIGNEDSSL_L}/O=${SELFSIGNEDSSL_O}/OU=${SELFSIGNEDSSL_OU}/CN=${domain}" > /dev/null 2>&1
/bin/cp $web_install_dir/conf/ssl/${domain}.csr{,_bk.`date +%Y-%m-%d_%H%M`}
/bin/cp $web_install_dir/conf/ssl/${domain}.key{,_bk.`date +%Y-%m-%d_%H%M`}
openssl x509 -req -days 36500 -sha256 -in $web_install_dir/conf/ssl/${domain}.csr -signkey $web_install_dir/conf/ssl/${domain}.key -out $web_install_dir/conf/ssl/${domain}.crt > /dev/null 2>&1
}

Print_ssl() {
echo "`printf "%-30s" "Self-signed SSL Certificate:"`${CMSG}$web_install_dir/conf/ssl/${domain}.crt${CEND}"
echo "`printf "%-30s" "SSL Private Key:"`${CMSG}$web_install_dir/conf/ssl/${domain}.key${CEND}"
echo "`printf "%-30s" "SSL CSR File:"`${CMSG}$web_install_dir/conf/ssl/${domain}.csr${CEND}"
}


Input_Add_domain() {
if [ -e "$web_install_dir/sbin/nginx" ];then
    while :
    do
        echo
        read -p "Do you want to setup SSL under Nginx? [y/n]: " nginx_ssl_yn
        if [[ ! $nginx_ssl_yn =~ ^[y,n]$ ]];then
            echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
        else
            break
        fi
    done
fi

while :
do
    echo
    read -p "Please input domain(example: test.cn): " domain
    if [ -z "`echo $domain | grep '.*\..*'`" ]; then
        echo "${CWARNING}input error! ${CEND}"
    else
        break
    fi
done

if [ -e "$web_install_dir/conf/vhost/$domain.conf" -o -e "$apache_install_dir/conf/vhost/$domain.conf" -o -e "$tomcat_install_dir/conf/vhost/$domain.xml" ]; then
    [ -e "$web_install_dir/conf/vhost/$domain.conf" ] && echo -e "$domain in the Nginx/Tengine/OpenResty already exist! \nYou can delete ${CMSG}$web_install_dir/conf/vhost/$domain.conf${CEND} and re-create"
    [ -e "$apache_install_dir/conf/vhost/$domain.conf" ] && echo -e "$domain in the Apache already exist! \nYou can delete ${CMSG}$apache_install_dir/conf/vhost/$domain.conf${CEND} and re-create"
    [ -e "$tomcat_install_dir/conf/vhost/$domain.xml" ] && echo -e "$domain in the Tomcat already exist! \nYou can delete ${CMSG}$tomcat_install_dir/conf/vhost/$domain.xml${CEND} and re-create"
    exit
else
    echo "domain=$domain"
fi

while :
do
    echo
    read -p "Do you want to add more domain name? [y/n]: " moredomainame_yn
    if [[ ! $moredomainame_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break
    fi
done

if [ "$moredomainame_yn" == 'y' ]; then
    while :
    do
        echo
        read -p "Type domainname or IP(example: linuxeye.com 121.43.8.8): " moredomain
        if [ -z "`echo $moredomain | grep '.*\..*'`" ]; then
            echo "${CWARNING}input error! ${CEND}"
        else
            [ "$moredomain" == "$domain" ] && echo "${CWARNING}Domain name already exists! ${CND}" && continue
            echo domain list="$moredomain"
            moredomainame=" $moredomain"
            break
        fi
    done
    
    Tomcat_Domain_alias=$(for D in `echo $moredomainame`; do echo "<Alias>$D</Alias>"; done)

    if [ -e "$web_install_dir/sbin/nginx" ];then
        while :
        do
            echo
            read -p "Do you want to redirect from $moredomain to $domain? [y/n]: " redirect_yn
            if [[ ! $redirect_yn =~ ^[y,n]$ ]];then
                echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
            else
                break
            fi
        done
        [ "$nginx_ssl_yn" == 'y' ] && HTTP_flag=https || HTTP_flag=http 
        [ "$redirect_yn" == 'y' ] && Nginx_redirect=$(echo -e "if (\$host != $domain) {\n    rewrite ^/(.*)\$ \$scheme://$domain/\$1 permanent;\n    }")
    fi
fi

if [ "$nginx_ssl_yn" == 'y' ]; then
    Nginx_ssl
    Nginx_conf=$(echo -e "listen $LISTENOPT;\nssl_certificate $web_install_dir/conf/ssl/$domain.crt;\nssl_certificate_key $web_install_dir/conf/ssl/$domain.key;\nssl_session_timeout 10m;\nssl_protocols TLSv1 TLSv1.1 TLSv1.2;\nssl_prefer_server_ciphers on;\nssl_ciphers "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-RC4-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:RC4-SHA:\!aNULL:\!eNULL:\!EXPORT:\!DES:\!3DES:\!MD5:\!DSS:\!PKS";\nssl_session_cache builtin:1000 shared:SSL:10m;\nresolver 8.8.8.8 8.8.4.4 valid=300s;\nresolver_timeout 5s;")
    if [ "$moredomainame_yn" == 'y' ]; then
        Nginx_http_to_https=$(echo -e "server {\nlisten 80;\nserver_name $domain$moredomainame;\nrewrite ^/(.*) https://$domain/\$1 permanent;\n}")
    else
        Nginx_http_to_https=$(echo -e "server {\nlisten 80;\nserver_name $domain;\nrewrite ^/(.*) https://$domain/\$1 permanent;\n}")
    fi
else
    Nginx_conf='listen 80;'
fi

while :
do
    echo
    echo "Please input the directory for the domain:$domain :"
    read -p "(Default directory: $wwwroot_dir/$domain): " vhostdir
    if [ -n "$vhostdir" -a -z "`echo $vhostdir | grep '^/'`" ];then
        echo "${CWARNING}input error! Press Enter to continue...${CEND}"
    else
        if [ -z "$vhostdir" ]; then
            vhostdir="$wwwroot_dir/$domain"
            echo "Virtual Host Directory=${CMSG}$vhostdir${CEND}"
        fi
        echo
        echo "Create Virtul Host directory......"
        mkdir -p $vhostdir
        echo "set permissions of Virtual Host directory......"
        chown -R ${run_user}.$run_user $vhostdir
        break
    fi
done
}

Nginx_anti_hotlinking() {
while :
do
    echo
    read -p "Do you want to add hotlink protection? [y/n]: " anti_hotlinking_yn 
    if [[ ! $anti_hotlinking_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break
    fi
done

if [ -n "`echo $domain | grep '.*\..*\..*'`" ];then
    domain_allow="*.${domain#*.} $domain"
else
    domain_allow="*.$domain $domain"
fi

if [ "$anti_hotlinking_yn" == 'y' ];then 
    if [ "$moredomainame_yn" == 'y' ]; then
        domain_allow_all=$domain_allow$moredomainame
    else
        domain_allow_all=$domain_allow
    fi
    anti_hotlinking=$(echo -e "location ~ .*\.(wma|wmv|asf|mp3|mmf|zip|rar|jpg|gif|png|swf|flv)$ {\n    valid_referers none blocked $domain_allow_all;\n    if (\$invalid_referer) {\n        #rewrite ^/ http://www.linuxeye.com/403.html;\n        return 403;\n        }\n    }")
else
    anti_hotlinking=
fi
}

Nginx_rewrite() {
[ ! -d "$web_install_dir/conf/rewrite" ] && mkdir $web_install_dir/conf/rewrite
while :
do
    echo
    read -p "Allow Rewrite rule? [y/n]: " rewrite_yn
    if [[ ! $rewrite_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break 
    fi
done
if [ "$rewrite_yn" == 'n' ];then
    rewrite="none"
    touch "$web_install_dir/conf/rewrite/$rewrite.conf"
else
    echo
    echo "Please input the rewrite of programme :"
    echo "${CMSG}wordpress${CEND},${CMSG}discuz${CEND},${CMSG}opencart${CEND},${CMSG}thinkphp${CEND},${CMSG}laravel${CEND},${CMSG}typecho${CEND},${CMSG}ecshop${CEND},${CMSG}drupal${CEND},${CMSG}joomla${CEND} rewrite was exist."
    read -p "(Default rewrite: other):" rewrite
    if [ "$rewrite" == "" ]; then
    	rewrite="other"
    fi
    echo "You choose rewrite=${CMSG}$rewrite${CEND}"
    [ "$NGX_FLAG" == 'php' -a "$rewrite" == "thinkphp" ] && NGX_CONF=$(echo -e "location ~ \.php {\n    #fastcgi_pass remote_php_ip:9000;\n    fastcgi_pass unix:/dev/shm/php-cgi.sock;\n    fastcgi_index index.php;\n    include fastcgi_params;\n    set \$real_script_name \$fastcgi_script_name;\n        if (\$fastcgi_script_name ~ \"^(.+?\.php)(/.+)\$\") {\n        set \$real_script_name \$1;\n        #set \$path_info \$2;\n        }\n    fastcgi_param SCRIPT_FILENAME \$document_root\$real_script_name;\n    fastcgi_param SCRIPT_NAME \$real_script_name;\n    #fastcgi_param PATH_INFO \$path_info;\n    }")
    if [ -e "config/$rewrite.conf" ];then
    	/bin/cp config/$rewrite.conf $web_install_dir/conf/rewrite/$rewrite.conf
    else
    	touch "$web_install_dir/conf/rewrite/$rewrite.conf"
    fi
fi
}

Nginx_log() {
while :
do
    echo
    read -p "Allow Nginx access_log? [y/n]: " access_yn 
    if [[ ! $access_yn =~ ^[y,n]$ ]];then
        echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
    else
        break 
    fi
done
if [ "$access_yn" == 'n' ]; then
    N_log="access_log off;"
else
    N_log="access_log $wwwlogs_dir/${domain}_nginx.log combined;"
    echo "You access log file=${CMSG}$wwwlogs_dir/${domain}_nginx.log${CEND}"
fi
}

Create_nginx_conf() {
[ ! -d $web_install_dir/conf/vhost ] && mkdir $web_install_dir/conf/vhost
cat > $web_install_dir/conf/vhost/$domain.conf << EOF
server {
$Nginx_conf
server_name $domain$moredomainame;
$N_log
index index.html index.htm index.jsp;
root $vhostdir;
$Nginx_redirect
$anti_hotlinking
location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|ico)$ {
    expires 7d;
    access_log off;
    }
location ~ .*\.(js|css)?$ {
    expires 3d;
    access_log off;
    }
$NGX_CONF
}
$Nginx_http_to_https
EOF

echo
$web_install_dir/sbin/nginx -t
if [ $? == 0 ];then
    echo "Reload Nginx......"
    $web_install_dir/sbin/nginx -s reload
else
    rm -rf $web_install_dir/conf/vhost/$domain.conf
    echo "Create virtualhost ... [${CFAILURE}FAILED${CEND}]"
    exit 1
fi

printf "
#######################################################################
#       OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+      #
#       For more information please visit http://oneinstack.com       #
#######################################################################
"
echo "`printf "%-30s" "Your domain:"`${CMSG}$domain${CEND}"
echo "`printf "%-30s" "Nginx Virtualhost conf:"`${CMSG}$web_install_dir/conf/vhost/$domain.conf${CEND}"
echo "`printf "%-30s" "Directory of:"`${CMSG}$vhostdir${CEND}"
[ "$nginx_ssl_yn" == 'y' ] && Print_ssl
}

Create_nginx_tomcat_conf() {
[ ! -d $web_install_dir/conf/vhost ] && mkdir $web_install_dir/conf/vhost
cat > $web_install_dir/conf/vhost/$domain.conf << EOF
server {
$Nginx_conf
server_name $domain$moredomainame;
$N_log
index index.html index.htm index.jsp;
root $vhostdir;
$Nginx_redirect
$anti_hotlinking
location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|ico)$ {
    expires 7d;
    access_log off;
    }
location ~ .*\.(js|css)?$ {
    expires 3d;
    access_log off;
    }
$NGX_CONF
}
$Nginx_http_to_https
EOF

cat > $tomcat_install_dir/conf/vhost/$domain.xml << EOF
<Host name="$domain" appBase="webapps" unpackWARs="true" autoDeploy="true"> $Tomcat_Domain_alias
  <Context path="" docBase="$vhostdir" debug="0" reloadable="false" crossContext="true"/>
  <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
         prefix="${domain}_access_log." suffix=".txt" pattern="%h %l %u %t &quot;%r&quot; %s %b" />
</Host>
EOF
[ -z "`grep -o "vhost-${domain} SYSTEM" $tomcat_install_dir/conf/server.xml`" ] && sed -i "/vhost-localhost SYSTEM/a<\!ENTITY vhost-${domain} SYSTEM \"file://$tomcat_install_dir/conf/vhost/$domain.xml\">" $tomcat_install_dir/conf/server.xml
[ -z "`grep -o "vhost-${domain};" $tomcat_install_dir/conf/server.xml`" ] && sed -i "s@vhost-localhost;@&\n      \&vhost-${domain};@" $tomcat_install_dir/conf/server.xml

echo
$web_install_dir/sbin/nginx -t
if [ $? == 0 ];then
    echo "Reload Nginx......"
    $web_install_dir/sbin/nginx -s reload
    /etc/init.d/tomcat restart
else
    rm -rf $web_install_dir/conf/vhost/$domain.conf
    echo "Create virtualhost ... [${CFAILURE}FAILED${CEND}]"
    exit 1
fi

printf "
#######################################################################
#       OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+      #
#       For more information please visit http://oneinstack.com       #
#######################################################################
"
echo "`printf "%-30s" "Your domain:"`${CMSG}$domain${CEND}"
echo "`printf "%-30s" "Nginx Virtualhost conf:"`${CMSG}$web_install_dir/conf/vhost/$domain.conf${CEND}"
echo "`printf "%-30s" "Tomcat Virtualhost conf:"`${CMSG}$tomcat_install_dir/conf/vhost/$domain.xml${CEND}"
echo "`printf "%-30s" "Directory of:"`${CMSG}$vhostdir${CEND}"
[ "$nginx_ssl_yn" == 'y' ] && Print_ssl
}

Create_tomcat_conf() {
cat > $tomcat_install_dir/conf/vhost/$domain.xml << EOF
<Host name="$domain" appBase="webapps" unpackWARs="true" autoDeploy="true"> $Tomcat_Domain_alias
  <Context path="" docBase="$vhostdir" debug="0" reloadable="false" crossContext="true"/>
  <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
         prefix="${domain}_access_log." suffix=".txt" pattern="%h %l %u %t &quot;%r&quot; %s %b" />
</Host>
EOF
[ -z "`grep -o "vhost-${domain} SYSTEM" $tomcat_install_dir/conf/server.xml`" ] && sed -i "/vhost-localhost SYSTEM/a<\!ENTITY vhost-${domain} SYSTEM \"file://$tomcat_install_dir/conf/vhost/$domain.xml\">" $tomcat_install_dir/conf/server.xml
[ -z "`grep -o "vhost-${domain};" $tomcat_install_dir/conf/server.xml`" ] && sed -i "s@vhost-localhost;@&\n      \&vhost-${domain};@" $tomcat_install_dir/conf/server.xml

echo
/etc/init.d/tomcat restart

printf "
#######################################################################
#       OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+      #
#       For more information please visit http://oneinstack.com       #
#######################################################################
"
echo "`printf "%-30s" "Your domain:"`${CMSG}$domain${CEND}"
echo "`printf "%-30s" "Tomcat Virtualhost conf:"`${CMSG}$tomcat_install_dir/conf/vhost/$domain.xml${CEND}"
echo "`printf "%-30s" "Directory of:"`${CMSG}$vhostdir${CEND}"
echo "`printf "%-30s" "index url:"`${CMSG}http://${domain}:8080/${CEND}"
}

Create_nginx_php-fpm_hhvm_conf() {
[ ! -d $web_install_dir/conf/vhost ] && mkdir $web_install_dir/conf/vhost
cat > $web_install_dir/conf/vhost/$domain.conf << EOF
server {
$Nginx_conf
server_name $domain$moredomainame;
$N_log
index index.html index.htm index.php;
include $web_install_dir/conf/rewrite/$rewrite.conf;
root $vhostdir;
$Nginx_redirect
$anti_hotlinking
$NGX_CONF
location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|ico)$ {
    expires 7d;
    access_log off;
    }
location ~ .*\.(js|css)?$ {
    expires 3d;
    access_log off;
    }
}
$Nginx_http_to_https
EOF

echo
$web_install_dir/sbin/nginx -t
if [ $? == 0 ];then
    echo "Reload Nginx......"
    $web_install_dir/sbin/nginx -s reload
else
    rm -rf $web_install_dir/conf/vhost/$domain.conf
    echo "Create virtualhost ... [${CFAILURE}FAILED${CEND}]"
    exit 1
fi

printf "
#######################################################################
#       OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+      #
#       For more information please visit http://oneinstack.com       #
#######################################################################
"
echo "`printf "%-30s" "Your domain:"`${CMSG}$domain${CEND}"
echo "`printf "%-30s" "Virtualhost conf:"`${CMSG}$web_install_dir/conf/vhost/$domain.conf${CEND}"
echo "`printf "%-30s" "Directory of:"`${CMSG}$vhostdir${CEND}"
[ "$rewrite_yn" == 'y' ] && echo "`printf "%-30s" "Rewrite rule:"`${CMSG}$web_install_dir/conf/rewrite/$rewrite.conf${CEND}" 
[ "$nginx_ssl_yn" == 'y' ] && Print_ssl
}

Add_Vhost() {
    if [ -e "$web_install_dir/sbin/nginx" -a ! -e "`ls $apache_install_dir/modules/libphp?.so 2>/dev/null`" ];then
        Choose_env
        Input_Add_domain
        Nginx_anti_hotlinking
        if [ "$NGX_FLAG" == 'java' ];then
            Nginx_log
            if [ -e "$tomcat_install_dir/conf/server.xml" ];then
                Create_nginx_tomcat_conf
            else
                Create_nginx_conf
            fi 
        elif [ "$NGX_FLAG" == 'php' ];then
            Nginx_rewrite
            Nginx_log
            Create_nginx_php-fpm_hhvm_conf
        fi
    fi
}

Del_NGX_Vhost() {
    if [ -e "$web_install_dir/sbin/nginx" ];then
        [ -d "$web_install_dir/conf/vhost" ] && Domain_List=`ls $web_install_dir/conf/vhost | sed "s@.conf@@g"`
        if [ -n "$Domain_List" ];then
            echo
            echo "Virtualhost list:"
	    echo ${CMSG}$Domain_List${CEND}
            while :
            do
                echo
                read -p "Please input a domain you want to delete: " domain
                if [ -z "`echo $domain | grep '.*\..*'`" ]; then
                    echo "${CWARNING}input error! ${CEND}"
                else
                    if [ -e "$web_install_dir/conf/vhost/${domain}.conf" ];then
                        Directory=`grep ^root $web_install_dir/conf/vhost/${domain}.conf | awk -F'[ ;]' '{print $2}'`
                        rm -rf $web_install_dir/conf/vhost/${domain}.conf
                        $web_install_dir/sbin/nginx -s reload
                        while :
                        do
                            echo
                            read -p "Do you want to delete Virtul Host directory? [y/n]: " Del_Vhost_wwwroot_yn 
                            if [[ ! $Del_Vhost_wwwroot_yn =~ ^[y,n]$ ]];then
                                echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
                            else
                                break
                            fi
                        done
                        if [ "$Del_Vhost_wwwroot_yn" == 'y' ];then
                            echo "Press Ctrl+c to cancel or Press any key to continue..."
                            char=`get_char`
                            rm -rf $Directory
                        fi
                        echo "${CSUCCESS}Domain: ${domain} has been deleted.${CEND}"
                    else
                        echo "${CWARNING}Virtualhost: $domain was not exist! ${CEND}"
                    fi
                    break
                fi
            done

        else
            echo "${CWARNING}Virtualhost was not exist! ${CEND}"
        fi
    fi
}

Del_Tomcat_Vhost() {
    if [ -e "$tomcat_install_dir/conf/server.xml" ];then
        if [ -e "$web_install_dir/sbin/nginx" ];then
            if [ -n "`grep vhost-${domain} $tomcat_install_dir/conf/server.xml`" ];then
                sed -i /vhost-${domain}/d $tomcat_install_dir/conf/server.xml 
                rm -rf $tomcat_install_dir/conf/vhost/${domain}.xml
                /etc/init.d/tomcat restart
            fi
        else
            Domain_List=`ls $tomcat_install_dir/conf/vhost | grep -v 'localhost.xml' | sed "s@.xml@@g"`
            if [ -n "$Domain_List" ];then
                echo
                echo "Virtualhost list:"
                echo ${CMSG}$Domain_List${CEND}
                while :
                do
                    echo
                    read -p "Please input a domain you want to delete: " domain
                    if [ -z "`echo $domain | grep '.*\..*'`" ]; then
                        echo "${CWARNING}input error! ${CEND}"
                    else
                        if [ -n "`grep vhost-${domain} $tomcat_install_dir/conf/server.xml`" ];then
                            sed -i /vhost-${domain}/d $tomcat_install_dir/conf/server.xml
                            rm -rf $tomcat_install_dir/conf/vhost/${domain}.xml
                            /etc/init.d/tomcat restart
                            while :
                            do
                                echo
                                read -p "Do you want to delete Virtul Host directory? [y/n]: " Del_Vhost_wwwroot_yn
                                if [[ ! $Del_Vhost_wwwroot_yn =~ ^[y,n]$ ]];then
                                    echo "${CWARNING}input error! Please only input 'y' or 'n'${CEND}"
                                else
                                    break
                                fi
                            done
    
                            if [ "$Del_Vhost_wwwroot_yn" == 'y' ];then
                                echo "Press Ctrl+c to cancel or Press any key to continue..."
                                char=`get_char`
                                rm -rf $Directory
                            fi
                            echo "${CSUCCESS}Domain: ${domain} has been deleted.${CEND}"
                        else
                            echo "${CWARNING}Virtualhost: $domain was not exist! ${CEND}"
                        fi
                        break
                    fi
                done
    
            else
                echo "${CWARNING}Virtualhost was not exist! ${CEND}"
            fi
        fi
    fi
}

if [ $# == 0 ];then
    Add_Vhost 
elif [ $# == 1 ];then
    case $1 in
    add)
        Add_Vhost
        ;;

    del)
        Del_NGX_Vhost
        Del_Tomcat_Vhost
        ;;

    *)
        Usage
        ;;
    esac
else
    Usage
fi
