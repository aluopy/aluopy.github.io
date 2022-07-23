---
title: "Kubernetes Metrics Server"
permalink: /kubernetes/metrics-server/
toc: true
#toc_label: "kubernetes-metrics-server"
#toc_icon: "cog"
categories: kubernetes
tags:
  - kubernetes
  - metrics-server
---

Metrics Server 是 Kubernetes 内置自动缩放管道的可扩展、高效的容器资源指标来源。

Metrics Server 从 Kubelets 收集资源指标，并通过 Metrics API 在 Kubernetes apiserver 中公开它们，供 Horizontal Pod Autoscaler 和 Vertical Pod Autoscaler 使用。 Metrics API 也可以通过 kubectl top 访问，从而更容易调试自动缩放管道。

Metrics Server 不适用于非自动缩放目的。例如，不要使用它来将指标转发给监控解决方案，或作为监控解决方案指标的来源。在这种情况下，请直接从 Kubelet /metrics/resource 端点收集指标。

Metrics Server 提供：

- 适用于大多数集群的单一部署（请参阅[要求](https://github.com/kubernetes-sigs/metrics-server#requirements)）
- 快速自动缩放，每 15 秒收集一次指标。
- 资源效率，集群中每个节点使用 1 mili 的 CPU 核心和 2 MB 的内存。
- 可扩展支持多达 5,000 个节点集群。

## 安装 Metrics Server

下载 yaml 文件

```shell
$ wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

通过将 `--kubelet-insecure-tls` 传递给 Metrics Server 来禁用证书验证

```yaml
kind: Deployment
spec:
    spec:
      containers:
      - args:
        - --kubelet-insecure-tls
        ...
```

> 修改 deployment 的镜像为国内镜像

安装

```shell
$ kubectl apply -f components.yaml
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
```

## 查看运行状态

```shell
$ kubectl get pod -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-7fcddf9954-vtl7g   1/1     Running   0          5d8h
calico-node-f4qw9                          1/1     Running   0          5d8h
calico-node-qs2lc                          1/1     Running   0          5d8h
calico-node-tsslv                          1/1     Running   0          5d8h
coredns-6d8c4cb4d-cgm4f                    1/1     Running   0          5d8h
coredns-6d8c4cb4d-mzzq6                    1/1     Running   0          5d8h
etcd-m1                                    1/1     Running   1          5d8h
kube-apiserver-m1                          1/1     Running   1          5d8h
kube-controller-manager-m1                 1/1     Running   1          5d8h
kube-proxy-bf6ns                           1/1     Running   0          5d8h
kube-proxy-rsrkp                           1/1     Running   0          5d8h
kube-proxy-vbv49                           1/1     Running   0          5d8h
kube-scheduler-m1                          1/1     Running   1          5d8h
metrics-server-8f99c487b-8qgpg             1/1     Running   0          41s
```

查看 metrics-server 或资源指标 API (`metrics.k8s.io`) 是否已经运行

```shell
$ kubectl get apiservices | grep metrics
v1beta1.metrics.k8s.io                 kube-system/metrics-server   True        52s
```

## 获取指标数据

获取 Pod 及 node 指标数据

```shell
$ kubectl top pod
NAME    CPU(cores)   MEMORY(bytes)   
nginx   0m           3Mi

$ kubectl top node
NAME   CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
m1     206m         4%     2884Mi          33%       
w1     135m         3%     1893Mi          21%       
w2     115m         2%     1582Mi          18%
```

