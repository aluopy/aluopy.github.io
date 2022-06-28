---
title: "Ansible Roles"
permalink: /ansible/roles/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

角色是 ansible 自1.2版本引入的新特性，用于层次性、结构化地组织 playbook。roles 能够根据层次型结构自动装载变量文件、tasks 以及 handlers 等。要使用 roles 只需要在 playbook 中使用 include 指令即可。简单来讲，roles 就是通过分别将变量、文件、任务、模板及处理器放置于单独的目录中，并可以便捷地 include 它们的一种机制。角色一般用于基于主机构建服务的场景中，但也可以是用于构建守护进程等场景中。

运维复杂的场景：建议使用 roles，代码复用度高

**roles**：多个角色的集合， 可以将多个的 role，分别放至 roles 目录下的独立子目录中

```shell
$ tree roles/
roles/
├── httpd
├── mysql
├── nginx
└── redis
```

