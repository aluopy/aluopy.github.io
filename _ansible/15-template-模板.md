---
title: "template 模板"
permalink: /ansible/playbook-template/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---

模板是一个文本文件，可以做为生成文件的模版，并且模板文件中还可嵌套 jinja 语法

## jinja2 语言

[Jinja](https://jinja.palletsprojects.com/en/3.0.x/) 是一个快速、富有表现力、可扩展的模板引擎。模板中的特殊占位符允许编写类似于 Python 语法的代码。然后向模板传递数据以呈现最终文档。

jinja2 语言使用字面量，有下面形式：

- 字符串：使用单引号或双引号
- 数字：整数，浮点数
- 列表：[item1, item2, …]
- 元组：(item1, item2, …)
- 字典：{key1:value1, key2:value2, …}
- 布尔型：true/false
- 算术运算：+，-，*，/，//，%，**
- 比较操作：==，!=，>，>=，<，<=
- 逻辑运算：and，or，not
- 流表达式：For，If，When

**字面量**

表达式最简单的形式就是字面量。字面量表示诸如字符串和数值的 Python 对象。如 "Hello World"
双引号或单引号中间的一切都是字符串。无论何时你需要在模板中使用一个字符串（比如函数调用、过滤器或只是包含或继承一个模板的参数），如42，42.23
数值可以为整数和浮点数。如果有小数点，则为浮点数，否则为整数。在 Python 里， 42 和 42.0 是不一样的

**算术运算**

Jinja 允许用计算值。支持下面的运算符
`+`：把两个对象加到一起。通常对象是素质，但是如果两者是字符串或列表，你可以用这 种方式来衔接它们。无论如何这不是首选的连接字符串的方式！连接字符串见 ~ 运算符。 {{ 1 + 1 }} 等于 2
`-`：用第一个数减去第二个数。 {{ 3 – 2 }} 等于 1
`/`：对两个数做除法。返回值会是一个浮点数。 {{ 1 / 2 }} 等于 {{ 0.5 }}
`//`：对两个数做除法，返回整数商。 {{ 20 // 7 }} 等于 2
`%`：计算整数除法的余数。 {{ 11 % 7 }} 等于 4
`*`：用右边的数乘左边的操作数。 {{ 2 * 2 }} 会返回 4 。也可以用于重复一个字符串多次。 {{ '=' `*`80 }} 会打印 80 个等号的横条
`**`：取左操作数的右操作数次幂。 {{ 2**3 }} 会返回 8

**比较操作符**

`==` 比较两个对象是否相等

`!=` 比较两个对象是否不等

`>` 如果左边大于右边，返回 true

`>=` 如果左边大于等于右边，返回 true

`<` 如果左边小于右边，返回 true

`<=` 如果左边小于等于右边，返回 true

**逻辑运算符**

对于 if 语句，在 for 过滤或 if 表达式中，它可以用于联合多个表达式
and 如果左操作数和右操作数同为真，返回 true
or 如果左操作数和右操作数有一个为真，返回 true
not 对一个表达式取反
(expr)表达式组
true / false true 永远是 true ，而 false 始终是 false

## template

template 功能：可以根据和参考模块文件，动态生成相类似的配置文件

template 文件必须存放于 templates 目录下，且命名为 .j2 结尾

yaml/yml 文件需和 templates 目录平级，目录结构如下示例：

```shell
./
├── temnginx.yml
└── templates
└── nginx.conf.j2
```

**示例：利用 template 同步 nginx 配置文件**

**Step 1）**准备 `templates/nginx.conf.j2` 文件

**Step 2）**准备 playbook 的 yaml 文件，如下

```yaml
# temnginx.yml
---
- hosts: websrvs
  remote_user: root

  tasks:
    - name: template config to remote hosts
      template: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf
```

**Step 3）**执行 playbook

```shell
$ ansible-playbook temnginx.yml
```

**template 变更替换**

**Step 1）**准备 template 文件：`templates/nginx.conf.j2`

可以将新安装的 nginx 配置文件拷贝并重命名为 `nginx.conf.j2`

```shell
# 创建用于存放模板的目录 templates
$ mkdir templates

$ cp /etc/nginx/nginx.conf templates/nginx.conf.j2
```

**Step 2）**修改 template 文件：`nginx.conf.j2` 

本例只修改了 nginx 的工作进程数（`worker_processes`）为调用远程主机的 vcpu 数（`{{ ansible_processor_vcpus }}`），也就是根据远程主机的 vcpu 的数量动态设置安装在该主机上的 nginx 的工作进程数。

```shell
$ vim templates/nginx.conf.j2
user  nginx;
worker_processes  {{ ansible_processor_vcpus }};

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;
... ...
```

**Step 3）**准备 playbook 的 yaml 文件

```yaml
# temnginx2.yml
---
- hosts: websrvs
  remote_user: root

  tasks:
    - name: install nginx
      yum: name=nginx
    - name: template config to remote hosts
      template: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf 
    - name: start service
      service: name=nginx state=started enable=yes
```

> `src=nginx.conf.j2` 中不用写 `templates/nginx.conf.j2` 路径，template 模块会自动在 `temnginx2.yml` 文件的同级目录下查找 templates 目录下的 `nginx.conf.j2` 文件。

**Step 4）**执行 playbook

安装 nginx 服务、根据模板文件 `nginx.conf.j2` 生成 nginx 配置文件、启动 nginx 服务

```shell
$ ansible-playbook temnginx2.yml
```

**template 算术运算**

示例1：

```shell
$ vim nginx.conf.j2 
worker_processes {{ ansible_processor_vcpus**2 }};    
worker_processes {{ ansible_processor_vcpus+2 }}; 
```

示例2：

```shell
$ vim templates/nginx.conf.j2
worker_processes {{ ansible_processor_vcpus**3 }};

$ cat templnginx.yml
---
- hosts: websrvs
  remote_user: root

  tasks:
    - name: install nginx
      yum: name=nginx
    - name: template config to remote hosts
      template: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf
      notify: restart nginx
    - name: start service
      service: name=nginx state=started enabled=yes

  handlers:
    - name: restart nginx
      service: name=nginx state=restarted

$ ansible-playbook  templnginx.yml --limit 10.0.0.8
```

## template 中使用流程控制 for 和 if

template 中也可以使用流程控制 for 循环和 if 条件判断，实现动态生成文件功能

示例1：

```shell
$ cat temlnginx2.yml
# temlnginx2.yml
---
- hosts: websrvs
  remote_user: root
  vars:
    nginx_vhosts:
      - 81
      - 82
      - 83
  tasks:
    - name: template config
      template: src=nginx.conf.j2 dest=/data/nginx.conf


$ cat templates/nginx.conf2.j2
# templates/nginx.conf2.j2
{% for vhost in  nginx_vhosts %}
server {
   listen {{ vhost }}
}
{% endfor %}


$ ansible-playbook templnginx2.yml  --limit 10.0.0.8

# 生成的结果：
server {
   listen 81   
}
server {
   listen 82   
}
server {
   listen 83   
}
```

示例2：

```shell
$ cat temlnginx3.yml
# temlnginx3.yml
---
- hosts: websrvs
  remote_user: root
  vars:
    nginx_vhosts:
      - listen: 8080
  tasks:
    - name: config file
      template: src=nginx.conf3.j2 dest=/data/nginx3.conf


$ cat templates/nginx.conf3.j2
# templates/nginx.conf3.j2
{% for vhost in nginx_vhosts %}   
server {
  listen {{ vhost.listen }}
}
{% endfor %}


$ ansible-playbook templnginx3.yml  --limit 10.0.0.8

# 生成的结果
server {
  listen 8080  
}
```

示例3：

```shell
$ cat templnginx4.yml
# templnginx4.yml
- hosts: websrvs
  remote_user: root
  vars:
    nginx_vhosts:
      - listen: 8080
        server_name: "web1.magedu.com"
        root: "/var/www/nginx/web1/"
      - listen: 8081
        server_name: "web2.magedu.com"
        root: "/var/www/nginx/web2/"
      - {listen: 8082, server_name: "web3.magedu.com", root: "/var/www/nginx/web3/"}
  tasks:
    - name: template config 
      template: src=nginx.conf4.j2 dest=/data/nginx4.conf


$ cat templates/nginx.conf4.j2
# templates/nginx.conf4.j2
{% for vhost in nginx_vhosts %}
server {
   listen {{ vhost.listen }}
   server_name {{ vhost.server_name }}
   root {{ vhost.root }}  
}
{% endfor %}


$ ansible-playbook templnginx4.yml --limit 10.0.0.8

# 生成结果：
server {
    listen 8080
    server_name web1.magedu.com
    root /var/www/nginx/web1/  
}
server {
    listen 8081
    server_name web2.magedu.com
    root /var/www/nginx/web2/  
}
server {
    listen 8082
    server_name web3.magedu.com
    root /var/www/nginx/web3/  
} 
```

在模版文件中还可以使用 if 条件判断，决定是否生成相关的配置信息

示例：

```shell
$ cat templnginx5.yml
# templnginx5.yml
- hosts: websrvs
  remote_user: root
  vars:
    nginx_vhosts:
      - web1:
        listen: 8080
        root: "/var/www/nginx/web1/"
      - web2:
        listen: 8080
        server_name: "web2.magedu.com"
        root: "/var/www/nginx/web2/"
      - web3:
        listen: 8080
        server_name: "web3.magedu.com"
        root: "/var/www/nginx/web3/"
  tasks:
    - name: template config to 
      template: src=nginx.conf5.j2 dest=/data/nginx5.conf


$ cat templates/nginx.conf5.j2
# templates/nginx.conf5.j2
{% for vhost in  nginx_vhosts %}
server {
   listen {{ vhost.listen }}
   {% if vhost.server_name is defined %}
server_name {{ vhost.server_name }}
   {% endif %}
root  {{ vhost.root }}
}
{% endfor %}


$ ansible-playbook templnginx5.yml --limit 10.0.0.8

# 生成的结果
server {
   listen 8080
   root  /var/www/nginx/web1/
}
server {
   listen 8080
   server_name web2.magedu.com
   root  /var/www/nginx/web2/
}
server {
   listen 8080
   server_name web3.magedu.com
   root  /var/www/nginx/web3/
}
```

