---
title: "alpine-pkg-glibc"
excerpt: "A glibc compatibility layer package for Alpine Linux."
toc: true
categories: Docker
tags:
  - docker
  - Dockerfile
  - alpine
---

A glibc compatibility layer package for Alpine Linux.

- [Alpine - Official Image \| Docker Hub](https://hub.docker.com/_/alpine)
- [sgerrand/alpine-pkg-glibc: A glibc compatibility layer package for Alpine Linux (github.com)](https://github.com/sgerrand/alpine-pkg-glibc)
- [Index of /pkgs/ (luojianjun.cn)](https://luojianjun.cn/pkgs/)

#### Local glibc

##### `en_US.UTF-8`

```dockerfile
FROM alpine:3.15.0
MAINTAINER aluopy <aluopy@qq.com>

ENV GLIBC_VERSION 2.34-r0

# Download glibc
# ARG GLIBC_RUL=https://github.com/sgerrand/alpine-pkg-glibc/releases/download
# wget ${GLIBC_RUL}/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk
# wget ${GLIBC_RUL}/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk
# wget ${GLIBC_RUL}/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk

# local glibc
COPY glibc-${GLIBC_VERSION}.apk .
COPY glibc-bin-${GLIBC_VERSION}.apk .
COPY glibc-i18n-${GLIBC_VERSION}.apk .

# Install 
RUN echo -e "http://mirrors.aliyun.com/alpine/v3.15/main\nhttp://mirrors.aliyun.com/alpine/v3.15/community" > /etc/apk/repositories && \
    apk update && \
    apk add tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	echo "Asia/Shanghai" > /etc/timezone && \
	apk del tzdata && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    apk add glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk glibc-i18n-${GLIBC_VERSION}.apk && \
	/usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 && \
	ln -s /usr/glibc-compat/bin/locale /usr/local/bin/locale && \
	rm /etc/apk/keys/sgerrand.rsa.pub && \
	rm -rf glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk glibc-i18n-${GLIBC_VERSION}.apk /var/cache/apk/*
	
ENV LANG=en_US.UTF-8
```

##### `zh_CN.UTF-8`

```dockerfile
FROM alpine:3.15.0
MAINTAINER aluopy <aluopy@qq.com>

ENV GLIBC_VERSION 2.34-r0

# Download glibc
# ARG GLIBC_RUL=https://github.com/sgerrand/alpine-pkg-glibc/releases/download
# wget ${GLIBC_RUL}/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk
# wget ${GLIBC_RUL}/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk
# wget ${GLIBC_RUL}/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk

# local glibc
COPY glibc-${GLIBC_VERSION}.apk .
COPY glibc-bin-${GLIBC_VERSION}.apk .
COPY glibc-i18n-${GLIBC_VERSION}.apk .

# Install 
RUN echo -e "http://mirrors.aliyun.com/alpine/v3.15/main\nhttp://mirrors.aliyun.com/alpine/v3.15/community" > /etc/apk/repositories && \
    apk update && \
    apk add tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	echo "Asia/Shanghai" > /etc/timezone && \
	apk del tzdata && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    apk add glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk glibc-i18n-${GLIBC_VERSION}.apk && \
	/usr/glibc-compat/bin/localedef -i zh_CN -f UTF-8 zh_CN.UTF-8 && \
	ln -s /usr/glibc-compat/bin/locale /usr/local/bin/locale && \
	rm /etc/apk/keys/sgerrand.rsa.pub && \
	rm -rf glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk glibc-i18n-${GLIBC_VERSION}.apk /var/cache/apk/*
	
ENV LANG=zh_CN.UTF-8
```

#### Download glibc

```dockerfile
FROM alpine:3.15.0
MAINTAINER aluopy <aluopy@qq.com>

# Glibc Version
ENV GLIBC_VERSION 2.34-r0

# glibc download url
# ARG GLIBC_RUL=https://github.com/sgerrand/alpine-pkg-glibc/releases/download
ARG GLIBC_RUL=https://luojianjun.cn/pkgs/alpine-pkg-glibc

# local glibc
#COPY glibc-${GLIBC_VERSION}.apk .
#COPY glibc-bin-${GLIBC_VERSION}.apk .
#COPY glibc-i18n-${GLIBC_VERSION}.apk .

# Install 
RUN echo -e "http://mirrors.aliyun.com/alpine/v3.15/main\nhttp://mirrors.aliyun.com/alpine/v3.15/community" > /etc/apk/repositories && \
    apk update && \
    apk add tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	echo "Asia/Shanghai" > /etc/timezone && \
	apk del tzdata && \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
	wget ${GLIBC_RUL}/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
	wget ${GLIBC_RUL}/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk && \
	wget ${GLIBC_RUL}/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk && \
    apk add glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk glibc-i18n-${GLIBC_VERSION}.apk && \
	/usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 && \
	ln -s /usr/glibc-compat/bin/locale /usr/local/bin/locale && \
	rm /etc/apk/keys/sgerrand.rsa.pub && \
	rm -rf glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk glibc-i18n-${GLIBC_VERSION}.apk /var/cache/apk/*

ENV LANG=en_US.UTF-8
```

