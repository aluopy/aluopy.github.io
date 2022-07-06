---
title: "Docker 容器之最小 JDK 基础镜像"
toc: true
categories: docker
tags:
  - docker
  - Dockerfile
---

使用的是 Oracle 的 JRE 不是 openjdk

因为 java 依赖 glibc，所以基础镜像使用的是 alpine-glibc 而非 alpine，alpine-glibc 大概是11.1 M

## 1、下载 jre

下载地址：https://www.java.com/en/download/manual.jsp，大概77M

## 2、解压 jre 包

删除根目录下文本文件，然后删除其他不必要文件。

```shell
# 解压
$ tar zxvf jre-8u311-linux-x64.tar.gz
# 进入目录
$ cd jre1.8.0_311/
# 删除文本文件
$ rm -rf COPYRIGHT LICENSE README release THIRDPARTYLICENSEREADME-JAVAFX.txtTHIRDPARTYLICENSEREADME.txt Welcome.html
# 删除其他无用文件
$ rm -rf     lib/plugin.jar \
             lib/ext/jfxrt.jar \
             bin/javaws \
             lib/javaws.jar \
             lib/desktop \
             plugin \
             lib/deploy* \
             lib/*javafx* \
             lib/*jfx* \
             lib/amd64/libdecora_sse.so \
             lib/amd64/libprism_*.so \
             lib/amd64/libfxplugins.so \
             lib/amd64/libglass.so \
             lib/amd64/libgstreamer-lite.so \
             lib/amd64/libjavafx*.so \
             lib/amd64/libjfx*.so
```

## 3、打包文件

重新打包所有文件，不打包也可以，在 Dockerfile 里 ADD 这个目录即可，当前精简完 jre 目录大小是107 M，压缩后是41 M

```bash
$ tar zcvf jre8.tar.gz *
```

## 4、创建 Dockerfile

```dockerfile
# using alpine-glibc instead of alpine  is mainly because JDK relies on glibc
FROM docker.io/jeanblanchard/alpine-glibc
# author
MAINTAINER aluopy <aluopy@qq.com>
# A streamlined jre
ADD jre8.tar.gz /usr/java/jdk/
# set env
ENV JAVA_HOME /usr/java/jdk
ENV PATH ${PATH}:${JAVA_HOME}/bin
# run container with base path:/opt
WORKDIR /opt
```

## 5、构建

整体大小是122 M

```bash
$ docker build -t aluopy/java8:1.0 .
```

## 6、测试运行

```bash
$ docker run -it aluopy/java8:1.0
/opt # java -version
java version "1.8.0_311"
Java(TM) SE Runtime Environment (build 1.8.0_311-b11)
Java HotSpot(TM) 64-Bit Server VM (build 25.311-b11, mixed mode)
```