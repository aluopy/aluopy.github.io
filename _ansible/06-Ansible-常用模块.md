---
title: "Ansible 常用模块"
permalink: /ansible/common-module/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---

2015年底270多个模块，2016年达到540个，2018年01月12日有1378个模块，2018年07月15日1852个模块，2019年05月25日（ansible 2.7.10）时2080个模块，2020年03月02日有3387个模块。

虽然模块众多，但最常用的模块也就二三十个而已，针对特定业务只用十几个模块。

模块帮助文档：[Index of all Modules — Ansible Documentation](https://docs.ansible.com/ansible/latest/collections/index_module.html)

## Command 模块

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

## Shell 模块

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

## Script 模块

功能：在远程主机上运行 ansible 服务器上的脚本

范例：

```shell
$ ansible websrvs  -m script -a /data/test.sh
```

## Copy 模块

功能：从 ansible 服务器主控端复制文件到远程主机

```shell
# 如目标存在，默认覆盖，此处指定先备份
$ ansible websrvs -m copy -a "src=/root/test1.sh dest=/tmp/test2.sh owner=wang mode=600 backup=yes"
# 指定内容，直接生成目标文件，如果目标文件存在则直接覆盖其内容
$ ansible websrvs -m copy -a "content='aluopy https://aluopy.cn\nhallo aluopy\n' dest=/tmp/test.txt"
# 复制 /etc/ 下的文件，不包括 /etc/ 目录自身
$ ansible websrvs -m copy -a "src=/etc/ dest=/backup"
```

## Fetch 模块

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

## File 模块

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

## unarchive 模块

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

## Archive 模块

打包压缩

```shell
# path: 源路径，需要打包的文件
# dest: 压缩成什么格式的包，放到什么位置
# owner: 属主
# mode: 包文件权限
$ ansible websrvs -m archive  -a 'path=/var/log/ dest=/data/log.tar.bz2 format=bz2 owner=wang mode=0600'
```

## Hostname 模块

管理主机名

```shell
$ ansible node1 -m hostname -a “name=websrv” 
$ ansible 192.168.100.18 -m hostname -a 'name=node18.magedu.com'
```

## Cron 模块

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

## Yum 模块

管理软件包，只支持 RHEL，CentOS，fedora，不支持 Ubuntu 及其它版本

```shell
# 安装
$ ansible websrvs -m yum -a 'name=httpd state=present'
# 删除
$ ansible websrvs -m yum -a 'name=httpd state=absent'
```

## Service 模块

管理服务

```shell
$ ansible all -m service -a 'name=httpd state=started enabled=yes'
$ ansible all -m service -a 'name=httpd state=stopped'
$ ansible all -m service -a 'name=httpd state=reloaded’
$ ansible all -m shell -a "sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf"
$ ansible all -m service -a 'name=httpd state=restarted' 
```

## User 模块

管理用户

```shell
# 创建用户
$ ansible all -m user -a 'name=user1 comment=“test user” uid=2048 home=/app/user1 group=root'
$ ansible all -m user -a 'name=nginx comment=nginx uid=88 group=nginx groups="root,daemon" shell=/sbin/nologin system=yes create_home=no home=/data/nginx non_unique=yes'

# 删除用户及家目录等数据
$ ansible all -m user -a 'name=nginx state=absent remove=yes'
```

## Group 模块

管理组

```shell
# 创建组
$ ansible websrvs -m group  -a 'name=nginx gid=88 system=yes'
# 删除组
$ ansible websrvs -m group  -a 'name=nginx state=absent'
```

## Lineinfile 模块

ansible 在使用 sed 进行替换时，经常会遇到需要转义的问题，而且 ansible 在遇到特殊符号进行替换时，存在问题，无法正常进行替换 。其实 ansible 自身提供了两个模块：lineinfile 模块和 replace 模块，可以方便的进行替换，相当于sed，可以修改文件内容。

```shell
$ ansible all -m lineinfile -a "path=/etc/selinux/config regexp='^SELINUX=' line='SELINUX=enforcing'"
$ ansible all -m lineinfile -a 'dest=/etc/fstab state=absent regexp="^#"'
```

## Replace 模块

该模块有点类似于 sed 命令，主要也是基于正则进行匹配和替换

```shell
$ ansible all -m replace -a "path=/etc/fstab regexp='^(UUID.*)' replace='#\1'"  
$ ansible all -m replace -a "path=/etc/fstab regexp='^#(.*)' replace='\1'"
```

## Setup 模块

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
