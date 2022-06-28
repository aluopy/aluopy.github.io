---
title: "Playbook 核心元素"
permalink: /ansible/playbook-core-element/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---



- **Hosts** 执行的远程主机列表；
- **Tasks** 任务集；
- **Variables** 内置变量或自定义变量在 playbook 中调用；
- **Templates** 模板，可替换模板文件中的变量并实现一些简单逻辑的文件；
- **Handlers** 和 **notify** 结合使用，由特定条件触发的操作，满足条件方才执行，否则不执行；
- **tags** 标签，指定某条任务执行，用于选择运行 playbook 中的部分代码。ansible 具有幂等性，因此会自动跳过没有变化的部分，即便如此，有些代码为测试其确实没有发生变化的时间依然会非常地长。此时，如果确信其没有变化，就可以通过 tags 跳过此些代码片断。

## hosts 组件

Hosts：playbook 中的每一个 play 的目的都是为了让特定主机以某个指定的用户身份执行任务。hosts 用于指定要执行指定任务的主机，须事先定义在主机清单中。

```ini
one.example.com
one.example.com:two.example.com
192.168.1.50
192.168.1.*
# 或，两个组的并集
Websrvs:dbsrvs
# 与，两个组的交集
Websrvs:&dbsrvs
# 在 websrvs 组，但不在 dbsrvs 组
webservers:!phoenix
```

示例：

```yaml
- hosts: websrvs:appsrvs
```

## remote_user 组件

remote_user 可用于 Host 和 task 中。也可以通过指定其通过 sudo 的方式在远程主机上执行任务，其可用于 play 全局或某任务；此外，甚至可以在 sudo 时使用 sudo_user 指定 sudo 时切换的用户。

```yaml
- hosts: websrvs
  remote_user: root

  tasks:
    - name: test connection
      ping:
      remote_user: magedu
      sudo: yes                 # 默认 sudo 为 root
      sudo_user:wang            # sudo 为 wang
```

## task 列表和 action 组件

play 的主体部分是 task list，task list 中有一个或多个 task，各个 task 按次序逐个在 hosts 中指定的所有主机上执行，即在所有主机上完成第一个 task 后，再开始第二个 task；
task 的目的是使用指定的参数执行模块，而在模块参数中可以使用变量。模块执行是幂等的，这意味着多次执行是安全的，因为其结果均一致；
每个 task 都应该有其 name，用于 playbook 的执行结果输出，建议其内容能清晰地描述任务执行步骤。如果未提供 name，则 action 的结果将用于输出。

**task 两种格式：**

- `action: module arguments`
- `module: arguments` (建议使用)

> **注意**：shell 和 command 模块后面跟命令，而非 key=value

示例：

```yaml
---
- hosts: websrvs
  remote_user: root
  tasks:
    - name: install httpd
      yum: name=httpd 
    - name: start httpd
      service: name=httpd state=started enabled=yes
```

## 其它组件

某任务的状态在运行后为 changed 时，可通过 “notify” 通知给相应的 handlers；
任务可以通过 "tags“ 打标签，可在 ansible-playbook 命令上使用 `-t` 指定进行调用。

## ShellScripts VS Playbook 案例

SHELL 脚本实现：

```shell
#!/bin/bash
# 安装 Apache
yum install --quiet -y httpd 
# 复制配置文件
cp /tmp/httpd.conf /etc/httpd/conf/httpd.conf
cp/tmp/vhosts.conf /etc/httpd/conf.d/
# 启动 Apache，并设置开机启动
systemctl enable --now httpd 
```

Playbook 实现：

```yaml
---
- hosts: websrvs
  remote_user: root
  tasks:
    - name: "安装 Apache"
      yum: name=httpd
    - name: "复制配置文件"
      copy: src=/tmp/httpd.conf dest=/etc/httpd/conf/
    - name: "复制配置文件"
      copy: src=/tmp/vhosts.conf dest=/etc/httpd/conf.d/
    - name: "启动 Apache，并设置开机启动"
      service: name=httpd state=started enabled=yes
```

