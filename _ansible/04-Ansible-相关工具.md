---
title: "Ansible 相关工具"
permalink: /ansible/related-tools/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---



- **/usr/bin/ansible：**主程序，临时命令执行工具
- **/usr/bin/ansible-doc：**查看配置文档，模块功能查看工具
- **/usr/bin/ansible-galaxy：**下载/上传优秀代码或 Roles 模块的官网平台
- **/usr/bin/ansible-playbook：**定制自动化任务，编排剧本工具
- **/usr/bin/ansible-pull：**远程执行命令的工具
- **/usr/bin/ansible-vault：**文件加密工具
- **/usr/bin/ansible-console：**基于 Console 界面与用户交互的执行工具

**利用 Ansible 实现管理的主要方式：**

- **Ad-Hoc：**即利用 ansible 命令，主要用于临时命令使用场景
- **Ansible-playbook：**主要用于长期规划好的，大型项目的场景，需要有前期的规划过程

## ansible-doc

此工具用来显示模块帮助

格式：

```shell
ansible-doc [options] [module...]
-l, --list          # 列出可用模块
-s, --snippet       # 显示指定模块的playbook片段
```

范例：

```shell
# 列出所有模块
$ ansible-doc -l  
# 查看指定模块帮助用法
$ ansible-doc ping  
# 查看指定模块帮助用法
$ ansible-doc -s  ping 
```

## ansible

此工具通过 ssh 协议，实现对远程主机的配置管理、应用部署、任务执行等功能

建议：使用此工具前，先配置 ansible 主控端能基于密钥认证的方式联系各个被管理节点

范例：利用 sshpass 批量实现基于 key 验证

```sh
#!/bin/bash
ssh-keygen -f /root/.ssh/id_rsa  -P ''
NET=192.168.100
export SSHPASS=magedu
for IP in {1..200};do 
    sshpass -e ssh-copy-id  $NET.$IP 
done
```

### Ansible 命令格式

```
ansible <host-pattern> [-m module_name] [-a args]
```

选项说明：

```shell
--version               # 显示版本
-m module               # 指定模块，默认为 command
-v                      # 详细过程–vv, -vvv 更详细
--list-hosts            # 显示主机列表，可简写 --list
-k, --ask-pass          # 提示输入 ssh 连接密码，默认 Key 验证    
-C, --check             # 检查，并不执行
-T, --timeout=TIMEOUT   # 执行命令的超时时间，默认10s
-u, --user=REMOTE_USER  # 执行远程执行的用户
-b, --become            # 代替旧版的 sudo 切换
--become-user=USERNAME  # 指定 sudo 的 runas 用户，默认为 root
-K, --ask-become-pass   # 提示输入 sudo 时的口令
```

### Ansible host-pattern

用于匹配被控制的主机的列表

下表列出了针对清单主机和组的常见模式

| 描述     | Pattern(s)（模式）           | 目标                                             |
| -------- | ---------------------------- | ------------------------------------------------ |
| 所有主机 | `all` (或 `*`)               |                                                  |
| 一台主机 | host1                        |                                                  |
| 多台主机 | host1:host2 (或 host1,host2) |                                                  |
| 一组     | websrvs                      |                                                  |
| 多组     | websrvs:dbsrvs               | websrvs 组中的所有主机加上 dbsrvs 组中的所有主机 |
| 排除组   | websrvs:!atlanta             | 在 websrvs 组但不在 atlanta 组中的所有主机       |
| 组的交集 | websrvs:&staging             | 在 websrvs 组并且在 staging 组中的所有主机       |

**`all`**  表示所有 Inventory 中的所有主机

```shell
$ ansible all –m ping
```

**`*`**  通配符

```shell
$ ansible  "*"  -m ping
$ ansible  192.168.1.* -m ping
$ ansible  "svc"  -m ping
```

**`:`**  或关系

```shell
$ ansible "websrvs:appsrvs"  -m ping 
$ ansible "192.168.1.10:192.168.1.20"  -m ping
```

**`:&`**  逻辑与

```shell
# 在 websrvs 组并且在 dbsrvs 组中的主机
$ ansible "websrvs:&dbsrvs" –m ping 
```

**`:!`**  逻辑非

```shell
# 在 websrvs 组，但不在 dbsrvs 组中的主机
# 注意：此处为单引号
$ ansible 'websrvs:!dbsrvs' –m ping 
```

**综合逻辑**

```shell
# 在 websrvs 组或 dbsrvs 组，并且在 appsrvs 组，而且不在 ftpsvc 组
$ ansible 'websrvs:dbsrvs:&appsrvs:!ftpsvc' –m ping
```

**正则表达式**

```shell
$ ansible "websrvs:&dbsrvs" –m ping 
$ ansible "~(web|db).*\.magedu\.com" –m ping 
```

### Ansible 命令执行过程

1. 加载自己的配置文件，默认 `/etc/ansible/ansible.cfg`

2. 加载自己对应的模块文件，如：`command`

3. 通过 ansible 将模块或命令生成对应的临时 `.py` 文件，并将该文件传输至远程服务器的对应执行用户的家目录，默认位置：`$HOME/.ansible/tmp/ansible-tmp-数字/xxx.py`

4. 给文件执行权限 `+x`

5. 执行并返回结果

6. 删除临时 `.py` 文件，退出

### Ansible 的执行状态

```shell
$ grep -A 14 '\[colors\]' /etc/ansible/ansible.cfg 
[colors]
#highlight = white
#verbose = blue
#warn = bright purple
#error = red
#debug = dark gray
#deprecate = purple
#skip = cyan
#unreachable = red
#ok = green
#changed = yellow
#diff_add = green
#diff_remove = red
#diff_lines = cyan
```

- <font color="#008000">绿色</font>：执行成功并且不需要做改变的操作
- <font color="FFFF00">黄色</font>：执行成功并且对目标主机做变更
- <font color="#FF0000">红色</font>：执行失败

### Ansible 使用范例

```shell
# 以 wang 用户执行 ping 存活检测
$ ansible all -m ping -u wang  -k
# 以 wang 用户 sudo 至 root 用户执行 ping 存活检测（默认 sudo 至 root 用户）
$ ansible all -m ping -u wang -k -b
# 以 wang 用户 sudo 至 mage 用户执行 ping 存活检测
$ ansible all -m ping -u wang -k -b --become-user=mage
# 以 wang 用户 sudo 至 root 用户执行 ls 命令
$ ansible all -m command  -u wang -a 'ls /root' -b --become-user=root   -k -K
```

## ansible-galaxy

此工具会连接 [Ansible Galaxy](https://galaxy.ansible.com/) 下载相应的 roles

范例：

```shell
# 列出所有已安装的 galaxy
$ ansible-galaxy list
# 安装 galaxy
$ ansible-galaxy install geerlingguy.mysql
$ ansible-galaxy install geerlingguy.redis
# 删除 galaxy
$ ansible-galaxy remove geerlingguy.redis
```

## ansible-pull

此工具会推送 ansible 的命令至远程，效率无限提升，对运维要求较高

## ansible-playbook

此工具用于执行编写好的 playbook 任务

范例：

```shell
$ ansible-playbook hello.yml
$ cat  hello.yml
---
#hello world yml file
- hosts: websrvs
  remote_user: root  
  tasks:
    - name: hello world
      command: /usr/bin/wall hello world
```

## ansible-vault

此工具可以用于加解密 yml 文件

格式：

```shell
ansible-vault [create|decrypt|edit|encrypt|rekey|view]
```

范例：

```shell
$ ansible-vault encrypt hello.yml     # 加密
$ ansible-vault decrypt hello.yml     # 解密
$ ansible-vault view hello.yml        # 查看
$ ansible-vault edit  hello.yml       # 编辑加密文件
$ ansible-vault rekey  hello.yml      # 修改口令
$ ansible-vault create new.yml        # 创建新文件
```

## ansible-console

此工具可交互执行命令，支持 tab，ansible 2.0+ 新增

提示符格式：

```
执行用户@当前操作的主机组 (当前组的主机数量)[f:并发数]$
```

常用子命令：

- 设置并发数： `forks n`   例如： forks 10
- 切换组： `cd 主机组`   例如： cd web
- 列出当前组主机列表： `list`
- 列出所有的内置命令： `?`或 `help`

范例：

```shell
$ ansible-console
Welcome to the ansible console.
Type help or ? to list commands.

root@all (3)[f:5]$ list
10.0.0.8
10.0.0.7
10.0.0.6
root@all (3)[f:5]$ cd websrvs
root@websrvs (2)[f:5]$ list
10.0.0.7
10.0.0.8
root@websrvs (2)[f:5]$ forks 10
root@websrvs (2)[f:10]$ cd appsrvs
root@appsrvs (2)[f:5]$ yum name=httpd state=present
root@appsrvs (2)[f:5]$ service name=httpd state=started
```

### 