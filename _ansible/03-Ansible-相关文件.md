---
title: "Ansible 相关文件"
permalink: /ansible/related-docs/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---

## 配置文件

- **`/etc/ansible/ansible.cfg`**：主配置文件，配置 ansible 工作特性
- **`/etc/ansible/hosts`**：主机清单文件
- **`/etc/ansible/roles`**：存放角色的目录

## Ansible 主配置文件

Ansible 主配置文件 `/etc/ansible/ansible.cfg` 的大部分配置内容无需修改

```ini
[defaults]
#inventory     = /etc/ansible/hosts      # 主机列表配置文件
#library       = /usr/share/my_modules/  # 库文件存放目录
#remote_tmp    = $HOME/.ansible/tmp      # 临时 py 命令文件存放在远程主机目录
#local_tmp     = $HOME/.ansible/tmp      # 本机的临时命令执行目录  
#forks         = 5                       # 默认并发数,同时可以执行5次
#sudo_user     = root                    # 默认 sudo 用户
#ask_sudo_pass = True                    # 每次执行 ansible 命令是否询问 ssh 密码
#ask_pass      = True                    # 每次执行 ansible 命令是否询问 ssh 口令
#remote_port   = 22                      # 远程主机的端口号(默认22)

# 建议优化项： 
host_key_checking = False               # 检查对应服务器的 host_key，建议取消注释
log_path=/var/log/ansible.log           # 日志文件,建议取消注释
module_name   = command                 # 默认模块,可修改为 shell 模块
```

## inventory 主机清单

Ansible 的主要功用在于批量主机操作，为了便捷地使用其中的部分主机，可以在 inventory file 中将其分组命名；

默认的 inventory file 为 `/etc/ansible/hosts` ；

inventory file 可以有多个，且也可以通过 Dynamic Inventory 来动态生成。

**主机清单文件格式：**

inventory 文件遵循 INI 文件风格，中括号中的字符为组名，可以将同一个主机同时归并到多个不同的组中；

此外，当如若目标主机使用了非默认的 SSH 端口，还可以在主机名称之后使用冒号加端口号来标明；

如果主机名称遵循相似的命名模式，还可以使用列表的方式标识各主机。

```ini
ntp.magedu.com

[webservers]
www1.magedu.com:2222
www2.magedu.com
    
[dbservers]
db1.magedu.com
db2.magedu.com
db3.magedu.com

[websrvs]
www[1:100].example.com

[dbsrvs]
db-[a:f].example.com

[appsrvs]
10.0.0.[1:100]
```

