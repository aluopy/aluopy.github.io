---
title: "PostgreSQL 设置通过密码验证远程连接数据库"
toc: true
categories: PostgreSQL 
tags:
  - pgsql
---

```shell
$ vi /var/lib/pgsql/data/pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# 添加允许通过密码验证远程连接数据库的网段，这里配置所有，md5 表示需要密码验证
host    all             all             0.0.0.0/0               md5
# IPv6 local connections:
host    all             all             ::1/128                 ident


$ vi /var/lib/pgsql/data/postgresql.conf
# - Connection Settings -
#listen_addresses = 'localhost'
# 将 localhost 改为 *
listen_addresses = '*'

# 重启数据库
$ systemctl restart postgresql

# 设置密码
$ psql -U postgres
psql (9.2.24)
输入 "help" 来获取帮助信息.

postgres=# alter role postgres with password 'Aluopy@posgresql#';

# 重启数据库
$ systemctl restart postgresql

# 防火墙添加 5432 端口
```

