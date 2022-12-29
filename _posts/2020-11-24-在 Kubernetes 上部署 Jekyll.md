---
title: "在 Kubernetes 上部署 Jekyll"
#excerpt: ""
permalink: /kubernetes/deploy-jekyll-on-kubernetes/
toc: true
#toc_label: ""
#toc_icon: "cog"
categories: 
  - kubernetes
  - jekyll
tags:
  - jekyll
---

## Overview

了解如何使用 Docker 对 Jekyll 静态内容网站进行容器化，并将其部署在 Kubernetes 集群上。

拥有大部分静态内容的网站不应该有运行和维护 CMS 和数据库后台的昂贵开销。相反，使用静态内容生成器（如Jekyll）来生成 HTML、CSS 和 JavaScript 文件提供给访问者，会使它们受益匪浅。在本指南中，你将学习如何从Jekyll 容器化静态内容生成的网站，并将其部署在 Kubernetes 上。

## Jekyll Build

Jekyll 是一个非常流行的基于 ruby 的静态内容生成器。最常见的地方是在 Github 上找到 Jekyll 生成的网站，它可以用来提供静态网站。

Jekyll 提供了一个模板系统来设计和组织你的网站内容和页面。因此，我们确保所有生成的页面具有相同的主题和一致的用户体验。

内容被写成 Markdown 文件，这是另一种用于格式化文本的流行文件格式，在 Github 和其他版本控制系统中被广泛使用。它的简单化的 Markdown 非常便于人类阅读，让人想起 80 年代和 90 年代的老式文字处理机时代。

### Docker Build

在 Kubernetes 中运行静态网站的第一步是为它建立一个容器镜像。在这个例子中，我们将为我们的 Jekyll 生成的网站建立一个 Docker 镜像，由 NGINX 提供服务。

Docker 构建过程将运行两个阶段。Docker 构建阶段是一种神奇的方式，可以将你的构建部署与我们的最终工件隔离开来，确保尽可能小的应用程序足迹，同时也提高了安全性，因为敏感信息不会被存储。

第一阶段将使用官方的 Ruby Docker 镜像作为基础，用来安装我们所有的 Jekyll 构建依赖项。然后，我们的 Jekyll 文件将被复制到构建阶段，并运行 jekyll 来生成我们的静态文件。

第二阶段是基于一个官方的 NGINX docker 镜像。我们的 Jekyll 构建工件（HTML、JS、CSS和其他静态内容）将被复制到默认的NGINX根目录 `/usr/share/nginx/html`。

1. 在你的项目根目录创建一个名为 `Dockerfile` 的新文件

2. 在其中加入以下内容

   ```dockerfile
   FROM ruby:2.7.1-buster AS build
   COPY . /app
   WORKDIR /app
   RUN bundle install \
       && jekyll build
   
   FROM nginx:1.19.2-alpine AS final
   COPY --from=build /app/_site /usr/share/nginx/html
   ```

3. 保存你的修改并退出文本编辑器

4. 运行 `docker build` 命令来构建你的新镜像。`-t` 标志为最终镜像设置了一个标签，它将被用来为我们的镜像 `jekyll-app:1.0.0` 提供名称和版本。构建过程可能需要几分钟，因为 Gemfile 中的每个依赖都必须在必要时下载和编译

   ```shell
   docker build -t jekyll-app:1.0.0 .
   ```

5. 使用 `docker image` 命令验证镜像是否已经创建。输出显示了新创建的镜像的信息，更重要的是，它的大小为 22.1 MB

   ```shell
   $ docker images
   REPOSITORY                           TAG                                              IMAGE ID            CREATED             SIZE
   jekyll-demo                          1.0.0                                            fb44a75708cc        4 hours ago         22.1MB
   ```

## Kubernetes

### Deployment

1. 创建一个名为 `deployment.yaml` 的新文件

2. 在其中加入以下内容

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: jekyll-website
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: jekyll-website
     template:
       metadata:
         labels:
           app: jekyll-website  
       spec:
         containers:
         - name: website
           image: jekyll-app:1.0.0
           ports:
             - containerPort: 80
   ```

3. 应用清单来创建 deployment

   ```shell
   kubectl apply -f deployment.yaml
   ```

4. 使用 `kubectl get deployment` 验证部署是否成功创建

   ```shell
   $ kubectl get deployment
   NAME               READY   UP-TO-DATE   AVAILABLE   AGE
   jekyll-website     3/3     3            3           30s
   ```

### Service

Kubernete service 用于将托管在 Kubernetes 集群上的应用程序作为一个运行中的服务公开。服务可以被分配一个可路由的 IP 地址。

下面的例子将把一个 service 映射到上面创建的部署所产生的 pod 上。任何时候，如果创建的 pod 的标签与下面 service 中设置的标准相匹配，它就会被添加为 service 的后端 pod。

1. 创建一个名为 `service.yaml` 的新文件

2. 在其中加入以下内容

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: jekyll-website
   spec:
     selector:
       app: jekyll-website
     ports:
     - protocol: TCP
       port: 80
     type: Loadbalancer
   ```

3. 通过应用清单创建 Kubernetes service

   ```shell
   kubectl apply -f service.yaml
   ```

4. 验证你的 jekyll-website 服务，以确保其成功创建

   ```shell
   $ kubectl get svc jekyll-website
   NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
   jekyll-website   ClusterIP   10.245.94.93   <pending>     80/TCP     45s
   ```

## Configuring NGINX

## Liveliness Probes

一般来说，一个容器被认为是健康的，直到其主进程退出。这样做的不幸结果是，你的应用程序不一定在健康状态下运行，只是因为容器还没有退出。

### TCP Checks

确定 NGINX 是否健康的一个方法是检查一个开放的端口，通常是 80 或 443 端口。

TCP 检查的一个缺点是它不一定意味着你的应用程序正在运行或接受连接。它只是检查服务器是否接受连接。例如，一个应用程序可能有一个 503 错误，但 TCP 端口是开放和监听的，导致一个假阳性的健康状态。

1. 在一个文本编辑器中打开你的 `deployment.yaml`

2. 添加如下所示行，以添加一个TCP `readinessProbe` 和一个 TCP `livelinessProbe`

   ```yaml
   spec:
     containers:
     - name: website
       ...
       readinessProbe:
         tcpSocket:
           port: 80
         initialDelaySeconds: 5
         periodSeconds: 10
       livenessProbe:
         tcpSocket:
           port: 80
         initialDelaySeconds: 15
         periodSeconds: 20
   ```

3. 保存您的更改并重新应用部署清单

   ```shell
   kubectl apply -f deployment.yaml
   ```

### HTTP Liveliness Probe

端点健康检查通过点击一个预先指定的 URI 来确定应用程序的健康状况。如果对 URI 的请求返回一个响应，如 HTTP 状态 2XX，应用程序，因此，容器被认为是健康的。

1. 在一个文本编辑器中打开 `deployment.yaml` 文件

2. 在部署清单中，向你的 `container` 添加以下 `livenessProbe` 部分

   ```yaml
   spec:
     containers:
     ...
       livenessProbe:
         httpGet:
           path: /healthz
           port: 8080
         httpHeaders:
         - name: Custom-Header
           value: Awesome
         initialDelaySeconds: 3
         periodSeconds: 3
   ```

3. 保存您对 `deployment.yaml` 的更改，并重新应用清单。

   ```shell
   kubectl apply -f deployment.yaml
   ```

## 参考

原文链接：[How to Deploy Jekyll on Kubernetes - CloudyTuts](https://www.cloudytuts.com/guides/kubernetes/how-to-deploy-jekyll-on-kubernetes/)