---
title: "minikube start"
permalink: /kubernetes/minikube-install/
toc: true
toc_label: "minikube start"
#toc_icon: "cog"
categories: kubernetes
tags:
  - kubernetes
  - minikube
---

minikube 是本地 Kubernetes，专注于让 Kubernetes 易于学习和开发。

您只需要 Docker（或类似兼容的）容器或虚拟机环境，只需一个命令即可使用 Kubernetes：`minikube start`

## 环境准备

- 2 个 CPU 或更多
- 2GB 可用内存
- 20GB 可用磁盘空间
- 网络连接
- 容器或虚拟机管理器，例如：[Docker](https://minikube.sigs.k8s.io/docs/drivers/docker/), [Hyperkit](https://minikube.sigs.k8s.io/docs/drivers/hyperkit/), [Hyper-V](https://minikube.sigs.k8s.io/docs/drivers/hyperv/), [KVM](https://minikube.sigs.k8s.io/docs/drivers/kvm2/), [Parallels](https://minikube.sigs.k8s.io/docs/drivers/parallels/), [Podman](https://minikube.sigs.k8s.io/docs/drivers/podman/), [VirtualBox](https://minikube.sigs.k8s.io/docs/drivers/virtualbox/), or [VMware Fusion/Workstation](https://minikube.sigs.k8s.io/docs/drivers/vmware/)

## 安装 minikube

本文使用 **.exe** 程序在 **x86-64 Windows** 上安装最新的 minikube 稳定版本

1. 下载并运行[最新版本](https://storage.googleapis.com/minikube/releases/latest/minikube-installer.exe)的安装程序

   或者，如果使用 PowerShell，请使用以下命令：

   ```powershell
   $ New-Item -Path 'D:\Program Files\Kubernetes\' -Name 'minikube' -ItemType Directory -Force
   $ Invoke-WebRequest -OutFile 'D:\Program Files\Kubernetes\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing
   ```

   > 第一条命令在目录 `D:\Program Files\Kubernetes\` 下创建 `minikube` 目录；
   >
   > 第二条命令在 GitHub 上下载 `minikube-windows-amd64.exe` 包并存放到 `D:\Program Files\Kubernetes\minikube\` 目录下并重命名为 `minikube.exe` 。

2. 将 `minikube.exe` 二进制文件添加到系统环境变量 PATH 中

   确保以管理员身份运行 PowerShell

   ```powershell
   $ $oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
   if ($oldPath.Split(';') -inotcontains 'D:\Program Files\Kubernetes\minikube'){ `
     [Environment]::SetEnvironmentVariable('Path', $('{0};D:\Program Files\Kubernetes\minikube' -f $oldPath), [EnvironmentVariableTarget]::Machine) `
   }
   ```

   > 检查系统环境变量 Path 中是否有 `D:\Program Files\Kubernetes\Minikube`
   >
   > 如果使用 CLI 执行安装，则需要先关闭该 CLI 并打开一个新的 CLI，然后再继续。

## 启动集群

从具有管理员访问权限的终端（但未以 root 身份登录），运行：

```bash
$ minikube start
```

如果 minikube 无法启动，请参阅 [drivers page](https://minikube.sigs.k8s.io/docs/drivers/) 以获取设置兼容容器或虚拟机管理器的帮助。

## 与集群交互

如果已经安装了 kubectl，现在可以使用它来访问新集群：

```bash
$ kubectl get po -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS      AGE
kube-system   coredns-64897985d-j76z2            1/1     Running   0             77s
kube-system   etcd-minikube                      1/1     Running   0             77s
kube-system   kube-apiserver-minikube            1/1     Running   0             77s
kube-system   kube-controller-manager-minikube   1/1     Running   0             77s
kube-system   kube-proxy-42l78                   1/1     Running   0             77s
kube-system   kube-scheduler-minikube            1/1     Running   0             77s
kube-system   storage-provisioner                1/1     Running   0             77s
```

或者使用如下命令（minikube 可以下载适当版本的 kubectl）：

```bash
$ minikube kubectl -- get po -A
```

为 `minikube kubectl --` 添加别名：

```shell
$ alias kubectl="minikube kubectl --"
```

最初，某些服务（例如 storage-provisioner）可能尚未处于运行状态。这是集群启动期间的正常情况，并且会立即自行解决。为了进一步了解集群状态，minikube 捆绑了 Kubernetes Dashboard，让您可以轻松适应新环境：

```bash
$ minikube dashboard
```

## 部署应用程序

创建一个示例部署并在端口 8080 上公开它：

```bash
$ kubectl create deployment hello-minikube --image=aluopy/echoserver:1.4
$ kubectl expose deployment hello-minikube --type=NodePort --port=8080
```

这可能需要一点时间，但是当您运行时，您的部署将很快出现：

```bash
$ kubectl get services hello-minikube
```

访问此服务的最简单方法是让 minikube 为您启动 Web 浏览器：

```bash
$ minikube service hello-minikube
```

或者，使用 kubectl 转发端口：

```bash
$ kubectl port-forward service/hello-minikube 7080:8080
```

此时应用程序将在 http://localhost:7080/ 上可用。

您应该能够在应用程序输出中看到来自 nginx 的请求元数据，例如 CLIENT VALUES、SERVER VALUES、HEADERS RECEIVED 和 BODY。尝试更改请求的路径并观察 CLIENT VALUES 的变化。同样，您可以对其执行 POST 请求并观察输出的 BODY 部分中显示的正文。

### 负载均衡器部署

要访问 LoadBalancer 部署，请使用“minikube tunnel”命令。这是一个示例部署：

```bash
$ kubectl create deployment balanced --image=aluopy/echoserver:1.4  
$ kubectl expose deployment balanced --type=LoadBalancer --port=8080
```

在另一个窗口中，启动隧道以为“均衡”部署创建可路由 IP：

```bash
$ minikube tunnel
```

要查找可路由 IP，请运行此命令并检查 `EXTERNAL-IP` 列：

```bash
$ kubectl get services balanced
```

您的部署现在在 `<EXTERNAL-IP>:8080` 可用

## 管理集群

在不影响已部署应用程序的情况下暂停 Kubernetes：

```bash
$ minikube pause
```

取消暂停的实例：

```bash
$ minikube unpause
```

停止集群：

```bash
$ minikube stop
```

增加默认内存限制（需要重新启动）：

```bash
$ minikube config set memory 16384
```

浏览易于安装的 Kubernetes 服务目录：

```bash
$ minikube addons list
```

创建第二个（运行旧 Kubernetes 版本的）集群：

```bash
$ minikube start -p aged --kubernetes-version=v1.16.1
```

删除所有 minikube 集群：

```bash
$ minikube delete --all
```

## 官方文档

- [minikube start \| minikube (k8s.io)](https://minikube.sigs.k8s.io/docs/start/)
- [Handbook \| minikube (k8s.io)](https://minikube.sigs.k8s.io/docs/handbook/)
- [minikube command reference (k8s.io)](https://minikube.sigs.k8s.io/docs/commands/)
- [kubernetes/minikube: Run Kubernetes locally (github.com)](https://github.com/kubernetes/minikube)

