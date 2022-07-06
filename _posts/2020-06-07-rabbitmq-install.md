---
title: "rabbitmq install"
toc: true
toc_label: "rabbitmq install"
#toc_icon: "cog"
categories: rabbitMQ
tags:
  - rabbitmq
---

**Tip:**  本次部署规划将 rabbitmq 部署到 `/usr/local` 目录下。
​         本次部署版本：RabbitMQ 3.6.10, Erlang 20.0。
{: .notice--info}

## 安装 erlang

```shell
$ cd /usr/local
$ wget http://erlang.org/download/otp_src_20.0.tar.gz
$ tar -xvf otp_src_20.0.tar.gz
$ mv otp_src_20.0 erlang
$ yum -y install make gcc gcc-c++ kernel-devel m4 ncurses-devel openssl-devel unixODBC-devel                                                               # 安装 gcc kernel-devle 等所需环境
$ cd erlang
$ ./configure --prefix=/usr/local/erlang      # 配置
$ make && make install                        # 编译 && 安装
# 测试
$ cd /usr/local/erlang/bin
$ ./erl
```

## 安装 rabbitmq

下载 binary：http://www.rabbitmq.com/download.html

软件包：rabbitmq-server-generic-unix-3.6.10.tar

```shell
$ tar xvf rabbitmq-server-generic-unix-3.6.10.tar   # 解压
$ mv rabbitmq_server-3.6.10 rabbitmq                # 文件夹更名
# 配置环境变量
$ echo "export PATH=\$PATH:/usr/local/erlang/bin:/usr/local/rabbitmq/sbin" >>/etc/profile
$ source /etc/profile
```

## rabbitmq 启动及配置

```shell
# 启动 rabbitmq
#$ ./rabbitmq-server start &
$ rabbitmq-server -detached

# 停止 rabbitmq
#$ ./rabbitmqctl stop

# 启动 web 监控
$ rabbitmq-plugins enable rabbitmq_management

# 设置 guest 可以远程连接
# 说明：这里的意思是开放使用，rabbitmq 默认创建的用户 guest，密码也是 guest，这个用户默认只能是本机访问，localhost 或者127.0.0.1，从外部访问需要添加上面的配置。
$ echo "[{rabbit, [{loopback_users, []}]}]." >> /usr/local/rabbitmq/etc/rabbitmq/rabbitmq.config

# 查看状态
$ ./rabbitmqctl status

# 创建用户名和密码
$ rabbitmqctl add_user  admin  Aisino123+

# 赋予权限最高权限
$ rabbitmqctl set_user_tags admin administrator  
$ rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

#防火墙添加端口
$ firewall-cmd --permanent --add-port=15672/tcp;
$ firewall-cmd --reload;

# 重启 rabbitmq，查看 web 管理界面：
http://localhost:15672/#/
```

