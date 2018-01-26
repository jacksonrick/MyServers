# MyServers

服务器组件集成化安装

在`oneinstack`基础上改进 https://oneinstack.com/

集成以下组件:

jdk | tomcat | nginx | mysql | php | redis | subversion | fdfs

支持Linux CentOS 7 +

#### 安装步骤

* ./install.sh 安装，选择相应组件

* ./uninstall.sh 卸载组件

* ./vhost.sh 添加虚拟主机

> apps.conf 组件版本配置

> options.conf 组件安装目录配置

#### 管理服务

* service nginx {start|stop|status|restart|reload}

* service mysqld {start|stop|restart|reload|status}

* service php-fpm {start|stop|restart|reload|status}

* service tomcat {start|stop|status|restart}

* service redis-server {start|stop|status|restart|reload}

* service fastdfs {start|stop|status}

* service svn {start|stop|status}

#### 注意
`src`目录为项目所用到的安装包，由于包过大，请在百度网盘下载

链接: https://pan.baidu.com/s/1eSTnXho 密码: 5kty