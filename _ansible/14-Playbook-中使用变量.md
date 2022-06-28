---
title: "Playbook 中使用变量"
permalink: /ansible/playbook-variable/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---

变量名：仅能由字母、数字和下划线组成，且只能以字母开头。

**变量定义：**`variable=value`

示例：`http_port=80`

**变量调用方式：**通过 `{{ variable_name }}` 调用变量，且变量名前后建议加空格，有时用 `"{{ variable_name }}"` 才生效。

## 变量来源

1. ansible 的 setup facts 远程主机的所有变量都可直接调用

2. 通过命令行指定变量，优先级最高

   ```shell
   $ ansible-playbook -e varname=value
   ```

3. 在 playbook 文件中定义

   ```yaml
     vars:
       - var1: value1
       - var2: value2
   ```

4. 在独立的变量 YAML 文件中定义

   ```yaml
   - hosts: all
     vars_files:
       - vars.yml
   ```

5. 在 `/etc/ansible/hosts` 中定义

   **主机（普通）变量**：主机组中主机单独定义，优先级高于公共变量
   **组（公共）变量**：针对主机组中所有主机定义统一变量

6. 在 role 中定义

## 使用 setup 模块中变量

执行 playbook 时默认会调用 setup 模块（`gather_facts` 设置为 `no` 则不会调用），所以在 playbook 中可以使用 setup 模块中的变量；ansible 调用其他模块执行单条命令时没有调用 setup 模块，所以 ansible 命令中将无法使用 setup 模块中的变量。

```yaml
# var.yml
---
- hosts: all
  remote_user: root
  gather_facts: yes

  tasks:
    - name: create log file
      file: name=/data/{{ ansible_nodename }}.log state=touch owner=wang mode=600
```

执行：

```shell
$ ansible-playbook var.yml
```

## 在 playbook 命令行中定义变量

示例：

```yaml
# var2.yml
---
- hosts: websrvs
  remote_user: root

  tasks:
    - name: install package
      yum: name={{ pkname }} state=present
```

执行：

```shell
$ ansible-playbook  –e pkname=httpd  var2.yml
```

## 在 playbook 文件中定义变量

示例：

```yaml
# var3.yml
---
- hosts: websrvs
  remote_user: root
  vars:
    - username: user1
    - groupname: group1

  tasks:
    - name: create group
      group: name={{ groupname }} state=present
    - name: create user
      user: name={{ username }} group={{ groupname }} state=present
```

执行：

```shell
$ ansible-playbook -e var3.yml
```

## 使用变量文件

可以在一个独立的 playbook 文件中定义变量，在另一个 playbook 文件中引用变量文件中的变量，比 playbook 中定义的变量优化级高。

示例1：

**Step 1）**创建用于定义变量的 yaml 文件，并在里面定义好变量

*vars.yml*

```yaml
# variables file
package_name: mariadb-server
service_name: mariadb
```

**Step 2）**在 playbook 中引用 `vars.yml` 文件中的变量

```yaml
# var4.yml
---
#install package and start service
- hosts: dbsrvs
  remote_user: root
  vars_files:
    - /root/vars.yml

  tasks:
    - name: install package
      yum: name={{ package_name }}
      tags: install
    - name: start service
      service: name={{ service_name }} state=started enabled=yes
```

示例2：

变量定义文件 `vars2.yml` ：

```yaml
---
var1: httpd
var2: nginx
```

playbook 文件 `var5.yml` ：

```yaml
# var5.yml
---         
- hosts: web
  remote_user: root
  vars_files:
    - vars2.yml

   tasks:
     - name: create httpd log
       file: name=/app/{{ var1 }}.log state=touch
     - name: create nginx log
       file: name=/app/{{ var2 }}.log state=touch
```

## 主机清单文件中定义变量

### 4.8.6.1 主机变量

在 inventory 主机清单文件中为指定的主机定义变量以便在 playbook 中使用

示例：

```ini
[websrvs]
www1.magedu.com http_port=80 maxRequestsPerChild=808
www2.magedu.com http_port=8080 maxRequestsPerChild=909
```

上述示例文件中，为主机 *www1.magedu.com* 定义了两个变量：`http_port=80` 和 `maxRequestsPerChild=808`；为主机 *www2.magedu.com* 定义了两个变量：`http_port=8080` 和 `maxRequestsPerChild=909`

### 4.8.6.2 组（公共）变量

在 inventory 主机清单文件中赋予给指定组内所有主机上的在playbook中可用的变量，如果和主机变是同名，优先级低于主机变量。

示例：

```ini
[websrvs]
www1.magedu.com
www2.magedu.com

[websrvs:vars]
ntp_server=ntp.magedu.com
nfs_server=nfs.magedu.com
```

上述示例文件中，为 *websrvs* 组定义了两个变量：`ntp_server=ntp.magedu.com` 和 `nfs_server=nfs.magedu.com`

### 综合示例

示例1：

```ini
[websrvs]
10.0.0.8 hname=node1
10.0.0.7 hname=node2

[websvrs:vars]
domain=magedu.org
```

调用：

```shell
$ ansible websvrs –m hostname –a 'name={{ hname }}.{{ domain }}'
```

在以上 ansible 使用 hostname 模块修改远程主机名的示例中：主机 *10.0.0.8* 的名字将被修改为：`node1.magedu.org`，主机 *10.0.0.7* 的名字将被修改为：`node2.magedu.org`

示例2：

*/etc/ansible/hosts*

```ini
[websrvs]
192.168.0.101 hname=www1 domain=magedu.io
192.168.0.102 hname=www2 

[websvrs:vars]
mark=“-”
domain=magedu.org
```

调用：

```shell
$ ansible websvrs –m hostname –a 'name={{ hname }}{{ mark }}{{ domain }}'

# 命令行指定变量： 
$ ansible websvrs –e domain=magedu.cn –m hostname –a 'name={{ hname }}{{ mark }}{{ domain }}'
```

