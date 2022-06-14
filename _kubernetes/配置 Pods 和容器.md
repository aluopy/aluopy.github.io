---
title: "配置 Pods 和容器"
excerpt: "本文展示如何将内存请求（request）和内存限制（limit）分配给一个容器。我们保障容器拥有它请求数量的内存，但不允许使用超过限制数量的内存。"
toc: true
toc_label: "配置 Pods 和容器"
toc_icon: "cog"
categories: Kubernetes
tags:
  - kubernetes
  - pod
  - Container
---

## 为容器和 Pod 分配内存资源

本文展示如何将内存 *请求* （request）和内存 *限制* （limit）分配给一个容器。 我们保障容器拥有它请求数量的内存，但不允许使用超过限制数量的内存。

### 指定内存请求和限制

要为容器指定内存请求，请在容器资源清单中添加 `resources：requests` 字段。 同理，要指定内存限制，请添加 `resources：limits`。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-ctr
    image: polinux/stress
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```

> 配置文件的 `args` 部分提供了容器启动时的参数。 `"--vm-bytes", "150M"` 参数告知容器尝试分配 150 MiB 内存。





#### 超过容器限制的内存

创建一个 Pod，尝试分配超出其限制的内存。 这是一个 Pod 的配置文件 `memory-request-limit-2.yaml`，其拥有一个容器，该容器的内存请求为 50 MiB，内存限制为 100 MiB：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo-2
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-2-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "50Mi"
      limits:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "250M", "--vm-hang", "1"]
```

在配置文件的 `args` 部分中，可以看到容器会尝试分配 250 MiB 内存，这远高于 100 MiB 的限制。

创建 Pod：

```shell
$ kubectl apply -f memory-request-limit-2.yaml --namespace=mem-example
pod/memory-demo-2 created
```

查看 Pod 相关的详细信息：

```shell
# 容器可能正在运行或被杀死。重复下面的命令，直到容器被杀掉
$ kubectl get pod memory-demo-2 --namespace=mem-example
NAME            READY   STATUS      RESTARTS   AGE
memory-demo-2   0/1     OOMKilled   0          12s
```

获取容器更详细的状态信息：

```shell
# 输出结果显示：由于内存溢出（OOM），容器已被杀掉
$ kubectl get pod memory-demo-2 --output=yaml --namespace=mem-example
... ...
    lastState:
       terminated:
         containerID: docker://65183c1877aaec2e8427bc95609cc52677a454b56fcb24340dbd22917c23b10f
         exitCode: 137
         finishedAt: 2017-06-20T20:52:19Z
         reason: OOMKilled
         startedAt: null
... ...
```

本练习中的容器可以被重启，所以 kubelet 会重启它。 多次运行下面的命令，可以看到容器在反复的被杀死和重启：

```shell
$ kubectl get pod memory-demo-2 --namespace=mem-example
NAME            READY     STATUS      RESTARTS   AGE
memory-demo-2   0/1       OOMKilled   1          37s
$ kubectl get pod memory-demo-2 --namespace=mem-example
NAME            READY     STATUS    RESTARTS   AGE
memory-demo-2   1/1       Running   2          40s
```

> 输出结果显示：容器被杀掉、重启、再杀掉、再重启……

查看关于该 Pod 历史的详细信息：

```shell
$ kubectl describe pod memory-demo-2 --namespace=mem-example
```

输出结果显示：该容器反复的在启动和失败：

```
... Normal  Created   Created container with id 66a3a20aa7980e61be4922780bf9d24d1a1d8b7395c09861225b0eba1b1f8511
... Warning BackOff   Back-off restarting failed container
```

查看关于集群节点的详细信息：

```shell
$ kubectl describe nodes
```

输出结果包含了一条练习中的容器由于内存溢出而被杀掉的记录：

```
Warning OOMKilling Memory cgroup out of memory: Kill process 4481 (stress) score 1994 or sacrifice child
```

删除 Pod:

```shell
$ kubectl delete pod memory-demo-2 --namespace=mem-example
pod "memory-demo-2" deleted
```

#### 超过整个节点容量的内存

内存请求和限制是与**容器**关联的，但将 Pod 视为具有内存请求和限制，也是很有用的。 Pod 的内存请求是 Pod 中所有容器的内存请求之和。 同理，Pod 的内存限制是 Pod 中所有容器的内存限制之和。

Pod 的调度基于请求。只有当节点拥有足够满足 Pod 内存请求的内存时，才会将 Pod 调度至节点上运行。

将创建一个 Pod，其内存请求超过了集群中的任意一个节点所拥有的内存。 这是该 Pod 的配置文件 `memory-request-limit-3.yaml`，其拥有一个请求 1000 GiB 内存的容器，这应该超过了集群中任何节点的容量。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo-3
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-3-ctr
    image: polinux/stress
    resources:
      limits:
        memory: "1000Gi"
      requests:
        memory: "1000Gi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```

创建 Pod：

```shell
$ kubectl apply -f memory-request-limit-3.yaml --namespace=mem-example
pod/memory-demo-3 created
```

查看 Pod 状态：

```shell
$ kubectl get pod memory-demo-3 --namespace=mem-example
NAME            READY   STATUS             RESTARTS   AGE
memory-demo-3   0/1     Pending            0          10s
```

> 输出结果显示：Pod 处于 PENDING 状态。 这意味着，该 Pod 没有被调度至任何节点上运行，并且它会无限期的保持该状态：

查看关于 Pod 的详细信息，包括事件：

```shell
# 输出结果显示：由于节点内存不足，该容器无法被调度
$ kubectl describe pod memory-demo-3 --namespace=mem-example
... ...
Events:
  ...  Reason            Message
       ------            -------
  ...  FailedScheduling  No nodes are available that match all of the following predicates:: Insu
```

#### 内存单位

内存资源的基本单位是字节（byte）。你可以使用这些后缀之一，将内存表示为 纯整数或定点整数：E、P、T、G、M、K、Ei、Pi、Ti、Gi、Mi、Ki。 例如，下面是一些近似相同的值：

```
128974848, 129e6, 129M , 123Mi
```

删除 Pod：

```shell
$ kubectl delete pod memory-demo-3 --namespace=mem-example
pod "memory-demo-3" deleted
```

#### 如果没有指定内存限制

如果没有为一个容器指定内存限制，则自动遵循以下情况之一：

- 容器可无限制地使用内存。容器可以使用其所在节点所有的可用内存， 进而可能导致该节点调用 OOM Killer。 此外，如果发生 OOM Kill，没有资源限制的容器将被杀掉的可行性更大。
- 运行的容器所在命名空间有默认的内存限制，那么该容器会被自动分配默认限制。 集群管理员可用使用 [LimitRange](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.21/#limitrange-v1-core) 来指定默认的内存限制。

#### 内存请求和限制的目的

通过为集群中运行的容器配置内存请求和限制，你可以有效利用集群节点上可用的内存资源。 通过将 Pod 的内存请求保持在较低水平，你可以更好地安排 Pod 调度。 通过让内存限制大于内存请求，你可以完成两件事：

- Pod 可以进行一些突发活动，从而更好的利用可用内存。
- Pod 在突发活动期间，可使用的内存被限制为合理的数量。

#### 





### 为容器和 Pods 分配 CPU 资源