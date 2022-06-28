---
title: "Playbook 初步"
permalink: /ansible/playbook-basics/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---



## 利用 playbook 创建 mysql 用户

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

## 利用 playbook 安装 nginx

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

## 利用 playbook 安装和卸载 httpd

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

## 利用 playbook 安装 mysql

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

