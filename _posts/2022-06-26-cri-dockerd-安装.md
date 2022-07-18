---
title: "cri-dockerd 安装"
excerpt: ""
permalink: /docker/cri-dockerd-install/
toc: false
#toc_label: ""
#toc_icon: "cog"
categories: docker
tags:
  - docker
  - cri-dockerd
---

这个适配器为 Docker Engine 提供了一个 shim，让您可以通过 Kubernetes Container Runtime Interface(CRI) 控制 Docker。

Docker Engine 没有实现 [CRI](https://kubernetes.io/zh-cn/docs/concepts/architecture/cri/)，而这是容器运行时在 Kubernetes 中工作所需要的。 为此，必须安装一个额外的服务 [cri-dockerd](https://github.com/Mirantis/cri-dockerd)。 cri-dockerd 是一个基于传统的内置 Docker 引擎支持的项目，它在 1.24 版本从 kubelet 中移除。

本文使用 rpm 包安装 cri-dockerd，下载地址：[Releases · Mirantis/cri-dockerd (github.com)](https://github.com/Mirantis/cri-dockerd/releases/)

下载 rpm 包

```shell
$ wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.2.3/cri-dockerd-0.2.3-3.el7.x86_64.rpm
```

安装 cri-dockerd

```shell
$ yum install cri-dockerd-0.2.3-3.el7.x86_64.rpm -y
```

修改启动文件

```shell
$ sed -i 's,^ExecStart.*,&cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.7,' /usr/lib/systemd/system/cri-docker.service
```

启动 cri-dockerd

> 依赖 docker，需要先安装 docker

```shell
$ systemctl daemon-reload
$ systemctl enable --now cri-docker.service
$ systemctl enable --now cri-docker.socket
```

查看 cri-dockerd 状态

```shell
$ systemctl status cri-docker.service
```

