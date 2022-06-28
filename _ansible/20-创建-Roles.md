---
title: "创建 Roles"
permalink: /ansible/create-role/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

**创建 role 的步骤**

1. 创建以 roles 命名的目录；
2. 在 roles 目录中分别创建以各角色名称命名的目录，如 webservers 等；
3. 在每个角色命名的目录中分别创建 files、handlers、meta、tasks、templates 和 vars 目录；用不到的目录可以创建为空目录，也可以不创建；
4. 在 playbook 文件中，调用各角色。

**针对大型项目使用 Roles 进行编排**

示例：roles 的目录结构

```shell
nginx-role.yml 
roles/
└── nginx 
     ├── files
     │    └── main.yml 
     ├── tasks
     │    ├── groupadd.yml 
     │    ├── install.yml 
     │    ├── main.yml 
     │    ├── restart.yml 
     │    └── useradd.yml 
     └── vars 
          └── main.yml 
```

