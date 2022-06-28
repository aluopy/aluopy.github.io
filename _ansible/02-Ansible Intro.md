---
title: "Ansible Intro"
permalink: /ansible/ansible-intro/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---

公司计划在年底做一次大型市场促销活动，全面冲刺下交易额，为明年的上市做准备。公司要求各业务组对年底大促做准备，运维部要求所有业务容量进行三倍的扩容，并搭建出多套环境可以共开发和测试人员做测试，运维老大为了在年底有所表现，要求运维部门同学尽快实现，当你接到这个任务时，有没有更快的解决方案？

## Ansible 发展史

Ansible 作者 Michael DeHaan（ Cobbler 与 Func 作者），Ansible 的名称来自科幻小说《安德的游戏》中跨越时空的即时通信工具，使用它可以在相距数光年的距离，远程实时控制前线的舰队战斗。2012年3月9日发布0.0.1版，2015年10月17日被 Red Hat 以1.5亿美元收购。
官方网站：[https://www.ansible.com](http://www.yunweipai.com/go?_=a49e019ca3aHR0cHM6Ly93d3cuYW5zaWJsZS5jb20v)
官方文档：[https://docs.ansible.com](http://www.yunweipai.com/go?_=beb2e5d97daHR0cHM6Ly9kb2NzLmFuc2libGUuY29tLw%3D%3D)

## Ansible 特性

- 模块化：调用特定的模块完成特定任务，支持自定义模块，可使用任何编程语言写模块
- Paramiko（python 对 ssh 的实现），PyYAML，Jinja2（模板语言）三个关键模块
- 基于 Python 语言实现
- 部署简单，基于 python 和 SSH (默认已安装)，agentless，无需代理不依赖 PKI（无需 ssl）
- 安全，基于 OpenSSH
- 幂等性：一个任务执行1遍和执行 n 遍效果一样，不因重复执行带来意外情况
- 支持 playbook 编排任务，YAML 格式，编排任务，支持丰富的数据结构
- 较强大的多层解决方案 role

## Ansible 架构

### Ansible 组成

![](https://aluopy.github.io/assets/images/ansible-06.png)
组合 INVENTORY、API、MODULES、PLUGINS 的绿框，可以理解为是 ansible 命令工具，其为核心执行工具。

- INVENTORY：Ansible 管理主机的清单 `/etc/anaible/hosts`
- MODULES：Ansible 执行命令的功能模块，多数为内置核心模块，也可自定义
- PLUGINS：模块功能的补充，如连接类型插件、循环插件、变量插件、过滤插件等，该功能不常用
- API：供第三方程序调用的应用程序编程接口

### Ansible 命令执行来源

- USER 普通用户，即 SYSTEM ADMINISTRATOR
- PLAYBOOKS：任务剧本（任务集），编排定义 Ansible 任务集的配置文件，由 Ansible 顺序依次执行，通常是 JSON 格式的 YML 文件
- CMDB（配置管理数据库） API 调用
- PUBLIC/PRIVATE CLOUD API 调用
- USER -> Ansible Playbook -> Ansibile

### 注意事项

- 执行 ansible 的主机一般称为主控端，中控，master 或堡垒机
- 主控端 Python 版本需要2.6或以上
- 被控端 Python 版本小于2.4，需要安装 python-simplejson
- 被控端如开启 SELinux 需要安装 libselinux-python
- windows 不能做为主控端

