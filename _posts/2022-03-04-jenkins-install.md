---
title: "Jenkins Install"
toc: false
toc_label: "Jenkins Install"
#toc_icon: "cog"
categories: Jenkins
tags:
  - jenkins
---

## Jenkins Redhat Packages

To use this repository, run the following command:

```shell
$ sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
$ sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
```

If you've previously imported the key from Jenkins, the `rpm --import` will fail because you already have a key. Please ignore that and move on.

```shell
$ yum install epel-release # repository that provides 'daemonize'
$ yum install java-11-openjdk-devel
$ yum install jenkins
```

安装后软件相关信息：

- `/usr/lib/jenkins/`  jenkins 安装目录，WAR包会放在这里。
- `/etc/sysconfig/jenkins`  jenkins 配置文件
- `/var/lib/jenkins/`  默认的 JENKINS_HOME
- `/var/log/jenkins/jenkins.log` 日志文件

启动 Jenkins

```shell
$ systemctl start jenkins
```

查看运行状态

```shell
$ systemctl status jenkins
```

