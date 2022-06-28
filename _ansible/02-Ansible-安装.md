---
title: "Ansible 安装"
permalink: /ansible/install/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---

Ansible 的安装方法有多种

## EPEL 源的 rpm 包安装

```shell
$ yum install epel-release -y
$ yum install ansible -y
```

## 编译安装

```shell
$ yum -y install python-jinja2 PyYAML python-paramiko python-babel python-crypto
$ tar xf ansible-1.5.4.tar.gz
$ cd ansible-1.5.4
$ python setup.py build
$ python setup.py install
$ mkdir /etc/ansible
$ cp -r examples/* /etc/ansible
```

## Git方式

```shell
$ git clone git://github.com/ansible/ansible.git --recursive
$ cd ./ansible
$ source ./hacking/env-setup
```

## pip 安装

pip 是安装 Python 包的管理器，类似 yum

```shell
$ yum install python-pip python-devel
$ yum install gcc glibc-devel zibl-devel  rpm-bulid openssl-devel
$ pip install  --upgrade pip
$ pip install ansible --upgrade
```

## 确认安装

```shell
$ ansible --version
ansible 2.9.5
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.6/site-packages/ansible
  executable location = /usr/bin/ansible
  python version = 3.6.8 (default, Nov 21 2019, 19:31:34) [GCC 8.3.1 20190507 (Red Hat 8.3.1-4)]
```

