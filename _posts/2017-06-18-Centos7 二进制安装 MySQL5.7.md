---
title: "Centos7 二进制安装 MySQL5.7"
toc: true
toc_label: "Centos7 二进制安装 MySQL5.7"
toc_icon: "cog"
categories: mysql
permalink: /mysql/centos7-binary-mysql57-install
tags:
  - mysql
  - centos
  - linux
---

## 1、卸载系统自带的 mariadb 数据库及删除 mysql 用户

查询是否有安装的 mariadb 文件

```shell
$ rpm -qa | grep mariadb
mariadb-5.5.56-2.el7.x86_64
mariadb-server-5.5.56-2.el7.x86_64
mariadb-libs-5.5.56-2.el7.x86_64
```

使用 -nodeps 不考虑依赖，强制卸载

```shell
$ rpm -e --nodeps mariadb-5.5.56-2.el7.x86_64
$ rpm -e --nodeps mariadb-server-5.5.56-2.el7.x86_64
$ rpm -e --nodeps mariadb-libs-5.5.56-2.el7.x86_64
```

查询及删除 mysql 用户

```shell
$ id mysql
$ userdel mysql
```

## 2、从官网下载mysql数据库安装包，并解压缩和重命名

mysql-5.7.37-linux-glibc2.12-x86_64.tar.gz

下载压缩的 [tar 包二进制分发版](https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.37-linux-glibc2.12-x86_64.tar.gz)【我已经下载到 /usr/local 目录】

```shell
$ ls /usr/local/mysql-5.7.37-linux-glibc2.12-x86_64.tar.gz
/usr/local/mysql-5.7.37-linux-glibc2.12-x86_64.tar.gz
```

解压缩文件并修改文件名为 mysql

```shell
$ tar zxvf /usr/local/mysql-5.7.37-linux-glibc2.12-x86_64.tar.gz
$ mv /usr/local/mysql-5.7.37-linux-glibc2.12-x86_64 /usr/local/mysql
```

创建 data、logs 数据文件目录

```shell
$ mkdir -p /usr/local/mysql/{data,logs/{binlog,errlog,slowlog,redolog}}
```

查看文件目录结构

```shell
$ tree /usr/local/mysql -L 1
/usr/local/mysql
├── bin
├── data
├── docs
├── include
├── lib
├── LICENSE
├── logs
├── man
├── README
├── share
└── support-files

9 directories, 2 files
$ tree /usr/local/mysql/logs
/usr/local/mysql/logs
├── binlog
├── errlog
├── redolog
└── slowlog

4 directories, 0 files
```

> 下表为通用 Unix / Linux 二进制包的 MySQL 安装布局
>
> | 目录          | 目录的内容                                                   |
> | ------------- | ------------------------------------------------------------ |
> | bin           | [**mysqld**](https://dev.mysql.com/doc/refman/5.7/en/mysqld.html) 服务器，客户端和实用程序 |
> | docs          | 信息格式的MySQL手册                                          |
> | man           | Unix手册页                                                   |
> | include       | 包含（标题）文件                                             |
> | lib           | 图书馆                                                       |
> | share         | 用于数据库安装的错误消息，字典和SQL                          |
> | support-files | 其他支持文件                                                 |

## 3、安装 ***libaio*** 依赖

MySQL 依赖于 libaio 库，如果未在本地安装此库，则数据目录初始化和后续服务器启动步骤将失败

```shell
# search for info
$ yum search libaio
# install library
$ yum install libaio
```

## 4、创建 mysql 用户和组

创建一个 mysql 用户和组，更改 mysql 目录所属组和用户，配置环境变量

```shell
# 添加 mysql 组
$ groupadd mysql
# 添加 mysql 用户
# 由于仅出于所有权目的而不是登录目的而要求用户，因此 useradd 命令使用 -r 和 -s /bin/false 选项来创建对服务器主机没有登录权限的用户。-r 参数表示 mysql 用户是系统用户，不可用于登录系统。-g 参数表示把 mysql 用户添加到 mysql 用户组中。
$ useradd -r -g mysql -s /bin/false mysql
$ tail -1 /etc/passwd
mysql:x:997:1000::/home/mysql:/bin/false
```

更改 mysql 目录所属组和用户

```shell
$ chown -R mysql:mysql /usr/local/mysql
```

配置环境变量

```shell
$ echo "export PATH=\$PATH:/usr/local/mysql/bin" >>/etc/profile
$ source /etc/profile
$ echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/local/mysql/bin:/root/bin
```

## 5、创建配置文件

***/usr/local/mysql/my.cnf***

```shell
[client]
port=3306
socket=/usr/local/mysql/mysql.sock

[mysql]
no_auto_rehash

[mysqld]
### Basic Parameters
user=mysql
port=3306
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
socket=/usr/local/mysql/mysql.sock
pid_file=/usr/local/mysql/mysql.pid
character_set_server=utf8
skip_character_set_client_handshake=1

### replication settings
server_id=3306
master_info_repository=TABLE
relay_log_info_repository=TABLE
binlog-ignore-db=mysql
log_bin=/usr/local/mysql/logs/binlog/mysql_bin
auto_increment_offset=1
auto_increment_increment=2
binlog_cache_size=2M
binlog_format=row
expire_logs_days=7
slave_skip_errors=ddl_exist_errors
relay_log=relay3306.log
relay_log_recovery=1
sync_binlog=1
gtid_mode=on
enforce_gtid_consistency=1
log_slave_updates
binlog_gtid_simple_recovery=true

### Binlog Parameters
log_output=FILE
log_timestamps=system
expire_logs_days=15
max_binlog_size=500M
max_binlog_cache_size=256M
master_info_repository=table
binlog_rows_query_log_events=on
log_bin_trust_function_creators=1

### Slowlog Parameters
log_slow_admin_statements=1
slow_query_log=on
long_query_time=2
log_queries_not_using_indexes=on
slow_query_log_file=/usr/local/mysql/logs/slowlog/mysql_slow.log

### Errlog Parameters
log-error=/usr/local/mysql/logs/errlog/mysql_error.log

### Other Parameters
autocommit=on
skip_external_locking=on
skip_name_resolve=on
max_connections=800
max_connect_errors=1000
max_allowed_packet=200M
wait_timeout=31536000
interactive_timeout=31536000
open_files_limit=65535
group_concat_max_len=4294967295
symbolic_links=0
transaction_write_set_extraction=off
transaction_isolation=READ-COMMITTED
explicit_defaults_for_timestamp=1
sql_mode="STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER"

### Innodb Parameters
default_storage_engine=InnoDB
innodb_flush_log_at_trx_commit=1
innodb_buffer_pool_size=2G
innodb_buffer_pool_instances=8
innodb_buffer_pool_dump_at_shutdown=1
innodb_buffer_pool_dump_pct=40
innodb_buffer_pool_load_at_startup=1
innodb_file_per_table=1
innodb_change_buffering=all
innodb_doublewrite=on
innodb_autoextend_increment=64
innodb_temp_data_file_path=ibtmp1:200M:autoextend:max:20G
innodb_data_file_path=ibdata1:200M;ibdata2:200M;ibdata3:200M:autoextend:max:20G
innodb_flush_method=O_DIRECT
innodb_log_buffer_size=16M
innodb_log_file_size=4G
innodb_log_files_in_group=2
innodb_log_group_home_dir=/usr/local/mysql/logs/redolog
innodb_undo_logs=128
innodb_undo_tablespaces=3
innodb_undo_log_truncate=1
innodb_max_undo_log_size=20G
innodb_purge_rseg_truncate_frequency=128
innodb_print_all_deadlocks=on
innodb_lock_wait_timeout=120
innodb_deadlock_detect=on
innodb_status_output_locks=on
innodb_strict_mode=1
innodb_sort_buffer_size=64M
innodb_open_files=65535
innodb_concurrency_tickets=5000
innodb_page_cleaners=4
innodb_old_blocks_time=1000
innodb_stats_on_metadata=0
innodb_checksum_algorithm=0
show_compatibility_56=on
innodb_lru_scan_depth=2000
innodb_flush_neighbors=1
innodb_purge_threads=4
innodb_large_prefix=1

### 开启审计功能
general_log=on                              // on为开启；off为关闭
general_log_file=/var/log/generalLog.log    // 审计信息存储位置
log_timestamps=SYSTEM                       // 设置日志文件的输出时间为地方时
```

## 6、初始化配置安装

创建错误日志

```shell
$ grep "errlog" /usr/local/mysql/my.cnf
log-error=/usr/local/mysql/logs/errlog/mysql_error.log
$ touch /usr/local/mysql/logs/errlog/mysql_error.log
$ chown -R mysql:mysql /usr/local/mysql
```

初始化 mysql

```shell
$ mysqld --defaults-file=/usr/local/mysql/my.cnf --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data/ --initialize
$ echo $?
0
```

## 7、启动 mysql 并修改默认密码

启动 mysql

```shell
$ mysqld_safe --defaults-file=/usr/local/mysql/my.cnf --user=mysql >/dev/null 2>&1 &
[1] 2190
$ ss -tunlp | grep 3306
tcp    LISTEN     0      210    [::]:3306               [::]:*                   users:(("mysqld",pid=3463,fd=25))
```

> 关闭 mysql：
>
> ```shell
> $ /usr/local/mysql/bin/mysqladmin -uUSER -pPASSWORD -S /usr/local/mysql/mysql.sock shutdown
> ```

查看 mysql 临时密码

```shell
$ grep "password" /usr/local/mysql/logs/errlog/mysql_error.log
2022-02-14T15:04:30.095985+08:00 1 [Note] A temporary password is generated for root@localhost: &EB.X)_)o654
```

> 临时密码为：`&EB.X)_)o654`

登陆数据库并修改 root 密码

```shell
$ mysql -uroot -p -S /usr/local/mysql/mysql.sock
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.37-log

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

# 设置 root 密码
# mysql> alter user 'root'@'localhost' identified by 'Aisino123+';
# mysql> set password for 'root'@'localhost'=password('Aisino123+');
mysql> set password=password('Aisino123+');
Query OK, 0 rows affected (0.02 sec)

# 设置 root 账户的 host 地址
mysql> grant all privileges on *.* to 'root'@'%' identified by 'Aisino123+';


mysql> select user,host,authentication_string,password_expired from mysql.user where user='root' and host='localhost';
+------+-----------+-------------------------------------------+------------------+
| user | host      | authentication_string                     | password_expired |
+------+-----------+-------------------------------------------+------------------+
| root | localhost | *0664E55FB55D248C86254212AD174EA72EB44F8E | N                |
+------+-----------+-------------------------------------------+------------------+
1 row in set (0.00 sec)

# 刷新系统权限表，使更改立即生效
mysql> flush privileges; 
Query OK, 0 rows affected (0.02 sec)

mysql> \q
Bye

$ mysql -uroot -p -S /usr/local/mysql/mysql.sock -e "show databases;"
Enter password: 
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```

> 创建查询账号：
>
> ```mysql
> mysql> GRANT select ON *.* TO 'query'@'%' IDENTIFIED BY 'Aisino_2020' WITH GRANT OPTION;
> Query OK, 0 rows affected, 1 warning (0.02 sec)
> 
> mysql> flush privileges;
> Query OK, 0 rows affected (0.03 sec)
> ```

## 8、编写启动脚本

本文启动脚本命名为 `mysqld` ,放在 /usr/local/mysql 目录下，执行 `/usr/local/mysql/mysqld start|stop|restart|status` 即可对数据库进行启动\|停止\|重启\|查看运行状态等操作。脚本中 Pass 变量改为自己的数据库密码，将该脚本文件的权限设置为700，因为脚本中有密码。

***/usr/local/mysql/mysqld***

```shell
#!/bin/bash
RETVAL=0
Port=3306
User=root
Pass=Aisino123+
Pid=/usr/local/mysql/mysql.pid
Sock=/usr/local/mysql/mysql.sock
My=/usr/local/mysql/my.cnf
Path=/usr/local/mysql/bin

# Determine the user to execute
if [ $UID -ne $RETVAL ];then
    echo "Must be root to run scripts"
    exit 1
fi

# Load the local functions
[ -f /etc/init.d/functions ] && source /etc/init.d/functions

# Define functions
start(){
        if [ ! -f "$Pid" ];then
          $Path/mysqld_safe --defaults-file=$My --user=mysql >/dev/null 2>&1 &
          RETVAL=$?
          if [ $RETVAL -eq 0 ];then
            action "Start MySQL [3306]" /bin/true
           else
            action "Start MySQL [3306]" /bin/false
          fi
         else
          echo "MySQL 3306 is running"
          exit 1
        fi
        return $RETVAL
}

stop(){
        if [ -f "$Pid" ];then
          $Path/mysqladmin -u$User -p$Pass -S $Sock shutdown >/dev/null 2>&1
          RETVAL=$?
          if [ $RETVAL -eq 0 ];then
            action "Stop MySQL[3306]" /bin/true
           else
           action "Stop MySQL[3306]" /bin/false
          fi
         else
          echo "MySQL [3306] is not running"
          exit 1
        fi
        return $RETVAL
}

status(){
        if [ -f "$Pid" ];then
          echo "MySQL [3306] is running"
         else
          echo "MySQL [3306] is not running"
        fi
        return $RETVAL
}

# Case call functions
case "$1" in
  start)
        start
        RETVAL=$?
        ;;  
  stop)
        stop
        RETVAL=$?
        ;; 
  restart)
        stop
        sleep 5
        start
        RETVAL=$?
        ;; 
  status)
        status
        RETVAL=$?
        ;;
  *)
        echo "USAGE:$0{start|stop|restart|status}"
        exit 1
esac

# Scripts return values
exit $RETVAL
```

设置启动脚本权限

```shell
$ chmod 700 /usr/local/mysql/mysqld
```

## 9、设置防火墙策略，加入开机启动

设置防火墙

```shell
$ firewall-cmd --permanent --add-port=3306/tcp;
$ firewall-cmd --reload;
```

加入开机启动

```shell
# 如果没有编写启动脚本则直接在末尾加上 mysql 数据库启动命令
$ echo "/usr/local/mysql/mysqld start" >> /etc/rc.d/rc.local
```

## 多实例部署

mysql 多实例，简单的说，就是在一台服务器上开启多个不同的 mysql 服务端口（如3306，3307），运行多个mysql服务进程。这些服务进程通过不同的 socket 监听不同的服务端口，来提供各自的服务。这些 mysql 实例共用一套 mysql 安装程序，使用不同的 my.cnf 配置文件、启动程序、数据文件。在提供服务时，mysql 多实例在逻辑上看来是各自独立的，各个实例之间根据配置文件的设定值，来取得服务器的相关硬件资源。
