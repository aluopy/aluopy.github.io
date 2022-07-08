---
title: "使用 kubeadm 创建高可用集群"
excerpt: ""
permalink: /kubernetes/kubeadm-high-availability/
toc: true
#toc_label: ""
#toc_icon: "cog"
categories: kubernetes
tags:
  - kubernetes
  - kubeadm
  - kube-vip
---

## 准备开始

- 一台兼容的 Linux 主机。Kubernetes 项目为基于 Debian 和 Red Hat 的 Linux 发行版以及一些不提供包管理器的发行版提供通用的指令
- 每台机器 2 GB 或更多的 RAM （如果少于这个数字将会影响你应用的运行内存)
- 2 CPU 核或更多
- 集群中的所有机器的网络彼此均能相互连接(公网和内网都可以)
- 节点之中不可以有重复的主机名、MAC 地址或 product_uuid。请参见[这里](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#verify-mac-address)了解更多详细信息
- 开启机器上的某些端口。请参见[这里](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports) 了解更多详细信息
- 禁用交换分区。为了保证 kubelet 正常工作，**必须** 禁用交换分区

## 集群规划

集群节点规划如下

| 主机名 | 主机 IP        | 主机配置 | 主机角色      | 系统                                 |
| ------ | -------------- | -------- | ------------- | ------------------------------------ |
| m1     | 192.168.20.17  | 2C4G     | Control plane | CentOS Linux release 7.6.1810 (Core) |
| m2     | 192.168.20.18  | 2C4G     | Control plane | CentOS Linux release 7.6.1810 (Core) |
| m3     | 192.168.20.19  | 2C4G     | Control plane | CentOS Linux release 7.6.1810 (Core) |
| w1     | 192.168.20.187 | 2C4G     | Worker node   | CentOS Linux release 7.6.1810 (Core) |

## 确保每个节点上 MAC 地址和 product_uuid 的唯一性

- 使用命令 `ip link` 或 `ifconfig -a` 来获取网络接口的 MAC 地址
- 使用 `sudo cat /sys/class/dmi/id/product_uuid` 命令对 product_uuid 校验

一般来讲，硬件设备会拥有唯一的地址，但是有些虚拟机的地址可能会重复。 Kubernetes 使用这些值来唯一确定集群中的节点。 如果这些值在每个节点上不唯一，可能会导致安装 [失败](https://github.com/kubernetes/kubeadm/issues/31)。

## 检查网络适配器

如果有一个以上的网络适配器，同时 Kubernetes 组件通过默认路由不可达，我们建议预先添加 IP 路由规则，这样 Kubernetes 集群就可以通过对应的适配器完成连接。

## 允许 iptables 检查桥接流量

确保 `br_netfilter` 模块被加载。这一操作可以通过运行 `lsmod | grep br_netfilter` 来完成。若要显式加载该模块，可执行 `sudo modprobe br_netfilter`。

为了让 Linux 节点上的 iptables 能够正确地查看桥接流量，需要确保在 `sysctl` 配置中将 `net.bridge.bridge-nf-call-iptables` 设置为 1。

```bash
$ cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

$ cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
$ sudo sysctl --system
```

## 检查所需端口

内网环境可以直接关闭防火墙。如需开启防火墙，启用这些必要的端口后才能使 Kubernetes 的各组件相互通信。

> 使用的 Pod 网络插件也可能需要开启某些特定端口。由于各个 Pod 网络插件的功能都有所不同， 请参阅他们各自文档中对端口的要求。

### 控制面

| 协议 | 方向 | 端口范围  | 目的                    | 使用者               |
| ---- | ---- | --------- | ----------------------- | -------------------- |
| TCP  | 入站 | 6443      | Kubernetes API server   | 所有                 |
| TCP  | 入站 | 2379-2380 | etcd server client API  | kube-apiserver, etcd |
| TCP  | 入站 | 10250     | Kubelet API             | 自身, 控制面         |
| TCP  | 入站 | 10259     | kube-scheduler          | 自身                 |
| TCP  | 入站 | 10257     | kube-controller-manager | 自身                 |

尽管 etcd 的端口也列举在控制面的部分，但也可以在外部自己托管 etcd 集群或者自定义端口。

### 工作节点

| 协议 | 方向 | 端口范围    | 目的               | 使用者       |
| ---- | ---- | ----------- | ------------------ | ------------ |
| TCP  | 入站 | 10250       | Kubelet API        | 自身, 控制面 |
| TCP  | 入站 | 30000-32767 | NodePort Services† | 所有         |

† [NodePort Services](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/) 的默认端口范围。

所有默认端口都可以重新配置。当使用自定义的端口时，需要打开这些端口来代替这里提到的默认端口。

一个常见的例子是 API 服务器的端口有时会配置为443。或者你也可以使用默认端口，把 API 服务器放到一个监听443 端口的负载均衡器后面，并且路由所有请求到 API 服务器的默认端口。

## 禁用交换分区

为了保证 kubelet 正常工作，**必须**禁用交换分区

```bash
# 临时禁用
$ sudo swapoff -a
# 永久禁用
$ sudo sed -ri 's/.*swap.*/#&/' /etc/fstab
```

## 禁用 SELinux

将 SELinux 设置为 permissive 模式（相当于将其禁用），禁用 SELinux 是允许容器访问主机文件系统所必需的，这些操作是为了例如 Pod 网络工作正常。

```bash
$ sudo setenforce 0
$ sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

## 添加主机映射

```shell
$ sudo cat <<EOF | sudo tee -a /etc/hosts
192.168.20.17  m1
192.168.20.18  m1
192.168.20.19  m2
192.168.20.187 w1
EOF
```

## 安装容器运行时

为了在 Pod 中运行容器，Kubernetes 使用 [容器运行时（Container Runtime）](https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes)。

默认情况下，Kubernetes 使用 [容器运行时接口（Container Runtime Interface，CRI）](https://kubernetes.io/zh-cn/docs/concepts/overview/components/#container-runtime) 来与所选择的容器运行时交互。

如果不指定运行时，kubeadm 会自动尝试通过扫描已知的端点列表来检测已安装的容器运行时。

如果检测到有多个或者没有容器运行时，kubeadm 将抛出一个错误并要求你指定一个想要使用的运行时。

Kubernetes 1.24 版本要求使用符合[容器运行时接口](https://kubernetes.io/zh-cn/docs/concepts/overview/components/#container-runtime)（CRI）的运行时。

Kubernetes 支持许多容器运行环境，例如 [Docker](https://kubernetes.io/zh-cn/docs/reference/kubectl/docker-cli-to-kubectl/)、 [containerd](https://containerd.io/docs/)、 [CRI-O](https://cri-o.io/#what-is-cri-o) 以及 [Kubernetes CRI (容器运行环境接口)](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-node/container-runtime-interface.md) 的其他任何实现。

本文选择 Docker Engine 作为容器运行时，其他常见的容器运行时安装请参考：[容器运行时 \| Kubernetes](https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/)

### Docker Engine

#### 设置存储库

安装 `yum-utils` 软件包并设置存储库

```bash
$ sudo yum install -y yum-utils
$ sudo yum-config-manager \
    --add-repo \
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

#### 安装 Docker Engine

默认安装最新的稳定版本的 Docker，安装指定版本请参考：[docker-install (aluopy.cn)](https://aluopy.cn/docker/docker-install/#安装指定版本)

```bash
$ sudo yum makecache fast
$ sudo yum install docker-ce -y
```

#### 启动 Docker

启动并加入开机启动

```bash
$ sudo systemctl enable docker --now
```

#### 安装验证

```bash
$ sudo docker -v
Docker version 20.10.17, build 100c701
```

#### 配置 Docker 的 cgroup 驱动程序

容器运行时和 kubelet 都具有名字为 [“cgroup driver”](https://kubernetes.io/zh/docs/setup/production-environment/container-runtimes/) 的属性，该属性对于在 Linux 机器上管理 CGroups 而言非常重要。**需要确保容器运行时和 kubelet 所使用的是相同的 cgroup 驱动**，否则 kubelet 进程会失败。

而令容器运行时和 kubelet 使用 `systemd` 作为 cgroup 驱动，会使系统更为为稳定。

```bash
$ sudo mkdir -p /etc/docker
$ sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

$ sudo systemctl restart docker
$ sudo docker info | grep "Cgroup Driver"
 Cgroup Driver: systemd
```

> **注意**：
>
> 更改已加入集群的节点的 cgroup 驱动是一项敏感的操作。 如果 kubelet 已经使用某 cgroup 驱动的语义创建了 pod，更改运行时以使用别的 cgroup 驱动，当为现有 Pods 重新创建 PodSandbox 时会产生错误。 重启 kubelet 也可能无法解决此类问题。
>
> 如果你有切实可行的自动化方案，使用其他已更新配置的节点来替换该节点， 或者使用自动化方案来重新安装。

## 安装 cri-dockerd

Docker Engine 没有实现 [CRI](https://kubernetes.io/zh-cn/docs/concepts/architecture/cri/)，而这是容器运行时在 Kubernetes 中工作所需要的。 为此，必须安装一个额外的服务 [cri-dockerd](https://github.com/Mirantis/cri-dockerd)。 cri-dockerd 是一个基于传统的内置 Docker 引擎支持的项目，它在 1.24 版本从 kubelet 中移除。

本文使用 rpm 包安装 cri-dockerd

下载地址：[Releases · Mirantis/cri-dockerd (github.com)](https://github.com/Mirantis/cri-dockerd/releases/)

```bash
# 下载 rpm 包
$ wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.2.3/cri-dockerd-0.2.3-3.el7.x86_64.rpm

# 安装 cri-dockerd
$ yum install cri-dockerd-0.2.3-3.el7.x86_64.rpm -y

# 修改启动文件
$ sed -i 's,^ExecStart.*,&cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.7,' /usr/lib/systemd/system/cri-docker.service

# 启动 cri-dockerd
$ systemctl daemon-reload
$ systemctl enable cri-docker.service --now
```

## 安装 kubeadm、kubelet 和 kubectl

添加阿里云 YUM 软件源

```bash
$ cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

安装 kubeadm、kubelet 和 kubectl

```bash
$ sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
$ sudo systemctl enable --now kubelet
```

> 以上安装命令默认安装最新版本，安装指定版本：`yum install -y kubelet-1.20.0 kubeadm-1.20.0 kubectl-1.20.0`

## 使用 kubeadm 创建集群