---
title: "Ansible Roles 目录编排"
permalink: /ansible/dir-arrange/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

roles 目录结构如下所示：

![](https://aluopy.github.io/assets/images/ansible-08.png) 

每个角色，以特定的层级目录结构进行组织。

**roles 目录结构：**
playbook.yml
roles/
project/
tasks/
files/
vars/
templates/
handlers/
default/
meta/

**Roles 各目录作用：**
`roles/project/ `：项目名称，有以下子目录

- `files/` ：存放由 copy 或 script 模块等调用的文件
- `templates/`：template 模块查找所需要模板文件的目录
- `tasks/`：定义 task，role 的基本元素，至少应该包含一个名为 main.yml 的文件；其它的文件需要在此文件中通过 include 进行包含
- `handlers/`：至少应该包含一个名为 main.yml 的文件；其它的文件需要在此文件中通过 include 进行包含
- `vars/`：定义变量，至少应该包含一个名为 main.yml 的文件；其它的文件需要在此文件中通过 include 进行包含
- `meta/`：定义当前角色的特殊设定及其依赖关系，至少应该包含一个名为 main.yml 的文件，其它文件需在此文件中通过 include 进行包含
- `default/`：设定默认变量时使用此目录中的 main.yml 文件，比 vars 的优先级低

