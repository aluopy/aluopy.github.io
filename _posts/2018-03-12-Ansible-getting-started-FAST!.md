---
title: "Ansible-getting-started-FAST!"
toc: true
categories: ansible
tags:
  - ansible
  - redhat
---

## 概述

红帽 Ansible 自动化是一种无代理的人类可读自动化工具，它使用 SSH 在平面或多层环境中协调配置管理、应用程序部署和供应。它基于开源的 Ansible 技术，该技术已成为世界上最流行的开源 IT 自动化技术之一。

这篇博文将帮助您了解 Ansible 的基础知识，以及如何在您作为系统管理员的角色中使用它来更有效地管理您的系统。

**ProTip:**  详细文档请查看：[Ansible Automation (aluopy.cn)](https://aluopy.cn/ansible/ansible-automation/)✨
{: .notice--info}

在开始之前，我们需要定义一些术语：

**Control node：**您使用 Ansible 在托管节点上执行任务的主机

**Managed node：**由控制节点配置的主机

**Host inventory：**受管节点列表

**Ad-hoc command：**一个简单的一次性任务

**Playbook：**一组可重复的任务，用于更复杂的配置

**Module：**执行特定常见任务的代码，例如添加用户、安装包等

**Idempotency：**一个操作是幂等的，如果执行一次的结果与重复执行的结果完全相同，没有任何干预动作

## 环境

本文中的环境由一个控制节点 (vm1) 和四个受管节点 (vm2、vm3、vm4、vm5) 组成，它们都在虚拟环境中运行，并安装了最小的 Red Hat Enterprise Linux 7.4。为简单起见，控制节点在 `/etc/hosts` 文件中有以下条目：

```
192.168.102.211 vm1 vm1.redhat.lab
192.168.102.212 vm2 vm2.redhat.lab
192.168.102.213 vm3 vm3.redhat.lab
192.168.102.214 vm4 vm4.redhat.lab
192.168.102.215 vm5 vm5.redhat.lab
```

为了便于使用，我将在此演示中为我的系统用户提供无密码 sudo，您的安全策略可能会有所不同，并且 Ansible 可以处理各种权限提升用例。此用户帐户已通过 /etc/sudoers 文件中的以下条目配置为特权升级：

```
%wheel ALL=(ALL) NOPASSWD: ALL
```

最后，为从控制节点到每个受管节点的这个用户帐户配置和测试 SSH 公钥认证。

```shell
# 为 ssh 生成认证密钥
$ ssh-keygen -f ~/.ssh/id_rsa -N ''
# 把本地的 ssh 公钥文件安装到受管节点对应的账户下
$ for i in vm2 vm3 vm4 vm5;do ssh-copy-id $i;done
# 测试登录
... 
```

## 安装

配置 **EPEL**（Extra Packages for Enterprise Linux） repository，安装 ansible

```shell
$ wget -O /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo
$ yum clean all
$ yum makecache
$ yum install -y ansible
```

安装完成后检查版本

```shell
$ ansible --version
ansible 2.4.1.0
 config file = /etc/ansible/ansible.cfg
 configured module search path = [u'/home/curtis/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
 ansible python module location = /usr/lib/python2.7/site-packages/ansible
 executable location = /bin/ansible
 python version = 2.7.5 (default, May 3 2017, 07:55:04) [GCC 4.8.5 20150623 (Red Hat 4.8.5-14)]
```

请注意默认配置文件，python 是必需的，并且出现在我们最小的 Red Hat Enterprise Linux 7.4 安装中。

## 配置

由于我们已经为受管节点配置了用户帐户、权限提升和 SSH 公钥认证，我们将继续配置控制节点。

控制节点的配置由 Ansible 配置文件和主机清单文件组成。

### 配置文件

正如我们刚刚发现的，默认配置文件是 `/etc/ansible/ansible.cfg`

您可以修改此全局配置文件或制作特定目录的副本。配置文件的位置顺序（查找优先级）如下：

- 环境变量 `ANSIBLE_CONFIG` 指定的配置文件

- 当前目录下的 `ansible.cfg` 文件

- 当前用户家目录下的 `~/ansible.cfg` 文件

- `/etc/ansible/ansible.cfg` 文件

在这篇文章中，我将使用之前添加的用户帐户主目录中的最小配置文件：

```shell
$ cat ~/ansible.cfg
[defaults]
inventory = $HOME/hosts
```

### Host inventory

默认主机清单文件是 `/etc/ansible/hosts` 但可以通过配置文件（如上所示）或使用 ansible 命令上的 `-i` 选项进行更改。我们将使用一个简单的静态清单文件。动态库存也是可能的，但超出了本文的范围。

我们的主机清单文件如下：

```ini
[webservers]
vm2
vm3

[dbservers]
vm4

[logservers]
vm5

[lamp:children]
webservers
dbservers
```

我们定义了四个组：vm2 和 vm3 上的 webservers，vm4 上的 dbservers，vm5 上的 logservers 和由 webservers 和 dbservers 组组成的 lamp。

让我们确认可以使用此配置文件定位所有主机：

```shell
$ ansible all --list-hosts
  hosts (4):
    vm5
    vm2
    vm3
    vm4
```

对于单个组也是如此，例如 webservers 组：

```shell
$ ansible webservers --list-hosts
  hosts (2):
    vm2
    vm3
```

现在我们已经验证了我们的主机清单，让我们快速检查一下以确保我们所有的主机都已启动并运行。我们将使用一个使用 ping 模块的临时命令来执行此操作：

```shell
$ ansible all -m ping
vm5 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
vm3 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
vm4 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
vm2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```

从上面的输出我们可以看出，所有系统都返回了成功的结果，没有任何变化，每次“ping”的结果都是“pong”。

您可以使用以下方法获取可用模块的列表：

```shell
$ ansible-doc -l
```

随着每个 Ansible 版本的发布，内置模块的数量不断增加：

```shell
$ ansible-doc -l | wc -l
1378
```

我们环境中的最终设置任务是使用 Apache 和 Red Hat Enterprise Linux 7 yum 存储库配置 vm1，以便受管节点安装其他软件包：

```shell
$ yum install -y httpd
$ systemctl enable httpd
$ systemctl start httpd
$ mkdir /media/iso
$ mount -o loop /root/rhel-server-7.4-x86_64-dvd.iso /media/iso
$ ln -s /media/iso /var/www/html/rhel7
```

## Ready, set, Ansible!

现在我们已经配置好环境并准备好了，让我们用 Ansible 做一些实际的工作。

由于托管节点需要安装一些额外的软件包，我们的第一个任务是使用此配置文件在每个主机上配置一个 yum 存储库：

```shell
$ cat dvd.repo
[RHEL7]
name = RHEL 7
baseurl = http://vm1/rhel7/
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
enabled = 1
gpgcheck = 1
```

我们可以使用带有 `-m` 选项的 `copy` 模块的 `ad-hoc` 命令将此文件复制到每个托管节点，并使用 `-a` 选项指定所需的参数，如下所示：

```shell
$ ansible all -m copy -a 'src=dvd.repo dest=/etc/yum.repos.d owner=root group=root mode=0644' -b
vm5 | SUCCESS => {
   "changed": true, 
   "checksum": "c15fdb5c1183f360ce29a1274c5f69e4e43060f5", 
   "dest": "/etc/yum.repos.d/dvd.repo", 
   "failed": false, 
   "gid": 0, 
   "group": "root", 
   "md5sum": "db5a5da08d1c4be953cd0ae6625d8358", 
   "mode": "0644", 
   "owner": "root", 
   "secontext": "system_u:object_r:system_conf_t:s0", 
   "size": 135, 
   "src": "/home/curtis/.ansible/tmp/ansible-tmp-1516898124.58-210025572567032/source", 
   "state": "file", 
   "uid": 0
}

[...]
```

为简洁起见，已删除其余主机的其他输出。

在这一点上，有几点值得注意：

1. 每个节点报告 SUCCESS 和 "changed" ： true 表示模块执行成功并且文件已创建/更改。如果我们再次运行该命令，输出将包括 "changed" : false 表示文件已经存在并根据需要进行了配置。换句话说，Ansible 只会在它们尚不存在的情况下进行所需的更改。这就是所谓的“幂等性”。
2. `-b` 选项（参见 http://docs.ansible.com/ansible/latest/become.html）使远程任务使用权限提升（即 sudo），这是将文件复制到 /etc/yum.repos.d 目录所必需的。
3. 您可以使用以下命令找出复制模块需要哪些参数：`ansible-doc copy`

## Playbooks

虽然 ad-hoc 命令对于测试和简单的一次性任务很有用，但 playbook 可用于捕获一组可重复的任务以在未来运行。剧本包含一个或多个剧本，这些剧本定义了一组要配置的主机和要执行的任务列表。

在我们的场景中，我们需要配置 Web 服务器、数据库服务器和集中式日志服务器。具体要求如下：

1. httpd 软件包安装在 Web 服务器上，启用并启动
2. 每个 Web 服务器都有一个默认页面，其中包含文本“Welcome to <hostname> on <ip address>”
3. 每个 Web 服务器都有一个用户帐户，具有适合内容管理的访问权限
4. MariaDB 包安装在数据库服务器上，启用并启动
5. 日志服务器主机配置为接受远程日志消息
6. webservers 和 dbservers 组中的主机将日志消息的副本发送到日志服务器主机

下面的剧本（myplaybook.yml）将配置我们需要的一切。

在查看剧本时，请注意以下几点：

1. 用户模块需要明文密码的哈希值（有关详细信息，请参阅“ansible-doc 用户”）。这可以通过以下方式实现

   ```shell
   $ python -c "from passlib.hash import sha512_crypt; import getpass; print sha512_crypt.encrypt(getpass.getpass())" Password: $6$rounds=656000$bp7zTIl.nar2WQPS$U5CBB15GHnzBqnhY0r7UX65FrBI6w/w9YcAL2kN9PpDaYQIDY6Bi.CAEL6PRRKUqe2bJYgsayyh9NOP1kUy4w.
   ```

2. 默认网页内容是使用从主机收集的“事实”创建的。您可以使用设置模块发现和使用主机事实：

   ```bash
   $ ansible vm2 -m setup
   
   ---
   - hosts: webservers
    become: yes
    tasks:
      - name: install Apache server
        yum:
          name: httpd
          state: latest
   
      - name: enable and start Apache server
        service:
          name: httpd
          enabled: yes
          state: started
   
      - name: open firewall port
        firewalld:
          service: http
          immediate: true
          permanent: true
          state: enabled
   
      - name: create web admin group
        group:
          name: web
          state: present
   
      - name: create web admin user
        user:
          name: webadm
          comment: "Web Admin"
          password: $6$rounds=656000$bp7zTIl.nar2WQPS$U5CBB15GHnzBqnhY0r7UX65FrBI6w/w9YcAL2kN9PpDaYQIDY6Bi.CAEL6PRRKUqe2bJYgsayyh9NOP1kUy4w.
          groups: web
          append: yes
   
      - name: set content directory group/permissions 
        file:
          path: /var/www/html
          owner: root
          group: web
          state: directory
          mode: u=rwx,g=rwx,o=rx,g+s
   
      - name: create default page content
        copy:
          content: "Welcome to {{ ansible_fqdn}} on {{ ansible_default_ipv4.address }}"
          dest: /var/www/html/index.html
          owner: webadm
          group: web
          mode: u=rw,g=rw,o=r
   
   - hosts: dbservers
    become: yes
    tasks:
      - name: install MariaDB server
        yum:
          name: mariadb-server
          state: latest
   
      - name: enable and start MariaDB server
        service:
          name: mariadb
          enabled: yes
          state: started
   
   - hosts: logservers
    become: yes
    tasks:
      - name: configure rsyslog remote log reception over udp
        lineinfile:
          path: /etc/rsyslog.conf
          line: "{{ item }}"
          state: present
        with_items:
          - '$ModLoad imudp'
          - '$UDPServerRun 514'
        notify:
          - restart rsyslogd
   
      - name: open firewall port
        firewalld:
          port: 514/udp
          immediate: true
          permanent: true
          state: enabled
   
    handlers:
      - name: restart rsyslogd
        service:
          name: rsyslog
          state: restarted
   
   - hosts: lamp
    become: yes
    tasks:
      - name: configure rsyslog
        lineinfile:
          path: /etc/rsyslog.conf
          line: '*.* @192.168.102.215:514'
          state: present
        notify:
          - restart rsyslogd
   
    handlers:
      - name: restart rsyslogd
        service:
          name: rsyslog
          state: restarted
   ```

### 运行 playbook

我们的剧本可以使用：

```shell
$ ansible-playbook myplaybook.yml
```

从下面的输出中，我们可以看到 web 服务器配置只发生在 vm2 和 vm3（play 1）上，而数据库安装在 vm4（play 2）上，日志服务器（vm5）配置了play 3。最后，play 4通过“lamp”组配置 webservers 和 dbservers 主机以进行远程日志记录。

```
PLAY [webservers] *********************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [vm2]
ok: [vm3]

TASK [install Apache server] **********************************************************
changed: [vm3]
changed: [vm2]

TASK [enable and start Apache server] *************************************************
changed: [vm2]
changed: [vm3]

TASK [open firewall port] *************************************************************
changed: [vm2]
changed: [vm3]

TASK [create web admin group] *********************************************************
changed: [vm3]
changed: [vm2]

TASK [create web admin user] **********************************************************
changed: [vm3]
changed: [vm2]

TASK [set content directory group/permissions] ****************************************
changed: [vm3]
changed: [vm2]

TASK [create default page content] ****************************************************
changed: [vm3]
changed: [vm2]

PLAY [dbservers] **********************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [vm4]

TASK [install MariaDB server] *********************************************************
changed: [vm4]

TASK [enable and start MariaDB server] ************************************************
changed: [vm4]

PLAY [logservers] *********************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [vm5]

TASK [configure rsyslog remote log reception over udp] ********************************
changed: [vm5] => (item=$ModLoad imudp)
changed: [vm5] => (item=$UDPServerRun 514)

TASK [open firewall port] *************************************************************
changed: [vm5]

RUNNING HANDLER [restart rsyslogd] ****************************************************
changed: [vm5]

PLAY [lamp] ***************************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [vm3]
ok: [vm2]
ok: [vm4]

TASK [configure rsyslog] **************************************************************
changed: [vm2]
changed: [vm3]
changed: [vm4]

RUNNING HANDLER [restart rsyslogd] ****************************************************
changed: [vm3]
changed: [vm2]
changed: [vm4]

PLAY RECAP ****************************************************************************
vm2                        : ok=11 changed=9 unreachable=0    failed=0 
vm3                        : ok=11 changed=9 unreachable=0    failed=0 
vm4                        : ok=6 changed=4 unreachable=0    failed=0 
vm5                        : ok=4 changed=3 unreachable=0    failed=0 
```

你完成了！

您可以使用以下方法验证网络服务器主机：

```shell
$ curl http://vm2
Welcome to vm2 on 192.168.102.212
$ curl http://vm3
Welcome to vm3 on 192.168.102.213 
```

并在 webservers 和 dbservers 主机上使用 logger 命令进行远程日志记录：

```shell
$ ansible lamp -m command -a 'logger hurray it works'
vm3 | SUCCESS | rc=0 >>

vm4 | SUCCESS | rc=0 >>

vm2 | SUCCESS | rc=0 >>
```

在中央日志服务器上确认：

```shell
$ ansible logservers -m command -a "grep 'hurray it works$' /var/log/messages" -b
vm5 | SUCCESS | rc=0 >>
Jan 30 13:28:29 vm3 curtis: hurray it works
Jan 30 13:28:29 vm2 curtis: hurray it works
Jan 30 13:28:29 vm4 curtis: hurray it works
```

## Tips & tricks

**如果您是 YAML 新手，一开始语法可能会很棘手，尤其是空格（没有制表符）。**

在运行剧本之前，您可以使用以下命令检查语法：

```shell
$ ansible-playbook --syntax-check myplaybook.yml
```

使用带有语法高亮的 vim 不仅有助于学习 yaml，而且有助于发现语法问题。为 yaml 语法启用 vim 的一种快速方法是将以下行添加到您的 ~/.vimrc 文件中：

```
autocmd Filetype yaml setlocal tabstop=2 ai colorcolumn=1,3,5,7,9,80
```

如果您想要具有更多功能（包括颜色）的东西，可以在[这里](https://github.com/pearofducks/ansible-vim)找到这样的插件。

如果您更喜欢使用 emacs 而不是 vim，请启用 [EPEL](https://docs.fedoraproject.org/en-US/epel/) 存储库并安装 emacs-yaml-mode 包。

**您可以在不实际对目标主机进行任何更改的情况下测试剧本：**

```shell
$ ansible-playbook --check myplaybook.yml
```

逐步浏览剧本也可能很有用：

```shell
$ ansible-playbook --step myplaybook.yml
```

**与 shell 脚本类似，您可以使 Ansible playbook 可执行并将以下内容添加到文件顶部：**

```shell
#!/bin/ansible-playbook
```

**要执行任意 ad-hoc shell 命令，请使用命令模块（如果未指定 -m，则为默认模块）。如果您需要使用重定向、管道等，请改用 shell 模块。**

**通过检查特定模块文档中的“示例：”部分来加快编写剧本。**

**在剧本中使用字符串引用来避免字符串中的特殊字符出现问题。**

**默认情况下禁用日志记录。要启用日志记录，请使用 Ansible 配置文件中的 log_path 参数。**

我希望这篇文章能让您更好地了解 Ansible 的工作原理，以及它如何使用剧本轻松准确地记录和重复日常任务，从而节省您的时间和精力。请务必在 http://docs.ansible.com 和 https://www.redhat.com/en/technologies/management/ansible 继续学习。

自动化快乐！

## 原文链接

- [A system administrator's guide to getting started with Ansible - FAST! (redhat.com)](https://www.redhat.com/en/blog/system-administrators-guide-getting-started-ansible-fast?)

