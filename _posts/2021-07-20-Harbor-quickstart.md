---
title: "Harbor Quickstart"
permalink: /harbor/quickstart/
toc: true
categories: harbor
tags:
  - harbor
  - docker
  - registry
---

## Harbor 简介

Harbor 是一个用于存储和分发 Docker 镜像的企业级私有 Registry 服务器。Habor 是由 VMWare 中国团队开源的企业级容器镜像仓库。特性包括：友好的用户界面，基于角色的访问控制，水平扩展，同步复制，AD/LDAP 集成以及审计日志等。

- [goharbor/harbor: An open source trusted cloud native registry project that stores, signs, and scans content. (github.com)](https://github.com/goharbor/harbor/)

- [Harbor docs \| Harbor 2.3 Documentation (goharbor.io)](https://goharbor.io/docs/2.3.0/)

本文档仅说明单机安装 harbor 服务，使用单机编排工具 docker-compose。

## Harbor 安装

### 环境准备

* [docker](https://www.runoob.com/docker/centos-docker-install.html)

* [docker-compose](https://www.runoob.com/docker/docker-compose.html)

### 创建目录及下载文件

```bash
[root@harbori ~]# mkdir /data
[root@harbori ~]# wget https://github.com/goharbor/harbor/releases/download/v2.2.3/harbor-offline-installer-v2.2.3.tgz -P /data
[root@harbori ~]# tar zxvf harbor-offline-installer-v2.2.3.tgz -C /data
# 创建用于存放SSL证书的目录
[root@harbori ~]# mkdir /data/harbor/ssl
[root@harbori ~]# tree /data/harbor
/data/harbor
├── common.sh
├── harbor.v2.2.3.tar.gz
├── harbor.yml.tmpl
├── install.sh
├── LICENSE
├── prepare
└── ssl
```

### 修改配置文件

```bash
[root@harbori ~]# cp /data/harbor/harbor.yml.tmpl /data/harbor/harbor.yml
[root@harbori ~]# sed -i '5s#reg.mydomain.com#luojianjun.cn#;17s#/your/certificate/path#/data/harbor/ssl/1_luojianjun.cn_bundle.crt#;18s#/your/private/key/path#/data/harbor/ssl/2_luojianjun.cn.key#;34s#Harbor12345#aluo.images#' /data/harbor/harbor.yml
```

> **修改项**：
>
> - ***hostname***：`reg.mydomain.com` ---> `luojianjun.cn`
> - ***certificate***：`/your/certificate/path` ---> `/data/harbor/ssl/1_luojianjun.cn_bundle.crt`
> - ***private_key***：`/your/private/key/path` ---> `/data/harbor/ssl/2_luojianjun.cn.key`
> - ***harbor_admin_password***：`Harbor12345` ---> `aluo.images`
>
> 因为我的域名有SSL证书，所以直接拷贝到 `/data/harbor/ssl` 目录了，如果你的域名没有SSL证书可以按照如下方式创建，**创建 harbor 访问域名证书：**
>
> ```bash
> # 修改 aluo.io 为你的域名
> $ cd /data/harbor/ssl
> $ openssl genrsa -out tls.key 2048
> $ openssl req -new -x509 -key tls.key -out tls.cert -days 360 -subj /CN=*.aluo.io
> ```

### 安装 harbor

```bash
[root@harbori harbor]# cd /data/harbor/
[root@harbori harbor]# ./prepare
[root@harbori harbor]# ./install.sh
# 启动
[root@harbori harbor]# docker-compose up -d
Creating network "harbor_harbor" with the default driver
Creating harbor-log ... done
Creating harbor-portal ... done
Creating registry      ... done
Creating harbor-db     ... done
Creating redis         ... done
Creating registryctl   ... done
Creating harbor-core   ... done
Creating harbor-jobservice ... done
Creating nginx             ... done
[root@harbori harbor]# docker-compose ps
      Name                     Command                  State                                          Ports                                    
------------------------------------------------------------------------------------------------------------------------------------------------
harbor-core         /harbor/entrypoint.sh            Up (healthy)                                                                               
harbor-db           /docker-entrypoint.sh            Up (healthy)                                                                               
harbor-jobservice   /harbor/entrypoint.sh            Up (healthy)                                                                               
harbor-log          /bin/sh -c /usr/local/bin/ ...   Up (healthy)   127.0.0.1:1514->10514/tcp                                                   
harbor-portal       nginx -g daemon off;             Up (healthy)                                                                               
nginx               nginx -g daemon off;             Up (healthy)   0.0.0.0:80->8080/tcp,:::80->8080/tcp, 0.0.0.0:443->8443/tcp,:::443->8443/tcp
redis               redis-server /etc/redis.conf     Up (healthy)                                                                               
registry            /home/harbor/entrypoint.sh       Up (healthy)                                                                               
registryctl         /home/harbor/start.sh            Up (healthy)
```

## Harbor 访问

地址：http://luojianjun.cn

账户/密码：admin/aluo.images

## Harbor 使用

### 登录 Harbor Docker Registry

```shell
# docker login --username=admin luojianjun.cn
$ docker login -u admin luojianjun.cn
```

### 从 Registry 中拉取镜像

```bash
$ docker pull luojianjun.cn/library/nginx:[镜像版本号]
```

### 将镜像推送到 Registry

```bash
# 请根据实际镜像信息替换示例中的[ImageId]和[镜像版本号]参数。
$ docker tag [ImageId] luojianjun.cn/library/nginx:[镜像版本号]
$ docker push luojianjun.cn/library/nginx:[镜像版本号]
```

### 示例

使用 "docker tag" 命令重命名镜像，并将它推送至 Registry。

```bash
$ docker images
REPOSITORY                                                       TAG              IMAGE ID       CREATED        SIZE
registry.cn-hangzhou.aliyuncs.com/acs/log-pilot                  0.9.7-filebeat   10a688e1229a   2 years ago    119MB

$ docker tag 10a688e1229a luojianjun.cn/library/log-pilot:0.9.7-filebeat
```

使用 "docker push" 命令将该镜像推送至远程。

```bash
$ docker push luojianjun.cn/library/log-pilot:0.9.7-filebeat
```

## 用户权限

| 角色       | 权限说明                                          |
| ---------- | ------------------------------------------------- |
| 访客       | 对于指定项目拥有只读权限                          |
| 开发人员   | 对于指定项目拥有读写权限                          |
| 维护人员   | 对于指定项目用户读写权限，创建 Webhooks           |
| 项目管理员 | 除了读写权限，同事拥有用户管理/镜像扫描等管理权限 |

