#!/bin/bash
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
# Project home page: http://oneinstack.com

[ -e "$nginx_install_dir/sbin/nginx" ] && web_install_dir=$nginx_install_dir
[ -e "$tengine_install_dir/sbin/nginx" ] && web_install_dir=$tengine_install_dir
[ -e "$openresty_install_dir/nginx/sbin/nginx" ] && web_install_dir=$openresty_install_dir/nginx
