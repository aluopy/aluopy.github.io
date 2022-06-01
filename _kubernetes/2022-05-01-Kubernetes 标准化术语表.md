---
title: "Kubernetes 标准化术语表"
excerpt: "本词汇表旨在成为 Kubernetes 术语的全面、标准化列表。它包括特定于 Kubernetes 的技术术语，以及提供有用上下文的更一般的术语。"
toc: true
categories: Kubernetes
tags:
  - kubernetes
  - glossary
---

### API Group

Kubernetes API 中的一组相关路径。

通过更改 API server 的配置，可以启用或禁用每个 API Group。 你还可以禁用或启用指向特定资源的路径。 API group 使扩展 Kubernetes API 更加的容易。 API group 在 REST 路径和序列化对象的 `apiVersion` 字段中指定。

- 阅读 [API Group](https://kubernetes.io/zh/docs/concepts/overview/kubernetes-api/#api-groups-and-versioning) 了解更多信息。

### API 发起的驱逐

API 发起的驱逐是一个先调用 [Eviction API](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#create-eviction-pod-v1-core) 创建 `Eviction` 对象，再由该对象体面地中止 Pod 的过程。

你可以通过 kube-apiserver 的客户端，比如 `kubectl drain` 这样的命令，直接调用 Eviction API 发起驱逐。 当 `Eviction` 对象创建出来之后，该对象将驱动 API 服务器终止选定的Pod。

API 发起的驱逐取决于你配置的 [`PodDisruptionBudgets`](https://kubernetes.io/zh/docs/tasks/run-application/configure-pdb/) 和 [`terminationGracePeriodSeconds`](https://kubernetes.io/zh/docs/concepts/workloads/pods/pod-lifecycle#pod-termination)。

API 发起的驱逐不同于 [节点压力引发的驱逐](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/eviction/#kubelet-eviction)。

- 有关详细信息，请参阅 [API 发起的驱逐](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/api-eviction/)。

### cAdvisor

cAdvisor (Container Advisor) 为容器用户提供对其运行中的[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers) 的资源用量和性能特征的知识。

cAdvisor 是一个守护进程，负责收集、聚合、处理并输出运行中容器的信息。 具体而言，针对每个容器，该进程记录容器的资源隔离参数、历史资源用量、 完整历史资源用量和网络统计的直方图。这些数据可以按容器或按机器层面输出。

### CIDR

CIDR (无类域间路由) 是一种描述 IP 地址块的符号，被广泛使用于各种网络配置中。

在 Kubernetes 的上下文中，每个[节点](https://kubernetes.io/zh/docs/concepts/architecture/nodes/) 以 CIDR 形式（含起始地址和子网掩码）获得一个 IP 地址段， 从而能够为每个 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 分配一个独一无二的 IP 地址。 虽然其概念最初源自 IPv4，CIDR 已经被扩展为涵盖 IPv6。

### ConfigMap

ConfigMap 是一种 API 对象，用来将非机密性的数据保存到键值对中。使用时， [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 可以将其用作环境变量、命令行参数或者存储卷中的配置文件。

ConfigMap 将你的环境配置信息和 [容器镜像](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-image) 解耦，便于应用配置的修改。

### containerd

强调简单性、健壮性和可移植性的一种容器运行时

containerd 是一种[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)运行时，能在 Linux 或者 Windows 后台运行。 containerd 能取回、存储容器镜像，执行容器实例，提供网络访问等。

### CRI-O

该工具可让你通过 Kubernetes CRI 使用 OCI 容器运行时。

CRI-O 是 [CRI](https://kubernetes.io/zh/docs/concepts/overview/components/#container-runtime) 的一种实现， 使得你可以使用与开放容器倡议（Open Container Initiative，OCI） [运行时规范](https://www.github.com/opencontainers/runtime-spec) 兼容的[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)。

部署 CRI-O 允许 Kubernetes 使用任何符合 OCI 要求的运行时作为容器运行时 去运行 [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)， 并从远程容器仓库获取 OCI 容器镜像。

### CustomResourceDefinition

通过定制化的代码给你的 Kubernetes API 服务器增加资源对象，而无需编译完整的定制 API 服务器。

当 Kubernetes 公开支持的 API 资源不能满足你的需要时， 定制资源对象（Custom Resource Definitions）让你可以在你的环境上扩展 Kubernetes API。

### DaemonSet

确保 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 的副本在[集群](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-cluster)中的一组节点上运行。

用来部署系统守护进程，例如日志搜集和监控代理，这些进程通常必须运行在每个[节点](https://kubernetes.io/zh/docs/concepts/architecture/nodes/)上。

### Deployment

Deployment 是管理应用副本的 API 对象，通常通过运行没有本地状态的Pods来实现。

应用的每个副本就是一个 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)， 并且这些 Pod 会分散运行在集群的[节点](https://kubernetes.io/zh/docs/concepts/architecture/nodes/)上。

### Docker

Docker（这里特指 Docker 引擎） 是一种可以提供操作系统级别虚拟化（也称作[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)）的软件技术。

Docker 使用了 Linux 内核中的资源隔离特性（如 cgroup 和内核命名空间）以及支持联合文件系统（如 OverlayFS 和其他）， 允许多个相互独立的“容器”一起运行在同一 Linux 实例上，从而避免启动和维护虚拟机（VMs）的开销。

### Dockershim

dockershim 是 Kubernetes v1.23 及之前版本中的一个组件。 Kubernetes 系统组件通过它与 [Docker Engine](https://kubernetes.io/zh/docs/reference/kubectl/docker-cli-to-kubectl/) 通信。

从 Kubernetes v1.24 开始，dockershim 已从 Kubernetes 中移除. 想了解更多信息，可参考[移除 Dockershim 的常见问题](https://kubernetes.io/zh/dockershim)。

### EndpointSlice

一种将网络端点与 Kubernetes 资源组合在一起的方法。

一种将网络端点组合在一起的可扩缩、可扩展方式。 它们将被 [kube-proxy](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-proxy/) 用于在 每个 [节点](https://kubernetes.io/zh/docs/concepts/architecture/nodes/) 上建立网络路由。

### etcd

etcd 是兼具一致性和高可用性的键值数据库，可以作为保存 Kubernetes 所有集群数据的后台数据库。

你的 Kubernetes 集群的 etcd 数据库通常需要有个备份计划。

要了解 etcd 更深层次的信息，请参考 [etcd 文档](https://etcd.io/docs/)。

### Finalizer

Finalizer 是带有命名空间的键，告诉 Kubernetes 等到特定的条件被满足后， 再完全删除被标记为删除的资源。 Finalizer 提醒[控制器](https://kubernetes.io/zh/docs/concepts/architecture/controller/)清理被删除的对象拥有的资源。

当你告诉 Kubernetes 删除一个指定了 Finalizer 的对象时， Kubernetes API 通过填充 `.metadata.deletionTimestamp` 来标记要删除的对象， 并返回`202`状态码 (HTTP "已接受") 使其进入只读状态。 此时控制平面或其他组件会采取 Finalizer 所定义的行动， 而目标对象仍然处于终止中（Terminating）的状态。 这些行动完成后，控制器会删除目标对象相关的 Finalizer。 当 `metadata.finalizers` 字段为空时，Kubernetes 认为删除已完成。

你可以使用 Finalizer 控制资源的[垃圾收集](https://kubernetes.io/zh/docs/concepts/workloads/controllers/garbage-collection/)。 例如，你可以定义一个 Finalizer，在删除目标资源前清理相关资源或基础设施。

### FlexVolume

FlexVolume 是一个已弃用的接口，用于创建树外卷插件。 [容器存储接口（CSI）](https://kubernetes.io/zh/docs/concepts/storage/volumes/#csi) 是比 Flexvolume 更新的接口，它解决了 Flexvolume 的一些问题。

Flexvolume 允许用户编写自己的驱动程序，并在 Kubernetes 中加入对用户自己的数据卷的支持。 FlexVolume 驱动程序的二进制文件和依赖项必须安装在主机上。 这需要 root 权限。如果可能的话，SIG Storage 建议实现 [CSI](https://kubernetes.io/zh/docs/concepts/storage/volumes/#csi) 驱动程序， 因为它解决了 Flexvolumes 的限制。

- [Kubernetes 文档中的 Flexvolume](https://kubernetes.io/zh/docs/concepts/storage/volumes/#flexvolume)
- [更多关于 Flexvolumes 的信息](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-storage/flexvolume.md)
- [存储供应商的卷插件 FAQ](https://github.com/kubernetes/community/blob/master/sig-storage/volume-plugin-faq.md)

### Helm Chart

Helm Chart 是一组预先配置的 Kubernetes 资源所构成的包，可以使用 Helm 工具对其进行管理。

Chart 提供了一种可重现的用来创建和共享 Kubernetes 应用的方法。 单个 Chart 可用来部署简单的系统（例如一个 memcached Pod）， 也可以用来部署复杂的系统（例如包含 HTTP 服务器、数据库、缓存等组件的完整 Web 应用堆栈）。

### HostAliases

主机别名 (HostAliases) 是一组 IP 地址和主机名的映射，用于注入到 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 内的 hosts 文件。

[HostAliases](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#hostalias-v1-core) 是一个包含主机名和 IP 地址的可选列表，配置后将被注入到 Pod 内的 hosts 文件中。 该选项仅适用于没有配置 hostNetwork 的 Pod.

### Ingress

Ingress 是对集群中服务的外部访问进行管理的 API 对象，典型的访问方式是 HTTP。

Ingress 可以提供负载均衡、SSL 终结和基于名称的虚拟托管。

### Istio

Istio 是个开放平台（非 Kubernetes 特有），提供了一种统一的方式来集成微服务、管理流量、实施策略和汇总度量数据。

添加 Istio 时不需要修改应用代码。它是基础设施的一层，介于服务和网络之间。 当它和服务的 Deployment 相结合时，就构成了通常所谓的服务网格（Service Mesh）。 Istio 的控制面抽象掉了底层的集群管理平台，这一集群管理平台可以是 Kubernetes、Mesosphere 等。

### Job

Job 是需要运行完成的确定性的或批量的任务。

Job 创建一个或多个 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 对象，并确保指定数量的 Pod 成功终止。 随着各 Pod 成功结束，Job 会跟踪记录成功完成的个数。

### Kops

kops 是一个命令行工具，可以帮助您创建、销毁、升级和维护生产级，高可用性的 Kubernetes 集群。

注意：官方仅支持 AWS，GCE 和 VMware vSphere 的支持还处于 alpha* 阶段。

`kops` 为你的集群提供了：

- 全自动化安装
- 基于 DNS 的集群标识
- 自愈功能：所有组件都在自动伸缩组（Auto-Scaling Groups）中运行
- 有限的操作系统支持 (推荐使用 Debian，支持 Ubuntu 16.04，试验性支持 CentOS & RHEL)
- 高可用 (HA) 支持
- 直接提供或者生成 Terraform 清单文件的能力

你也可以将自己的集群作为一个构造块，使用 [Kubeadm](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/) 构造集群。 `kops` 是建立在 kubeadm 之上的。

### kube-apiserver

API 服务器是 Kubernetes [控制面](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-control-plane)的组件， 该组件公开了 Kubernetes API。 API 服务器是 Kubernetes 控制面的前端。

Kubernetes API 服务器的主要实现是 [kube-apiserver](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-apiserver/)。 kube-apiserver 设计上考虑了水平伸缩，也就是说，它可通过部署多个实例进行伸缩。 你可以运行 kube-apiserver 的多个实例，并在这些实例之间平衡流量。

### kube-controller-manager

运行[控制器](https://kubernetes.io/zh/docs/concepts/architecture/controller/)进程的控制平面组件。

从逻辑上讲，每个[控制器](https://kubernetes.io/zh/docs/concepts/architecture/controller/)都是一个单独的进程， 但是为了降低复杂性，它们都被编译到同一个可执行文件，并在一个进程中运行。

### kube-proxy

[kube-proxy](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-proxy/) 是集群中每个节点上运行的网络代理， 实现 Kubernetes [服务（Service）](https://kubernetes.io/zh/docs/concepts/services-networking/service/) 概念的一部分。

kube-proxy 维护节点上的网络规则。这些网络规则允许从集群内部或外部的网络会话与 Pod 进行网络通信。

如果操作系统提供了数据包过滤层并可用的话，kube-proxy 会通过它来实现网络规则。否则， kube-proxy 仅转发流量本身。

### kube-scheduler

控制平面组件，负责监视新创建的、未指定运行[节点（node）](https://kubernetes.io/zh/docs/concepts/architecture/nodes/)的 [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)，选择节点让 Pod 在上面运行。

调度决策考虑的因素包括单个 Pod 和 Pod 集合的资源需求、硬件/软件/策略约束、亲和性和反亲和性规范、数据位置、工作负载间的干扰和最后时限。

### Kubeadm

用来快速安装 Kubernetes 并搭建安全稳定的集群的工具。

你可以使用 kubeadm 安装控制面和 [工作节点](https://kubernetes.io/zh/docs/concepts/architecture/nodes/) 组件。

### Kubectl

Also known as:*kubectl*
kubectl 是使用 Kubernetes API 与 Kubernetes 集群的[控制面](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-control-plane)进行通信的命令行工具。

你可以使用 `kubectl` 创建、检视、更新和删除 Kubernetes 对象。

### Kubelet

一个在集群中每个[节点（node）](https://kubernetes.io/zh/docs/concepts/architecture/nodes/)上运行的代理。 它保证[容器（containers）](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)都 运行在 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 中。

kubelet 接收一组通过各类机制提供给它的 PodSpecs，确保这些 PodSpecs 中描述的容器处于运行状态且健康。 kubelet 不会管理不是由 Kubernetes 创建的容器。

### Kubernetes API

Kubernetes API 是通过 RESTful 接口提供 Kubernetes 功能服务并负责集群状态存储的应用程序。

Kubernetes 资源和"意向记录"都是作为 API 对象储存的，并可以通过调用 RESTful 风格的 API 进行修改。 API 允许以声明方式管理配置。 用户可以直接和 Kubernetes API 交互，也可以通过 `kubectl` 这样的工具进行交互。 核心的 Kubernetes API 是很灵活的，可以扩展以支持定制资源。

### LimitRange

提供约束来限制命名空间中每个 [容器（Containers）](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers) 或 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 的资源消耗。

LimitRange 按照类型来限制命名空间中对象能够创建的数量，以及单个 [容器（Containers）](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers) 或 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 可以请求/使用的计算资源量。

### Master

遗留术语，作为运行 [控制平面](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-control-plane) 的 [节点](https://kubernetes.io/zh/docs/concepts/architecture/nodes/) 的同义词使用。

该术语仍被一些配置工具使用，如 [kubeadm](https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/) 以及托管的服务，为 [节点（nodes）](https://kubernetes.io/zh/docs/concepts/architecture/nodes/) 添加 `kubernetes.io/role` 的 [标签（label）](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/labels/)，以及管理控制平面 Pod 的调度。

### Minikube

Minikube 是用来在本地运行 Kubernetes 的一种工具。

Minikube 在用户计算机上的一个虚拟机内运行单节点 Kubernetes 集群。 你可以使用 Minikube [在学习环境中尝试 Kubernetes](https://kubernetes.io/zh/docs/setup/learning-environment/).

### Operator 模式

[operator 模式](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/operator/) 是一种系统设计, 将 [控制器（Controller）](https://kubernetes.io/zh/docs/concepts/architecture/controller/) 关联到一个或多个自定义资源。

除了使用作为 Kubernetes 自身一部分的内置控制器之外，你还可以通过 将控制器添加到集群中来扩展 Kubernetes。

如果正在运行的应用程序能够充当控制器并通过 API 访问的方式来执行任务操控 那些在控制平面中定义的自定义资源，这就是一个 operator 模式的示例。

### Pod

Pod 是 Kubernetes 的原子对象。Pod 表示您的集群上一组正在运行的[容器（containers）](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)。

通常创建 Pod 是为了运行单个主容器。Pod 还可以运行可选的边车（sidecar）容器，以添加诸如日志记录之类的补充特性。通常用 [Deployment](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/) 来管理 Pod。

### Pod Disruption Budget

Also known as:*PDB*
[Pod 干扰预算（Pod Disruption Budget，PDB）](https://kubernetes.io/zh/docs/concepts/workloads/pods/disruptions/) 使应用所有者能够为多实例应用创建一个对象，来确保一定数量的具有指定标签的 Pod 在任何时候都不会被主动驱逐。

PDB 无法防止非主动的中断，但是会计入预算（budget）。

### Pod 优先级（Pod Priority）

Pod 优先级表示一个 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 相对于其他 Pod 的重要性。

[Pod 优先级](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/pod-priority-preemption/#pod-priority) 允许用户为 Pod 设置高于或低于其他 Pod 的优先级 -- 这对于生产集群 工作负载而言是一个重要的特性。

### Pod 安全策略

为 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 的创建和更新操作启用细粒度的授权。

Pod 安全策略是集群级别的资源，它控制着 Pod 规约中的安全性敏感的内容。 `PodSecurityPolicy`对象定义了一组条件以及相关字段的默认值，Pod 运行时必须满足这些条件。Pod 安全策略控制实现上体现为一个可选的准入控制器。

PodSecurityPolicy 自 Kubernetes v1.21 起已弃用，并将在 v1.25 中删除。 我们建议迁移到 [Pod 安全准入](https://kubernetes.io/zh/docs/concepts/security/pod-security-admission/)或第三方准入插件。

### Pod 干扰

[pod 干扰](https://kubernetes.io/zh/docs/concepts/workloads/pods/disruptions/) 是指节点上的 pod 被自愿或非自愿终止的过程。

自愿干扰是由应用程序所有者或集群管理员有意启动的。非自愿干扰是无意的，可能由不可避免的问题触发，如节点耗尽资源或意外删除。

### Pod 水平自动扩缩器（Horizontal Pod Autoscaler）

Also known as:*HPA*
Horizontal Pod Autoscaler（Pod 水平自动扩缩器）是一种 API 资源，它根据目标 CPU 利用率或自定义度量目标扩缩 Pod 副本的数量。

HPA 通常用于 [ReplicationControllers](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-replication-controller) 、[Deployments](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/) 或者 [ReplicaSets](https://kubernetes.io/zh/docs/concepts/workloads/controllers/replicaset/) 上。 HPA 不能用于不支持扩缩的对象，例如 [DaemonSets](https://kubernetes.io/zh/docs/concepts/workloads/controllers/daemonset/)。

### Pod 生命周期

关于 Pod 在其生命周期中处于哪个阶段的更高层次概述。

[Pod 生命周期](https://kubernetes.io/zh/docs/concepts/workloads/pods/pod-lifecycle/) 是关于 Pod 处于哪个阶段的概述。包含了下面5种可能的的阶段: Running、Pending、Succeeded、 Failed、Unknown。关于 Pod 的阶段的更高级描述请查阅 [PodStatus](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#podstatus-v1-core) `phase` 字段。

### QoS 类（QoS Class）

QoS Class（Quality of Service Class）为 Kubernetes 提供了一种将集群中的 Pod 分为几个类型并做出有关调度和驱逐决策的方法。

Pod 的 QoS 类是基于 Pod 在创建时配置的计算资源请求和限制。QoS 类用于制定有关 Pod 调度和逐出的决策。 Kubernetes 可以为 Pod 分配以下 QoS 类：`Guaranteed`，`Burstable` 或者 `BestEffort`。

### ReplicaSet

ReplicaSet 是下一代副本控制器。

ReplicaSet 就像 ReplicationController 那样，确保一次运行指定数量的 Pod 副本。ReplicaSet 支持新的基于集合的选择器需求（在标签的用户指南中有相关描述），而副本控制器只支持基于等值的选择器需求。

### Secret

Secret 用于存储敏感信息，如密码、 OAuth 令牌和 SSH 密钥。

Secret 允许用户对如何使用敏感信息进行更多的控制，并减少信息意外暴露的风险。 默认情况下，Secret 值被编码为 base64 字符串并以非加密的形式存储，但可以配置为 [静态加密（Encrypt at rest）](https://kubernetes.io/zh/docs/tasks/administer-cluster/encrypt-data/#ensure-all-secrets-are-encrypted)。 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 通过挂载卷中的文件的方式引用 Secret，或者通过 kubelet 为 pod 拉取镜像时引用。 Secret 非常适合机密数据使用，而 [ConfigMaps](https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-pod-configmap/) 适用于非机密数据。

### ServiceAccount

为在 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 中运行的进程提供标识。

当 Pod 中的进程访问集群时，API 服务器将它们作为特定的服务帐户进行身份验证， 例如 `default` ，创建 Pod 时，如果你没有指定服务帐户，它将自动被赋予同一个 [名字空间](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/namespaces/)中的 default 服务账户。

### StatefulSet

StatefulSet 用来管理某 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 集合的部署和扩缩， 并为这些 Pod 提供持久存储和持久标识符。

和 [Deployment](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/) 类似， StatefulSet 管理基于相同容器规约的一组 Pod。但和 Deployment 不同的是， StatefulSet 为它们的每个 Pod 维护了一个有粘性的 ID。这些 Pod 是基于相同的规约来创建的， 但是不能相互替换：无论怎么调度，每个 Pod 都有一个永久不变的 ID。

如果希望使用存储卷为工作负载提供持久存储，可以使用 StatefulSet 作为解决方案的一部分。 尽管 StatefulSet 中的单个 Pod 仍可能出现故障， 但持久的 Pod 标识符使得将现有卷与替换已失败 Pod 的新 Pod 相匹配变得更加容易。

### StorageClass

StorageClass 是管理员用来描述不同的可用存储类型的一种方法。

StorageClass 可以映射到服务质量等级（QoS）、备份策略、或者管理员任意定义的策略。 每个 StorageClass 对象包含的字段有 `provisioner`、`parameters` 和 `reclaimPolicy`。 动态制备该存储类别的[持久卷](https://kubernetes.io/zh/docs/concepts/storage/persistent-volumes/)时需要用到这些字段值。 通过设置 StorageClass 对象的名称，用户可以请求特定存储类别。

### UID

Kubernetes 系统生成的字符串，唯一标识对象。

在 Kubernetes 集群的整个生命周期中创建的每个对象都有一个不同的 uid，它旨在区分类似实体的历史事件。

### 上游（Uptream）

可能指的是：核心 Kubernetes 仓库或作为当前仓库派生来源的仓库。

- 在 **Kubernetes社区**：对话中通常使用 *upstream* 来表示核心 Kubernetes 代码库，也就是更广泛的 kubernetes 生态系统、其他代码或第三方工具所依赖的仓库。 例如，[社区成员](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-member)可能会建议将某个功能特性贡献到 upstream，使其位于核心代码库中，而不是维护于插件或第三方工具中。
- 在 **GitHub** 或 **git** 中：约定是将源仓库称为 *upstream*，而派生的仓库则被视为 *downstream*。

### 下游（Downstream）

可以指：Kubernetes 生态系统中依赖于核心 Kubernetes 代码库或分支代码库的代码。

- 在 **Kubernetes 社区**中：*下游(downstream)* 在人们交流中常用来表示那些依赖核心 Kubernetes 代码库的生态系统、代码或者第三方工具。例如，Kubernetes 的一个新特性可以被*下游(downstream)* 应用采用，以提升它们的功能性。
- 在 **GitHub** 或 **git** 中：约定用*下游(downstream)* 表示分支代码库，源代码库被认为是*上游(upstream)*。

### 临时容器（Ephemeral Container）

你可以在 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 中临时运行的一种 [容器（Container）](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers) 类型。

如果想要调查运行中有问题的 Pod，可以向该 Pod 添加一个临时容器并进行诊断。 临时容器没有资源或调度保证，因此不应该使用它们来运行任何部分的工作负荷本身。

### 事件（Event）

每个 Event 是[集群](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-cluster)中某处发生的事件的报告。 它通常用来表述系统中的某种状态变化。

事件的保留时间有限，随着时间推进，其触发方式和消息都可能发生变化。 事件用户不应该对带有给定原因（反映下层触发源）的时间特征有任何依赖， 也不要寄希望于对应该原因的事件会一直存在。

事件应该被视为一种告知性质的、尽力而为的、补充性质的数据。

在 Kubernetes 中，[审计](https://kubernetes.io/zh/docs/tasks/debug/debug-cluster/audit/) 机制会生成一种不同种类的 Event 记录（API 组为 `audit.k8s.io`）。

### 云供应商（Cloud Provider）

Also known as:*云服务供应商（Cloud Service Provider）*
一个提供云计算平台的商业机构或其他组织。

云供应商，有时也称作云服务供应商（CSPs）提供云计算平台或服务。

很多云供应商提供托管的基础设施（也称作基础设施即服务或 IaaS）。 针对托管的基础设施，云供应商负责服务器、存储和网络，而用户（你） 负责管理其上运行的各层软件，例如运行一个 Kubernetes 集群。

你也会看到 Kubernetes 被作为托管服务提供；有时也称作平台即服务或 PaaS。 针对托管的 Kubernetes，你的云供应商负责 Kubernetes 的控制面以及 [节点](https://kubernetes.io/zh/docs/concepts/architecture/nodes/) 及他们所依赖的基础设施： 网络、存储以及其他一些诸如负载均衡器之类的元素。

### 云原生计算基金会（CNCF）

云原生计算基金会（CNCF）建立了可持续的生态系统，并在围绕着 [项目](https://www.cncf.io/projects/) 建立一个社区，将容器编排微服务架构的一部分。 Kubernetes 是一个云原生计算基金会项目.

云原生计算基金会（CNCF）是 [Linux 基金会](https://www.linuxfoundation.org/) 的下属基金会。它的使命是让云原生计算无处不在。

### 云控制器管理器（Cloud Controller Manager）

云控制器管理器是指嵌入特定云的控制逻辑的 [控制平面](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-control-plane)组件。 云控制器管理器使得你可以将你的集群连接到云提供商的 API 之上， 并将与该云平台交互的组件同与你的集群交互的组件分离开来。

通过分离 Kubernetes 和底层云基础设置之间的互操作性逻辑， 云控制器管理器组件使云提供商能够以不同于 Kubernetes 主项目的 步调发布新特征。

### 亲和性（Affinity）

在 Kubernetes 中，_亲和性（affinity）_是一组规则，它们为调度程序提供在何处放置 Pods 提示信息。

亲和性有两种：

- [节点亲和性](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity)
- [Pod 间亲和性](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity)

这些规则是使用 Kubernetes [标签](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/labels/)（label） 和 [pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 中指定的 [选择算符](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/labels/)定义的， 这些规则可以是必需的或首选的，这取决于你希望调度程序执行它们的严格程度。

### 代理（Proxy）

在计算机领域，代理指的是充当远程服务中介的服务器。

客户端与代理进行交互；代理将客户端的数据复制到实际服务器；实际服务器回复代理；代理将实际服务器的回复发送给客户端。

[kube-proxy](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-proxy/) 是集群中每个节点上运行的网络代理，实现了部分 Kubernetes [服务（Service）](https://kubernetes.io/zh/docs/concepts/services-networking/service/) 概念。

你可以将 kube-proxy 作为普通的用户态代理服务运行。 如果你的操作系统支持，则可以在混合模式下运行 kube-proxy；该模式使用较少的系统资源即可达到相同的总体效果。

### 代码贡献者（Code Contributor）

为 Kubernetes 开源代码库开发并贡献代码的人。

代码贡献者也是加入一个或多个 [特别兴趣小组 (SIGs)](https://github.com/kubernetes/community/blob/master/sig-list.md#master-sig-list) 的活跃的 [社区成员](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-member)。

### 准入控制器（Admission Controller）

在对象持久化之前拦截 Kubernetes Api 服务器请求的一段代码

准入控制器可针对 Kubernetes Api 服务器进行配置，可以执行验证，变更或两者都执行。任何准入控制器都可以拒绝访问请求。 变更（mutating）控制器可以修改其允许的对象，验证（validating）控制器则不可以。

- [Kubernetes 文档中的准入控制器](https://kubernetes.io/zh/docs/reference/access-authn-authz/admission-controllers/)

### 初始化容器（Init Container）

应用[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)运行前必须先运行完成的一个或多个初始化容器。

初始化（init）容器像常规应用容器一样，只有一点不同：初始化（init）容器必须在应用容器启动前运行完成。 Init 容器的运行顺序：一个初始化（init）容器必须在下一个初始化（init）容器开始前运行完成。

### 副本控制器（Replication Controller）

一种工作管理多副本应用的负载资源，能够确保特定个数的 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 实例处于运行状态。

控制面确保所指定的个数的 Pods 处于运行状态，即使某些 Pod 会失效， 比如被你手动删除或者因为其他错误启动过多 Pod 时。

**Note:**

ReplicationController 已被启用。请参见 Deployment 执行类似功能。

### 动态卷供应（Dynamic Volume Provisioning）

允许用户请求自动创建存储 [卷](https://kubernetes.io/zh/docs/concepts/storage/volumes/)。

动态供应让集群管理员无需再预先供应存储。相反，它通过用户请求自动地供应存储。 动态卷供应是基于 API 对象 [StorageClass](https://kubernetes.io/zh/docs/concepts/storage/storage-classes/) 的， StorageClass 可以引用 [卷插件](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-volume-plugin) 提供的 [卷](https://kubernetes.io/zh/docs/concepts/storage/volumes/)，也可以引用传递给卷插件（Volume Plugin）的参数集。

### 卷插件（Volume Plugin）

卷插件可以让 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 集成存储。

卷插件让你能给 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 附加和挂载存储卷。 卷插件既可以是 *in tree* 也可以是 *out of tree* 。*in tree* 插件是 Kubernetes 代码库的一部分， 并遵循其发布周期。而 *Out of tree* 插件则是独立开发的。

### 卷（Volume）

A directory containing data, accessible to the containers in a pod. aka: tags: - core-object - fundamental --- -- containers in a Pod. -- 包含可被 Pod 中容器访问的数据的目录。 每个 Kubernetes 卷在所处的 Pod 存在期间保持存在状态。 因此，卷的生命期会超出 Pod 中运行的容器， 并且保证容器重启之后仍保留数据。 更多信息可参考storage

包含可被 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 中[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)访问的数据的目录。

每个 Kubernetes 卷在所处的 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 存在期间保持存在状态。 因此，卷的生命期会超出 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 中运行的[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)， 并且保证[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)重启之后仍保留数据。

更多信息可参考[storage](https://kubernetes.io/zh/docs/concepts/storage/)

### 名字空间（Namespace）

名字空间是 Kubernetes 用来支持隔离单个 [集群](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-cluster)中的资源组的一种抽象。

名字空间用来组织集群中对象，并为集群资源划分提供了一种方法。 同一名字空间内的资源名称必须唯一，但跨名字空间时不作要求。 基于名字空间的作用域限定仅适用于名字空间作用域的对象（例如 Deployment、Services 等）， 而不适用于集群作用域的对象（例如 StorageClass、Node、PersistentVolume 等）。 在一些文档里名字空间也称为命名空间。

### 名称（Name）

客户端提供的字符串，引用资源 url 中的对象，如`/api/v1/pods/some name`。

某一时刻，只能有一个给定类型的对象具有给定的名称。但是，如果删除该对象，则可以创建同名的新对象。

### 周期调度任务（CronJob）

管理定期运行的 [任务](https://kubernetes.io/zh/docs/concepts/workloads/controllers/job/)。

Cronjob 对象类似 *crontab* 文件中的一行命令，它声明了一个遵循 [Cron](https://en.wikipedia.org/wiki/Cron) 格式的调度任务。

### 垃圾收集

垃圾收集是 Kubernetes 用于清理集群资源的各种机制的统称。

Kubernetes 使用垃圾收集机制来清理资源，例如： [未使用的容器和镜像](https://kubernetes.io/zh/docs/concepts/workloads/controllers/garbage-collection/#containers-images)、 [失败的 Pod](https://kubernetes.io/zh/docs/concepts/workloads/pods/pod-lifecycle/#pod-garbage-collection)、 [目标资源拥有的对象](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/owners-dependents/)、 [已完成的 Job](https://kubernetes.io/zh/docs/concepts/workloads/controllers/ttlafterfinished/)、 过期或出错的资源。

### 基于角色的访问控制（RBAC）

管理授权决策，允许管理员通过 [Kubernetes API](https://kubernetes.io/zh/docs/concepts/overview/kubernetes-api/) 动态配置访问策略。

RBAC 使用 *角色* (包含权限规则)和 *角色绑定* (将角色中定义的权限授予一组用户)。

### 安全上下文（Security Context）

securityContext 字段定义 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 或 [容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)的特权和访问控制设置。

在一个 `securityContext` 字段中，你可以设置进程所属用户和用户组、权限相关设置。你也可以设置安全策略（例如：SELinux、AppArmor、seccomp）。

`PodSpec.securityContext` 字段配置会应用到一个 Pod 中的所有的 container 。

### 容器存储接口（Container Storage Interface，CSI）

容器存储接口 （CSI） 定义了存储系统暴露给容器的标准接口。

CSI 允许存储驱动提供商为 Kubernetes 创建定制化的存储插件， 而无需将这些插件的代码添加到 Kubernetes 代码仓库（外部插件）。 要使用某个存储提供商的 CSI 驱动，你首先要 [将它部署到你的集群上](https://kubernetes-csi.github.io/docs/deploying.html)。 然后你才能创建使用该 CSI 驱动的 [Storage Class](https://kubernetes.io/zh/docs/concepts/storage/storage-classes/) 。

- [Kubernetes 文档中关于 CSI 的描述](https://kubernetes.io/zh/docs/concepts/storage/volumes/#csi)
- [可用的 CSI 驱动列表](https://kubernetes-csi.github.io/docs/drivers.html)

### 容器环境变量（Container Environment Variables）

容器环境变量提供了 name=value 形式的、在 [pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 中运行的容器所必须的一些重要信息。

容器环境变量为运行中的容器化应用提供必要的信息，同时还提供与 [容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers) 重要资源相关的其他信息，例如：文件系统信息、容器自身的信息以及其他像服务端点（Service endpoints）这样的集群资源信息。

### 容器生命周期钩子（Container Lifecycle Hooks）

生命周期钩子暴露[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)管理生命周期中的事件，允许用户在事件发生时运行代码。

针对容器暴露了两个钩子：PostStart 在容器创建之后立即执行，PreStop 在容器停止之前立即阻塞并被调用。

### 容器网络接口（CNI）

容器网络接口 (CNI) 插件是遵循 appc/CNI 协议的一类网络插件。

- 想了解 Kubernetes 和 CNI 请参考 ["网络插件"](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#cni)。

### 容器运行时接口（CRI）

容器运行时接口 (CRI) 是一组与节点上 kubelet 集成的容器运行时 API

更多信息， 请参考 [容器运行时接口](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-node/container-runtime-interface.md) API 与规格。

### 容器运行时（Container Runtime）

容器运行环境是负责运行容器的软件。

Kubernetes 支持容器运行时，例如 [Docker](https://kubernetes.io/zh/docs/reference/kubectl/docker-cli-to-kubectl/)、 [containerd](https://containerd.io/docs/)、[CRI-O](https://cri-o.io/#what-is-cri-o) 以及 [Kubernetes CRI (容器运行环境接口)](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-node/container-runtime-interface.md) 的其他任何实现。

### 容器（Container）

容器是可移植、可执行的轻量级的镜像，包含其中的软件及其相关依赖。

容器使应用和底层的主机基础设施解耦，降低了应用在不同云环境或者操作系统上的部署难度，便于应用扩展。

### 容忍度（Toleration）

一个核心对象，由三个必需的属性组成：key、value 和 effect。 容忍度允许将 Pod 调度到具有对应[污点](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/taint-and-toleration/) 的节点或节点组上。

容忍度和[污点](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/taint-and-toleration/)共同作用可以 确保不会将 Pod 调度在不适合的节点上。 在同一 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 上可以设置一个 或者多个容忍度。 容忍度表示在包含对应[污点](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/taint-and-toleration/) 的节点或节点组上调度 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 是允许的（但不必要）。

### 对象（Object）

Kubernetes 系统中的实体。Kubernetes API 用这些实体表示集群的状态。

Kubernetes 对象通常是一个“目标记录”-一旦你创建了一个对象，Kubernetes [控制平面（Control Plane）](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-control-plane) 不断工作，以确保它代表的项目确实存在。 创建一个对象相当于告知 Kubernetes 系统：你期望这部分集群负载看起来像什么；这也就是你集群的期望状态。

### 工作组（Working Group，WG）

工作组是为了方便讨论和（或）推进执行一些短周期、窄范围、或者从委员会和 SIG 分离出来的项目、以及跨 SIG 的活动。

工作组可以将人们组织起来，一起完成一项分散的任务。

更多信息请参考 [kubernetes/community](https://github.com/kubernetes/community) 代码库和当前的 [SIGs 和工作组](https://github.com/kubernetes/community/blob/master/sig-list.md) 列表。

### 工作负载（Workload）

工作负载是在 Kubernetes 上运行的应用程序。

代表不同类型或部分工作负载的各种核心对象包括 DaemonSet， Deployment， Job， ReplicaSet， and StatefulSet。

例如，具有 Web 服务器和数据库的工作负载可能在一个 [StatefulSet](https://kubernetes.io/zh/docs/concepts/workloads/controllers/statefulset/) 中运行数据库， 而 Web 服务器运行在 [Deployment](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/)。

### 干扰（Disruption）

干扰是指导致一个或者多个 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 服务停止的事件。 干扰会影响工作负载资源，比如 [Deployment](https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment/) 这种依赖于受影响 Pod 的资源。

如果你作为一个集群操作人员，销毁了一个从属于某个应用的 Pod, Kubernetes 视之为**自愿干扰（Voluntary Disruption）**。 如果由于节点故障 或者影响更大区域故障的断电导致 Pod 离线，kubernetes 视之为**非愿干扰（Involuntary Disruption）**。

更多信息请查阅[Disruptions](https://kubernetes.io/zh/docs/concepts/workloads/pods/disruptions/)

### 平台开发人员（Platform Developer）

定制 Kubernetes 平台以满足自己的项目需求的人。

平台开发人员可以使用[定制资源](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/api-extension/custom-resources/) 或[使用汇聚层扩展 Kubernetes API](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/) 来为其 Kubernetes 实例增加功能，特别是为其应用程序添加功能。 一些平台开发人员也是 kubernetes [贡献者](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-contributor)， 他们会开发贡献给 Kubernetes 社区的扩展。 另一些平台开发人员则开发封闭源代码的商业扩展或用于特定网站的扩展。

### 应用开发者（Application Developer）

编写可以在 Kubernetes 集群上运行的应用的人。

应用开发者专注于应用的某一部分。他们工作范围的大小有明显的差异。

### 应用架构师（Application Architect）

应用架构师是负责应用高级设计的人。

应用架构师确保应用的实现允许它和周边组件进行可扩展的、可持续的交互。 周边组件包括数据库、日志基础设施和其他微服务。

### 应用程序容器（App Container）

应用程序 [容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers) （或 app 容器）在 [pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 中，在 [初始化容器](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-init-container) 启动完毕后才开始启动。

初始化容器使你可以分离对于[工作负载](https://kubernetes.io/zh/docs/concepts/workloads/) 整体而言很重要的初始化细节，并且一旦应用容器启动，它不需要继续运行。 如果 pod 没有配置任何初始化容器，则该 pod 中的所有容器都是应用程序容器。

### 应用（Applications）

The layer where various containerized applications run. aka: tags: - fundamental --- -- 各种容器化应用运行所在的层。

各种容器化应用运行所在的层。

### 开发者（Developer）

指的是：[应用开发者](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-application-developer)、 [代码贡献者](https://kubernetes.io/docs/community/devel/)、 或[平台开发者](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-platform-developer)。

根据上下文的不同，“开发者”这个被多处使用的词条会有不同的含义。

### 成员（Member）

K8s 社区中持续活跃的[贡献者（contributor）](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-contributor)。

可以将问题单（issue）和 PR 指派给成员（Member），成员（Member）也可以通过 GitHub 小组加入 [特别兴趣小组 (SIGs)](https://github.com/kubernetes/community/blob/master/sig-list.md#master-sig-list)。针对成员（Member）所提交的 PR，系统自动运行提交前测试。成员（Member）应该是持续活跃的社区贡献者。

### 托管服务

由第三方供应商负责维护的一种软件产品。

托管服务的一些例子有 AWS EC2、Azure SQL 数据库和 GCP Pub/Sub 等， 不过它们也可以是可以被某应用使用的任何软件交付件。 [服务目录](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/service-catalog/) 提供了一种方法用来列举、制备和绑定到 [服务代理商（Service Brokers）](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-service-broker) 所提供的托管服务。

### 扩展组件（Extensions）

扩展组件是扩展并与 Kubernetes 深度集成以支持新型硬件的软件组件。

许多集群管理员会使用托管的 Kubernetes 或其某种发行包，这些集群预装了扩展。 因此，大多数 Kubernetes 用户将不需要 安装[扩展组件](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/extend-cluster/#extensions)， 需要编写新的扩展组件的用户就更少了。

### 批准者（Approver）

可以审核并批准 Kubernetes 代码贡献的人。

代码审核的重点是代码质量和正确性，而批准的重点是对贡献的整体接受。 整体接受包括向后/向前兼容性、遵守 API 和参数约定、细微的性能和正确性问题、与系统其他部分的交互等。 批准者状态的作用域是代码库的一部分。审批者以前被称为维护者。

### 抢占（Preemption）

Kubernetes 中的抢占逻辑通过驱逐[节点（Node）](https://kubernetes.io/zh/docs/concepts/architecture/nodes/) 上的低优先级[Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 来帮助悬决的 Pod 找到合适的节点。

如果一个 Pod 无法调度，调度器会尝试 [抢占](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/pod-priority-preemption/#preemption) 较低优先级的 Pod，以使得悬决的 Pod 有可能被调度。

### 持久卷申领（Persistent Volume Claim）

申领[持久卷（PersistentVolume）](https://kubernetes.io/zh/docs/concepts/storage/persistent-volumes/)中定义的存储资源，以便可以将其挂载为[容器（container）](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)中的卷。

指定存储的数量，如何访问存储（只读、读写或独占）以及如何回收存储（保留、回收或删除）。存储本身的详细信息在 PersistentVolume 对象中。

### 持久卷（Persistent Volume）

持久卷是代表集群中一块存储空间的 API 对象。 它是通用的、可插拔的、并且不受单个 [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 生命周期约束的持久化资源。

持久卷（PersistentVolumes，PV）提供了一个 API，该 API 对存储的供应方式细节进行抽象，令其与使用方式相分离。 在提前创建存储（静态供应）的场景中，PV 可以直接使用。 在按需提供存储（动态供应）的场景中，需要使用 PersistentVolumeClaims (PVCs)。

### 控制器（Controller）

在 Kubernetes 中，控制器通过监控[集群](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-cluster) 的公共状态，并致力于将当前状态转变为期望的状态。

控制器（[控制平面](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-control-plane)的一部分） 通过 [apiserver](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-apiserver/) 监控你的集群中的公共状态。

其中一些控制器是运行在控制平面内部的，对 Kubernetes 来说，他们提供核心控制操作。 比如：部署控制器（deployment controller）、守护控制器（daemonset controller）、 命名空间控制器（namespace controller）、持久化数据卷控制器（persistent volume controller）（等）都是运行在 [kube-controller-manager](https://kubernetes.io/docs/reference/generated/kube-controller-manager/) 中的。

### 控制平面（Control Plane）

控制平面（Control Plane）是指容器编排层，它暴露 API 和接口来定义、 部署容器和管理容器的生命周期。

这个编排层是由多个不同的组件组成，例如以下（但不限于）几种：

- [etcd](https://kubernetes.io/zh/docs/tasks/administer-cluster/configure-upgrade-etcd/)
- [API 服务器](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-apiserver/)
- [调度器](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-scheduler/)
- [控制器管理器](https://kubernetes.io/docs/reference/generated/kube-controller-manager/)
- [云控制器管理器](https://kubernetes.io/zh/docs/concepts/architecture/cloud-controller/)

这些组件可以以传统的系统服务运行也可以以容器的形式运行.运行这些组件的主机过去称为 master 节点。

### 控制组（cgroup）

一组具有可选资源隔离、审计和限制的 Linux 进程。

Cgroup 是一个 Linux 内核特性，对一组进程的资源使用（CPU、内存、磁盘 I/O 和网络等）进行限制、审计和隔离。

### 数据平面（Data Plane）

提供诸如 CPU，内存，网络和存储的能力，以便容器可以运行并连接到网络。

### 日志（Logging）

日志是 [集群（cluster）](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-cluster) 或应用程序记录的事件列表。

应用程序和系统日志可以帮助你了解集群内部发生的情况。日志对于调试问题和监视集群活动非常有用。

### 服务代理（Service Broker）

由第三方提供并维护的一组[托管服务](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-managed-service)的访问端点。

[服务代理（Service Brokers）](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-service-broker)会实现 [开放服务代理 API 规范](https://github.com/openservicebrokerapi/servicebroker/blob/v2.13/spec.md) 并为应用提供使用其托管服务的标准接口。 [服务目录（Service Catalog）](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/service-catalog/)则提供一种方法，用来列举、供应和绑定服务代理商所提供的托管服务。

### 服务目录（Service Catalog）

服务目录是一种扩展 API，它能让 Kubernetes 集群中运行的应用易于使用外部托管的的软件服务，例如云供应商提供的数据仓库服务。

服务目录可以检索、供应、和绑定由 [服务代理人（Service Brokers）](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-service-broker) 提供的外部[托管服务（Managed Services）](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-managed-service)， 而无需知道那些服务具体是怎样创建和托管的。

### 服务（Service）

将运行在一组 [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 上的应用程序公开为网络服务的抽象方法。

服务所针对的 Pod 集（通常）由[选择算符](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/labels/)确定。 如果有 Pod 被添加或被删除，则与选择算符匹配的 Pod 集合将发生变化。 服务确保可以将网络流量定向到该工作负载的当前 Pod 集合。

### 标签（Label）

用来为对象设置可标识的属性标记；这些标记对用户而言是有意义且重要的。

标签是一些关联到 [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 这类对象上的键值对。 它们通常用来组织和选择对象子集。

### 污点（Taint）

污点是一种一个核心对象，包含三个必需的属性：key、value 和 effect。 污点会阻止在[节点](https://kubernetes.io/zh/docs/concepts/architecture/nodes/) 或节点组上调度 [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)。

污点和[容忍度](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/taint-and-toleration/)一起工作， 以确保不会将 Pod 调度到不适合的节点上。 同一[节点](https://kubernetes.io/zh/docs/concepts/architecture/nodes/)上可标记一个或多个污点。 节点应该仅调度那些带着能与污点相匹配容忍度的 Pod。

### 注解（Annotation）

注解是以键值对的形式给资源对象附加随机的无法标识的元数据。

注解中的元数据可大可小，可以是结构化的也可以是非结构化的， 并且能包含[标签](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/labels/)不允许使用的字符。 像工具和软件库这样的客户端可以检索这些元数据。

### 混排切片（Shuffle Sharding）

混排切片（Shuffle Sharding）是指一种将请求指派给队列的技术，其隔离性好过对队列个数哈希取模的方式。

### 清单（Manifest）

JSON 或 YAML 格式的 Kubernetes API 对象规范。

清单指定了在应用该清单时 kubernetes 将维护的对象的期望状态。每个配置文件可包含多个清单。

### 特别兴趣小组（SIG）

共同管理大范畴 Kubernetes 开源项目中某组件或方面的一组[社区成员](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-member)。

SIG 中的成员对推进某个领域（如体系结构、API 机制构件或者文档）具有相同的兴趣。 SIGs 必须遵从 [governance guidelines](https://github.com/kubernetes/community/blob/master/committee-steering/governance/sig-governance.md) 的规定， 不过可以有自己的贡献策略以及通信渠道（方式）。

更多的详细信息可参阅 [kubernetes/community](https://github.com/kubernetes/community) 仓库以及 [SIGs 和工作组（Working Groups）](https://github.com/kubernetes/community/blob/master/sig-list.md)的最新列表。

### 用户名字空间

用来模拟 root 用户的内核功能特性。用来支持“Rootless 容器”。

用户名字空间（User Namespace）是一种 Linux 内核功能特性，允许非 root 用户 模拟超级用户（"root"）的特权，例如用来运行容器却不必成为容器之外的超级用户。

用户名字空间对于缓解因潜在的容器逃逸攻击而言是有效的。

在用户名字空间语境中，名字空间是 Linux 内核的功能特性而不是 Kubernetes 意义上的 [名字空间](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/namespaces/)概念。

### 端点（Endpoints）

端点负责记录与服务的[选择器](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/labels/)相匹配的 Pods 的 IP 地址。

端点可以手动配置到[服务（Service）](https://kubernetes.io/zh/docs/concepts/services-networking/service/)上，而不必指定选择器标识。

[EndpointSlice](https://kubernetes.io/zh/docs/concepts/services-networking/endpoint-slices/)提供了一种可伸缩、可扩展的替代方案。

### 网络策略

网络策略是一种规范，规定了允许 Pod 组之间、Pod 与其他网络端点之间以怎样的方式进行通信。

网络策略帮助你声明式地配置允许哪些 Pod 之间、哪些命名空间之间允许进行通信， 并具体配置了哪些端口号来执行各个策略。`NetworkPolicy` 资源使用标签来选择 Pod， 并定义了所选 Pod 可以接受什么样的流量。网络策略由网络提供商提供的并被 Kubernetes 支持的网络插件实现。 请注意，当没有控制器实现网络资源时，创建网络资源将不会生效。

### 聚合层（Aggregation Layer）

聚合层允许你在自己的集群上安装额外的 Kubernetes 风格的 API。

当你配置了 [Kubernetes API Server](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-apiserver/) 来 [支持额外的 API](https://kubernetes.io/zh/docs/tasks/extend-kubernetes/configure-aggregation-layer/)， 你就可以在 Kubernetes API 中增加 `APIService` 对象来 "申领（Claim）" 一个 URL 路径。

### 节点压力驱逐

Also known as:*kubelet eviction*
节点压力驱逐是 [kubelet](https://kubernetes.io/docs/reference/generated/kubelet) 主动终止 Pod 以回收节点上资源的过程。

kubelet 监控集群节点上的 CPU、内存、磁盘空间和文件系统 inode 等资源。 当这些资源中的一个或多个达到特定消耗水平时， kubelet 可以主动使节点上的一个或多个 Pod 失效，以回收资源并防止饥饿。

节点压力驱逐不用于 [API 发起的驱逐](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/)。

### 节点（Node）

Kubernetes 中的工作机器称作节点。

工作机器可以是虚拟机也可以是物理机，取决于集群的配置。 其上部署了运行 [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 所必需的本地守护进程或服务， 并由主控组件来管理。 节点上的的守护进程包括 [kubelet](https://kubernetes.io/docs/reference/generated/kubelet)、 [kube-proxy](https://kubernetes.io/zh/docs/reference/command-line-tools-reference/kube-proxy/) 以及一个 [Docker](https://kubernetes.io/zh/docs/reference/kubectl/docker-cli-to-kubectl/) 这种 实现了 [CRI](https://kubernetes.io/zh/docs/concepts/overview/components/#container-runtime) 的容器运行时。

在早期的 Kubernetes 版本中，节点也称作 "Minions"。

### 设备插件（Device Plugin）

设备插件工作在节点主机上，给 [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 提供访问资源的权限，比如特定厂商初始化或者安装的本地硬件。

设备插件将资源告知 [kubelet](https://kubernetes.io/docs/reference/generated/kubelet) ，以便相关节点上运行的工作负载Pod可以访问硬件功能。

更多信息请查阅[设备插件](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/)

### 证书（Certificate）

证书是个安全加密文件，用来确认对 Kubernetes 集群访问的合法性。

证书可以让 Kubernetes 集群中运行的应用程序安全的访问 Kubernetes API。证书可以确认客户端是否被允许访问 API。

### 评审者（Reviewer）

评审者是负责评审项目的某部分代码以便提高代码质量和正确性的人。

评审者既要了解代码库又要了解软件工程规范。评审者状态是基于代码库的组成部分来设定的。

### 贡献者许可协议（CLA）

[贡献者](https://kubernetes.io/zh/docs/reference/glossary/?all=true#term-contributor)对他们在开源项目中所贡献的代码的授权许可条款。

CLA 对解决贡献者在开源社区所贡献的资料和智力资产（IP）导致的法律纠纷很有帮助。

### 贡献者（Contributor）

通过贡献代码、文档或者投入时间等方式来帮助 Kubernetes 项目或社区的人。

贡献形式包括提交拉取请求（PRs）、问题报告（Issues）、反馈、参与[特别兴趣小组（SIG）](https://github.com/kubernetes/community/blob/master/sig-list.md#master-sig-list)或者组织社区活动等等。

### 资源配额（Resource Quotas）

资源配额提供了限制每个 [命名空间](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/namespaces/) 的资源消耗总和的约束。

限制了命名空间中每种对象可以创建的数量，也限制了项目中可被资源对象利用的计算资源总数。

### 选择算符（Selector）

选择算符允许用户通过[标签（labels）](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/labels/)对一组资源对象进行筛选过滤。

在查询资源列表时，选择算符可以通过标签对资源进行过滤筛选。

### 量纲（Quantity）

使用全数字来表示较小数值或使用 [SI](https://zh.wikipedia.org/wiki/International_System_of_Units) 后缀表示较大数值的表示法。

量纲是使用紧凑的全数字表示法来表示小数值或带有国际计量单位制（SI） 的大数值的表示法。 小数用 milli 单位表示，而大数用 kilo、mega 或 giga 单位表示。

例如，数字 `1.5` 表示为 `1500m`， 而数字 `1000` 表示为 `1k`，`1000000` 表示为 `1M`。 你还可以指定二进制表示法后缀；数字 2048 可以写成 `2Ki`。

公认的十进制（10 的幂数）单位是 `m`（milli）、`k`（kilo，有意小写）、 `M`（mega）、`G`（giga）、`T`（terra）、`P`（peta）、`E`（exa）。

公认的二进制（2 的幂数）单位是 `Ki` (kibi)、`Mi` (mebi)、`Gi` (gibi)、 `Ti` (tebi)、 `Pi` (pebi)、 `Ei` (exbi)。

### 镜像（Image）

镜像是保存的[容器](https://kubernetes.io/zh/docs/concepts/overview/what-is-kubernetes/#why-containers)实例，它打包了应用运行所需的一组软件。

镜像是软件打包的一种方式，可以将镜像存储在容器镜像仓库、拉取到本地系统并作为应用来运行。 镜像中包含的元数据指明了运行什么可执行程序、是由谁构建的以及其他信息。

### 附加组件（Add-ons）

扩展 Kubernetes 功能的资源。

[安装附加组件](https://kubernetes.io/zh/docs/concepts/cluster-administration/addons/) 阐释了更多关于如何在集群内使用附加组件，并列出了一些流行的附加组件。

### 集群操作者（Cluster Operator）

配置、控制、监控集群的人。

他们的主要责任是保持集群正常运行，可能需要进行周期性的维护和升级活动。

**注意：** 集群操作者不同于[操作者模式（Operator Pattern）](https://www.openshift.com/learn/topics/operators)，操作者模式是用来扩展 Kubernetes API 的。

### 集群架构师（Cluster Architect）

集群架构师负责设计集群的基础设施，可能包含一个或多个 Kubernetes 集群。

集群架构师要具备分布式系统的最佳实践经验，例如：高可用性和安全性。

### 集群（Cluster）

集群由一组被称作节点的机器组成。这些节点上运行 Kubernetes 所管理的容器化应用。集群具有至少一个工作节点。

工作节点托管作为应用负载的组件的 Pod 。控制平面管理集群中的工作节点和 Pod 。 为集群提供故障转移和高可用性，这些控制平面一般跨多主机运行，集群跨多个节点运行。

### 静态 Pod（Static Pod）

由特定节点上的 kubelet 守护进程直接管理的 [pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)，

API 服务器不了解它的存在。

### 驱逐

驱逐即终止节点上一个或多个 Pod 的过程。

驱逐的两种类型

- [节点压力驱逐](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/pod-priority-preemption/)
- [API 发起的驱逐](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.23/)