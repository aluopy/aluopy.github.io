---
title: "运维自动化之 Ansible"
toc: true
toc_label: "运维自动化之 Ansible"
toc_icon: "cog"
categories: Ansible
tags:
  - ansible
---



## 本书内容

- 运维自动化发展历程及技术应用
- Ansible 命令使用
- Ansible 常用模块详解
- YAML 语法简介
- Ansible playbook 基础
- Playbook 变量、tags、handlers 使用
- Playbook 模板 templates
- Playbook 条件判断 when
- Playbook 字典 with_items
- Ansible Roles
## 1. 自动化运维应用场景
### 1.1 云计算运维工程师核心职能
![](https://aluopy.github.io/assets/images/ansible-01.png)
![](https://aluopy.github.io/assets/images/ansible-02.jpg)
![](https://aluopy.github.io/assets/images/ansible-03.jpg)
**相关工具**

- 代码管理（SCM）：GitHub、GitLab、BitBucket、SubVersion
- 构建工具：maven、Ant、Gradle
- 自动部署：Capistrano、CodeDeploy
- 持续集成（CI）：Jenkins、Travis
- 配置管理：Ansible、SaltStack、Chef、Puppet
- 容器：Docker、Podman、LXC、第三方厂商如 AWS
- 编排：Kubernetes、Core、Apache Mesos
- 服务注册与发现：Zookeeper、etcd、Consul
- 脚本语言：python、ruby、shell
- 日志管理：ELK、Logentries
- 系统监控：Prometheus、Zabbix、Datadog、Graphite、Ganglia、Nagios
- 性能监控：AppDynamics、New Relic、Splunk
- 压力测试：JMeter、Blaze Meter、loader.io
- 应用服务器：Tomcat、JBoss、IIS
- Web服务器：Apache、Nginx
- 数据库：MySQL、Oracle、PostgreSQL 等关系型数据库；mongoDB、redis 等 NoSQL 数据库
- 项目管理（PM）：Jira、Asana、Taiga、Trello、Basecamp、Pivotal Tracker
### 1.2 运维职业发展路线
![](https://aluopy.github.io/assets/images/ansible-04.jpg) 

**运维的未来是什么？**
**一切皆自动化**

“运维的未来是，让研发人员能够借助工具、自动化和流程，并且让他们能够在运维干预极少的情况下部署和运营服务，从而实现自助服务。每个角色都应该努力使工作实现自动化。”——《运维的未来》

### 1.3 企业实际应用场景分析
![](https://aluopy.github.io/assets/images/ansible-05.png) 
#### 1.3.1 Dev开发环境
使用者：程序员
功能：程序员个人的办公电脑或项目的开发测试环境，部署开发软件，测试个人或项目整体的 BUG 的环境
管理者：程序员
#### 1.3.2 测试环境
使用者：QA 测试工程师
功能：测试经过 Dev 环境测试通过的软件的功能和性能，判断是否达到项目的预期目标，生成测试报告
管理者：运维
说明：测试环境往往有多套,测试环境满足测试功能即可，不宜过多
1、测试人员希望测试环境有多套,公司的产品多产品线并发，即多个版本，意味着多个版本同步测试
2、通常测试环境有多少套和产品线数量保持一样
#### 1.3.3 预发布环境
使用者：运维
功能：使用和生产环境一样的数据库，缓存服务等配置，测试是否正常
#### 1.3.4 发布环境
包括代码发布机，有些公司为堡垒机（安全屏障）
使用者：运维
功能：发布代码至生产环境
管理者：运维（有经验）
发布机：往往需要有2台（主备）
#### 1.3.5 生产环境
使用者：运维，少数情况开放权限给核心开发人员，极少数公司将权限完全开放给开发人员并其维护
功能：对用户提供公司产品的服务
管理者：只能是运维
生产环境服务器数量：一般比较多，且应用非常重要。往往需要自动工具协助部署配置应用
#### 1.3.6 灰度环境
属于生产环境的一部分
使用者：运维
功能：在全量发布代码前将代码的功能面向少量精准用户发布的环境,可基于主机或用户执行灰度发布
案例：共100台生产服务器，先发布其中的10台服务器，这10台服务器就是灰度服务器
管理者：运维
灰度环境：往往该版本功能变更较大，为保险起见特意先让一部分用户优化体验该功能，待这部分用户使用没有重大问题的时候，再全量发布至所有服务器。
### 1.4 程序发布
**程序发布要求：**
不能导致系统故障或造成系统完全不可用
不能影响用户体验

**预发布验证：**
新版本的代码先发布到服务器（跟线上环境配置完全相同，只是未接入到调度器）

**灰度发布：**
基于主机，用户，业务

**发布路径：**
`/webapp/tuangou`
`/webapp/tuangou-1.1`
`/webapp/tuangou-1.2`

**发布过程：**
1. 在调度器上下线一批主机(标记为 maintenance 状态)
2. 关闭服务
3. 部署新版本的应用程序
4. 启动服务
5. 在调度器上启用这一批服务器

**自动化灰度发布：**
- 脚本
- 发布平台
### 1.5 自动化运维应用场景
- 文件传输
- 应用部署
- 配置管理
- 任务流编排
### 1.6 常用自动化运维工具
- **Ansible：**python，Agentless，中小型应用环境
- **Saltstack：**python，一般需部署 agent，执行效率更高
- **Puppet：**ruby, 功能强大，配置复杂，重型，适合大型环境
- **Fabric：**python，agentless
- **Chef：**ruby，国内应用少
- **Cfengine**
- **func**
## 2. Ansible 介绍和架构
公司计划在年底做一次大型市场促销活动，全面冲刺下交易额，为明年的上市做准备。公司要求各业务组对年底大促做准备，运维部要求所有业务容量进行三倍的扩容，并搭建出多套环境可以共开发和测试人员做测试，运维老大为了在年底有所表现，要求运维部门同学尽快实现，当你接到这个任务时，有没有更快的解决方案？
### 2.1 Ansible 发展史
Ansible 作者 Michael DeHaan（ Cobbler 与 Func 作者），Ansible 的名称来自科幻小说《安德的游戏》中跨越时空的即时通信工具，使用它可以在相距数光年的距离，远程实时控制前线的舰队战斗。2012年3月9日发布0.0.1版，2015年10月17日被 Red Hat 以1.5亿美元收购。
官方网站：[https://www.ansible.com](http://www.yunweipai.com/go?_=a49e019ca3aHR0cHM6Ly93d3cuYW5zaWJsZS5jb20v)
官方文档：[https://docs.ansible.com](http://www.yunweipai.com/go?_=beb2e5d97daHR0cHM6Ly9kb2NzLmFuc2libGUuY29tLw%3D%3D)

### 2.2 Ansible 特性
- 模块化：调用特定的模块完成特定任务，支持自定义模块，可使用任何编程语言写模块
- Paramiko（python 对 ssh 的实现），PyYAML，Jinja2（模板语言）三个关键模块
- 基于 Python 语言实现
- 部署简单，基于 python 和 SSH (默认已安装)，agentless，无需代理不依赖 PKI（无需 ssl）
- 安全，基于 OpenSSH
- 幂等性：一个任务执行1遍和执行 n 遍效果一样，不因重复执行带来意外情况
- 支持 playbook 编排任务，YAML 格式，编排任务，支持丰富的数据结构
- 较强大的多层解决方案 role
### 2.3 Ansible 架构
#### 2.3.1 Ansible 组成
![](https://aluopy.github.io/assets/images/ansible-06.png)
组合 INVENTORY、API、MODULES、PLUGINS 的绿框，可以理解为是 ansible 命令工具，其为核心执行工具。

- INVENTORY：Ansible 管理主机的清单 `/etc/anaible/hosts`
- MODULES：Ansible 执行命令的功能模块，多数为内置核心模块，也可自定义
- PLUGINS：模块功能的补充，如连接类型插件、循环插件、变量插件、过滤插件等，该功能不常用
- API：供第三方程序调用的应用程序编程接口
#### 2.3.2 Ansible 命令执行来源
- USER 普通用户，即 SYSTEM ADMINISTRATOR
- PLAYBOOKS：任务剧本（任务集），编排定义 Ansible 任务集的配置文件，由 Ansible 顺序依次执行，通常是 JSON 格式的 YML 文件
- CMDB（配置管理数据库） API 调用
- PUBLIC/PRIVATE CLOUD API 调用
- USER -> Ansible Playbook -> Ansibile
#### 2.3.3 注意事项
- 执行 ansible 的主机一般称为主控端，中控，master 或堡垒机
- 主控端 Python 版本需要2.6或以上
- 被控端 Python 版本小于2.4，需要安装 python-simplejson
- 被控端如开启 SELinux 需要安装 libselinux-python
- windows 不能做为主控端
## 3. Ansible 安装和入门
### 3.1 Ansible 安装
Ansible 的安装方法有多种
#### 3.1.1 EPEL 源的 rpm 包安装
```shell
$ yum install epel-release -y
$ yum install ansible -y
```
#### 3.1.2 编译安装
```shell
$ yum -y install python-jinja2 PyYAML python-paramiko python-babel python-crypto
$ tar xf ansible-1.5.4.tar.gz
$ cd ansible-1.5.4
$ python setup.py build
$ python setup.py install
$ mkdir /etc/ansible
$ cp -r examples/* /etc/ansible
```
#### 3.1.3 Git方式
```shell
$ git clone git://github.com/ansible/ansible.git --recursive
$ cd ./ansible
$ source ./hacking/env-setup
```
#### 3.1.4 pip 安装
pip 是安装 Python 包的管理器，类似 yum
```shell
$ yum install python-pip python-devel
$ yum install gcc glibc-devel zibl-devel  rpm-bulid openssl-devel
$ pip install  --upgrade pip
$ pip install ansible --upgrade
```
#### 3.1.5 确认安装
```shell
$ ansible --version
ansible 2.9.5
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.6/site-packages/ansible
  executable location = /usr/bin/ansible
  python version = 3.6.8 (default, Nov 21 2019, 19:31:34) [GCC 8.3.1 20190507 (Red Hat 8.3.1-4)]
```
### 3.2 Ansible 相关文件

#### 3.2.1 配置文件

- **`/etc/ansible/ansible.cfg`**：主配置文件，配置 ansible 工作特性
- **`/etc/ansible/hosts`**：主机清单文件
- **`/etc/ansible/roles`**：存放角色的目录

#### 3.2.2 Ansible 主配置文件

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

#### 3.2.3 inventory 主机清单

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

### 3.3 Ansible 相关工具

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

#### 3.3.1 ansible-doc

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

#### 3.3.2 ansible

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

##### Ansible 命令格式

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

##### Ansible host-pattern

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

##### Ansible 命令执行过程

1. 加载自己的配置文件，默认 `/etc/ansible/ansible.cfg`

2. 加载自己对应的模块文件，如：`command`

3. 通过 ansible 将模块或命令生成对应的临时 `.py` 文件，并将该文件传输至远程服务器的对应执行用户的家目录，默认位置：`$HOME/.ansible/tmp/ansible-tmp-数字/xxx.py`

4. 给文件执行权限 `+x`

5. 执行并返回结果

6. 删除临时 `.py` 文件，退出

##### Ansible 的执行状态

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

##### Ansible 使用范例

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

#### 3.3.3 ansible-galaxy

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

#### 3.3.4 ansible-pull

此工具会推送 ansible 的命令至远程，效率无限提升，对运维要求较高

#### 3.3.5 ansible-playbook

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

#### 3.3.6 ansible-vault

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

#### 3.3.7 ansible-console

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

### 3.4 Ansible 常用模块

2015年底270多个模块，2016年达到540个，2018年01月12日有1378个模块，2018年07月15日1852个模块，2019年05月25日（ansible 2.7.10）时2080个模块，2020年03月02日有3387个模块。

虽然模块众多，但最常用的模块也就二三十个而已，针对特定业务只用十几个模块。

模块帮助文档：[Index of all Modules — Ansible Documentation](https://docs.ansible.com/ansible/latest/collections/index_module.html)

#### 3.4.1 Command 模块

功能：在远程主机执行命令，此模块为默认模块，可忽略 `-m` 选项

注意：此命令不支持 `$VARNAME`、`<`、`>`、`|`、`;`、`&` 等，需要用 shell 模块实现

范例：

```shell
$ ansible websrvs -m command -a 'chdir=/etc cat centos-release'
10.0.0.7 | CHANGED | rc=0 >>
CentOS Linux release 7.7.1908 (Core)
10.0.0.8 | CHANGED | rc=0 >>
CentOS Linux release 8.1.1911 (Core)
$ ansible websrvs -m command -a 'chdir=/etc creates=/data/f1.txt cat centos-release'
10.0.0.7 | CHANGED | rc=0 >>
CentOS Linux release 7.7.1908 (Core)
10.0.0.8 | SUCCESS | rc=0 >>
skipped, since /data/f1.txt exists
$ ansible websrvs -m command -a 'chdir=/etc removes=/data/f1.txt cat centos-release'
10.0.0.7 | SUCCESS | rc=0 >>
skipped, since /data/f1.txt does not exist
10.0.0.8 | CHANGED | rc=0 >>
CentOS Linux release 8.1.1911 (Core)

$ ansible websrvs -m command -a 'service vsftpd start'
$ ansible websrvs -m command -a 'rm -rf /data/'

# 以下为错误示例，因为 command 模块不支持 |, >, $
$ ansible websrvs -m command -a 'echo magedu |passwd --stdin wang'
$ ansible websrvs -m command -a 'echo hello > /data/hello.log'
$ ansible websrvs -m command -a 'echo $HOSTNAME'
```

#### 3.4.2 Shell 模块

功能：与 command 模块相似，用 shell 模块执行命令

范例：

```shell
$ ansible websrvs -m shell -a "echo $HOSTNAME"
10.0.0.7 | CHANGED | rc=0 >>
ansible
10.0.0.8 | CHANGED | rc=0 >>
ansible
# 需要换成单引号，不然会输出当前主机的主机名
$ ansible websrvs -m shell -a 'echo $HOSTNAME'
10.0.0.7 | CHANGED | rc=0 >>
centos7.wangxiaochun.com
10.0.0.8 | CHANGED | rc=0 >>
centos8.localdomain

$ ansible websrvs -m shell -a 'echo centos | passwd --stdin wang'
10.0.0.7 | CHANGED | rc=0 >>
Changing password for user wang.
passwd: all authentication tokens updated successfully.
10.0.0.8 | CHANGED | rc=0 >>
Changing password for user wang.
passwd: all authentication tokens updated successfully.
$ ansible websrvs -m shell -a 'ls -l /etc/shadow'
10.0.0.7 | CHANGED | rc=0 >>
---------- 1 root root 889 Mar  2 14:34 /etc/shadow
10.0.0.8 | CHANGED | rc=0 >>
---------- 1 root root 944 Mar  2 14:34 /etc/shadow
$ ansible websrvs -m shell -a 'echo hello > /data/hello.log'
10.0.0.7 | CHANGED | rc=0 >>

10.0.0.8 | CHANGED | rc=0 >>

$ ansible websrvs -m shell -a 'cat  /data/hello.log'
10.0.0.7 | CHANGED | rc=0 >>
hello
10.0.0.8 | CHANGED | rc=0 >>
hello
```

> **注意：**
>
> **问题：**调用 bash 执行命令，当执行类似 `cat /tmp/test.md | awk -F'|' '{print $1,$2}' &> /tmp/example.txt` 这些复杂命令时，即使使用 shell 模块也可能会失败。
>
> **解决办法：**
>
> 1. 把复杂命令写到脚本里面，将脚本 copy 到远程主机，然后使用 shell 模块执行脚本，再把需要的结果拉回执行命令的机器。因为这种方式需要事先将脚本拷贝到远程主机，比较麻烦，而且当远程主机数量较多时，就更显得麻烦了（至少需要写一个 for 循环来拷贝脚本）。
> 2. 可以直接使用 script 模块，这个模块就是专门用来在远程主机上执行 ansible 服务器上的脚本。script 模块会自动将 ansible 主机上的脚本拷贝到远程主机然后再执行，执行完毕后会删除拷贝到远程服务器上的脚本。在 ansible 服务器上使用 ansible 命令调用 script 模块时，在命令还没执行完毕前使用 `Ctrl + C` 结束命令（假设脚本已经拷贝到远程主机），这时 ansible 也会删除远程服务器上的脚本 （不留一点痕迹😏)。

修改默认模块，将 shell 模块设置为默认模块

```shell
$ vim /etc/ansible/ansible.cfg
# 修改下面一行
module_name = shell
```

#### 3.4.3 Script 模块

功能：在远程主机上运行 ansible 服务器上的脚本

范例：

```shell
$ ansible websrvs  -m script -a /data/test.sh
```

#### 3.4.4 Copy 模块

功能：从 ansible 服务器主控端复制文件到远程主机

```shell
# 如目标存在，默认覆盖，此处指定先备份
$ ansible websrvs -m copy -a "src=/root/test1.sh dest=/tmp/test2.sh owner=wang mode=600 backup=yes"
# 指定内容，直接生成目标文件，如果目标文件存在则直接覆盖其内容
$ ansible websrvs -m copy -a "content='aluopy https://aluopy.cn\nhallo aluopy\n' dest=/tmp/test.txt"
# 复制 /etc/ 下的文件，不包括 /etc/ 目录自身
$ ansible websrvs -m copy -a "src=/etc/ dest=/backup"
```

#### 3.4.5 Fetch 模块

功能：从远程主机提取文件至 ansible 的主控端，与 copy 模块相反，目前不支持目录

```shell
$ ansible websrvs -m fetch -a 'src=/root/test.sh dest=/data/scripts'
$ ansible all -m fetch -a 'src=/etc/redhat-release dest=/data/os'
$ tree /data/os/
/data/os/
├── 10.0.0.6
│   └── etc
│       └── redhat-release
├── 10.0.0.7
│   └── etc
│       └── redhat-release
└── 10.0.0.8
    └── etc
        └── redhat-release

6 directories, 3 files
```

#### 3.4.6 File 模块

功能：设置文件属性

```shell
# 创建空文件
$ ansible all -m file -a 'path=/data/test.txt state=touch'
$ ansible all -m file -a 'path=/data/test.txt state=absent'
$ ansible all -m file -a "path=/root/test.sh owner=wang mode=755"
# 创建目录
$ ansible all -m file -a "path=/data/mysql state=directory owner=mysql group=mysql"
# 创建软链接
$ ansible all -m file -a 'src=/data/testfile dest=/data/testfile-link state=link'
```

#### 3.4.7 unarchive 模块

用于在远程主机上解包

实现有三种用法：

1. **先拷贝再解包：**将 ansible 主机上的压缩包传到远程主机后解压缩至特定目录，设置 `copy=yes` 或 `remote_src=no`

   > 注意：在解包之前将源文件从本地系统复制到目标主机的 `$HOME/.ansible/tmp/ansible-tmp-数字/` 目录下

2. **直接解包：**将远程主机上的某个压缩包解压缩到指定路径下，设置 `copy=no` 或 `remote_src=yes`

3. **先下载再解包：**从指定的 URL 地址下载文件到远程主机并执行解包，设置 `copy=no` 或 `remote_src=yes` 且 src 指定的路径为 URL 地址

常见参数：

- `copy`：默认为 yes，即先将包文件从 Ansible 主机复制到远程主机再执行解包；设为 no 时，会直接在远程主机上查找 src 指定的文件，找到后执行解包。
- `remote_src`：和 copy 功能一样且互斥，二者设置一个就可以。默认为 no，即不在远程主机上查找 src 指定的文件；设为 yes 时，会直接在远程主机上查找 src 指定的文件，找到后执行解包。
- `src`：包文件的路径，是在 Ansible 主机上查找，还是在远程主机上查找，取决于 copy 或 remote_src 的设置。当设置 copy=no 或remote-src=yes 且 src 指定的路径中包含`://`，则会先从指定的 URL 下载文件到远程主机然后再执行解包（解包后删除包文件）。
- `dest`：远程主机上的目标路径，绝对路径。
- `mode`：设置解包后的文件或目录权限。

```shell
# 拷贝 ansible 主机上的 foo.tgz 包并解压到远程主机的 /var/lib/foo 目录
# dest 目录必须存在, 命令运行完毕后 foo.tgz 包不会存在于 dest 目录
$ ansible all -m unarchive -a 'src=/data/foo.tgz dest=/var/lib/foo'
$ ansible all -m unarchive -a 'src=/tmp/foo.zip dest=/data copy=no mode=0777'
$ ansible all -m unarchive -a 'src=https://luojianjun.cn/download/apache-tomcat-9.0.55.tar.gz dest=/data copy=no'
```

#### 3.4.8 Archive 模块

打包压缩

```shell
# path: 源路径，需要打包的文件
# dest: 压缩成什么格式的包，放到什么位置
# owner: 属主
# mode: 包文件权限
$ ansible websrvs -m archive  -a 'path=/var/log/ dest=/data/log.tar.bz2 format=bz2 owner=wang mode=0600'
```

#### 3.4.9 Hostname 模块

管理主机名

```shell
$ ansible node1 -m hostname -a “name=websrv” 
$ ansible 192.168.100.18 -m hostname -a 'name=node18.magedu.com'
```

#### 3.4.10 Cron 模块

计划任务

支持时间：minute，hour，day，month，weekday

```shell
# 备份数据库脚本
$ cat mysql_backup.sh 
mysqldump -A -F --single-transaction --master-data=2 -q -uroot |gzip > /data/mysql_date+%F_%T.sql.gz
# 创建任务
$ ansible 10.0.0.8 -m cron -a 'hour=2 minute=30 weekday=1-5 name="backup mysql" job=/root/mysql_backup.sh'
$ ansible websrvs   -m cron -a "minute=*/5 job='/usr/sbin/ntpdate 172.20.0.1 &>/dev/null' name=Synctime"
# 禁用计划任务
$ ansible websrvs   -m cron -a "minute=*/5 job='/usr/sbin/ntpdate 172.20.0.1 &>/dev/null' name=Synctime disabled=yes"
# 启用计划任务
$ ansible websrvs   -m cron -a "minute=*/5 job='/usr/sbin/ntpdate 172.20.0.1 &>/dev/null' name=Synctime disabled=no"
# 删除任务
$ ansible websrvs -m cron -a "name='backup mysql' state=absent"
$ ansible websrvs -m cron -a 'state=absent name=Synctime'
```

#### 3.4.11 Yum 模块

管理软件包，只支持 RHEL，CentOS，fedora，不支持 Ubuntu 及其它版本

```shell
# 安装
$ ansible websrvs -m yum -a 'name=httpd state=present'
# 删除
$ ansible websrvs -m yum -a 'name=httpd state=absent'
```

#### 3.4.12 Service 模块

管理服务

```shell
$ ansible all -m service -a 'name=httpd state=started enabled=yes'
$ ansible all -m service -a 'name=httpd state=stopped'
$ ansible all -m service -a 'name=httpd state=reloaded’
$ ansible all -m shell -a "sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf"
$ ansible all -m service -a 'name=httpd state=restarted' 
```

#### 3.4.13 User 模块

管理用户

```shell
# 创建用户
$ ansible all -m user -a 'name=user1 comment=“test user” uid=2048 home=/app/user1 group=root'
$ ansible all -m user -a 'name=nginx comment=nginx uid=88 group=nginx groups="root,daemon" shell=/sbin/nologin system=yes create_home=no home=/data/nginx non_unique=yes'

# 删除用户及家目录等数据
$ ansible all -m user -a 'name=nginx state=absent remove=yes'
```

#### 3.4.14 Group 模块

管理组

```shell
# 创建组
$ ansible websrvs -m group  -a 'name=nginx gid=88 system=yes'
# 删除组
$ ansible websrvs -m group  -a 'name=nginx state=absent'
```

#### 3.4.15 Lineinfile 模块

ansible 在使用 sed 进行替换时，经常会遇到需要转义的问题，而且 ansible 在遇到特殊符号进行替换时，存在问题，无法正常进行替换 。其实 ansible 自身提供了两个模块：lineinfile 模块和 replace 模块，可以方便的进行替换，相当于sed，可以修改文件内容。

```shell
$ ansible all -m lineinfile -a "path=/etc/selinux/config regexp='^SELINUX=' line='SELINUX=enforcing'"
$ ansible all -m lineinfile -a 'dest=/etc/fstab state=absent regexp="^#"'
```

#### 3.4.16 Replace 模块

该模块有点类似于 sed 命令，主要也是基于正则进行匹配和替换

```shell
$ ansible all -m replace -a "path=/etc/fstab regexp='^(UUID.*)' replace='#\1'"  
$ ansible all -m replace -a "path=/etc/fstab regexp='^#(.*)' replace='\1'"
```

#### 3.4.17 Setup 模块

setup 模块来收集主机的系统信息，这些 facts 信息可以直接以变量的形式使用，但是如果主机较多，会影响执行速度，可以使用 `gather_facts: no` 来禁止 Ansible 收集 facts 信息

```shell
$ ansible all -m setup
$ ansible all -m setup -a "filter=ansible_nodename"
$ ansible all -m setup -a "filter=ansible_hostname"
$ ansible all -m setup -a "filter=ansible_domain"
$ ansible all -m setup -a "filter=ansible_memtotal_mb"
$ ansible all -m setup -a "filter=ansible_memory_mb"
$ ansible all -m setup -a "filter=ansible_memfree_mb"
$ ansible all -m setup -a "filter=ansible_os_family"
$ ansible all -m setup -a "filter=ansible_distribution_major_version"
$ ansible all -m setup -a "filter=ansible_distribution_version"
$ ansible all -m setup -a "filter=ansible_processor_vcpus"
$ ansible all -m setup -a "filter=ansible_all_ipv4_addresses"
$ ansible all -m setup -a "filter=ansible_architecture"
$ ansible all -m setup -a "filter=ansible_processor*"

$ ansible all -m setup -a 'filter=ansible_python_version'
10.0.0.7 | SUCCESS => {
    "ansible_facts": {
        "ansible_python_version": "2.7.5",
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false
}
10.0.0.6 | SUCCESS => {
    "ansible_facts": {
        "ansible_python_version": "2.6.6",
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false
}
10.0.0.8 | SUCCESS => {
    "ansible_facts": {
        "ansible_python_version": "3.6.8",
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false
}
[root@ansible ~]#
```

## 4. Playbook

### 4.1 Playbook 介绍

playbook 剧本是由一个或多个 “play” 组成的列表
play 的主要功能在于将预定义的一组主机，装扮成事先通过 ansible 中的 task 定义好的角色。Task 实际是调用 ansible 的一个 module，将多个 play 组织在一个playbook中，即可以让它们联合起来，按事先编排的机制执行预定义的动作
Playbook 文件是采用YAML语言编写的

### 4.2 YAML 语言

#### 4.2.1 YAMl 语言介绍

YAML 是一个可读性高的用来表达资料序列的格式。YAML 参考了其他多种语言，包括：XML、C 语言、Python、Perl 以及电子邮件格式 RFC2822等。Clark Evans 在2001年在首次发表了这种语言，另外 Ingy döt Net 与 Oren Ben-Kiki 也是这语言的共同设计者,目前很多软件中采有此格式的文件，如 ubuntu，anisble，docker，k8s 等
YAML：YAML Ain’t Markup Language，即 YAML 不是 XML。不过，在开发的这种语言时，YAML 的意思其实是："Yet Another Markup Language"（仍是一种标记语言）

YAML 官方网站：[The Official YAML Web Site](https://yaml.org/)

#### 4.2.2 YAML 语言特性

- YAML 可读性好
- YAML 和脚本语言的交互性好
- YAML 使用实现语言的数据类型
- YAML 有一个一致的信息模型
- YAML 易于实现
- YAML 可以基于流来处理
- YAML 表达能力强，扩展性好

#### 4.2.3 YAML 语法简介

- 在单一文件第一行，用连续三个连字号“-” 开始，还有选择性的连续三个点号( … )用来表示文件的结尾
- 次行开始正常写 Playbook 的内容，一般建议写明该 Playbook 的功能
- 使用#号注释代码
- 缩进必须是统一的，不能空格和 tab 混用
- 缩进的级别也必须是一致的，同样的缩进代表同样的级别，程序判别配置的级别是通过缩进结合换行来实现的
  YAML 文件内容是区别大小写的，key/value 的值均需大小写敏感
- 多个 key/value 可同行写也可换行写，同行使用 `,` 分隔
- v 可是个字符串，也可是另一个列表
- 一个完整的代码块功能需最少元素需包括 name 和 task
- 一个 name 只能包括一个 task
- YAML 文件扩展名通常为 yml 或 yaml

YAML 的语法和其他高阶语言类似，并且可以简单表达清单、散列表、标量等数据结构。其结构（Structure）通过空格来展示，序列（Sequence）里的项用"-"来代表，Map 里的键值对用":"分隔，下面介绍常见的数据结构。

##### 4.2.3.1 List 列表

列表由多个元素组成，每个元素放在不同行，且元素前均使用“-”打头，或者将所有元素用 [ ] 括起来放在同一行

```yaml
# A list of tasty fruits
- Apple
- Orange
- Strawberry
- Mango

[Apple,Orange,Strawberry,Mango]
```

##### 4.2.3.2 Dictionary 字典

字典由多个 key 与 value 构成，key 和 value 之间用 `: ` 分隔，所有 k/v 可以放在一行，或者每个 k/v 分别放在不同行

```yaml
# An employee record
name: Example Developer
job: Developer
skill: Elite

# 也可以将 key: value 放置于{}中进行表示，用,分隔多个 key: value
# An employee record
{name: "Example Developer",job: "Developer",skill: "Elite"}

# 示例
name: John Smith
age: 41
gender: Male
spouse:
  name: Jane Smith
  age: 37
  gender: Female
children:
  - name: Jimmy Smith
    age: 17
    gender: Male
  - name: Jenny Smith
    age 13
    gender: Female
```

#### 4.2.4 三种常见的数据格式

- **XML**：Extensible Markup Language，可扩展标记语言，可用于数据交换和配置
- **JSON**：JavaScript Object Notation, JavaScript 对象表记法，主要用来数据交换或配置，不支持注释
- **YAML**：YAML Ain’t Markup Language YAML 不是一种标记语言， 主要用来配置，大小写敏感，不支持 tab

![](https://aluopy.github.io/assets/images/ansible-07.png) 

**可以用工具互相转换，参考网站：**

- [https://www.json2yaml.com/](http://www.yunweipai.com/go?_=60bb30fe06aHR0cHM6Ly93d3cuanNvbjJ5YW1sLmNvbS8%3D)

- [http://www.bejson.com/json/json2yaml/](http://www.yunweipai.com/go?_=07b1ecff68aHR0cDovL3d3dy5iZWpzb24uY29tL2pzb24vanNvbjJ5YW1sLw%3D%3D)

### 4.3 Playbook 核心元素

- **Hosts** 执行的远程主机列表；
- **Tasks** 任务集；
- **Variables** 内置变量或自定义变量在 playbook 中调用；
- **Templates** 模板，可替换模板文件中的变量并实现一些简单逻辑的文件；
- **Handlers** 和 **notify** 结合使用，由特定条件触发的操作，满足条件方才执行，否则不执行；
- **tags** 标签，指定某条任务执行，用于选择运行 playbook 中的部分代码。ansible 具有幂等性，因此会自动跳过没有变化的部分，即便如此，有些代码为测试其确实没有发生变化的时间依然会非常地长。此时，如果确信其没有变化，就可以通过 tags 跳过此些代码片断。

#### 4.3.1 hosts 组件

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

#### 4.3.2 remote_user 组件

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

#### 4.3.3 task 列表和 action 组件

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

#### 4.3.4 其它组件

某任务的状态在运行后为 changed 时，可通过 “notify” 通知给相应的 handlers；
任务可以通过 "tags“ 打标签，可在 ansible-playbook 命令上使用 `-t` 指定进行调用。

#### 4.3.5 ShellScripts VS Playbook 案例

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

### 4.4 Playbook 命令

格式：`ansible-playbook <filename.yml> ... [options]`

常见选项：

```shell
-C --check          # 只检测可能会发生的改变，但不真正执行操作
--list-hosts        # 列出运行任务的主机
--list-tags         # 列出 tag
--list-tasks        # 列出 task
--limit HostList    # 只针对主机列表 HostList 中的主机执行
-v -vv  -vvv        # 显示过程
```

示例：

```shell
$ ansible-playbook  file.yml  --check   # 只检测
$ ansible-playbook  file.yml  
$ ansible-playbook  file.yml  --limit websrvs
```

### 4.5 Playbook 初步

#### 4.5.1 利用 playbook 创建 mysql 用户

示例：`mysql_user.yml`

```yaml
---
- hosts: dbsrvs
  remote_user: root
  # 禁止 Ansible 收集 facts 信息
  gather_facts: no

  tasks:
    - {name: create group, group: name=mysql system=yes gid=306}
    - name: create user
      user: name=mysql shell=/sbin/nologin system=yes group=mysql uid=306 home=/data/mysql create_home=no
```

#### 4.5.2 利用 playbook 安装 nginx

示例：`install_nginx.yml`

```yaml
---
- hosts: websrvs
  remote_user: root
  gather_facts: no

  tasks:
    - name: add group nginx
      user: name=nginx state=present
    - name: add user nginx
      user: name=nginx state=present group=nginx
    - name: Install Nginx
      yum: name=nginx state=present
    - name: web page
      copy: src=files/index.html dest=/usr/share/nginx/html/index.html
    - name: Start Nginx
      service: name=nginx state=started enabled=yes
```

#### 4.5.3 利用 playbook 安装和卸载 httpd

示例：`install_httpd.yml`

```yaml
---
- hosts: websrvs
  remote_user: root
  gather_facts: no

  tasks:
    - name: Install httpd
      yum: name=httpd state=present
    - name: Install configure file
      copy: src=files/httpd.conf dest=/etc/httpd/conf/
    - name: web html
      copy: src=files/index.html  dest=/var/www/html/
    - name: start service
      service: name=httpd state=started enabled=yes
```

安装：

```shell
$ ansible-playbook install_httpd.yml --limit 10.0.0.8
```

示例：`remove_httpd.yml`

```yaml
---
- hosts: websrvs
  remote_user: root

  tasks:
    - name: remove httpd package
      yum: name=httpd state=absent
    - name: remove apache user 
      user: name=apache state=absent
    - name: remove config file
      file: name=/etc/httpd  state=absent
    - name: remove web html
      file: name=/var/www/html/index.html state=absent
```

#### 4.5.4 利用 playbook 安装 mysql

安装 mysql-5.6.46-linux-glibc2.12

```shell
$ ls -l /data/ansible/files/mysql-5.6.46-linux-glibc2.12-x86_64.tar.gz 
-rw-r--r-- 1 root root 403177622 Dec  4 13:05 /data/ansible/files/mysql-5.6.46-linux-glibc2.12-x86_64.tar.gz

$ cat /data/ansible/files/my.cnf 
[mysqld]
socket=/tmp/mysql.sock
user=mysql
symbolic-links=0
datadir=/data/mysql
innodb_file_per_table=1
log-bin
pid-file=/data/mysql/mysqld.pid

[client]
port=3306
socket=/tmp/mysql.sock

[mysqld_safe]
log-error=/var/log/mysqld.log

$ cat /data/ansible/files/secure_mysql.sh 
#!/bin/bash
/usr/local/mysql/bin/mysql_secure_installation <<EOF

y
magedu
magedu
y
y
y
y
EOF

$ tree /data/ansible/files/
/data/ansible/files/
├── my.cnf
├── mysql-5.6.46-linux-glibc2.12-x86_64.tar.gz
└── secure_mysql.sh

0 directories, 3 files
```

示例：`install_mysql.yml`

```yaml
---
- hosts: dbsrvs
  remote_user: root
  gather_facts: no

  tasks:
    - name: install packages
      yum: name=libaio,perl-Data-Dumper,perl-Getopt-Long
    - name: create mysql group
      group: name=mysql gid=306 
    - name: create mysql user
      user: name=mysql uid=306 group=mysql shell=/sbin/nologin system=yes create_home=no home=/data/mysql
    - name: copy tar to remote host and file mode 
      unarchive: src=/data/ansible/files/mysql-5.6.46-linux-glibc2.12-x86_64.tar.gz dest=/usr/local/ owner=root group=root 
    - name: create linkfile  /usr/local/mysql 
      file: src=/usr/local/mysql-5.6.46-linux-glibc2.12-x86_64 dest=/usr/local/mysql state=link
    - name: data dir
      shell: chdir=/usr/local/mysql/  ./scripts/mysql_install_db --datadir=/data/mysql --user=mysql
      tags: data
    - name: config my.cnf
      copy: src=/data/ansible/files/my.cnf  dest=/etc/my.cnf 
    - name: service script
      shell: /bin/cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
    - name: enable service
      shell: /etc/init.d/mysqld start;chkconfig --add mysqld;chkconfig mysqld on  
      tags: service
    - name: PATH variable
      copy: content='PATH=/usr/local/mysql/bin:$PATH' dest=/etc/profile.d/mysql.sh
    - name: secure script
      script: /data/ansible/files/secure_mysql.sh
      tags: script
```

示例：`install_mariadb.yml`

```yaml
---
- hosts: dbsrvs
  remote_user: root
  gather_facts: no

  tasks:
    - name: create group
      group: name=mysql gid=27 system=yes
    - name: create user
      user: name=mysql uid=27 system=yes group=mysql shell=/sbin/nologin home=/data/mysql create_home=no
    - name: mkdir datadir
      file: path=/data/mysql owner=mysql group=mysql state=directory
    - name: unarchive package
      unarchive: src=/data/ansible/files/mariadb-10.2.27-linux-x86_64.tar.gz dest=/usr/local/ owner=root group=root
    - name: link
      file: src=/usr/local/mariadb-10.2.27-linux-x86_64 path=/usr/local/mysql state=link 
    - name: install database
      shell: chdir=/usr/local/mysql   ./scripts/mysql_install_db --datadir=/data/mysql --user=mysql
    - name: config file
      copy: src=/data/ansible/files/my.cnf  dest=/etc/ backup=yes
    - name: service script
      shell: /bin/cp  /usr/local/mysql/support-files/mysql.server  /etc/init.d/mysqld
    - name: start service
      service: name=mysqld state=started enabled=yes
    - name: PATH variable
      copy: content='PATH=/usr/local/mysql/bin:$PATH' dest=/etc/profile.d/mysql.sh
```

### 4.6 Playbook 中使用 Handlers 和 notify

Handlers 本质是 task list，类似于 MySQL 中的触发器触发的行为，其中的 task 与前述的 task 并没有本质上的不同，主要用于当关注的资源发生变化时，才会采取一定的操作。而 Notify 对应的 action 可用于在每个 play 的最后被触发，这样可避免多次有改变发生时每次都执行指定的操作，仅在所有的变化发生完成后一次性地执行指定操作。在 notify 中列出的操作成为 handler，也即 notify 中调用 handler 中定义的操作。

案例1：

```yaml
- hosts: websrvs
  remote_user: root

  tasks:
    - name: Install httpd
      yum: name=httpd state=present
    - name: Install configure file
      copy: src=files/httpd.conf dest=/etc/httpd/conf/
      notify: restart httpd
    - name: ensure apache is running
      service: name=httpd state=started enabled=yes
  
  handlers:
    - name: restart httpd
      service: name=httpd state=restarted
```

案例2：

```yaml
- hosts: webnodes
  vars:
    http_port: 80
    max_clients: 256
  remote_user: root
  
  tasks:
    - name: ensure apache is at the latest version
      yum: name=httpd state=latest
    - name: ensure apache is running
      service: name=httpd state=started
    - name: Install configure file
      copy: src=files/httpd.conf dest=/etc/httpd/conf/
      notify: restart httpd
  
  handlers:
      - name: restart httpd 
        service: name=httpd state=restarted
```

案例3：

```yaml
- hosts: websrvs
  remote_user: root
  
  tasks:
    - name: add group nginx
      tags: user
      user: name=nginx state=present
    - name: add user nginx
      user: name=nginx state=present group=nginx
    - name: Install Nginx
      yum: name=nginx state=present
    - name: config
      copy: src=/root/config.txt dest=/etc/nginx/nginx.conf
      notify:
        - Restart Nginx
        - Check Nginx Process
  
  handlers:
    - name: Restart Nginx
      service: name=nginx state=restarted enabled=yes
    - name: Check Nginx process
      shell: killall -0 nginx > /tmp/nginx.log
```

### 4.7 Playbook 中使用 tags 组件

在 playbook 文件中，可以利用 tags 组件为特定的 task 指定标签，当在执行 playbook 时，可以选择只执行特定 tags 的 task ，而非整个 playbook 文件。多个 task 可以使用同一个 tags 。

示例：

```yaml
- hosts: websrvs
  remote_user: root
  gather_facts: no
  
  tasks:
    - name: Install httpd
      yum: name=httpd state=present
      tags: install 
    - name: Install configure file
      copy: src=files/httpd.conf dest=/etc/httpd/conf/
      tags: conf
    - name: start httpd service
      tags: service
      service: name=httpd state=started enabled=yes
```

指定执行 `conf`、`service` 两个 tags 的 task

```shell
$ ansible-playbook –t conf,service httpd.yml
```

### 4.8 Playbook 中使用变量

变量名：仅能由字母、数字和下划线组成，且只能以字母开头。

**变量定义：**`variable=value`

示例：`http_port=80`

**变量调用方式：**通过 `{{ variable_name }}` 调用变量，且变量名前后建议加空格，有时用 `"{{ variable_name }}"` 才生效。

#### 4.8.1 变量来源

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

#### 4.8.2 使用 setup 模块中变量

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

#### 4.8.3 在 playbook 命令行中定义变量

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

#### 4.8.4 在 playbook 文件中定义变量

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

#### 4.8.5使用变量文件

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

#### 4.8.6 主机清单文件中定义变量

##### 4.8.6.1 主机变量

在 inventory 主机清单文件中为指定的主机定义变量以便在 playbook 中使用

示例：

```ini
[websrvs]
www1.magedu.com http_port=80 maxRequestsPerChild=808
www2.magedu.com http_port=8080 maxRequestsPerChild=909
```

上述示例文件中，为主机 *www1.magedu.com* 定义了两个变量：`http_port=80` 和 `maxRequestsPerChild=808`；为主机 *www2.magedu.com* 定义了两个变量：`http_port=8080` 和 `maxRequestsPerChild=909`

##### 4.8.6.2 组（公共）变量

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

##### 综合示例

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

### 4.9 template 模板

模板是一个文本文件，可以做为生成文件的模版，并且模板文件中还可嵌套 jinja 语法

#### 4.9.1 jinja2 语言

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

#### 4.9.2 template

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

#### 4.9.3 template 中使用流程控制 for 和 if

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

### 4.10 Playbook 使用 when

when 语句，可以实现条件测试。如果需要根据变量、facts 或此前任务的执行结果来做为某 task 执行与否的前提时要用到条件测试，通过在 task 后添加 when 子句即可使用条件测试，jinja2 的语法格式

示例1：

```yaml
---
- hosts: websrvs
  remote_user: root
  tasks:
    - name: "shutdown RedHat flavored systems"
      command: /sbin/shutdown -h now
      when: ansible_os_family == "RedHat"
```

示例2：

```yaml
---
- hosts: websrvs
  remote_user: root
  tasks:
    - name: add group nginx
      tags: user
      user: name=nginx state=present
    - name: add user nginx
      user: name=nginx state=present group=nginx
    - name: Install Nginx
      yum: name=nginx state=present
    - name: restart Nginx
      service: name=nginx state=restarted
      when: ansible_distribution_major_version == “6”
```

示例3：

```yaml
---
- hosts: websrvs
  remote_user: root
  tasks: 
    - name: install conf file to centos7
      template: src=nginx.conf.c7.j2 dest=/etc/nginx/nginx.conf
      when: ansible_distribution_major_version == "7"
    - name: install conf file to centos6
      template: src=nginx.conf.c6.j2 dest=/etc/nginx/nginx.conf
      when: ansible_distribution_major_version == "6"
```

### 4.11 Playbook 使用迭代 with_items

迭代：当有需要重复性执行的任务时，可以使用迭代机制
对迭代项的引用，固定变量名为 "`item`"
要在 task 中使用 `with_items` 给定要迭代的元素列表

**列表元素格式：**

- 字符串
- 字典

示例1：循环创建用户

```yaml
---
- hosts: websrvs
  remote_user: root

  tasks:
    - name: add several users
      user: name={{ item }} state=present groups=wheel
      with_items:
        - testuser1
        - testuser2

# 上面语句的功能等同于下面的语句
    - name: add user testuser1
      user: name=testuser1 state=present groups=wheel
    - name: add user testuser2
      user: name=testuser2 state=present groups=wheel
```

示例2：循环删除文件

```yaml
---
# remove mariadb server
- hosts: appsrvs:!192.168.38.8
  remote_user: root

  tasks:
    - name: stop service
      shell: /etc/init.d/mysqld stop
    - name:  delete files and dir
      file: path={{item}} state=absent
      with_items:
        - /usr/local/mysql
        - /usr/local/mariadb-10.2.27-linux-x86_64
        - /etc/init.d/mysqld
        - /etc/profile.d/mysql.sh
        - /etc/my.cnf
        - /data/mysql
    - name: delete user
      user: name=mysql state=absent remove=yes 
```

示例3：循环安装软件

```yaml
---
- hosts：websrvs
  remote_user: root

  tasks
    - name: install some packages
      yum: name={{ item }} state=present
      with_items:
        - nginx
        - memcached
        - php-fpm 
```

示例4：循环拷贝文件及安装软件

```yaml
---
- hosts: websrvs
  remote_user: root
  tasks:
    - name: copy file
      copy: src={{ item }} dest=/tmp/{{ item }}
      with_items:
        - file1
        - file2
        - file3
    - name: yum install httpd
      yum: name={{ item }}  state=present 
      with_items:
        - apr
        - apr-util
        - httpd
```

**迭代嵌套子变量：**在迭代中，还可以嵌套子变量，关联多个变量在一起使用

示例1：

```yaml
---
- hosts: websrvs
  remote_user: root

  tasks:
    - name: add some groups
      group: name={{ item }} state=present
      with_items:
        - nginx
        - mysql
        - apache
    - name: add some users
      user: name={{ item.name }} group={{ item.group }} state=present
      with_items:
        - { name: 'nginx', group: 'nginx' }
        - { name: 'mysql', group: 'mysql' }
        - { name: 'apache', group: 'apache' }
```

示例2：

```yaml
---
- hosts: websrvs
  remote_user: root

  tasks:
    - name: add some groups
      group: name={{ item }} state=present
      with_items:
        - g1
        - g2
        - g3
    - name: add some users
      user: name={{ item.name }} group={{ item.group }} home={{ item.home }} create_home=yes state=present
      with_items:
        - { name: 'user1', group: 'g1', home: '/data/user1' }
        - { name: 'user2', group: 'g2', home: '/data/user2' }
        - { name: 'user3', group: 'g3', home: '/data/user3' }
```

## 5. Roles 角色

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

### 5.1 Ansible Roles 目录编排

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

### 5.2 创建 role

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

### 5.3 Playbook 调用角色

**调用角色方法1：**

```yaml
---
- hosts: websrvs
  remote_user: root
  roles:
    - mysql
    - memcached
    - nginx   
```

**调用角色方法2：**

键 role 用于指定角色名称，后续的 k/v 用于传递变量给角色

```yaml
---
- hosts: all
  remote_user: root
  roles:
    - mysql
    - { role: nginx, username: nginx }
```

**调用角色方法3：**

还可基于条件测试实现角色调用

```yaml
---
- hosts: all
  remote_user: root
  roles:
    - { role: nginx, username: nginx, when: ansible_distribution_major_version == ‘7’  }
```

### 5.4 roles 中 tags 使用

示例：

```shell
$ cat nginx-role.yml
# nginx-role.yml
---
- hosts: websrvs
  remote_user: root
  roles:
    - { role: nginx ,tags: [ 'nginx', 'web' ] ,when: ansible_distribution_major_version == "6“ }
    - { role: httpd ,tags: [ 'httpd', 'web' ]  }
    - { role: mysql ,tags: [ 'mysql', 'db' ] }
    - { role: mariadb ,tags: [ 'mariadb', 'db' ] }
    

$ ansible-playbook --tags="nginx,httpd,mysql" nginx-role.yml
```

### 5.5 实战案例

#### 5.5.1 案例1: 实现 httpd 角色

```shell
# 创建角色相关的目录
$ mkdir -pv /data/ansible/roles/httpd/{tasks,handlers,files}

# 创建角色相关的文件
$ cd /data/ansible/roles/httpd/

$ vim tasks/main.yml
- include: group.yml
- include: user.yml
- include: install.yml
- include: config.yml
- include: index.yml
- include: service.yml

$ vim  tasks/user.yml
- name: create apache user
  user: name=apache system=yes shell=/sbin/nologin home=/var/www/ uid=80 group=apache

$ vim  tasks/group.yml
- name: create apache group
  group: name=apache system=yes gid=80

$ vim tasks/install.yml
- name: install httpd package
  yum: name=httpd

$ vim tasks/config.yml
- name: config file
  copy: src=httpd.conf dest=/etc/httpd/conf/ backup=yes
  notify: restart

$ vim tasks/index.yml
- name: index.html
  copy: src=index.html dest=/var/www/html/

$ vim tasks/service.yml
- name: start service
  service: name=httpd state=started enabled=yes

$ vim handlers/main.yml
- name: restart
  service: name=httpd state=restarted

# 在 files 目录下准备两个文件
$ ls files/
httpd.conf index.html

$ tree /data/ansible/roles/httpd/
/data/ansible/roles/httpd/
├── files
│   ├── httpd.conf
│   └── index.html
├── handlers
│   └── main.yml
└── tasks
    ├── config.yml
    ├── group.yml
    ├── index.yml
    ├── install.yml
    ├── main.yml
    ├── service.yml
    └── user.yml

3 directories, 10 files

# 在 playbook 中调用角色
$ vim  /data/ansible/role_httpd.yml
---
# httpd role
- hosts: websrvs
  remote_user: root

  roles:
    - httpd

# 运行playbook
$ ansible-playbook  /data/ansible/role_httpd.yml
```

#### 5.5.2 案例2: 实现 nginx 角色

```shell
$ mkdir -pv  /data/ansible/roles/nginx/{tasks,handlers,templates,vars}

# 创建 task文件
$ cd /data/ansible/roles/nginx/

$ vim tasks/main.yml 
- include: install.yml
- include: config.yml
- include: index.yml
- include: service.yml

$ vim  tasks/install.yml 
- name: install
  yum: name=nginx 

$ vim tasks/config.yml 
- name: config file for centos7
  template: src=nginx7.conf.j2 dest=/etc/nginx/nginx.conf
  when: ansible_distribution_major_version=="7"
  notify: restart
- name: config file for centos8
  template: src=nginx8.conf.j2 dest=/etc/nginx/nginx.conf
  when: ansible_distribution_major_version=="8"
  notify: restart

$ vim  tasks/index.yml 
- name: index.html
  copy: src=roles/httpd/files/index.html dest=/usr/share/nginx/html/

$ vim tasks/service.yml 
- name: start service
  service: name=nginx state=started enabled=yes

# 创建 handler 文件
$ cat handlers/main.yml 
- name: restart
  service: name=nginx state=restarted

# 创建两个 template 文件
$ cat templates/nginx7.conf.j2
...省略...
user {{user}};
worker_processes {{ansible_processor_vcpus+3}};   # 修改此行
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
...省略...

$ cat templates/nginx8.conf.j2
...省略...
user nginx;
worker_processes {{ansible_processor_vcpus**3}};  # 修改此行
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
...省略...

# 创建变量文件
$ vim vars/main.yml 
user: daemon

# 目录结构如下
$ tree /data/ansible/roles/nginx/
/data/ansible/roles/nginx/
├── handlers
│   └── main.yml
├── tasks
│   ├── config.yml
│   ├── file.yml
│   ├── install.yml
│   ├── main.yml
│   └── service.yml
├── templates
│   ├── nginx7.conf.j2
│   └── nginx8.conf.j2
└── vars
    └── main.yml

4 directories, 9 files

# 在 playbook 中调用角色
$ vim /data/ansible/role_nginx.yml 
---
# nginx role 
- hosts: websrvs

  roles:
    - role: nginx

# 运行 playbook
$ ansible-playbook  /data/ansible/role_nginx.yml
```

#### 5.5.3 案例3: 实现 memcached 角色

```shell
$ mkdir -pv  /data/ansible/roles/memcached/{tasks,templates}

$ cd /data/ansible/roles/memcached
$ vim tasks/main.yml 
- include: install.yml
- include: config.yml
- include: service.yml

$ vim tasks/install.yml 
- name: install
  yum: name=memcached

$ vim tasks/config.yml 
- name: config file
  template: src=memcached.j2  dest=/etc/sysconfig/memcached

$ vim tasks/service.yml 
- name: service
  service: name=memcached state=started enabled=yes

$ vim templates/memcached.j2 
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="{{ansible_memtotal_mb//4}}"
OPTIONS=""

$ tree /data/ansible/roles/memcached/
/data/ansible/roles/memcached/
├── tasks
│   ├── config.yml
│   ├── install.yml
│   ├── main.yml
│   └── service.yml
└── templates
    └── memcached.j2

2 directories, 5 files

$ vim /data/ansible/role_memcached.yml 
---
- hosts: appsrvs

  roles:
    - role: memcached

$ ansible-play /data/ansible/role_memcached.yml
```

#### 5.5.4 案例4: 实现 mysql 角色

```shell
$ cat /data/ansible/roles/mysql/files/my.cnf 
[mysqld]
socket=/tmp/mysql.sock
user=mysql
symbolic-links=0
datadir=/data/mysql
innodb_file_per_table=1
log-bin
pid-file=/data/mysql/mysqld.pid

[client]
port=3306
socket=/tmp/mysql.sock

[mysqld_safe]
log-error=/var/log/mysqld.log

$ cat /data/ansible/roles/mysql/files/secure_mysql.sh 
#!/bin/bash
/usr/local/mysql/bin/mysql_secure_installation <<EOF

y
magedu
magedu
y
y
y
y
EOF

$ chmod +x  /data/ansible/roles/mysql/files/secure_mysql.sh

$ ls /data/ansible/roles/mysql/files/
my.cnf  mysql-5.6.46-linux-glibc2.12-x86_64.tar.gz  secure_mysql.sh

$ cat /data/ansible/roles/mysql/tasks/main.yml
- include: install.yml
- include: group.yml
- include: user.yml
- include: unarchive.yml
- include: link.yml
- include: data.yml
- include: config.yml
- include: service.yml
- include: path.yml
- include: secure.yml

$ cat /data/ansible/roles/mysql/tasks/install.yml 
- name: install packages                                            
  yum: name=libaio,perl-Data-Dumper,perl-Getopt-Long
$ cat /data/ansible/roles/mysql/tasks/group.yml 
- name: create mysql group
  group: name=mysql gid=306
$ cat /data/ansible/roles/mysql/tasks/user.yml 
- name: create mysql user
  user: name=mysql uid=306 group=mysql shell=/sbin/nologin system=yes create_home=no home=/data/mysql
$ cat /data/ansible/roles/mysql/tasks/unarchive.yml 
- name: copy tar to remote host and file mode 
  unarchive: src=mysql-5.6.46-linux-glibc2.12-x86_64.tar.gz dest=/usr/local/ owner=root group=root
$ cat /data/ansible/roles/mysql/tasks/link.yml 
- name: mkdir /usr/local/mysql 
  file: src=/usr/local/mysql-5.6.46-linux-glibc2.12-x86_64 dest=/usr/local/mysql state=link
$ cat /data/ansible/roles/mysql/tasks/data.yml 
- name: data dir
  shell: chdir=/usr/local/mysql/  ./scripts/mysql_install_db --datadir=/data/mysql --user=mysql
$ cat /data/ansible/roles/mysql/tasks/config.yml 
- name: config my.cnf
  copy: src=my.cnf  dest=/etc/my.cnf 
$ cat /data/ansible/roles/mysql/tasks/service.yml 
- name: service script
  shell: /bin/cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld;chkconfig --add mysqld;chkconfig mysqld on;/etc/init.d/mysqld start

$ cat /data/ansible/roles/mysql/tasks/path.yml 
- name: PATH variable
  copy: content='PATH=/usr/local/mysql/bin:$PATH' dest=/etc/profile.d/mysql.sh  

$ cat /data/ansible/roles/mysql/tasks/secure.yml 
- name: secure script
  script: secure_mysql.sh

$ tree /data/ansible/roles/mysql/
/data/ansible/roles/mysql/
├── files
│   ├── my.cnf
│   ├── mysql-5.6.46-linux-glibc2.12-x86_64.tar.gz
│   └── secure_mysql.sh
└── tasks
    ├── config.yml
    ├── data.yml
    ├── group.yml
    ├── install.yml
    ├── link.yml
    ├── main.yml
    ├── path.yml
    ├── secure.yml
    ├── service.yml
    ├── unarchive.yml
    └── user.yml

2 directories, 14 files

$ cat /data/ansible/mysql_roles.yml
- hosts: dbsrvs
  remote_user: root

  roles:
    - {role: mysql,tags: ["mysql","db"]}
    - {role: nginx,tage: ["nginx","web"]}

$ ansible-playbook -t mysql /data/ansible/mysql_roles.yml
```

#### 5.5.5 案例5: 实现多角色的选择

```shell
$ vim /data/ansible/role_httpd_nginx.yml 
---
- hosts: websrvs

  roles:
    - {role: httpd,tags: [httpd,web], when: ansible_distribution_major_version=="7" }
    - {role: nginx,tags: [nginx,web], when: ansible_distribution_major_version=="8" }

$ ansible-playbook -t nginx /data/ansible/role_httpd_nginx.yml 
```

## 6. Ansible 推荐学习资料

- [ansible/ansible (github.com)](https://github.com/ansible/ansible)
- [ansible/ansible-examples (github.com)](https://github.com/ansible/ansible-examples)
- [Ansible Documentation](https://docs.ansible.com/)
- [User Guide — Ansible Documentation](https://docs.ansible.com/ansible/2.9/user_guide/index.html#)
- [Ansible 中文权威指南 (ansible.com.cn)](http://www.ansible.com.cn/index.html)
- [Ansible Galaxy](https://galaxy.ansible.com/)
- [ansible/galaxy (github.com)](https://github.com/ansible/galaxy)
- [Ansible Automation for SysAdmins \| Opensource.com](https://opensource.com/downloads/ansible-quickstart?extIdCarryOver=true&sc_cid=701f2000001OH7YAAW)
- [A system administrator's guide to getting started with Ansible - FAST! (redhat.com)](https://www.redhat.com/en/blog/system-administrators-guide-getting-started-ansible-fast?extIdCarryOver=true&sc_cid=701f2000001OH7YAAW)

## 7. Troubleshooting

### 7.1 Ansible 节点过多超时解决方法

Ansible 管理的节点过多导致的超时问题解决方法：默认情况下，Ansible 将尝试并行管理 playbook 中所有的机器。对于滚动更新用例，可以使用 serial 关键字定义 Ansible 一次应管理多少主机，还可以将 serial 关键字指定为百分比，表示每次并行执行的主机数占总数的比例。

示例：

```yaml
# vim test_serial.yml
---
- hosts: all
  serial: 2  # 每次只同时处理2个主机
  gather_facts: False

  tasks:
    - name: task one
      comand: hostname
    - name: task two
      command: hostname
```

示例：

```yaml
- name: test serail
  hosts: all
  serial: "20%"  # 每次只同时处理20%的主机
```
