#!/bin/bash
# Notes: OneinStack for CentOS/RadHat 5+ Debian 6+ and Ubuntu 12+
# Project home page: http://oneinstack.com

[ -d "$mysql_install_dir/support-files" ] && { db_install_dir=$mysql_install_dir; db_data_dir=$mysql_data_dir; }
[ -d "$mariadb_install_dir/support-files" ] && { db_install_dir=$mariadb_install_dir; db_data_dir=$mariadb_data_dir; }
[ -d "$percona_install_dir/support-files" ] && { db_install_dir=$percona_install_dir; db_data_dir=$percona_data_dir; }
