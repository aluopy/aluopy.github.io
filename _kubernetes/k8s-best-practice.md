## 配置 Pods 和容器

### 为容器和 Pod 分配内存资源

本章展示如何将内存**请求**（request）和内存**限制**（limit）分配给一个容器。 我们保障容器拥有它请求数量的内存，但不允许使用超过限制数量的内存。

#### 创建命名空间

创建一个命名空间，以便将本练习中创建的资源与集群的其余部分隔离。

```shell
$ kubectl create namespace mem-example
namespace/mem-example created
```

#### 指定内存请求和限制

要为容器指定内存请求，请在容器资源清单中包含 `resources：requests` 字段。 同理，要指定内存限制，请包含 `resources：limits`。

创建一个拥有一个容器的 Pod。 容器将会请求 100 MiB 内存，并且内存会被限制在 200 MiB 以内。Pod 的配置文件如下：

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
      requests:
        memory: "100Mi"
      limits:
        memory: "200Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```

> 配置文件的 `args` 部分提供了容器启动时的参数。 `"--vm-bytes", "150M"` 参数告知容器尝试分配 150 MiB 内存。

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/memory-request-limit.yaml --namespace=mem-example
```

查看 Pod 中的容器是否已运行：

```shell
$ kubectl get pod -n mem-example 
NAME          READY   STATUS    RESTARTS   AGE
memory-demo   1/1     Running   0          18s
```

查看 Pod 相关的详细信息：

```shell
$ kubectl get pod memory-demo -o yaml --namespace=mem-example
...
    resources:
      limits:
        memory: 200Mi
      requests:
        memory: 100Mi
...
```

> 输出结果显示：该 Pod 中容器的内存请求为 100 MiB，内存限制为 200 MiB。

运行 `kubectl top` 命令，获取该 Pod 的指标数据：

```shell
$ kubectl top pod memory-demo --namespace=mem-example
NAME          CPU(cores)   MEMORY(bytes)   
memory-demo   36m          150Mi
```

删除 Pod：

```shell
$ kubectl delete pod memory-demo --namespace=mem-example
pod "memory-demo" deleted
```

#### 超过容器限制的内存

当节点拥有足够的可用内存时，容器可以使用其请求的内存。 但是，容器不允许使用超过其限制的内存。 如果容器分配的内存超过其限制，该容器会成为被终止的候选容器。 如果容器继续消耗超出其限制的内存，则终止容器。 如果终止的容器可以被重启，则 kubelet 会重新启动它，就像其他任何类型的运行时失败一样。

创建一个拥有一个容器的 Pod，尝试分配超出其限制的内存。该容器的内存请求为 50 MiB，内存限制为 100 MiB：

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

> 在配置文件的 `args` 部分中，可以看到容器会尝试分配 250 MiB 内存，这远高于 100 MiB 的限制。

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/memory-request-limit-2.yaml --namespace=mem-example
```

查看 Pod 相关的详细信息：

```shell
$ kubectl get pod memory-demo-2 --namespace=mem-example
NAME            READY   STATUS      RESTARTS   AGE
memory-demo-2   0/1     OOMKilled   0          11s
```

> 此时，容器可能正在运行或被杀死。重复前面的命令，直到容器被杀掉

获取容器更详细的状态信息：

```shell
$ kubectl get pod memory-demo-2 --output=yaml --namespace=mem-example
...
    lastState:
      terminated:
        containerID: docker://62c21cf71c43312e441a81f7640d2194c6a82917dc8fd9142ef9a8ac419081df
        exitCode: 1
        finishedAt: "2022-08-03T01:54:43Z"
        reason: OOMKilled
        startedAt: "2022-08-03T01:54:43Z"
...
```

输出结果显示：由于内存溢出（OOM），容器已被杀掉。

> 本示例中的容器可以被重启，kubelet 会重启它，所以容器在反复的被杀死和重启。

删除 Pod：

```shell
$ kubectl delete pod memory-demo-2 --namespace=mem-example
pod "memory-demo-2" deleted
```

#### 超过节点容量的内存

内存请求和限制是与容器关联的，但将 Pod 视为具有内存请求和限制，也是很有用的。 Pod 的内存请求是 Pod 中所有容器的内存请求之和。 同理，Pod 的内存限制是 Pod 中所有容器的内存限制之和。

Pod 的调度基于请求。只有当节点拥有足够满足 Pod 内存请求的内存时，才会将 Pod 调度至节点上运行。

创建一个 Pod，其内存请求超过了集群中的任意一个节点所拥有的内存。 这是该 Pod 的配置文件，其拥有一个请求 1000 GiB 内存的容器，这应该超过了你集群中任何节点的容量。

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
      requests:
        memory: "1000Gi"
      limits:
        memory: "1000Gi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/memory-request-limit-3.yaml --namespace=mem-example
```

查看 Pod 状态：

```shell
$ kubectl get pod memory-demo-3 --namespace=mem-example
NAME            READY   STATUS    RESTARTS   AGE
memory-demo-3   0/1     Pending   0          41s
```

> 输出结果显示：Pod 处于 PENDING 状态。 这意味着，该 Pod 没有被调度至任何节点上运行，并且它会无限期的保持该状态。

查看关于 Pod 的详细信息，包括事件：

```shell
$ kubectl describe pod memory-demo-3 --namespace=mem-example
...
Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  3m44s  default-scheduler  0/3 nodes are available: 3 Insufficient memory. preemption: 0/3 nodes are available: 3 No preemption victims found for incoming pod.
```

> 输出结果显示：由于节点内存不足，该容器无法被调度。

删除 Pod：

```shell
$ kubectl delete pod memory-demo-3 --namespace=mem-example
pod "memory-demo-3" deleted
```

#### 内存单位

内存资源的基本单位是字节（byte）。可以使用这些后缀之一，将内存表示为纯整数或定点整数：E、P、T、G、M、K、Ei、Pi、Ti、Gi、Mi、Ki。 例如，下面是一些近似相同的值：

```
128974848, 129e6, 129M, 123Mi
```

#### 如果没有指定内存限制

如果没有为一个容器指定内存限制，则自动遵循以下情况之一：

- 容器可无限制地使用内存。容器可以使用其所在节点所有的可用内存， 进而可能导致该节点调用 OOM Killer。 此外，如果发生 OOM Kill，没有资源限制的容器将被杀掉的可行性更大。
- 运行的容器所在命名空间有默认的内存限制，那么该容器会被自动分配默认限制。 集群管理员可用使用 [LimitRange](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#limitrange-v1-core) 来指定默认的内存限制。

#### 如果设置了内存限制但未设置内存请求

如果为容器指定了内存限制值但未为其设置内存请求，Kubernetes 会自动为其设置与内存限制相同的内存请求值。类似的，如果容器设置了 CPU 限制值但未设置 CPU 请求值，Kubernetes 也会为其设置与 CPU 限制值相同的 CPU 请求。

#### 内存请求和限制的目的

通过为集群中运行的容器配置内存请求和限制，可以有效利用集群节点上可用的内存资源。 通过将 Pod 的内存请求保持在较低水平，可以更好地安排 Pod 调度。 通过让内存限制大于内存请求，可以完成两件事：

- Pod 可以进行一些突发活动，从而更好的利用可用内存。
- Pod 在突发活动期间，可使用的内存被限制为合理的数量。

#### 环境清理

删除命名空间。下面的命令会删除你根据这个任务创建的所有 Pod：

```shell
$ kubectl delete ns mem-example
namespace "mem-example" deleted
```

### 为容器和 Pods 分配 CPU 资源

本章展示如何为容器设置 CPU **request（请求）** 和 CPU **limit（限制）**。 容器使用的 CPU 不能超过所配置的限制。 如果系统有空闲的 CPU 时间，则可以保证给容器分配其所请求数量的 CPU 资源。

#### 创建命名空间

创建一个名字空间，以便将 本练习中创建的资源与集群的其余部分资源隔离。

```shell
$ kubectl create namespace cpu-example
namespace/cpu-example created
```

#### 指定 CPU 请求和 CPU 限制

要为容器指定 CPU 请求，请在容器资源清单中包含 `resources: requests` 字段。 要指定 CPU 限制，请包含 `resources:limits`。

创建一个具有一个容器的 Pod。容器将会请求 0.5 个 CPU，而且最多限制使用 1 个 CPU。 Pod 的配置文件如下：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-demo
  namespace: cpu-example
spec:
  containers:
  - name: cpu-demo-ctr
    image: vish/stress
    resources:
      limits:
        cpu: "1"
      requests:
        cpu: "0.5"
    args:
    - -cpus
    - "2"
```

> 配置文件的 `args` 部分提供了容器启动时的参数。 `-cpus "2"` 参数告诉容器尝试使用 2 个 CPU。

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/cpu-request-limit.yaml --namespace=cpu-example
```

查看 Pod 状态：

```shell
$ kubectl get pod cpu-demo --namespace=cpu-example
NAME       READY   STATUS    RESTARTS   AGE
cpu-demo   1/1     Running   0          16s
```

查看显示关于 Pod 的详细信息：

```shell
$ kubectl get pod cpu-demo --output=yaml --namespace=cpu-example
...
    resources:
      limits:
        cpu: "1"
      requests:
        cpu: 500m
...
```

> 输出显示 Pod 中的一个容器的 CPU 请求为 500 milliCPU，并且 CPU 限制为 1 个 CPU。

使用 `kubectl top` 命令来获取该 Pod 的指标：

```shell
$ kubectl top pod cpu-demo --namespace=cpu-example
NAME       CPU(cores)   MEMORY(bytes)   
cpu-demo   1000m        1Mi
```

> 此示例输出显示 Pod 使用的是 1000 milliCPU，即 Pod 配置中指定的 1 个 CPU 的限制。

通过设置 `-cpu "2"`，将容器配置为尝试使用 2 个 CPU， 但是容器只被允许使用大约 1 个 CPU。 容器的 CPU 用量受到限制，因为该容器正尝试使用超出其限制的 CPU 资源。

删除 Pod：

```shell
$ kubectl delete pod cpu-demo --namespace=cpu-example
pod "cpu-demo" deleted
```

#### CPU 单位

CPU 资源以 **CPU** 单位度量。Kubernetes 中的一个 CPU 等同于：

- 1 个 AWS vCPU
- 1 个 GCP核心
- 1 个 Azure vCore
- 裸机上具有超线程能力的英特尔处理器上的 1 个超线程

小数值是可以使用的。一个请求 0.5 CPU 的容器保证会获得请求 1 个 CPU 的容器的 CPU 的一半。 你可以使用后缀 `m` 表示毫。例如 `100m` CPU、100 milliCPU 和 0.1 CPU 都相同。 精度不能超过 1m。

CPU 请求只能使用绝对数量，而不是相对数量。0.1 在单核、双核或 48 核计算机上的 CPU 数量值是一样的。

#### 超过节点能力的 CPU 请求

CPU 请求和限制与都与容器相关，但是我们可以考虑一下 Pod 具有对应的 CPU 请求和限制这样的场景。 Pod 对 CPU 用量的请求等于 Pod 中所有容器的请求数量之和。 同样，Pod 的 CPU 资源限制等于 Pod 中所有容器 CPU 资源限制数之和。

Pod 调度是基于资源请求值来进行的。 仅在某节点具有足够的 CPU 资源来满足 Pod CPU 请求时，Pod 将会在对应节点上运行。

创建一个 Pod，该 Pod 的 CPU 请求对于集群中任何节点的容量而言都会过大。 下面是 Pod 的配置文件，其中有一个容器。容器请求 100 个 CPU，这可能会超出集群中任何节点的容量。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-demo-2
  namespace: cpu-example
spec:
  containers:
  - name: cpu-demo-ctr-2
    image: vish/stress
    resources:
      limits:
        cpu: "100"
      requests:
        cpu: "100"
    args:
    - -cpus
    - "2"
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/cpu-request-limit-2.yaml --namespace=cpu-example
```

查看该 Pod 的状态：

```shell
$ kubectl get pod cpu-demo-2 --namespace=cpu-example
NAME         READY   STATUS    RESTARTS   AGE
cpu-demo-2   0/1     Pending   0          60s
```

> 输出显示 Pod 状态为 Pending。也就是说，Pod 未被调度到任何节点上运行， 并且 Pod 将无限期地处于 Pending 状态。

查看有关 Pod 的详细信息，包含事件：

```shell
$ kubectl describe pod cpu-demo-2 --namespace=cpu-example
...
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  114s  default-scheduler  0/3 nodes are available: 3 Insufficient cpu. preemption: 0/3 nodes are available: 3 No preemption victims found for incoming pod.
```

> 输出显示由于节点上的 CPU 资源不足，无法调度 Pod。

删除 Pod：

```shell
$ kubectl delete pod cpu-demo-2 --namespace=cpu-example
pod "cpu-demo-2" deleted
```

#### 如果不指定 CPU 限制

如果你没有为容器指定 CPU 限制，则会发生以下情况之一：

- 容器在可以使用的 CPU 资源上没有上限。因而可以使用所在节点上所有的可用 CPU 资源。
- 容器在具有默认 CPU 限制的名字空间中运行，系统会自动为容器设置默认限制。 集群管理员可以使用 [LimitRange](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#limitrange-v1-core/) 指定 CPU 限制的默认值。

#### 如果设置了 CPU 限制但未设置 CPU 请求

如果为容器指定了 CPU 限制值但未为其设置 CPU 请求，Kubernetes 会自动为其设置与 CPU 限制相同的 CPU 请求值。类似的，如果容器设置了内存限制值但未设置内存请求值，Kubernetes 也会为其设置与内存限制值相同的内存请求。

#### CPU 请求和限制的初衷

通过配置集群中运行的容器的 CPU 请求和限制，可以有效利用集群上可用的 CPU 资源。 通过将 Pod CPU 请求保持在较低水平，可以使 Pod 更有机会被调度。 通过使 CPU 限制大于 CPU 请求，可以完成两件事：

- Pod 可能会有突发性的活动，它可以利用碰巧可用的 CPU 资源。
- Pod 在突发负载期间可以使用的 CPU 资源数量仍被限制为合理的数量。

#### 环境清理

删除命名空间：

```shell
$ kubectl delete namespace cpu-example
namespace "cpu-example" deleted
```

### 配置 Pod 的服务质量

本章介绍怎样配置 Pod 让其获得特定的服务质量（QoS）类。Kubernetes 使用 QoS 类来决定 Pod 的调度和驱逐策略。

#### QoS 类

Kubernetes 创建 Pod 时就给它指定了下列一种 QoS 类：

- Guaranteed
- Burstable
- BestEffort

#### 创建命名空间

创建一个命名空间，以便将本练习所创建的资源与集群的其余资源相隔离。

```shell
$ kubectl create namespace qos-example
namespace/qos-example created
```

#### Guaranteed

创建一个 QoS 类为 Guaranteed 的 Pod。

对于 QoS 类为 Guaranteed 的 Pod：

- Pod 中的每个容器都必须指定内存限制和内存请求。
- 对于 Pod 中的每个容器，内存限制必须等于内存请求。
- Pod 中的每个容器都必须指定 CPU 限制和 CPU 请求。
- 对于 Pod 中的每个容器，CPU 限制必须等于 CPU 请求。

这些限制同样适用于初始化容器和应用程序容器。

下面是包含一个容器的 Pod 配置文件。 容器设置了内存请求和内存限制，值都是 200 MiB。 容器设置了 CPU 请求和 CPU 限制，值都是 700 milliCPU：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-demo
  namespace: qos-example
spec:
  containers:
  - name: qos-demo-ctr
    image: nginx
    resources:
      limits:
        memory: "200Mi"
        cpu: "700m"
      requests:
        memory: "200Mi"
        cpu: "700m"
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/qos-pod.yaml --namespace=qos-example
```

查看 Pod 详情：

```shell
$ kubectl get pod qos-demo --namespace=qos-example --output=yaml
...
spec:
    resources:
      limits:
        cpu: 700m
        memory: 200Mi
      requests:
        cpu: 700m
        memory: 200Mi
...
status:
  qosClass: Guaranteed
...
```

> 结果表明 Kubernetes 为 Pod 配置的 QoS 类为 Guaranteed。 结果也确认了 Pod 容器设置了与内存限制匹配的内存请求，设置了与 CPU 限制匹配的 CPU 请求。

> **说明：**
>
> 如果容器指定了自己的内存限制，但没有指定内存请求，Kubernetes 会自动为它指定与内存限制匹配的内存请求。 同样，如果容器指定了自己的 CPU 限制，但没有指定 CPU 请求，Kubernetes 会自动为它指定与 CPU 限制匹配的 CPU 请求。

删除 Pod：

```shell
$ kubectl delete pod qos-demo --namespace=qos-example
pod "qos-demo" deleted
```

#### Burstable

如果满足下面条件，将会指定 Pod 的 QoS 类为 Burstable：

- Pod 不符合 Guaranteed QoS 类的标准。
- Pod 中至少一个容器具有内存或 CPU 的请求或限制。

下面是包含一个容器的 Pod 配置文件。 容器设置了内存限制 200 MiB 和内存请求 100 MiB。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-demo-2
  namespace: qos-example
spec:
  containers:
  - name: qos-demo-2-ctr
    image: nginx
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "100Mi"
```

创建 Pod：

```shell
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/qos-pod-2.yaml --namespace=qos-example
```

查看 Pod 详情：

```shell
$ kubectl get pod qos-demo-2 --namespace=qos-example --output=yaml
...
spec:
    resources:
      limits:
        memory: 200Mi
      requests:
        memory: 100Mi
...
status:
  qosClass: Burstable
...
```

> 结果表明 Kubernetes 为 Pod 配置的 QoS 类为 Burstable。

删除 Pod：

```shell
$ kubectl delete pod qos-demo-2 --namespace=qos-example
pod "qos-demo-2" deleted
```

#### BestEffort

对于 QoS 类为 BestEffort 的 Pod，Pod 中的容器必须没有设置内存和 CPU 限制或请求。

下面是包含一个容器的 Pod 配置文件。 容器没有设置内存和 CPU 限制或请求。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-demo-3
  namespace: qos-example
spec:
  containers:
  - name: qos-demo-3-ctr
    image: nginx
```

创建 Pod：

```shell
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/qos-pod-3.yaml --namespace=qos-example
```

查看 Pod 详情：

```shell
$ kubectl get pod qos-demo-3 --namespace=qos-example --output=yaml
...
spec:
    resources: {}
...
  qosClass: BestEffort
...
```

> 结果表明 Kubernetes 为 Pod 配置的 QoS 类为 BestEffort。

删除 Pod：

```shell
$ kubectl delete pod qos-demo-3 --namespace=qos-example
pod "qos-demo-3" deleted
```

#### 创建包含两个容器的 Pod

下面是包含两个容器的 Pod 配置文件。 一个容器指定了内存请求 200 MiB。 另外一个容器没有指定任何请求和限制。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-demo-4
  namespace: qos-example
spec:
  containers:

  - name: qos-demo-4-ctr-1
    image: nginx
    resources:
      requests:
        memory: "200Mi"

  - name: qos-demo-4-ctr-2
    image: redis
```

> 此 Pod 中有一个容器没有设置内存请求，因此它不满足 Guaranteed QoS 类标准；而有一个容器设置了内存请求，所以它满足 Burstable QoS 类的标准。

创建 Pod：

```shell
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/qos-pod-4.yaml --namespace=qos-example
```

查看 Pod 详情：

```shell
$ kubectl get pod qos-demo-4 --namespace=qos-example --output=yaml
...
spec:
  containers:
    ...
    name: qos-demo-4-ctr-1
    resources:
      requests:
        memory: 200Mi
    ...
    name: qos-demo-4-ctr-2
    resources: {}
    ...
status:
  qosClass: Burstable
...
```

> 结果表明 Kubernetes 为 Pod 配置的 QoS 类为 Burstable。

删除 Pod：

```shell
$ kubectl delete pod qos-demo-4 --namespace=qos-example
pod "qos-demo-4" deleted
```

#### 环境清理

删除命名空间：

```shell
$ kubectl delete namespace qos-example
namespace "qos-example" deleted
```

### 为容器分配扩展资源

#### 为节点发布扩展资源

本章展示了如何为节点指定扩展资源（Extended Resource）。 扩展资源允许集群管理员发布节点级别的资源，这些资源在不进行发布的情况下无法被 Kubernetes 感知。

为了在一个节点上发布一种新的扩展资源，需要发送一个 HTTP PATCH 请求到 Kubernetes API server。下面是一个 PATCH 请求的示例，该请求为你的节点发布四个 dongle 资源。

**Step 1）**获取节点名称

```shell
$ kubectl get nodes
NAME   STATUS   ROLES           AGE   VERSION
m1     Ready    control-plane   15d   v1.24.3
w1     Ready    worker          15d   v1.24.3
w2     Ready    worker          15d   v1.24.3
```

选择一个节点用于此练习。本文选择节点 `w2`

**Step 2）**启动一个代理（proxy）

以便可以很容易地向 Kubernetes API server 发送请求

```shell
$ kubectl proxy
Starting to serve on 127.0.0.1:8001
```

**Step 3）**发布扩展资源

在另一个命令窗口中，发送 HTTP PATCH 请求

```shell
$ curl --header "Content-Type: application/json-patch+json" \
  --request PATCH \
  --data '[{"op": "add", "path": "/status/capacity/example.com~1dongle", "value": "4"}]' \
  http://localhost:8001/api/v1/nodes/w2/status
```

> **说明：** 在前面的请求中，`~1` 为 patch 路径中 “/” 符号的编码。 JSON-Patch 中的操作路径值被解析为 JSON 指针。 更多细节，请查看 [IETF RFC 6901](https://tools.ietf.org/html/rfc6901) 的第 3 节。

**Step 4）**查看发布的扩展资源

```shell
$ kubectl describe node w2
...
Capacity:
  cpu:                 3
  example.com/dongle:  4
  memory:              8117256Ki
...
```

> 输出显示该节点的 dongle 资源容量（capacity）为 4

#### 给 Pod 分配扩展资源[ ](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/extended-resource/#给-pod-分派扩展资源)

要请求扩展资源，需要在容器清单中包括 `resources:requests` 字段。 扩展资源可以使用任何完全限定名称，只是不能使用 `*.kubernetes.io/`。 有效的扩展资源名的格式为 `example.com/foo`，其中 `example.com` 应被替换为 你的组织的域名，而 `foo` 则是描述性的资源名称。

下面是包含一个容器的 Pod 配置文件：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: extended-resource-demo
spec:
  containers:
  - name: extended-resource-demo-ctr
    image: nginx
    resources:
      requests:
        example.com/dongle: 3
      limits:
        example.com/dongle: 3
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/extended-resource-pod.yaml
```

检查 Pod 是否运行正常：

```shell
$ kubectl get pod extended-resource-demo
NAME                     READY   STATUS    RESTARTS   AGE
extended-resource-demo   1/1     Running   0          41s
```

查看有关 Pod 的详细信息：

```shell
$ kubectl describe pod extended-resource-demo
...
    Limits:
      example.com/dongle:  3
    Requests:
      example.com/dongle:  3
...
```

#### 尝试创建第二个 Pod

下面是包含一个容器的 Pod 配置文件，容器请求了 2 个 dongles。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: extended-resource-demo-2
spec:
  containers:
  - name: extended-resource-demo-2-ctr
    image: nginx
    resources:
      requests:
        example.com/dongle: 2
      limits:
        example.com/dongle: 2
```

> Kubernetes 将不能满足 2 个 dongles 的请求，因为第一个 Pod 已经使用了 4 个可用 dongles 中的 3 个。

尝试创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/extended-resource-pod-2.yaml
```

查看有关 Pod 的详细信息：

```shell
$ kubectl describe pod extended-resource-demo-2
...
Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  2m10s  default-scheduler  0/3 nodes are available: 3 Insufficient example.com/dongle. preemption: 0/3 nodes are available: 3 No preemption victims found for incoming pod.
```

> 输出结果表明 Pod 不能被调度，因为没有一个节点上存在两个可用的 dongles。

查看 Pod 的状态：

```shell
$ kubectl get pod extended-resource-demo-2
NAME                       READY   STATUS    RESTARTS   AGE
extended-resource-demo-2   0/1     Pending   0          101s
```

> 输出结果表明 Pod 虽然被创建了，但没有被调度到节点上正常运行。Pod 的状态为 Pending。

#### 环境清理

删除本练习中创建的 Pod：

```shell
$ kubectl delete pod extended-resource-demo
pod "extended-resource-demo" deleted
$ kubectl delete pod extended-resource-demo-2
pod "extended-resource-demo-2" deleted
```

移除 dongle 资源发布：

```shell
# 启动一个代理
$ kubectl proxy
Starting to serve on 127.0.0.1:8001

# 在另一个命令窗口中，发送移除 dongle 资源发布的 HTTP PATCH 请求
$ curl --header "Content-Type: application/json-patch+json" \
--request PATCH \
--data '[{"op": "remove", "path": "/status/capacity/example.com~1dongle"}]' \
http://localhost:8001/api/v1/nodes/w2/status

# 查看节点详细信息，验证 dongle 资源的发布已经被移除
$ kubectl describe node w2 | grep dongle
```

### 配置 Pod 以使用卷进行存储

本章展示了如何配置 Pod 以使用卷进行存储。

只要容器存在，容器的文件系统就会存在，因此当一个容器终止并重新启动，对该容器的文件系统改动将丢失。 对于独立于容器的持久化存储，可以使用卷。 这对于有状态应用程序尤为重要，例如键值存储（如 Redis）和数据库。

#### 为 Pod 配置卷

在本练习中，将创建一个运行一个容器的 Pod。这个 Pod 有一个 emptyDir 类型的 Volume，它在 Pod 的生命周期内持续存在，即使容器终止并重新启动也是如此。以下是 Pod 的配置文件：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis
spec:
  containers:
  - name: redis
    image: redis
    volumeMounts:
    - name: redis-storage
      mountPath: /data/redis
  volumes:
  - name: redis-storage
    emptyDir: {}
```

1. 创建 Pod：

   ```shell
   $ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/redis.yaml
   ```

2. 查看 Pod 运行状态：

   ```shell
   $ kubectl get pod redis
   NAME    READY   STATUS    RESTARTS   AGE
   redis   1/1     Running   0          10s
   ```

3. 在另一个终端，用 shell 连接正在运行的容器，切换到 `/data/redis` 目录下，然后创建一个文件：

   ```shell
   $ kubectl exec -it redis -- /bin/bash
   root@redis:/data# cd /data/redis/
   root@redis:/data/redis# echo Hello > test-file
   ```

4. 在 Shell 中，列出正在运行的进程：

   ```shell
   root@redis:/data/redis# apt-get update
   root@redis:/data/redis# apt-get install procps
   root@redis:/data/redis# ps aux
   USER        PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
   redis         1  0.1  0.1  53612 13524 ?        Ssl  07:49   0:01 redis-server *:6379
   root         27  0.0  0.0   4100  3332 pts/0    Ss   07:55   0:00 /bin/bash
   root        357  0.0  0.0   6700  3012 pts/0    R+   08:03   0:00 ps aux
   ```

5. 在 Shell 中，结束 Redis 进程：

   ```shell
   root@redis:/data/redis# kill 1
   root@redis:/data# command terminated with exit code 137
   ```

6. 在原先的终端中，留意 Redis Pod 的更改。最终你将会看到和下面类似的输出：

   ```shell
   $ kubectl get pod redis --watch
   NAME    READY   STATUS    RESTARTS   AGE
   redis   1/1     Running   0          9m5s
   redis   0/1     Completed   0          14m
   redis   1/1     Running     1 (6s ago)   15m
   ```

此时，容器已经终止并重新启动。这是因为 Redis Pod 的 restartPolicy 为 `Always`。

1. 用 Shell 进入重新启动的容器中，并确认 `test-file` 文件是否仍然存在。

   ```shell
   $ kubectl exec -it redis -- /bin/bash
   root@redis:/data# ls /data/redis/
   test-file
   ```

2. 删除为此练习所创建的 Pod：

   ```shell
   $ kubectl delete pod redis
   ```

### 配置 Pod 以使用 PersistentVolume 作为存储

本章将介绍如何配置 Pod 使用 [PersistentVolumeClaim](https://kubernetes.io/zh-cn/docs/concepts/storage/persistent-volumes/) 作为存储。 以下是该过程的总结：

1. 作为集群管理员，您创建一个由物理存储支持的 PersistentVolume。您没有将卷与任何 Pod 关联。
2. 你现在以开发人员或者集群用户的角色创建一个 PersistentVolumeClaim， 它将自动绑定到合适的 PersistentVolume。
3. 你创建一个使用 PersistentVolumeClaim 作为存储的 Pod。

#### 在节点上创建 index.html 文件

打开集群中的某个节点的 Shell。本文选择节点 `w2` 。在该节点创建一个 `/mnt/data` 目录：

```shell
$ mkdir /mnt/data
```

在 `/mnt/data` 目录中创建一个 index.html 文件：

```shell
$ sh -c "echo 'Hello from Kubernetes storage' > /mnt/data/index.html"
```

测试 `index.html` 文件确实存在：

```shell
$ cat /mnt/data/index.html
Hello from Kubernetes storage
```

#### 创建 PersistentVolume

在本练习中，将创建一个 **hostPath** 类型的 PersistentVolume。 Kubernetes 支持用于在单节点集群上开发和测试的 hostPath 类型的 PersistentVolume。 hostPath 类型的 PersistentVolume 使用节点上的文件或目录来模拟网络附加存储。

在生产集群中，请不要使用 hostPath。 集群管理员会提供网络存储资源，比如 Google Compute Engine 持久盘卷、NFS 共享卷或 Amazon Elastic Block Store 卷。 集群管理员还可以使用 StorageClasses 来设置动态提供存储。

下面是 hostPath PersistentVolume 的配置文件：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
```

> 配置文件指定卷位于集群节点上的 `/mnt/data` 路径。 配置还指定了卷的容量大小为 10 GB， 访问模式为 `ReadWriteOnce`， 这意味着该卷可以被单个节点以读写方式安装。 配置文件还在 PersistentVolume 中定义了 StorageClass 的名称为 `manual`。它将用于将 PersistentVolumeClaim 的请求绑定到此 PersistentVolume。

创建 PersistentVolume：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pv-volume.yaml
```

查看 PersistentVolume 的信息：

```shell
$ kubectl get pv task-pv-volume
NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
task-pv-volume   10Gi       RWO            Retain           Available           manual                  7s
```

> 输出结果显示该 PersistentVolume 的`状态（STATUS）` 为 `Available`。 这意味着它还没有被绑定给 PersistentVolumeClaim。

#### 创建 PersistentVolumeClaim

下一步是创建一个 PersistentVolumeClaim。Pod 使用 PersistentVolumeClaim 来请求物理存储。 在本练习中，将创建一个 PersistentVolumeClaim，它请求至少 3 GB 容量的卷， 该卷至少可以为一个节点提供读写访问。

下面是 PersistentVolumeClaim 的配置文件：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

创建 PersistentVolumeClaim：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pv-claim.yaml
```

创建 PersistentVolumeClaim 之后，Kubernetes 控制平面将查找满足申领要求的 PersistentVolume。 如果控制平面找到具有相同 StorageClass 的适当的 PersistentVolume， 则将 PersistentVolumeClaim 绑定到该 PersistentVolume 上。

再次查看 PersistentVolume 信息：

```shell
$ kubectl get pv task-pv-volume
NAME             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS   REASON   AGE
task-pv-volume   10Gi       RWO            Retain           Bound    default/task-pv-claim   manual                  17m
```

> 现在输出的 `STATUS` 为 `Bound`。

查看 PersistentVolumeClaim：

```shell
$ kubectl get pvc task-pv-claim
NAME            STATUS   VOLUME           CAPACITY   ACCESS MODES   STORAGECLASS   AGE
task-pv-claim   Bound    task-pv-volume   10Gi       RWO            manual         93s
```

> 输出结果表明该 PersistentVolumeClaim `task-pv-claim` 绑定了 PersistentVolume `task-pv-volume`。

#### 创建 Pod

下一步是创建一个 Pod， 该 Pod 使用前面创建的 PersistentVolumeClaim 作为存储卷。

下面是 Pod 的 配置文件：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: task-pv-pod
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        claimName: task-pv-claim
  containers:
    - name: task-pv-container
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: task-pv-storage
```

> 注意 Pod 的配置文件指定了 PersistentVolumeClaim，但没有指定 PersistentVolume。 对 Pod 而言，PersistentVolumeClaim 就是一个存储卷。

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pv-pod.yaml
```

检查 Pod 中的容器是否运行正常：

```shell
$ kubectl get pod task-pv-pod
NAME          READY   STATUS    RESTARTS   AGE
task-pv-pod   1/1     Running   0          14s
```

打开一个 Shell 访问 Pod 中的容器，验证 nginx 是否正在从 hostPath 卷提供 `index.html` 文件：

```shell
$ kubectl exec -it task-pv-pod -- /bin/bash
root@task-pv-pod:/# cat /usr/share/nginx/html/index.html
Hello from Kubernetes storage
```

> 输出结果正是之前写到 hostPath 卷中的 `index.html` 文件中的内容，这说明已经成功地配置了 Pod 使用 PersistentVolumeClaim 的存储。

#### 环境清理

删除 Pod、PersistentVolumeClaim 和 PersistentVolume 对象：

```shell
$ kubectl delete pod task-pv-pod
pod "task-pv-pod" deleted
$ kubectl delete pvc task-pv-claim
persistentvolumeclaim "task-pv-claim" deleted
$ kubectl delete pv task-pv-volume
persistentvolume "task-pv-volume" deleted
```

在 `w2` 节点的 Shell 上，删除所创建的目录和文件：

```shell
$ rm -rf /mnt/data/
```

#### 在两个地方挂载相同的 persistentVolume

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test
spec:
  containers:
    - name: test
      image: nginx
      volumeMounts:
        # 网站数据挂载
        - name: config
          mountPath: /usr/share/nginx/html
          subPath: html
        # Nginx 配置挂载
        - name: config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
  volumes:
    - name: config
      persistentVolumeClaim:
        claimName: test-nfs-claim
```

可以在 nginx 容器上执行两个卷挂载：

`/usr/share/nginx/html` 用于静态网站，`/etc/nginx/nginx.conf` 作为默认配置。

#### 访问控制

使用组 ID（GID）配置的存储仅允许 Pod 使用相同的 GID 进行写入。 GID 不匹配或缺失将会导致无权访问错误。 为了减少与用户的协调，管理员可以对 PersistentVolume 添加 GID 注解。 这样 GID 就能自动添加到使用 PersistentVolume 的任何 Pod 中。

使用 `pv.beta.kubernetes.io/gid` 注解的方法如下所示：

```yaml
apiVersion: v1
kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv1
  annotations:
    pv.beta.kubernetes.io/gid: "1234"
```

当 Pod 使用带有 GID 注解的 PersistentVolume 时，注解的 GID 会被应用于 Pod 中的所有容器， 应用的方法与 Pod 的安全上下文中指定的 GID 相同。 每个 GID，无论是来自 PersistentVolume 注解还是来自 Pod 规约，都会被应用于每个容器中运行的第一个进程。

> **说明：** 当 Pod 使用 PersistentVolume 时，与 PersistentVolume 关联的 GID 不会在 Pod 资源本身的对象上出现。

### 配置 Pod 使用投射卷作存储

本章介绍怎样通过`projected` 卷将现有的多个卷资源挂载到相同的目录。 当前，`secret`、`configMap`、`downwardAPI` 和 `serviceAccountToken` 卷可以被投射。

#### 为 Pod 配置 projected 卷

本练习中，将从本地文件来创建包含有用户名和密码的 Secret。然后创建运行一个容器的 Pod， 该 Pod 使用`projected` 卷将 Secret 挂载到相同的路径下。

下面是 Pod 的配置文件：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-projected-volume
spec:
  containers:
  - name: test-projected-volume
    image: busybox:1.28
    args:
    - sleep
    - "86400"
    volumeMounts:
    - name: all-in-one
      mountPath: "/projected-volume"
      readOnly: true
  volumes:
  - name: all-in-one
    projected:
      sources:
      - secret:
          name: user
      - secret:
          name: pass
```

1. 创建 Secret：

   ```shell
   # 创建包含用户名和密码的文件
   $ echo -n "admin" > ./username.txt
   $ echo -n "1f2d1e2e67df" > ./password.txt
   
   # 将上述文件引用到 Secret
   $ kubectl create secret generic user --from-file=./username.txt
   secret/user created
   $ kubectl create secret generic pass --from-file=./password.txt
   secret/pass created
   ```

2. 创建 Pod：

   ```shell
   $ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/projected.yaml
   ```

3. 确认 Pod 中的容器运行正常，然后监视 Pod 的变化：

   ```shell
   $ kubectl get --watch pod test-projected-volume
   NAME                    READY   STATUS              RESTARTS   AGE
   test-projected-volume   0/1     ContainerCreating   0          5s
   test-projected-volume   1/1     Running             0          13s
   ```

4. 在另外一个终端中，打开容器的 shell：

   ```shell
   $ kubectl exec -it test-projected-volume -- /bin/sh
   ```

5. 在 shell 中，确认 `projected-volume` 目录是否包含投射源：

   ```shell
   $ ls /projected-volume/
   password.txt  username.txt
   ```

#### 环境清理

删除 Pod 和 Secret:

```shell
$ kubectl delete pod test-projected-volume
pod "test-projected-volume" deleted
$ kubectl delete secret user pass
secret "user" deleted
secret "pass" deleted

$ rm -f ./username.txt ./password.txt
```

### 为 Pod 或容器配置安全上下文

#### 为 Pod 设置安全性上下文

要为 Pod 设置安全性设置，可在 Pod 规约中包含 `securityContext` 字段。`securityContext` 字段值是一个 PodSecurityContext 对象。你为 Pod 所设置的安全性配置会应用到 Pod 中所有 Container 上。 下面是一个 Pod 的配置文件，该 Pod 定义了 `securityContext` 和一个 `emptyDir` 卷：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  volumes:
  - name: sec-ctx-vol
    emptyDir: {}
  containers:
  - name: sec-ctx-demo
    image: busybox:1.28
    command: [ "sh", "-c", "sleep 1h" ]
    volumeMounts:
    - name: sec-ctx-vol
      mountPath: /data/demo
    securityContext:
      allowPrivilegeEscalation: false
```

> 在配置文件中，`runAsUser` 字段指定 Pod 中的所有容器内的进程都使用用户 ID 1000 来运行。`runAsGroup` 字段指定所有容器中的进程都以主组 ID 3000 来运行。 如果忽略此字段，则容器的主组 ID 将是 root（0）。 当 `runAsGroup` 被设置时，所有创建的文件也会划归用户 1000 和组 3000。 由于 `fsGroup` 被设置，容器中所有进程也会是附组 ID 2000 的一部分。 卷 `/data/demo` 及在该卷中创建的任何文件的属主都会是组 ID 2000。

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/security-context.yaml
```

检查 Pod 运行状态：

```shell
$ kubectl get pod security-context-demo
NAME                    READY   STATUS    RESTARTS   AGE
security-context-demo   1/1     Running   0          2s
```

开启一个 Shell 进入到运行中的容器：

```shell
$ kubectl exec -it security-context-demo -- sh
# 列举运行中的进程
/ $ ps
PID   USER     TIME  COMMAND
    1 1000      0:00 sleep 1h
    7 1000      0:00 sh
   14 1000      0:00 sh
   21 1000      0:00 ps

# 进入 /data 目录列举其内容
/ $ cd /data
/data $ ls -l
total 0
drwxrwsrwx    2 root     2000             6 Aug  4 09:20 demo

# 进入到 /data/demo 目录下创建一个文件
/data $ cd demo
/data/demo $ echo hello > testfile
/data/demo $ ls -l
total 4
-rw-r--r--    1 1000     2000             6 Aug  4 09:27 testfile

# 运行 id 命令获取用户和所在组的信息
/data/demo $ id
uid=1000 gid=3000 groups=2000

# 退出
/data/demo $ exit
```

> `ps` 命令输出显示进程以用户 1000 运行，即 `runAsUser` 所设置的值；输出显示 `/data/demo` 目录的组 ID 为 2000，即 `fsGroup` 的设置值；输出显示新创建文件 `testfile` 的组 ID 为 2000，也就是 `fsGroup` 所设置的值；运行 `id` 命令后，从输出中会看到 `gid` 值为 3000，也就是 `runAsGroup` 字段的值。 如果 `runAsGroup` 被忽略，则 `gid` 会取值 0（root），而进程就能够与 root 用户组所拥有以及要求 root 用户组访问权限的文件交互。

#### 为 Pod 配置卷访问权限和属主变更策略

**特性状态：** `Kubernetes v1.23 [stable]`

默认情况下，Kubernetes 在挂载一个卷时，会递归地更改每个卷中的内容的属主和访问权限， 使之与 Pod 的 `securityContext` 中指定的 `fsGroup` 匹配。 对于较大的数据卷，检查和变更属主与访问权限可能会花费很长时间，降低 Pod 启动速度。 可以在 `securityContext` 中使用 `fsGroupChangePolicy` 字段来控制 Kubernetes 检查和管理卷属主和访问权限的方式。

**fsGroupChangePolicy** - `fsGroupChangePolicy` 定义在卷被暴露给 Pod 内部之前对其内容的属主和访问许可进行变更的行为。此字段仅适用于那些支持使用 `fsGroup` 来控制属主与访问权限的卷类型。此字段的取值可以是：

- `OnRootMismatch`：只有根目录的属主与访问权限与卷所期望的权限不一致时， 才改变其中内容的属主和访问权限。这一设置有助于缩短更改卷的属主与访问 权限所需要的时间。
- `Always`：在挂载卷时总是更改卷中内容的属主和访问权限。

例如：

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 3000
  fsGroup: 2000
  fsGroupChangePolicy: "OnRootMismatch"
```

> **说明：** 此字段对于 [`secret`](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#secret)、 [`configMap`](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#configmap) 和 [`emptydir`](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#emptydir) 这类临时性存储无效。

#### 将卷权限和所有权更改委派给 CSI 驱动程序

**特性状态：** `Kubernetes v1.23 [beta]`

如果你部署了一个[容器存储接口 (CSI)](https://github.com/container-storage-interface/spec/blob/master/spec.md) 驱动，而该驱动支持 `VOLUME_MOUNT_GROUP` `NodeServiceCapability`， 在 `securityContext` 中指定 `fsGroup` 来设置文件所有权和权限的过程将由 CSI 驱动而不是 Kubernetes 来执行，前提是 Kubernetes 的 `DelegateFSGroupToCSIDriver` 特性门控已启用。在这种情况下，由于 Kubernetes 不执行任何所有权和权限更改， `fsGroupChangePolicy` 不会生效，并且按照 CSI 的规定，CSI 驱动应该使用所指定的 `fsGroup` 来挂载卷，从而生成了一个对 `fsGroup` 可读/可写的卷.

更多的信息请参考 [KEP](https://github.com/gnufied/enhancements/blob/master/keps/sig-storage/2317-fsgroup-on-mount/README.md) 和 [CSI 规范](https://github.com/container-storage-interface/spec/blob/master/spec.md#createvolume) 中的字段 `VolumeCapability.MountVolume.volume_mount_group` 的描述。

#### 为 Container 设置安全性上下文

若要为 Container 设置安全性配置，可以在 Container 清单中包含 `securityContext` 字段。`securityContext` 字段的取值是一个 [SecurityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#securitycontext-v1-core) 对象。为 Container 设置的安全性配置仅适用于该容器本身，并且所指定的设置在与 Pod 层面设置的内容发生重叠时，会重载后者。Container 层面的设置不会影响到 Pod 的卷。

下面是一个 Pod 的配置文件，其中包含一个 Container。Pod 和 Container 都有 `securityContext` 字段：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-2
spec:
  securityContext:
    runAsUser: 1000
  containers:
  - name: sec-ctx-demo-2
    image: registry.cn-shenzhen.aliyuncs.com/aluopy/node-hello:1.0
    securityContext:
      runAsUser: 2000
      allowPrivilegeEscalation: false
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/security-context-2.yaml
```

验证 Pod 中的容器处于运行状态：

```shell
$ kubectl get pod security-context-demo-2
NAME                      READY   STATUS    RESTARTS   AGE
security-context-demo-2   1/1     Running   0          96s
```

启动一个 Shell 进入到运行中的容器内查看相关信息：

```shell
$ kubectl exec -it security-context-demo-2 -- sh
$ ps aux
USER        PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
2000          1  0.0  0.0   4340   764 ?        Ss   03:25   0:00 /bin/sh -c node server.js
2000          6  0.0  0.2 772128 22732 ?        Sl   03:25   0:00 node server.js
2000         17  0.0  0.0   4340   812 pts/0    Ss   03:30   0:00 sh
2000         23  0.0  0.0  17504  2080 pts/0    R+   03:30   0:00 ps aux
```

> 输出显示进程以用户 2000 运行。该值是在 Container 的 `runAsUser` 中设置的。 该设置值重载了 Pod 层面所设置的值 1000。

#### 为 Container 设置权能

使用 [Linux 权能](https://man7.org/linux/man-pages/man7/capabilities.7.html)， 可以赋予进程 root 用户所拥有的某些特权，但不必赋予其全部特权。 要为 Container 添加或移除 Linux 权能，可以在 Container 清单的 `securityContext` 节包含 `capabilities` 字段。

首先，看一下不包含 `capabilities` 字段时候会发生什么。 下面是一个配置文件，其中没有添加或移除容器的权能：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-3
spec:
  containers:
  - name: sec-ctx-3
    image: registry.cn-shenzhen.aliyuncs.com/aluopy/node-hello:1.0
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/security-context-3.yaml
```

验证 Pod 的容器处于运行状态：

```shell
$ kubectl get pod security-context-demo-3
NAME                      READY   STATUS    RESTARTS   AGE
security-context-demo-3   1/1     Running   0          2s
```

启动一个 Shell 进入到运行中的容器：

```shell
$ kubectl exec -it security-context-demo-3 -- sh
# 列举运行中的进程
# ps aux
USER        PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root          1  0.0  0.0   4340   708 ?        Ss   03:38   0:00 /bin/sh -c node server.js
root          7  0.1  0.2 772128 22856 ?        Sl   03:38   0:00 node server.js
root         12  0.0  0.0   4340   756 pts/0    Ss   03:39   0:00 sh
root         19  0.0  0.0  17504  2120 pts/0    R+   03:39   0:00 ps aux

# 查看进程 1 的状态，输出显示进程的权能位图
# cat /proc/1/status
...
CapPrm:	00000000a80425fb
CapEff:	00000000a80425fb
...
```

接下来运行一个与前例中容器相同的容器，只是这个容器有一些额外的权能设置。

下面是一个 Pod 的配置，其中运行一个容器。配置为容器添加 `CAP_NET_ADMIN` 和 `CAP_SYS_TIME` 权能：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo-4
spec:
  containers:
  - name: sec-ctx-4
    image: registry.cn-shenzhen.aliyuncs.com/aluopy/node-hello:1.0
    securityContext:
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/security-context-4.yaml
```

验证 Pod 的容器处于运行状态：

```shell
$ kubectl get pod security-context-demo-4
NAME                      READY   STATUS    RESTARTS   AGE
security-context-demo-4   1/1     Running   0          4s
```

启动一个 Shell，进入到运行中的容器，查看进程 1 的权能：

```shell
$ kubectl exec -it security-context-demo-4 -- sh
# cat /proc/1/status
...
CapPrm:	00000000aa0435fb
CapEff:	00000000aa0435fb
...
```

比较两个容器的权能位图：

```
00000000a80425fb
00000000aa0435fb
```

在第一个容器的权能位图中，位 12 和 25 是没有设置的。在第二个容器中，位 12 和 25 是设置了的。位 12 是 `CAP_NET_ADMIN` 而位 25 则是 `CAP_SYS_TIME`。 参见 [capability.h](https://github.com/torvalds/linux/blob/master/include/uapi/linux/capability.h) 了解权能常数的定义。

> **说明：** Linux 权能常数定义的形式为 `CAP_XXX`。但是你在 Container 清单中列举权能时， 要将权能名称中的 `CAP_` 部分去掉。例如，要添加 `CAP_SYS_TIME`， 可在权能列表中添加 `SYS_TIME`。

#### 为容器设置 Seccomp 配置

若要为容器设置 Seccomp 配置（Profile），可在你的 Pod 或 Container 清单的 `securityContext` 节中包含 `seccompProfile` 字段。该字段是一个 [SeccompProfile](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#seccompprofile-v1-core) 对象，包含 `type` 和 `localhostProfile` 属性。 `type` 的合法选项包括 `RuntimeDefault`、`Unconfined` 和 `Localhost`。 `localhostProfile` 只能在 `type: Localhost` 配置下才可以设置。 该字段标明节点上预先设定的配置的路径，路径是相对于 kubelet 所配置的 Seccomp 配置路径（使用 `--root-dir` 设置）而言的。

下面是一个例子，设置容器使用节点上容器运行时的默认配置作为 Seccomp 配置：

```yaml
...
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

下面是另一个例子，将 Seccomp 的样板设置为位于 `<kubelet-根目录>/seccomp/my-profiles/profile-allow.json` 的一个预先配置的文件。

```yaml
...
securityContext:
  seccompProfile:
    type: Localhost
    localhostProfile: my-profiles/profile-allow.json
```

#### 为 Container 赋予 SELinux 标签

若要给 Container 设置 SELinux 标签，可以在 Pod 或 Container 清单的 `securityContext` 节包含 `seLinuxOptions` 字段。 `seLinuxOptions` 字段的取值是一个 [SELinuxOptions](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#selinuxoptions-v1-core) 对象。下面是一个应用 SELinux 标签的例子：

```yaml
...
securityContext:
  seLinuxOptions:
    level: "s0:c123,c456"
```

> **说明：** 要指定 SELinux，需要在宿主操作系统中装载 SELinux 安全性模块。

#### 讨论

Pod 的安全上下文适用于 Pod 中的容器，也适用于 Pod 所挂载的卷（如果有的话）。 尤其是，`fsGroup` 和 `seLinuxOptions` 按下面的方式应用到挂载卷上：

- `fsGroup`：支持属主管理的卷会被修改，将其属主变更为 `fsGroup` 所指定的 GID， 并且对该 GID 可写。进一步的细节可参阅 [属主变更设计文档](https://git.k8s.io/design-proposals-archive/storage/volume-ownership-management.md)。

- `seLinuxOptions`：支持 SELinux 标签的卷会被重新打标签，以便可被 `seLinuxOptions` 下所设置的标签访问。通常你只需要设置 `level` 部分。 该部分设置的是赋予 Pod 中所有容器及卷的 [多类别安全性（Multi-Category Security，MCS)](https://selinuxproject.org/page/NB_MLS)标签。

  > **警告：** 在为 Pod 设置 MCS 标签之后，所有带有相同标签的 Pod 可以访问该卷。 如果你需要跨 Pod 的保护，你必须为每个 Pod 赋予独特的 MCS 标签。

#### 环境清理

删除之前创建的所有 Pod：

```shell
$ kubectl delete pod security-context-demo
pod "security-context-demo" deleted
$ kubectl delete pod security-context-demo-2
pod "security-context-demo-2" deleted
$ kubectl delete pod security-context-demo-3
pod "security-context-demo-3" deleted
$ kubectl delete pod security-context-demo-4
pod "security-context-demo-4" deleted
```

### 为 Pod 配置服务账户

服务账户为 Pod 中运行的进程提供了一个标识。

> **说明：** 本章是服务账户的用户使用介绍，描述服务账户在集群中如何起作用。 你的集群管理员可能已经对你的集群做了定制，因此导致本文中所讲述的内容并不适用。

当你（自然人）访问集群时（例如，使用 `kubectl`），API 服务器将你的身份验证为特定的用户帐户（当前这通常是 `admin`，除非你的集群管理员已经定制了你的集群配置）。 Pod 内的容器中的进程也可以与 api 服务器接触，当它们进行身份验证时，它们被验证为特定的服务帐户（例如，`default`）。

#### 使用默认的服务账户访问 API 服务器

当创建 Pod 时，如果没有指定服务账户，Pod 会被指定给命名空间中的 `default` 服务账户。 如果查看 Pod 的原始 JSON 或 YAML（例如：`kubectl get pods/<podname> -o yaml`）， 可以看到 `spec.serviceAccountName` 字段已经被自动设置了。

可以使用自动挂载给 Pod 的服务账户凭据访问 API， 访问集群页面中有相关描述。 服务账户的 API 许可取决于你所使用的**鉴权插件和策略**。

可以通过在 ServiceAccount 上设置 `automountServiceAccountToken: false` 来实现不给服务账户自动挂载 API 凭据到 `/var/run/secrets/kubernetes.io/serviceaccount/token` 的目的：

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build-robot
automountServiceAccountToken: false
...
```

在 1.6 以上版本中，也可以选择不给特定 Pod 自动挂载 API 凭据：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: build-robot
  automountServiceAccountToken: false
  ...
```

如果 Pod 和服务账户都指定了 `automountServiceAccountToken` 值，则 Pod 的 spec 优先于服务帐户。

#### 使用多个服务账户

每个命名空间都有一个名为 `default` 的服务账户资源。 可以用下面的命令查询这个服务账户以及命名空间中的其他 ServiceAccount 资源：

```shell
# $ kubectl get serviceaccounts
$ kubectl get sa
NAME      SECRETS   AGE
default   0         17d
```

创建额外的 ServiceAccount 对象：

```shell
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build-robot
EOF
```

ServiceAccount 对象的名字必须是一个有效的 [DNS 子域名](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/names#dns-subdomain-names).

查询服务帐户对象的详细信息，如下所示：

```shell
$ kubectl describe sa build-robot 
Name:                build-robot
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>    # 注意这里没有引用令牌
Events:              <none>
```

> **注意：**自 v1.24.0-alpha.3 版本以来，系统已默认不再为每个 ServiceAccount 自动生成包含服务帐户令牌的 Secret API 对象。ServiceAccount 准入控制器会为 Pod 创建一个 [volume](#绑定的服务账号令牌卷)（`projected` Volume），在其中包含用来访问 API 的令牌（通过 [TokenRequest](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/token-request-v1/) API 从 kube-apiserver 处获得的 ServiceAccountToken）；并为 Pod 中的每个容器添加一个 `volumeSource`，挂载在其 `/var/run/secrets/kubernetes.io/serviceaccount` 目录下。

可以使用授权插件来[设置服务账户的访问许可](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/rbac/#service-account-permissions)。

要使用非默认的服务账户，将 Pod 的 `spec.serviceAccountName` 字段设置为你想用的服务账户名称。

Pod 被创建时服务账户必须存在，否则会被拒绝。

不能更新已经创建好的 Pod 的服务账户。

可以清除服务账户，如下所示：

```shell
$ kubectl delete serviceaccount/build-robot
serviceaccount "build-robot" deleted
```

##### [绑定的服务账号令牌卷](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-token-volume)

**特性状态：** `Kubernetes v1.22 [stable]`

ServiceAccount 准入控制器将添加如下投射卷， 而不是为令牌控制器所生成的不过期的服务账号令牌而创建的基于 Secret 的卷。

```yaml
...
spec:
  containers:
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-nlvd8
      readOnly: true
      ...
...
  volumes:
  - name: kube-api-access-nlvd8
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
...
```

#### 手动创建服务账户 API 令牌

假设我们有一个上面提到的名为 "build-robot" 的服务账户，现在我们手动创建一个 Secret API 对象以填充服务帐户令牌：

```shell
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: build-robot-secret
  annotations:
    kubernetes.io/service-account.name: build-robot
type: kubernetes.io/service-account-token
# data:
  # 可以像 Opaque Secret 一样在这里添加额外的键/值偶对
  # extra: YmFyCg==
EOF
```

现在，可以确认新构建的 Secret API 对象中填充了 "build-robot" 服务帐户的 API 令牌。 令牌控制器将清理不存在的服务帐户的所有令牌。

```shell
$ kubectl describe secrets/build-robot-secret
Name:         build-robot-secret
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: build-robot
              kubernetes.io/service-account.uid: 06bef0f8-8ad0-4d21-86fd-e51675b13a28

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1099 bytes
namespace:  7 bytes
token:      ...
```

查询服务帐户对象 "build-robot" 的详细信息，如下所示：

```shell
$ kubectl describe sa build-robot
Name:                build-robot
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              build-robot-secret
Events:              <none>
```

#### 为服务账户添加 ImagePullSecrets

##### 创建 ImagePullSecret

- 创建一个 ImagePullSecret，如[为 Pod 设置 ImagePullSecret](https://kubernetes.io/zh-cn/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod) 所述。

  ```shell
  $ kubectl create secret docker-registry myregistrykey --docker-server=DUMMY_SERVER \
            --docker-username=DUMMY_USERNAME --docker-password=DUMMY_DOCKER_PASSWORD \
            --docker-email=DUMMY_DOCKER_EMAIL
  ```

- 确认创建成功：

  ```shell
  $ kubectl get secrets myregistrykey
  NAME            TYPE                             DATA   AGE
  myregistrykey   kubernetes.io/dockerconfigjson   1      4s
  ```

##### 将 ImagePullSecret 添加到服务账户

修改命名空间的 `default` 服务帐户，令其使用该 Secret 用作 `imagePullSecret`。

```shell
$ kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "myregistrykey"}]}'
```

也可以使用 `kubectl edit`，或者如下所示手动编辑 YAML 清单：

```shell
$ kubectl get serviceaccounts default -o yaml > ./sa.yaml
```

`sa.yaml` 文件的输出类似这样：

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2022-07-18T16:15:14Z"
  name: default
  namespace: default
  resourceVersion: "329"
  uid: 81ff4db9-563d-419b-8634-ed2f61f3a108
```

使用常用的编辑器（例如 `vi`），打开 `sa.yaml` 文件，删除带有键名 `resourceVersion` 的行，添加带有 `imagePullSecrets:` 的行，最后保存文件。

所得到的 `sa.yaml` 文件类似于：

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2022-07-18T16:15:14Z"
  name: default
  namespace: default
  uid: 81ff4db9-563d-419b-8634-ed2f61f3a108
imagePullSecrets:
- name: myregistrykey
```

最后，使用新更新的 `sa.yaml` 文件替换服务账户。

```shell
$ kubectl replace serviceaccount default -f ./sa.yaml
serviceaccount/default replaced
```

验证 `default` 服务帐户详细信息：

```shell
$ kubectl get sa default -o yaml
apiVersion: v1
imagePullSecrets:
- name: myregistrykey
kind: ServiceAccount
metadata:
  creationTimestamp: "2022-07-18T16:15:14Z"
  name: default
  namespace: default
  resourceVersion: "3201964"
  uid: 81ff4db9-563d-419b-8634-ed2f61f3a108
```

##### 验证 ImagePullSecret 已经被添加到 Pod 规约

现在，在当前命名空间中创建使用默认服务账户的新 Pod 时，新 Pod 会自动设置其 `.spec.imagePullSecrets` 字段：

```shell
$ kubectl run nginx --image=nginx --restart=Never
pod/nginx created
$ kubectl get pod nginx -o=jsonpath='{.spec.imagePullSecrets[0].name}{"\n"}'
myregistrykey
```

#### 服务帐户令牌卷投射

**特性状态：** `Kubernetes v1.20 [stable]`

为了启用令牌请求投射，你必须为 `kube-apiserver` 设置以下命令行参数：

- `--service-account-issuer`

  此参数可作为服务账户令牌发放者的身份标识（Identifier）。你可以多次指定 `--service-account-issuer` 参数，对于要变更发放者而又不想带来业务中断的场景， 这样做是有用的。如果这个参数被多次指定，则第一个参数值会被用来生成令牌， 而所有参数值都会被用来确定哪些发放者是可接受的。你所运行的 Kubernetes 集群必须是 v1.22 或更高版本，才能多次指定 `--service-account-issuer`。

- `--service-account-key-file`

  包含 PEM 编码的 x509 RSA 或 ECDSA 私钥或公钥，用来检查 ServiceAccount 的令牌。所指定的文件中可以包含多个秘钥，并且你可以多次使用此参数， 每次参数值为不同的文件。多次使用此参数时，由所给的秘钥之一签名的令牌会被 Kubernetes API 服务器认为是合法令牌。

- `--service-account-signing-key-file`

  指向包含当前服务账户令牌发放者的私钥的文件路径。 此发放者使用此私钥来签署所发放的 ID 令牌。

- `--api-audiences` (可以省略)

  服务账户令牌身份检查组件会检查针对 API 访问所使用的令牌， 确认令牌至少是被绑定到这里所给的受众（audiences）之一。 如果此参数被多次指定，则针对所给的多个受众中任何目标的令牌都会被 Kubernetes API 服务器当做合法的令牌。如果 `--service-account-issuer` 参数被设置，而这个参数未指定，则这个参数的默认值为一个只有一个元素的列表， 且该元素为令牌发放者的 URL。

kubelet 还可以将服务帐户令牌投射到 Pod 中。 你可以指定令牌的期望属性，例如受众和有效期限。 这些属性在 default 服务帐户令牌上无法配置。 当删除 Pod 或 ServiceAccount 时，服务帐户令牌也将对 API 无效。

使用名为 ServiceAccountToken 的 ProjectedVolume 类型在 PodSpec 上配置此功能。 要向 Pod 提供具有 "vault" 用户以及两个小时有效期的令牌，可以在 PodSpec 中配置以下内容：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    volumeMounts:
    - mountPath: /var/run/secrets/tokens
      name: vault-token
  serviceAccountName: build-robot
  volumes:
  - name: vault-token
    projected:
      sources:
      - serviceAccountToken:
          path: vault-token
          expirationSeconds: 7200
          audience: vault
```

创建 Pod：

```shell
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-projected-svc-token.yaml
```

查看 Pod 详细信息：

```shell
$ kubectl get pod nginx -o yaml
...
spec:
  containers:
  - image: nginx
    volumeMounts:
    - mountPath: /var/run/secrets/tokens
      name: vault-token
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount  # 默认账户 default
      name: kube-api-access-7bg4r
      readOnly: true
      ...
...
  volumes:
  - name: vault-token
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          audience: vault
          expirationSeconds: 7200
          path: vault-token
  - name: kube-api-access-7bg4r  # 默认账户 default
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
...
```

`kubelet` 组件会替 Pod 请求令牌并将其保存起来， 通过将令牌存储到一个可配置的路径使之在 Pod 内可用， 并在令牌快要到期的时候刷新它。 `kubelet` 会在令牌存在期达到其 TTL 的 80% 的时候或者令牌生命期超过 24 小时的时候主动轮换它。

应用程序负责在令牌被轮换时重新加载其内容。对于大多数使用场景而言， 周期性地（例如，每隔 5 分钟）重新加载就足够了。

#### 发现服务账户分发者

**特性状态：** `Kubernetes v1.21 [stable]`

当启用服务账户令牌投射时启用发现服务账户分发者（Service Account Issuer Discovery） 这一功能特性，如[上文所述](#服务帐户令牌卷投射)。

> **说明：**
>
> 分发者的 URL 必须遵从 [OIDC 发现规范](https://openid.net/specs/openid-connect-discovery-1_0.html)。 这意味着 URL 必须使用 `https` 模式，并且必须在 `{service-account-issuer}/.well-known/openid-configuration` 路径给出 OpenID 提供者（Provider）配置。
>
> 如果 URL 没有遵从这一规范，`ServiceAccountIssuerDiscovery` 末端就不会被注册， 即使该特性已经被启用。

发现服务账户分发者这一功能使得用户能够用联邦的方式结合使用 Kubernetes 集群（“Identity Provider”，标识提供者）与外部系统（“Relying Parties”， 依赖方）所分发的服务账户令牌。

当此功能被启用时，Kubernetes API 服务器会在 `/.well-known/openid-configuration` 提供一个 OpenID 提供者配置文档，并在 `/openid/v1/jwks` 处提供与之关联的 JSON Web Key Set（JWKS）。 这里的 OpenID 提供者配置有时候也被称作“发现文档（Discovery Document）”。

集群包括一个的默认 RBAC ClusterRole, 名为 `system:service-account-issuer-discovery`。 默认的 RBAC ClusterRoleBinding 将此角色分配给 `system:serviceaccounts` 组， 所有服务帐户隐式属于该组。这使得集群上运行的 Pod 能够通过它们所挂载的服务帐户令牌访问服务帐户发现文档。 此外，管理员可以根据其安全性需要以及期望集成的外部系统选择是否将该角色绑定到 `system:authenticated` 或 `system:unauthenticated`。

> **说明：** 对 `/.well-known/openid-configuration` 和 `/openid/v1/jwks` 路径请求的响应被设计为与 OIDC 兼容，但不是与其完全一致。 返回的文档仅包含对 Kubernetes 服务账户令牌进行验证所必须的参数。

JWKS 响应包含依赖方可以用来验证 Kubernetes 服务账户令牌的公钥数据。 依赖方先会查询 OpenID 提供者配置，之后使用返回响应中的 `jwks_uri` 来查找 JWKS。

在很多场合，Kubernetes API 服务器都不会暴露在公网上，不过对于缓存并向外提供 API 服务器响应数据的公开末端而言，用户或者服务提供商可以选择将其暴露在公网上。 在这种环境中，可能会重载 OpenID 提供者配置中的 `jwks_uri`，使之指向公网上可用的末端地址，而不是 API 服务器的地址。 这时需要向 API 服务器传递 `--service-account-jwks-uri` 参数。 与分发者 URL 类似，此 JWKS URI 也需要使用 `https` 模式。

### 从私有仓库拉取镜像

本章节介绍如何使用 Secret 从私有的镜像仓库或代码仓库拉取镜像来创建 Pod。 有很多私有镜像仓库正在使用中。这个任务使用的镜像仓库是 [Docker Hub](https://www.docker.com/products/docker-hub)。

#### 登录 Docker 镜像仓库

在个人电脑上，要想拉取私有镜像必须在镜像仓库上进行身份验证。

使用 `docker` 命令工具来登录到 Docker Hub。 更多详细信息，请查阅 [Docker ID accounts](https://docs.docker.com/docker-id/#log-in) 中的 *log in* 部分。

```shell
$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: aluopy
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

当出现提示时，输入你的 Docker ID 和登录凭证（访问令牌、 或 Docker ID 的密码）。

登录过程会创建或更新保存有授权令牌的 `config.json` 文件。 查看 [Kubernetes 中如何解析这个文件](https://kubernetes.io/zh-cn/docs/concepts/containers/images#config-json)。

查看 `config.json` 文件：

```shell
$ cat /root/.docker/config.json
{
	"auths": {
		"https://index.docker.io/v1/": {
			"auth": "YWx1b3B5OmFsdW9weS5pbWFnZXM="
		}
	}
```

> **说明：** 如果使用 Docker 凭证仓库，则不会看到 `auth` 条目，看到的将是以仓库名称作为值的 `credsStore` 条目。

#### 创建一个基于现有凭证的 Secret

Kubernetes 集群使用 `kubernetes.io/dockerconfigjson` 类型的 Secret 来通过镜像仓库的身份验证，进而提取私有镜像。

如果已经运行了 `docker login` 命令，可以复制该镜像仓库的凭证到 Kubernetes：

```shell
$ kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=/root/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
```

如果需要更多的设置（例如，为新 Secret 设置名字空间或标签）， 则可以在存储 Secret 之前对它进行自定义。 请务必：

- 将 data 项中的名称设置为 `.dockerconfigjson`
- 使用 base64 编码方法对 Docker 配置文件进行编码，然后粘贴该字符串的内容，作为字段 `data[".dockerconfigjson"]` 的值
- 将 `type` 设置为 `kubernetes.io/dockerconfigjson`

示例：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myregistrykey
  namespace: awesomeapps
data:
  .dockerconfigjson: ewoJImF1dGhzIjogewoJCSJodHRwczovL2luZGV4LmRvY2tlci5pby92MS8iOiB7CgkJCSJhdXRoIjogIllXeDFiM0I1T21Gc2RXOXdlUzVwYldGblpYTT0iCgkJfQoJfQp9
type: kubernetes.io/dockerconfigjson
```

如果收到错误消息：`error: no objects passed to create`， 这可能意味着 base64 编码的字符串是无效的。 如果收到类似 `Secret "myregistrykey" is invalid: data[.dockerconfigjson]: invalid value ...` 的错误消息，则表示数据中的 base64 编码字符串已成功解码， 但无法解析为 `.docker/config.json` 文件。

#### 在命令行上提供凭证来创建 Secret

创建 Secret，命名为 `regcred`：

```shell
$ kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=aluopy \
  --docker-password=aluopy \
  --docker-email=hallo@aluopy.cn
```

这样就成功地将集群中的 Docker 凭证设置为名为 `regcred` 的 Secret。

> **说明：** 在命令行上键入 Secret 可能会将它们存储在你的 shell 历史记录中而不受保护， 并且这些 Secret 信息也可能在 `kubectl` 运行期间对你 PC 上的其他用户可见。

#### 检查 Secret `regcred`

查看创建的 `regcred` Secret 的内容

```shell
$ kubectl get secrets regcred -o yaml
apiVersion: v1
data:
  .dockerconfigjson: eyJhdXRocyI6eyJodHRwczovL2luZGV4LmRvY2tlci5pby92MS8iOnsidXNlcm5hbWUiOiJhbHVvcHkiLCJwYXNzd29yZCI6ImFsdW9weSIsImVtYWlsIjoiaGFsbG9AYWx1b3B5LmNuIiwiYXV0aCI6IllXeDFiM0I1T21Gc2RXOXdlUT09In19fQ==
kind: Secret
metadata:
  creationTimestamp: "2022-08-08T05:38:22Z"
  name: regcred
  namespace: default
  resourceVersion: "3734725"
  uid: b9c479af-df93-4445-a297-b2ff93f8957e
type: kubernetes.io/dockerconfigjson
```

`.dockerconfigjson` 字段的值是 Docker 凭证的 base64 表示。

要了解 `dockerconfigjson` 字段中的内容，请将 Secret 数据转换为可读格式：

```shell
$ kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
{"auths":{"https://index.docker.io/v1/":{"username":"aluopy","password":"aluopy","email":"hallo@aluopy.cn","auth":"YWx1b3B5OmFsdW9weQ=="}}}
```

要了解 `auth` 字段中的内容，请将 base64 编码过的数据转换为可读格式：

```shell
$ echo "eyJhdXRocyI6eyJodHRwczovL2luZGV4LmRvY2tlci5pby92MS8iOnsidXNlcm5hbWUiOiJhbHVvcHkiLCJwYXNzd29yZCI6ImFsdW9weSIsImVtYWlsIjoiaGFsbG9AYWx1b3B5LmNuIiwiYXV0aCI6IllXeDFiM0I1T21Gc2RXOXdlUT09In19fQ==" | base64 --decode
{"auths":{"https://index.docker.io/v1/":{"username":"aluopy","password":"aluopy","email":"hallo@aluopy.cn","auth":"YWx1b3B5OmFsdW9weQ=="}}}
```

注意，Secret 数据包含与本地 `~/.docker/config.json` 文件类似的授权令牌。

这样就已经成功地将 Docker 凭证设置为集群中的名为 `regcred` 的 Secret。

#### 创建一个使用 Secret 的 Pod

下面是一个 Pod 配置清单示例，该示例中 Pod 需要访问 Docker 凭证 `regcred`：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-reg
spec:
  containers:
  - name: private-reg-container
    image: aluopy/alpine-glibc:3.15
  imagePullSecrets:
  - name: regcred
```

要从私有仓库拉取镜像，Kubernetes 需要凭证。 配置文件中的 `imagePullSecrets` 字段表明 Kubernetes 应该通过名为 `regcred` 的 Secret 获取凭证。

创建使用了你的 Secret 的 Pod，并检查它是否正常运行：

```shell
$ kubectl apply -f private-reg-pod.yaml
$ kubectl get pod private-reg
```

### 配置存活、就绪和启动探测器

本章介绍如何给容器配置活跃（Liveness）、就绪（Readiness）和启动（Startup）探测器。

[kubelet](https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/kubelet/) 使用存活探测器来确定什么时候要重启容器。 例如，存活探测器可以探测到应用死锁（应用程序在运行，但是无法继续执行后面的步骤）情况。 重启这种状态下的容器有助于提高应用的可用性，即使其中存在缺陷。

kubelet 使用就绪探测器可以知道容器何时准备好接受请求流量，当一个 Pod 内的所有容器都就绪时，才能认为该 Pod 就绪。 这种信号的一个用途就是控制哪个 Pod 作为 Service 的后端。 若 Pod 尚未就绪，会被从 Service 的负载均衡器中剔除。

kubelet 使用启动探测器来了解应用容器何时启动。 如果配置了这类探测器，你就可以控制容器在启动成功后再进行存活性和就绪态检查， 确保这些存活、就绪探测器不会影响应用的启动。 启动探测器可以用于对慢启动容器进行存活性检测，避免它们在启动运行之前就被杀掉。

#### 定义存活命令[ ](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command)

许多长时间运行的应用最终会进入损坏状态，除非重新启动，否则无法被恢复。 Kubernetes 提供了存活探测器来发现并处理这种情况。

在本练习中，将创建一个 Pod，其中运行一个基于 `k8s.gcr.io/busybox` 镜像的容器。 下面是这个 Pod 的配置文件。

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    # image: k8s.gcr.io/busybox
    image: registry.cn-shenzhen.aliyuncs.com/aluopy/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

在这个配置文件中，可以看到 Pod 中只有一个 `Container`。 `periodSeconds` 字段指定了 kubelet 应该每 5 秒执行一次存活探测。 `initialDelaySeconds` 字段告诉 kubelet 在执行第一次探测前应该等待 5 秒。 kubelet 在容器内执行命令 `cat /tmp/healthy` 来进行探测。 如果命令执行成功并且返回值为 0，kubelet 就会认为这个容器是健康存活的。 如果这个命令返回非 0 值，kubelet 会杀死这个容器并重新启动它。

当容器启动时，执行如下的命令：

```shell
/bin/sh -c "touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600"
```

这个容器生命的前 30 秒，`/tmp/healthy` 文件是存在的。 所以在这最开始的 30 秒内，执行命令 `cat /tmp/healthy` 会返回成功代码。 30 秒之后，执行命令 `cat /tmp/healthy` 就会返回失败代码。

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/exec-liveness.yaml
```

在 30 秒内，查看 Pod 的事件：

```shell
$ kubectl describe pod liveness-exec
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  25s   default-scheduler  Successfully assigned default/liveness-exec to w1
  Normal  Pulling    24s   kubelet            Pulling image "registry.cn-shenzhen.aliyuncs.com/aluopy/busybox"
  Normal  Pulled     24s   kubelet            Successfully pulled image "registry.cn-shenzhen.aliyuncs.com/aluopy/busybox" in 424.693462ms
  Normal  Created    24s   kubelet            Created container liveness
  Normal  Started    23s   kubelet            Started container liveness
```

> 输出结果表明还没有存活探测失败。

35 秒之后，再来看 Pod 的事件：

```shell
$ kubectl describe pod liveness-exec
...
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  39s   default-scheduler  Successfully assigned default/liveness-exec to w1
  Normal   Pulling    38s   kubelet            Pulling image "registry.cn-shenzhen.aliyuncs.com/aluopy/busybox"
  Normal   Pulled     38s   kubelet            Successfully pulled image "registry.cn-shenzhen.aliyuncs.com/aluopy/busybox" in 424.693462ms
  Normal   Created    38s   kubelet            Created container liveness
  Normal   Started    37s   kubelet            Started container liveness
  Warning  Unhealthy  4s    kubelet            Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
```

> 在输出结果的最下面，有信息显示存活探测失败了，这个失败的容器被杀死并且被重建了。

再等 30 秒，确认这个容器被重启了：

```shell
$ kubectl get pod liveness-exec
NAME            READY   STATUS              RESTARTS   AGE
liveness-exec   1/1     Running             1 (1s ago)   76s
```

> 输出结果显示 `RESTARTS` 的值增加了 1。请注意，一旦失败的容器恢复为运行状态，`RESTARTS` 计数器就会增加 1

#### 定义存活态 HTTP 请求接口

另外一种类型的存活探测方式是使用 HTTP GET 请求。 下面是一个 Pod 的配置文件，其中运行一个基于 `k8s.gcr.io/liveness` 镜像的容器。

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    # image: k8s.gcr.io/liveness
    image: registry.cn-shenzhen.aliyuncs.com/aluopy/liveness
    args:
    - /server
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

在这个配置文件中，可以看到 Pod 也只有一个容器。 `periodSeconds` 字段指定了 kubelet 每隔 3 秒执行一次存活探测。 `initialDelaySeconds` 字段告诉 kubelet 在执行第一次探测前应该等待 3 秒。 kubelet 会向容器内运行的服务（服务在监听 8080 端口）发送一个 HTTP GET 请求来执行探测。 如果服务器上 `/healthz` 路径下的处理程序返回成功代码，则 kubelet 认为容器是健康存活的。 如果处理程序返回失败代码，则 kubelet 会杀死这个容器并将其重启。

返回大于或等于 200 并且小于 400 的任何代码都标示成功，其它返回代码都标示失败。

可以访问 [server.go](https://github.com/kubernetes/kubernetes/blob/master/test/images/agnhost/liveness/server.go)。 阅读服务的源码。 容器存活期间的最开始 10 秒中，`/healthz` 处理程序返回 200 的状态码。 之后处理程序返回 500 的状态码。

```go
http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
    duration := time.Now().Sub(started)
    if duration.Seconds() > 10 {
        w.WriteHeader(500)
        w.Write([]byte(fmt.Sprintf("error: %v", duration.Seconds())))
    } else {
        w.WriteHeader(200)
        w.Write([]byte("ok"))
    }
})
```

kubelet 在容器启动之后 3 秒开始执行健康检测。所以前几次健康检查都是成功的。 但是 10 秒之后，健康检查会失败，并且 kubelet 会杀死容器再重新启动容器。

创建一个 Pod 来测试 HTTP 的存活检测：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/http-liveness.yaml
```

10 秒之后，通过查看 Pod 事件来确认活跃探测器已经失败，并且容器被重新启动了。

```shell
$ kubectl describe pod liveness-http
```

在 1.13 之前（包括 1.13）的版本中，如果在 Pod 运行的节点上设置了环境变量 `http_proxy`（或者 `HTTP_PROXY`），HTTP 的存活探测会使用这个代理。 在 1.13 之后的版本中，设置本地的 HTTP 代理环境变量不会影响 HTTP 的存活探测。

#### 定义 TCP 的存活探测

第三种类型的存活探测是使用 TCP 套接字。 使用这种配置时，kubelet 会尝试在指定端口和容器建立套接字链接。 如果能建立连接，这个容器就被看作是健康的，如果不能则这个容器就被看作是有问题的。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: goproxy
  labels:
    app: goproxy
spec:
  containers:
  - name: goproxy
    # image: k8s.gcr.io/goproxy:0.1
    image: registry.cn-shenzhen.aliyuncs.com/aluopy/goproxy:0.1
    ports:
    - containerPort: 8080
    readinessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    livenessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 20
```

如你所见，TCP 检测的配置和 HTTP 检测非常相似。 下面这个例子同时使用就绪和存活探测器。kubelet 会在容器启动 5 秒后发送第一个就绪探测。 探测器会尝试连接 `goproxy` 容器的 8080 端口。 如果探测成功，这个 Pod 会被标记为就绪状态，kubelet 将继续每隔 10 秒运行一次检测。

除了就绪探测，这个配置包括了一个存活探测。 kubelet 会在容器启动 15 秒后进行第一次存活探测。 与就绪探测类似，存活探测会尝试连接 `goproxy` 容器的 8080 端口。 如果存活探测失败，容器会被重新启动。

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/tcp-liveness-readiness.yaml
```

15 秒之后，通过看 Pod 事件来检测存活探测器：

```shell
$ kubectl describe pod goproxy
```

#### 定义 gRPC 活跃探测器

**特性状态：** `Kubernetes v1.24 [beta]`

如果你的应用实现了 [gRPC 健康检查协议](https://github.com/grpc/grpc/blob/master/doc/health-checking.md)， kubelet 可以配置为使用该协议来执行应用活跃性检查。 你必须启用 `GRPCContainerProbe` [特性门控](https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/feature-gates/) 才能配置依赖于 gRPC 的检查机制。

下面是一个示例清单：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: etcd-with-grpc
spec:
  containers:
  - name: etcd
    # image: k8s.gcr.io/etcd:3.5.1-0
    image: registry.cn-shenzhen.aliyuncs.com/aluopy/etcd:3.5.1-0
    command: [ "/usr/local/bin/etcd", "--data-dir",  "/var/lib/etcd", "--listen-client-urls", "http://0.0.0.0:2379", "--advertise-client-urls", "http://127.0.0.1:2379", "--log-level", "debug"]
    ports:
    - containerPort: 2379
    livenessProbe:
      grpc:
        port: 2379
      initialDelaySeconds: 10
```

要使用 gRPC 探测器，必须配置 `port` 属性。如果健康状态端点配置在非默认服务之上， 你还必须设置 `service` 属性。

> **说明：**与 HTTP 和 TCP 探测器不同，gRPC 探测不能使用命名端口或定制主机。

配置问题（例如：错误的 `port` 和 `service`、未实现健康检查协议） 都被认作是探测失败，这一点与 HTTP 和 TCP 探测器类似。

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/grpc-liveness.yaml
```

15 秒钟之后，查看 Pod 事件确认活跃性检查并未失败：

```shell
$ kubectl describe pod etcd-with-grpc
```

在 Kubernetes 1.23 之前，gRPC 健康探测通常使用 [grpc-health-probe](https://github.com/grpc-ecosystem/grpc-health-probe/) 来实现，如博客 [Health checking gRPC servers on Kubernetes（对 Kubernetes 上的 gRPC 服务器执行健康检查）](https://kubernetes.io/blog/2018/10/01/health-checking-grpc-servers-on-kubernetes/)所描述。 内置的 gRPC 探测器行为与 `grpc-health-probe` 所实现的行为类似。 从 `grpc-health-probe` 迁移到内置探测器时，请注意以下差异：

- 内置探测器运行时针对的是 Pod 的 IP 地址，不像 `grpc-health-probe` 那样通常针对 `127.0.0.1` 执行探测； 请一定配置你的 gRPC 端点使之监听于 Pod 的 IP 地址之上。
- 内置探测器不支持任何身份认证参数（例如 `-tls`）。
- 对于内置的探测器而言，不存在错误代码。所有错误都被视作探测失败。
- 如果 `ExecProbeTimeout` 特性门控被设置为 `false`，则 `grpc-health-probe` 不会考虑 `timeoutSeconds` 设置状态（默认值为 1s）， 而内置探测器则会在超时时返回失败。

#### 使用命名端口

对于 HTTP 或者 TCP 存活检测可以使用命名的 [`port`](https://kubernetes.io/zh-cn/docs/reference/kubernetes-api/workload-resources/pod-v1/#ports)。

```yaml
ports:
- name: liveness-port
  containerPort: 8080
  hostPort: 8080

livenessProbe:
  httpGet:
    path: /healthz
    port: liveness-port
```

#### 使用启动探测器保护慢启动容器

有时候，会有一些现有的应用在启动时需要较长的初始化时间。 在这种情况下，若要不影响对死锁作出快速响应的探测，设置存活探测参数可能会很棘手。 诀窍是是使用相同的命令来设置启动探测，针对 HTTP 或 TCP 检测，可以通过将 `failureThreshold * periodSeconds` 参数设置为足够长的时间来覆盖最坏情况的启动时间。

这样，前面的例子就变成了：

```yaml
ports:
- name: liveness-port
  containerPort: 8080
  hostPort: 8080

livenessProbe:
  httpGet:
    path: /healthz
    port: liveness-port
  failureThreshold: 1
  periodSeconds: 10

startupProbe:
  httpGet:
    path: /healthz
    port: liveness-port
  failureThreshold: 30
  periodSeconds: 10
```

幸亏有**启动探测**，应用程序将会有最多 5 分钟（30 * 10 = 300s）的时间来完成其启动过程。 一旦启动探测成功一次，存活探测任务就会接管对容器的探测，对容器死锁作出快速响应。 如果启动探测一直没有成功，容器会在 300 秒后被杀死，并且根据 `restartPolicy` 来 执行进一步处置。

> `failureThreshold` 当探测失败时，Kubernetes 的重试次数。 对存活探测而言，放弃就意味着重新启动容器。 对就绪探测而言，放弃意味着 Pod 会被打上未就绪的标签。默认值是 3。最小值是 1。

#### 定义就绪探测器

有时候，应用会暂时性地无法为请求提供服务。 例如，应用在启动时可能需要加载大量的数据或配置文件，或是启动后要依赖等待外部服务。 在这种情况下，既不想杀死应用，也不想给它发送请求。 Kubernetes 提供了就绪探测器来发现并缓解这些情况。 容器所在 Pod 上报还未就绪的信息，并且不接受通过 Kubernetes Service 的流量。

> **说明：**就绪探测器在容器的整个生命周期中保持运行状态。

> **注意：**活跃探测器 **不等待** 就绪性探测器成功。 如果要在执行活跃探测器之前等待，应该使用 `initialDelaySeconds` 或 `startupProbe`。

就绪探测器的配置和存活探测器的配置相似。 唯一区别就是要使用 `readinessProbe` 字段，而不是 `livenessProbe` 字段。

```yaml
readinessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 5
```

HTTP 和 TCP 的就绪探测器配置也和存活探测器的配置完全相同。

就绪和存活探测可以在同一个容器上并行使用。 两者共同使用，可以确保流量不会发给还未就绪的容器，当这些探测失败时容器会被重新启动。

#### 配置探测器

[Probe](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#probe-v1-core) 有很多配置字段，可以使用这些字段精确地控制活跃和就绪检测的行为：

- `initialDelaySeconds`：容器启动后要等待多少秒后才启动存活和就绪探测器， 默认是 0 秒，最小值是 0。
- `periodSeconds`：执行探测的时间间隔（单位是秒）。默认是 10 秒。最小值是 1。
- `timeoutSeconds`：探测的超时后等待多少秒。默认值是 1 秒。最小值是 1。
- `successThreshold`：探测器在失败后，被视为成功的最小连续成功数。默认值是 1。 存活和启动探测的这个值必须是 1。最小值是 1。
- `failureThreshold`：当探测失败时，Kubernetes 的重试次数。 对存活探测而言，放弃就意味着重新启动容器。 对就绪探测而言，放弃意味着 Pod 会被打上未就绪的标签。默认值是 3。最小值是 1。

> **说明：**
>
> 在 Kubernetes 1.20 版本之前，`exec` 探针会忽略 `timeoutSeconds`： 探针会无限期地持续运行，甚至可能超过所配置的限期，直到返回结果为止。
>
> 这一缺陷在 Kubernetes v1.20 版本中得到修复。你可能一直依赖于之前错误的探测行为， 甚至都没有觉察到这一问题的存在，因为默认的超时值是 1 秒钟。 作为集群管理员，你可以在所有的 kubelet 上禁用 `ExecProbeTimeout` [特性门控](https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/feature-gates/) （将其设置为 `false`），从而恢复之前版本中的运行行为。之后当集群中所有的 exec 探针都设置了 `timeoutSeconds` 参数后，移除此标志重载。 如果你有 Pod 受到此默认 1 秒钟超时值的影响，你应该更新这些 Pod 对应的探针的超时值， 这样才能为最终去除该特性门控做好准备。
>
> 当此缺陷被修复之后，在使用 `dockershim` 容器运行时的 Kubernetes `1.20+` 版本中，对于 exec 探针而言，容器中的进程可能会因为超时值的设置保持持续运行， 即使探针返回了失败状态。

> **注意：**
>
> 如果就绪态探针的实现不正确，可能会导致容器中进程的数量不断上升。 如果不对其采取措施，很可能导致资源枯竭的状况。

#### HTTP 探测

[HTTP Probes](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#httpgetaction-v1-core) 允许针对 `httpGet` 配置额外的字段：

- `host`：连接使用的主机名，默认是 Pod 的 IP。也可以在 HTTP 头中设置 “Host” 来代替。
- `scheme` ：用于设置连接主机的方式（HTTP 还是 HTTPS）。默认是 "HTTP"。
- `path`：访问 HTTP 服务的路径。默认值为 "/"。
- `httpHeaders`：请求中自定义的 HTTP 头。HTTP 头字段允许重复。
- `port`：访问容器的端口号或者端口名。如果数字必须在 1～65535 之间。

对于 HTTP 探测，kubelet 发送一个 HTTP 请求到指定的路径和端口来执行检测。 除非 `httpGet` 中的 `host` 字段设置了，否则 kubelet 默认是给 Pod 的 IP 地址发送探测。 如果 `scheme` 字段设置为了 `HTTPS`，kubelet 会跳过证书验证发送 HTTPS 请求。 大多数情况下，不需要设置`host` 字段。 这里有个需要设置 `host` 字段的场景，假设容器监听 127.0.0.1，并且 Pod 的 `hostNetwork` 字段设置为了 `true`。那么 `httpGet` 中的 `host` 字段应该设置为 127.0.0.1。 可能更常见的情况是如果 Pod 依赖虚拟主机，你不应该设置 `host` 字段，而是应该在 `httpHeaders` 中设置 `Host`。

针对 HTTP 探针，kubelet 除了必需的 `Host` 头部之外还发送两个请求头部字段： `User-Agent` 和 `Accept`。这些头部的默认值分别是 `kube-probe/{{ skew currentVersion >}}` （其中 `1.24` 是 kubelet 的版本号）和 `*/*`。

你可以通过为探测设置 `.httpHeaders` 来重载默认的头部字段值；例如：

```yaml
livenessProbe:
  httpGet:
    httpHeaders:
      - name: Accept
        value: application/json

startupProbe:
  httpGet:
    httpHeaders:
      - name: User-Agent
        value: MyUserAgent
```

你也可以通过将这些头部字段定义为空值，从请求中去掉这些头部字段。

```yaml
livenessProbe:
  httpGet:
    httpHeaders:
      - name: Accept
        value: ""

startupProbe:
  httpGet:
    httpHeaders:
      - name: User-Agent
        value: ""
```

#### TCP 探测

对于 TCP 探测而言，kubelet 在节点上（不是在 Pod 里面）发起探测连接， 这意味着你不能在 `host` 参数上配置服务名称，因为 kubelet 不能解析服务名称。

#### 探测器层面的 `terminationGracePeriodSeconds`

**特性状态：** `Kubernetes v1.22 [beta]`

在 1.21 发行版之前，Pod 层面的 `terminationGracePeriodSeconds` 被用来终止活跃探测或启动探测失败的容器。 这一行为上的关联不是我们想要的，可能导致 Pod 层面设置了 `terminationGracePeriodSeconds` 时容器要花非常长的时间才能重新启动。

在 1.21 及更高版本中，当特性门控 `ProbeTerminationGracePeriod` 被启用时， 用户可以指定一个探测器层面的 `terminationGracePeriodSeconds` 作为探测器规约的一部分。 当该特性门控被启用，并且 Pod 层面和探测器层面的 `terminationGracePeriodSeconds` 都已设置，kubelet 将使用探测器层面设置的值。

在 Kubernetes 1.22 中，`ProbeTerminationGracePeriod` 特性门控只能用在 API 服务器上。 kubelet 始终遵守探针级别 `terminationGracePeriodSeconds` 字段 （如果它存在于 Pod 上）。

如果你已经为现有 Pod 设置了 `terminationGracePeriodSeconds` 字段并且不再希望使用针对每个探针的终止宽限期，则必须删除现有的这类 Pod。

当你（或控制平面或某些其他组件）创建替换 Pod，并且特性门控 `ProbeTerminationGracePeriod` 被禁用时，API 服务器会忽略探针级别的 `terminationGracePeriodSeconds` 字段设置， 即使 Pod 或 Pod 模板指定了它。

例如:

```yaml
spec:
  terminationGracePeriodSeconds: 3600  # Pod 级别设置
  containers:
  - name: test
    image: ...

    ports:
    - name: liveness-port
      containerPort: 8080
      hostPort: 8080

    livenessProbe:
      httpGet:
        path: /healthz
        port: liveness-port
      failureThreshold: 1
      periodSeconds: 60
      # 重载 Pod 级别的 terminationGracePeriodSeconds
      terminationGracePeriodSeconds: 60
```

探测器层面的 `terminationGracePeriodSeconds` 不能用于就绪态探针。 这一设置将被 API 服务器拒绝。

### 将 Pod 分配给节点

本章显示如何将 Kubernetes Pod 指派给 Kubernetes 集群中的特定节点。

#### 给节点添加标签

1. 列出集群中的节点：

   ```shell
   $ kubectl get node
   NAME   STATUS   ROLES           AGE   VERSION
   m1     Ready    control-plane   20d   v1.24.3
   w1     Ready    worker          20d   v1.24.3
   w2     Ready    worker          20d   v1.24.3
   ```

2. 从节点中选择一个，为它添加标签（本文选择节点 `w2`）：

   ```shell
   $ kubectl label nodes w2 disktype=ssd
   node/w2 labeled
   ```

3. 验证选择的节点确实带有 `disktype=ssd` 标签：

   ```shell
   $ NAME   STATUS   ROLES           AGE   VERSION   LABELS
   m1     Ready    control-plane   20d   v1.24.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=m1,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
   w1     Ready    worker          20d   v1.24.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=w1,kubernetes.io/os=linux,kubernetes.io/rols=ingress,node-role.kubernetes.io/worker=worker
   w2     Ready    worker          20d   v1.24.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/arch=amd64,kubernetes.io/hostname=w2,kubernetes.io/os=linux,kubernetes.io/rols=ingress,node-role.kubernetes.io/worker=worker
   ```

   > 在上面的输出中可以看到 `w2` 节点有 `disktype=ssd` 标签。

#### 创建一个将被调度到你选择的节点的 Pod

此 Pod 配置文件描述了一个拥有节点选择器 `disktype: ssd` 的 Pod。这表明该 Pod 将被调度到有 `disktype=ssd` 标签的节点。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disktype: ssd
```

1. 使用该配置文件创建一个 Pod，该 Pod 将被调度到你选择的节点上：

   ```shell
   $ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-nginx.yaml
   ```

2. 验证 Pod 确实运行在你选择的节点上：

   ```shell
   $ kubectl get pod nginx -owide
   NAME    READY   STATUS    RESTARTS   AGE   IP           NODE   NOMINATED NODE   READINESS GATES
   nginx   1/1     Running   0          41s   10.0.1.237   w2     <none>           <none>
   ```

#### 创建一个会被调度到特定节点上的 Pod

也可以通过设置 `nodeName` 将某个 Pod 调度到特定的节点。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeName: w1  # 调度 Pod 到特定的节点
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
```

使用此配置文件来创建一个 Pod，该 Pod 将只能被调度到 `w1` 节点。

### 用节点亲和性把 Pods 分配到节点

本章展示在 Kubernetes 集群中，如何使用节点亲和性把 Kubernetes Pod 分配到特定节点。

#### 给节点添加标签

1. 列出集群中的节点：

   ```shell
   $ kubectl get node
   NAME   STATUS   ROLES           AGE   VERSION
   m1     Ready    control-plane   20d   v1.24.3
   w1     Ready    worker          20d   v1.24.3
   w2     Ready    worker          20d   v1.24.3
   ```

2. 从节点中选择一个，为它添加标签（本文选择节点 `w2`）：

   ```shell
   $ kubectl label nodes w2 disktype=ssd
   node/w2 labeled
   ```

3. 验证选择的节点确实带有 `disktype=ssd` 标签：

   ```shell
   $ NAME   STATUS   ROLES           AGE   VERSION   LABELS
   m1     Ready    control-plane   20d   v1.24.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=m1,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
   w1     Ready    worker          20d   v1.24.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=w1,kubernetes.io/os=linux,kubernetes.io/rols=ingress,node-role.kubernetes.io/worker=worker
   w2     Ready    worker          20d   v1.24.3   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/arch=amd64,kubernetes.io/hostname=w2,kubernetes.io/os=linux,kubernetes.io/rols=ingress,node-role.kubernetes.io/worker=worker
   ```

   > 在上面的输出中可以看到 `w2` 节点有 `disktype=ssd` 标签。

#### 依据强制的节点亲和性调度 Pod

下面清单描述了一个 Pod，它有一个节点亲和性配置 `requiredDuringSchedulingIgnoredDuringExecution`，`disktype=ssd`。 这意味着 pod 只会被调度到具有 `disktype=ssd` 标签的节点上。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd            
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-nginx-required-affinity.yaml
```

验证 Pod 是否在所选节点上运行：

```shell
$ kubectl get pod nginx -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE   NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          15s   10.0.1.205   w2     <none>           <none>
```

#### 使用首选的节点亲和性调度 Pod

本清单描述了一个Pod，它有一个节点亲和性设置 `preferredDuringSchedulingIgnoredDuringExecution`，`disktype: ssd`。 这意味着 pod 将首选具有 `disktype=ssd` 标签的节点。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd          
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-nginx-preferred-affinity.yaml
```

验证 Pod 是否在所选节点上运行：

```shell
$ kubectl get pod nginx -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP          NODE   NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          8s    10.0.1.66   w2     <none>           <none>
```

### 配置 Pod 初始化

本章介绍在应用容器运行前，怎样利用 Init 容器初始化 Pod。

#### 创建一个包含 Init 容器的 Pod

本例中你将创建一个包含一个应用容器和一个 Init 容器的 Pod。Init 容器在应用容器启动前运行完成。

下面是 Pod 的配置文件：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: workdir
      mountPath: /usr/share/nginx/html
  # 这些容器在 Pod 初始化期间运行
  initContainers:
  - name: install
    image: busybox:1.28
    command:
    - wget
    - "-O"
    - "/work-dir/index.html"
    - http://info.cern.ch
    volumeMounts:
    - name: workdir
      mountPath: "/work-dir"
  dnsPolicy: Default
  volumes:
  - name: workdir
    emptyDir: {}
```

配置文件中，可以看到应用容器和 Init 容器共享了一个卷。

Init 容器将共享卷挂载到了 `/work-dir` 目录，应用容器将共享卷挂载到了 `/usr/share/nginx/html` 目录。 Init 容器执行完 `wget -O /work-dir/index.html http://info.cern.ch` 命令就终止。

请注意 Init 容器在 nginx 服务器的根目录写入 `index.html`。

创建 Pod：

```shell
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/init-containers.yaml
```

检查 nginx 容器运行正常：

```shell
$ kubectl get pod init-demo
NAME        READY   STATUS    RESTARTS   AGE
init-demo   1/1     Running   0          58s
```

> 结果表明 nginx 容器运行正常。

通过 shell 进入 init-demo Pod 中的 nginx 容器，发送 GET 请求到 nginx 服务器：

```shell
$ kubectl exec -it init-demo -- /bin/bash
root@init-demo:/# apt-get update
root@init-demo:/# apt-get install curl
root@init-demo:/# curl localhost
<html><head></head><body><header>
<title>http://info.cern.ch</title>
</header>

<h1>http://info.cern.ch - home of the first website</h1>
...
<li><a href="http://info.cern.ch/hypertext/WWW/TheProject.html">Browse the first website</a></li>
...
```

> 结果表明 nginx 正在为 Init 容器编写的 web 页面服务。

### 为容器的生命周期事件设置处理函数

这个页面将演示如何为容器的生命周期事件挂接处理函数。Kubernetes 支持 postStart 和 preStop 事件。 当一个容器启动后，Kubernetes 将立即发送 postStart 事件；在容器被终结之前， Kubernetes 将发送一个 preStop 事件。容器可以为每个事件指定一个处理程序。

#### 定义 postStart 和 preStop 处理函数

在本练习中，将创建一个包含一个容器的 Pod，该容器为 postStart 和 preStop 事件提供对应的处理函数。

下面是对应 Pod 的配置文件：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-demo
spec:
  containers:
  - name: lifecycle-demo-container
    image: nginx
    lifecycle:
      postStart:
        exec:
          command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
      preStop:
        exec:
          command: ["/bin/sh","-c","nginx -s quit; while killall -0 nginx; do sleep 1; done"]
```

在上述配置文件中，可以看到 postStart 命令在容器的 `/usr/share` 目录下写入文件 `message`。 命令 preStop 负责优雅地终止 nginx 服务。当因为失效而导致容器终止时，这一处理方式很有用。

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/lifecycle-events.yaml
```

验证 Pod 中的容器已经运行：

```shell
$ kubectl get pod lifecycle-demo 
NAME             READY   STATUS    RESTARTS   AGE
lifecycle-demo   1/1     Running   0          10s
```

使用 shell 连接到 Pod 里的容器，验证 `postStart` 处理函数创建了 `message` 文件：

```shell
$ kubectl exec -it lifecycle-demo -- /bin/bash
root@lifecycle-demo:/# cat /usr/share/message
Hello from the postStart handler
```

> 命令行输出的是 `postStart` 处理函数所写入的文本。

#### 讨论

Kubernetes 在容器创建后立即发送 postStart 事件。 然而，postStart 处理函数的调用不保证早于容器的入口点（entrypoint） 的执行。postStart 处理函数与容器的代码是异步执行的，但 Kubernetes 的容器管理逻辑会一直阻塞等待 postStart 处理函数执行完毕。 只有 postStart 处理函数执行完毕，容器的状态才会变成 RUNNING。

Kubernetes 在容器结束前立即发送 preStop 事件。除非 Pod 宽限期限超时，Kubernetes 的容器管理逻辑 会一直阻塞等待 preStop 处理函数执行完毕。更多的相关细节，可以参阅 [Pods 的结束](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination)。

> **说明：** Kubernetes 只有在 Pod *结束（Terminated）* 的时候才会发送 preStop 事件， 这意味着在 Pod *完成（Completed）* 时 preStop 的事件处理逻辑不会被触发。这个限制在 [issue #55087](https://github.com/kubernetes/kubernetes/issues/55807) 中被追踪。

### 配置 Pod 使用 ConfigMap

很多应用在其初始化或运行期间要依赖一些配置信息。大多数时候， 存在要调整配置参数所设置的数值的需求。 ConfigMap 是 Kubernetes 用来向应用 Pod 中注入配置数据的方法。

ConfigMap 允许你将配置文件与镜像文件分离，以使容器化的应用程序具有可移植性。 本页提供了一系列使用示例，这些示例演示了如何创建 ConfigMap 以及配置 Pod 使用存储在 ConfigMap 中的数据。

#### 创建 ConfigMap

可以使用 `kubectl create configmap` 或者在 `kustomization.yaml` 中的 ConfigMap 生成器来创建 ConfigMap。注意，`kubectl` 从 1.14 版本开始支持 `kustomization.yaml`。

##### 使用 kubectl create configmap 创建 ConfigMap

你可以使用 `kubectl create configmap` 命令基于目录、 文件或者字面值来创建 ConfigMap：

```shell
$ kubectl create configmap <映射名称> <数据源>
```

其中，`<映射名称>` 是为 ConfigMap 指定的名称，`<数据源>` 是要从中提取数据的目录、 文件或者字面值。ConfigMap 对象的名称必须是合法的 [DNS 子域名](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/names#dns-subdomain-names).

在基于文件来创建 ConfigMap 时，`<数据源>` 中的键名默认取自文件的基本名， 而对应的值则默认为文件的内容。

可以使用 [`kubectl describe`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands/#describe) 或者 [`kubectl get`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands/#get) 获取有关 ConfigMap 的信息。

###### 基于目录创建 ConfigMap

可以使用 `kubectl create configmap` 基于同一目录中的多个文件创建 ConfigMap。 当你基于目录来创建 ConfigMap 时，kubectl 识别目录下基本名可以作为合法键名的文件， 并将这些文件打包到新的 ConfigMap 中。普通文件之外的所有目录项都会被忽略 （例如：子目录、符号链接、设备、管道等等）。

创建本地目录、下载示例文件：

```shell
# 创建本地目录
$ mkdir -p configure-pod-container/configmap/

# 将示例文件下载到 configure-pod-container/configmap/ 目录
$ wget https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/configmap/game.properties -O configure-pod-container/configmap/game.properties
$ wget https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/configmap/ui.properties -O configure-pod-container/configmap/ui.properties
```

基于目录创建 ConfigMap

```shell
$ kubectl create configmap game-config --from-file=configure-pod-container/configmap/
```

> 以上命令将 `configure-pod-container/configmap` 目录下的所有文件，也就是 `game.properties` 和 `ui.properties` 打包到 `game-config` ConfigMap 中。你

查看 ConfigMap 的详细信息：

```shell
$ kubectl describe configmaps game-config
Name:         game-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
game.properties:
----
enemies=aliens
lives=3
enemies.cheat=true
enemies.cheat.level=noGoodRotten
secret.code.passphrase=UUDDLRLRBABAS
secret.code.allowed=true
secret.code.lives=30

ui.properties:
----
color.good=purple
color.bad=yellow
allow.textmode=true
how.nice.to.look=fairlyNice


BinaryData
====

Events:  <none>
```

> `configure-pod-container/configmap/` 目录中的 `game.properties` 和 `ui.properties` 文件出现在 ConfigMap 的 `data` 部分。

查看 ConfigMap 的 yaml 输出：

```shell
$ kubectl get configmaps game-config -o yaml
apiVersion: v1
data:
  game.properties: "enemies=aliens\r\nlives=3\r\nenemies.cheat=true\r\nenemies.cheat.level=noGoodRotten\r\nsecret.code.passphrase=UUDDLRLRBABAS\r\nsecret.code.allowed=true\r\nsecret.code.lives=30\r\n"
  ui.properties: |
    color.good=purple
    color.bad=yellow
    allow.textmode=true
    how.nice.to.look=fairlyNice
kind: ConfigMap
metadata:
  creationTimestamp: "2022-08-09T02:26:11Z"
  name: game-config
  namespace: default
  resourceVersion: "3898175"
  uid: 0de229a0-ba25-49eb-b65e-7206d5737afb
```

###### 基于文件创建 ConfigMap

可以使用 `kubectl create configmap` 基于单个文件或多个文件创建 ConfigMap。

**基于普通文件创建 ConfigMap**

**1）**基于单个普通文件创建 ConfigMap

```shell
$ kubectl create configmap game-config-2 --from-file=configure-pod-container/configmap/game.properties
```

将产生以下 ConfigMap:

```shell
$ kubectl describe configmaps game-config-2
Name:         game-config-2
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
game.properties:
----
enemies=aliens
lives=3
enemies.cheat=true
enemies.cheat.level=noGoodRotten
secret.code.passphrase=UUDDLRLRBABAS
secret.code.allowed=true
secret.code.lives=30


BinaryData
====

Events:  <none>
```

**2）**基于多个普通文件创建 ConfigMap

可以多次使用 `--from-file` 参数，从多个数据源创建 ConfigMap。

```shell
$ kubectl create configmap game-config-2 --from-file=configure-pod-container/configmap/game.properties --from-file=configure-pod-container/configmap/ui.properties
```

查看 `game-config-2` ConfigMap 的详细信息：

```shell
$ kubectl describe configmaps game-config-2
Name:         game-config-2
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
game.properties:
----
enemies=aliens
lives=3
enemies.cheat=true
enemies.cheat.level=noGoodRotten
secret.code.passphrase=UUDDLRLRBABAS
secret.code.allowed=true
secret.code.lives=30

ui.properties:
----
color.good=purple
color.bad=yellow
allow.textmode=true
how.nice.to.look=fairlyNice


BinaryData
====

Events:  <none>
```

当 `kubectl` 基于非 ASCII 或 UTF-8 的输入创建 ConfigMap 时， 该工具将这些输入放入 ConfigMap 的 `BinaryData` 字段，而不是 `Data` 中。 同一个 ConfigMap 中可同时包含文本数据和二进制数据源。 

**基于 env 文件创建 ConfigMap**

使用 `--from-env-file` 选项从环境文件创建 ConfigMap，例如：

Env 文件包含环境变量列表。其中适用以下语法规则:

- Env 文件中的每一行必须为 VAR=VAL 格式。
- 以＃开头的行（即注释）将被忽略。
- 空行将被忽略。
- 引号不会被特殊处理（即它们将成为 ConfigMap 值的一部分）。

将示例文件下载到 `configure-pod-container/configmap/` 目录：

```shell
$ wget https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/configmap/game-env-file.properties
$ wget https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/configmap/ui-env-file.properties
```

**1）**基于单个 env 文件创建 ConfigMap

创建 ConfigMap

```shell
$ kubectl create configmap game-config-env-file \
       --from-env-file=configure-pod-container/configmap/game-env-file.properties
```

查看 ConfigMap 信息：

```shell
$ kubectl get configmap game-config-env-file -o yaml
apiVersion: v1
data:
  allowed: '"true"'
  enemies: aliens
  lives: "3"
kind: ConfigMap
metadata:
  creationTimestamp: "2022-08-09T03:02:58Z"
  name: game-config-env-file
  namespace: default
  resourceVersion: "3902999"
  uid: d900a8a0-27a9-42c2-aac6-af9ce628b5bb
```

**2）**基于多个 env 文件创建 ConfigMap

从 Kubernetes 1.23 版本开始，`kubectl` 支持多次指定 `--from-env-file` 参数来从多个数据源创建 ConfigMap：

```
$ kubectl create configmap config-multi-env-files \
        --from-env-file=configure-pod-container/configmap/game-env-file.properties \
        --from-env-file=configure-pod-container/configmap/ui-env-file.properties
```

查看 ConfigMap 信息：

```shell
$ kubectl get configmap config-multi-env-files -o yaml
apiVersion: v1
data:
  allowed: '"true"'
  color: purple
  enemies: aliens
  how: fairlyNice
  lives: "3"
  textmode: "true"
kind: ConfigMap
metadata:
  creationTimestamp: "2022-08-09T03:06:26Z"
  name: config-multi-env-files
  namespace: default
  resourceVersion: "3903446"
  uid: 1f30ff49-cbdf-41cd-83ac-3ce2d0db7224
```

###### 自定义从文件创建 ConfigMap 时要使用的键

在使用 `--from-file` 参数时，可以自定义在 ConfigMap 的 `data` 部分出现的键名， 而不是按默认行为使用文件名：

```shell
$ kubectl create configmap game-config-3 --from-file=<我的键名>=<文件路径>
```

> `<我的键名>` 是要在 ConfigMap 中使用的键名，`<文件路径>` 是想要键所表示的数据源文件的位置。

例如：

```
$ kubectl create configmap game-config-3 --from-file=game-special-key=configure-pod-container/configmap/game.properties
```

查看 ConfigMap 信息：

```shell
$ kubectl get configmap game-config-3 -o yaml
apiVersion: v1
data:
  game-special-key: "enemies=aliens\r\nlives=3\r\nenemies.cheat=true\r\nenemies.cheat.level=noGoodRotten\r\nsecret.code.passphrase=UUDDLRLRBABAS\r\nsecret.code.allowed=true\r\nsecret.code.lives=30\r\n"
kind: ConfigMap
metadata:
  creationTimestamp: "2022-08-09T03:18:11Z"
  name: game-config-3
  namespace: default
  resourceVersion: "3904985"
  uid: 82d226aa-edd6-4b3e-8f38-33d51855bdd6
```

> 从输出可以看到，此 ConfigMap 的 `data` 部分的键名为我们自定义的 `game-special-key`，而不是之前默认的文件名。

###### 根据字面值创建 ConfigMap

可以将 `kubectl create configmap` 与 `--from-literal` 参数一起使用， 通过命令行定义文字值：

```shell
$ kubectl create configmap special-config --from-literal=special.how=very --from-literal=special.type=charm
```

可以传入多个键值对。命令行中提供的每对键值在 ConfigMap 的 `data` 部分中均表示为单独的条目。

```shell
$ kubectl get configmap special-config -o yaml
apiVersion: v1
data:
  special.how: very
  special.type: charm
kind: ConfigMap
metadata:
  creationTimestamp: "2022-08-09T03:23:59Z"
  name: special-config
  namespace: default
  resourceVersion: "3905741"
  uid: 0e9cd295-ed02-4033-b709-0e1bf839a364
```

###### 使用 yaml 文件创建 ConfigMap

编写 yaml 文件：

```shell
$ cat <<EOF > special-aluo.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: special-aluo
  namespace: default
data:
  special.how: very
  special.name: aluo
  special.age: '18'
EOF
```

创建 ConfigMap：

```shell
$ kubectl apply -f special-aluo.yaml 
configmap/special-aluo created
```

查看 ConfigMap：

```shell
$ kubectl get configmap/special-aluo -o yaml
apiVersion: v1
data:
  special.age: "18"
  special.how: very
  special.name: aluo
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"special.age":"18","special.how":"very","special.name":"aluo"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"special-aluo","namespace":"default"}}
  creationTimestamp: "2022-08-09T05:48:00Z"
  name: special-aluo
  namespace: default
  resourceVersion: "3924594"
  uid: b5197373-e69a-4852-94fc-09eac6ba5570
```

##### 基于生成器创建 ConfigMap

自 1.14 开始，`kubectl` 开始支持 `kustomization.yaml`。 你还可以基于生成器（Generators）创建 ConfigMap，然后将其应用于 API 服务器上创建对象。 生成器应在目录内的 `kustomization.yaml` 中指定。

###### 基于文件生成 ConfigMap

例如，要基于 `configure-pod-container/configmap/game.properties` 文件生成一个 ConfigMap：

```shell
# 创建包含 ConfigMapGenerator 的 kustomization.yaml 文件
$ cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: game-config-4
  files:
  - configure-pod-container/configmap/game.properties
EOF
```

应用（Apply）kustomization 目录创建 ConfigMap 对象：

```shell
$ kubectl apply -k .
configmap/game-config-4-89fk664tmf created
```

查看 ConfigMap：

```shell
$ kubectl describe configmaps/game-config-4-89fk664tmf
Name:         game-config-4-89fk664tmf
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
game.properties:
----
enemies=aliens
lives=3
enemies.cheat=true
enemies.cheat.level=noGoodRotten
secret.code.passphrase=UUDDLRLRBABAS
secret.code.allowed=true
secret.code.lives=30


BinaryData
====

Events:  <none>
```

请注意，生成的 ConfigMap 名称具有通过对内容进行散列而附加的后缀， 这样可以确保每次修改内容时都会生成新的 ConfigMap。

[基于 `env` 文件生成 ConfigMap](https://aluopy.cn/kubernetes/kustomize/#基于-env-文件envs)

###### 自定义从文件生成 ConfigMap 时要使用的键

在 ConfigMap 生成器中，可以自定义一个非文件名的键名。 例如，从 `configure-pod-container/configmap/game.properties` 文件生成 ConfigMap， 但使用 `game-special-key` 作为键名：

```shell
# 创建包含 ConfigMapGenerator 的 kustomization.yaml 文件
$ cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: game-config-5
  files:
  - game-special-key=configure-pod-container/configmap/game.properties
EOF
```

应用 Kustomization 目录创建 ConfigMap 对象：

```shell
$ kubectl apply -k .
configmap/game-config-5-4bgd4c9hkd created
```

查看 ConfigMap：

```shell
$ kubectl describe configmaps/game-config-5-4bgd4c9hkd
Name:         game-config-5-4bgd4c9hkd
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
game-special-key:
----
enemies=aliens
lives=3
enemies.cheat=true
enemies.cheat.level=noGoodRotten
secret.code.passphrase=UUDDLRLRBABAS
secret.code.allowed=true
secret.code.lives=30


BinaryData
====

Events:  <none>
```

###### 基于字面值生成 ConfigMap

要基于字符串 `special.type=charm` 和 `special.how=very` 生成 ConfigMap， 可以在 `kustomization.yaml` 中配置 ConfigMap 生成器：

```shell
# 创建带有 ConfigMapGenerator 的 kustomization.yaml 文件
$ cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: special-config-2
  literals:
  - special.how=very
  - special.type=charm
EOF
```

应用 Kustomization 目录创建 ConfigMap 对象：

```shell
$ kubectl apply -k .
configmap/special-config-2-2b86tk8fhm created
```

查看 ConfigMap：

```shell
$ kubectl get configmap/special-config-2-2b86tk8fhm -o yaml
apiVersion: v1
data:
  special.how: very
  special.type: charm
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"special.how":"very","special.type":"charm"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"special-config-2-2b86tk8fhm","namespace":"default"}}
  creationTimestamp: "2022-08-09T03:39:01Z"
  name: special-config-2-2b86tk8fhm
  namespace: default
  resourceVersion: "3907710"
  uid: 54dccab0-6057-4934-81af-f1ac7a3b0c05
```

#### 使用 ConfigMap 数据定义容器环境变量

##### 使用单个 ConfigMap 中的数据定义容器环境变量

1. 在 ConfigMap 中将环境变量定义为键值对：

   ```shell
   $ kubectl create configmap special-config --from-literal=special.how=very
   ```

2. 将 ConfigMap 中定义的 `special.how` 赋值给 Pod 规约中的 `SPECIAL_LEVEL_KEY` 环境变量：

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: dapi-test-pod
   spec:
     containers:
       - name: test-container
         # image: k8s.gcr.io/busybox
         image: registry.cn-shenzhen.aliyuncs.com/aluopy/busybox
         command: [ "/bin/sh", "-c", "env" ]
         env:
           # 定义环境变量
           - name: SPECIAL_LEVEL_KEY
             valueFrom:
               configMapKeyRef:
                 # ConfigMap 包含要赋给 SPECIAL_LEVEL_KEY 的值
                 name: special-config
                 # 指定与取值相关的键名
                 key: special.how
     restartPolicy: Never
   ```

   创建 Pod：

   ```shell
   $ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-single-configmap-env-variable.yaml
   ```

3. 查看容器日志打印的环境变量是否包含 `SPECIAL_LEVEL_KEY=very`

   ```shell
   $ kubectl logs pod/dapi-test-pod | grep SPECIAL_LEVEL_KEY
   SPECIAL_LEVEL_KEY=very
   ```

##### 使用来自多个 ConfigMap 的数据定义容器环境变量

1. 根据 yaml 描述文件创建 ConfigMap，yaml 文件如下：

   ```shell
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: special-config
     namespace: default
   data:
     special.how: very
   ---
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: env-config
     namespace: default
   data:
     log_level: INFO
   ```

   创建 ConfigMap：

   ```shell
   $ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/configmap/configmaps.yaml
   ```

2. 在 Pod 规约中定义环境变量

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: dapi-test-pod
   spec:
     containers:
       - name: test-container
         # image: k8s.gcr.io/busybox
         image: registry.cn-shenzhen.aliyuncs.com/aluopy/busybox
         command: [ "/bin/sh", "-c", "env" ]
         env:
           - name: SPECIAL_LEVEL_KEY
             valueFrom:
               configMapKeyRef:
                 name: special-config
                 key: special.how
           - name: LOG_LEVEL
             valueFrom:
               configMapKeyRef:
                 name: env-config
                 key: log_level
     restartPolicy: Never
   ```

   创建 Pod：

   ```shell
   $ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-multiple-configmap-env-variable.yaml
   ```

3. 查看容器日志打印的环境变量是否包含 `SPECIAL_LEVEL_KEY=very` 和 `LOG_LEVEL=INFO`

   ```shell
   $ kubectl logs dapi-test-pod | grep SPECIAL_LEVEL_KEY
   SPECIAL_LEVEL_KEY=very
   
   $ kubectl logs dapi-test-pod | grep LOG_LEVEL
   LOG_LEVEL=INFO
   ```

#### 将 ConfigMap 中的所有键值对配置为容器环境变量

> **说明：**Kubernetes v1.6 和更高版本支持此功能。

- 创建一个包含多个键值对的 ConfigMap

  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: special-config
    namespace: default
  data:
    SPECIAL_LEVEL: very
    SPECIAL_TYPE: charm
  ```

  创建 ConfigMap：

  ```
  $ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/configmap/configmap-multikeys.yaml
  ```

- 使用 `envFrom` 将所有 ConfigMap 的数据定义为容器环境变量，ConfigMap 中的键成为 Pod 中的环境变量名称。

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: dapi-test-pod
  spec:
    containers:
      - name: test-container
        # image: k8s.gcr.io/busybox
        image: registry.cn-shenzhen.aliyuncs.com/aluopy/busybox
        command: [ "/bin/sh", "-c", "env" ]
        envFrom:
        - configMapRef:
            name: special-config
    restartPolicy: Never
  ```

  创建 Pod：

  ```shell
  $ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-configmap-envFrom.yaml
  ```

- 查看容器日志打印的环境变量是否包含 `SPECIAL_LEVEL=very` 和 `SPECIAL_TYPE=charm`

  ```shell
  $ kubectl logs dapi-test-pod | grep SPECIAL_LEVEL
  SPECIAL_LEVEL=very
  
  $ kubectl logs dapi-test-pod | grep SPECIAL_TYPE
  SPECIAL_TYPE=charm
  ```

#### 在 Pod 命令中使用 ConfigMap 定义的环境变量

可以使用 `$(VAR_NAME)` Kubernetes 替换语法在容器的 `command` 和 `args` 属性中使用 ConfigMap 定义的环境变量。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      # image: k8s.gcr.io/busybox
      image: registry.cn-shenzhen.aliyuncs.com/aluopy/busybox
      command: [ "/bin/echo", "$(SPECIAL_LEVEL_KEY) $(SPECIAL_TYPE_KEY)" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_LEVEL
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config
              key: SPECIAL_TYPE
  restartPolicy: Never
```

创建 Pod：

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-configmap-env-var-valueFrom.yaml
```

查看 Pod 日志：

```shell
$ kubectl logs dapi-test-pod
very charm
```

#### 将 ConfigMap 数据添加到一个卷中

##### 使用存储在 ConfigMap 中的数据填充卷

在 Pod 规约的 `volumes` 部分下添加 ConfigMap 名称。 这会将 ConfigMap 数据添加到 `volumeMounts.mountPath` 所指定的目录 （在本例中为 `/etc/config`）。 `command` 部分列出了名称与 ConfigMap 中的键匹配的目录文件。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      # image: k8s.gcr.io/busybox
      image: registry.cn-shenzhen.aliyuncs.com/aluopy/busybox
      command: [ "/bin/sh", "-c", "ls /etc/config/" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        # 提供包含要添加到容器中的文件的 ConfigMap 的名称
        name: special-config
  restartPolicy: Never
```

创建 Pod:

```shell
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-configmap-volume.yaml
```

Pod 运行时，命令 `ls /etc/config/` 产生下面的输出：

```
$ kubectl logs dapi-test-pod 
SPECIAL_LEVEL
SPECIAL_TYPE
```

> **注意：**
>
> 如果在 `/etc/config/` 目录中有一些文件，这些文件将被删除。

> **说明：**
>
> 文本数据会展现为 UTF-8 字符编码的文件。如果使用其他字符编码， 可以使用 `binaryData`。

##### 将 ConfigMap 数据添加到卷中的特定路径

使用 `path` 字段为特定的 ConfigMap 项目指定预期的文件路径。 在这里，ConfigMap 中键 `SPECIAL_LEVEL` 的内容将挂载在 `config-volume` 卷中 `/etc/config/keys` 文件中。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      # image: k8s.gcr.io/busybox
      image: registry.cn-shenzhen.aliyuncs.com/aluopy/busybox
      command: [ "/bin/sh","-c","cat /etc/config/keys" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: special-config
        items:
        - key: SPECIAL_LEVEL
          path: keys
  restartPolicy: Never
```

创建Pod：

```shell
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/k8s/pod/pod-configmap-volume-specific-key.yaml
```

当 Pod 运行时，命令 `cat /etc/config/keys` 产生以下输出：

```shell
$ kubectl logs dapi-test-pod 
very
```

> **注意：**
>
> 如前，`/etc/config/` 目录中所有先前的文件都将被删除。

##### 映射键到指定路径并设置文件访问权限

可以将指定键名投射到特定目录，也可以逐个文件地设定访问权限。 [Secret 用户指南](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod) 中为这一语法提供了解释。

#### 了解 ConfigMap 和 Pod

ConfigMap API 资源将配置数据存储为键值对。 数据可以在 Pod 中使用，也可以用来提供系统组件（如控制器）的配置。 ConfigMap 与 Secret 类似， 但是提供的是一种处理不含敏感信息的字符串的方法。 用户和系统组件都可以在 ConfigMap 中存储配置数据。

> **说明：**
>
> ConfigMap 应该引用属性文件，而不是替换它们。可以将 ConfigMap 理解为类似于 Linux `/etc` 目录及其内容的东西。例如，如果你基于 ConfigMap 创建 Kubernetes 卷，则 ConfigMap 中的每个数据项都由该数据卷中的某个独立的文件表示。

ConfigMap 的 `data` 字段包含配置数据。如下例所示，它可以简单 （如用 `--from-literal` 的单个属性定义）或复杂 （如用 `--from-file` 的配置文件或 JSON blob定义）。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: 2016-02-18T19:14:38Z
  name: example-config
  namespace: default
data:
  # 使用 --from-literal 定义的简单属性
  example.property.1: hello
  example.property.2: world
  # 使用 --from-file 定义复杂属性的例子
  example.property.file: |-
    property.1=value-1
    property.2=value-2
    property.3=value-3    
```

##### 限制

- 在 Pod 规约中引用某个 `ConfigMap` 之前，必须先创建这个对象， 或者在 Pod 规约中将 ConfigMap 标记为 `optional`（请参阅[可选的 ConfigMaps](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-pod-configmap/#optional-configmaps)）。 如果所引用的 ConfigMap 不存在，并且没有将应用标记为 `optional` 则 Pod 将无法启动。 同样，引用 ConfigMap 中不存在的主键也会令 Pod 无法启动，除非你将 Configmap 标记为 `optional`。

- 如果你使用 `envFrom` 来基于 ConfigMap 定义环境变量，那么无效的键将被忽略。 Pod 可以被启动，但无效名称将被记录在事件日志中（`InvalidVariableNames`）。 日志消息列出了每个被跳过的键。例如:

  ```shell
  kubectl get events
  ```

  输出与此类似:

  ```
  LASTSEEN FIRSTSEEN COUNT NAME          KIND  SUBOBJECT  TYPE      REASON                            SOURCE                MESSAGE
  0s       0s        1     dapi-test-pod Pod              Warning   InvalidEnvironmentVariableNames   {kubelet, 127.0.0.1}  Keys [1badkey, 2alsobad] from the EnvFrom configMap default/myconfig were skipped since they are considered invalid environment variable names.
  ```

- ConfigMap 位于确定的[名字空间](https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/namespaces/)中。 每个 ConfigMap 只能被同一名字空间中的 Pod 引用.

- 你不能将 ConfigMap 用于[静态 Pod](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/static-pod/)， 因为 Kubernetes 不支持这种用法。

##### 可选的 ConfigMap

可以在 Pod 规约中将对 ConfigMap 的引用标记为 **可选（optional）**。 如果 ConfigMap 不存在，那么它在 Pod 中为其提供数据的配置（例如环境变量、挂载的卷）将为空。 如果 ConfigMap 存在，但引用的键不存在，那么数据也是空的。

例如，以下 Pod 规约将 ConfigMap 中的环境变量标记为可选：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: gcr.io/google_containers/busybox
      command: [ "/bin/sh", "-c", "env" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: a-config
              key: akey
              optional: true # 将环境变量标记为可选
  restartPolicy: Never
```

当你运行这个 Pod 并且名称为 `a-config` 的 ConfigMap 不存在时，输出空值。 当你运行这个 Pod 并且名称为 `a-config` 的 ConfigMap 存在， 但是在 ConfigMap 中没有名称为 `akey` 的键时，控制台输出也会为空。 如果你确实在名为 `a-config` 的 ConfigMap 中为 `akey` 设置了键值， 那么这个 Pod 会打印该值，然后终止。

也可以在 Pod 规约中将 ConfigMap 提供的卷和文件标记为可选。 此时 Kubernetes 将总是为卷创建挂载路径，即使引用的 ConfigMap 或键不存在。 例如，以下 Pod 规约将所引用的 ConfigMap 卷标记为可选：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: gcr.io/google_containers/busybox
      command: [ "/bin/sh", "-c", "ls /etc/config" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: no-config
        optional: true # 将引用的 ConfigMap 的卷标记为可选
  restartPolicy: Never
```

##### 挂载的 ConfigMap 将被自动更新

当某个已被挂载的 ConfigMap 被更新，所投射的内容最终也会被更新。 对于 Pod 已经启动之后所引用的、可选的 ConfigMap 才出现的情形， 这一动态更新现象也是适用的。

kubelet 在每次周期性同步时都会检查已挂载的 ConfigMap 是否是最新的。 但是，它使用其本地的基于 TTL 的缓存来获取 ConfigMap 的当前值。 因此，从更新 ConfigMap 到将新键映射到 Pod 的总延迟可能等于 kubelet 同步周期 （默认 1 分钟） + ConfigMap 在 kubelet 中缓存的 TTL（默认 1 分钟）。

> **说明：**
>
> 使用 ConfigMap 作为 [subPath](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#using-subpath) 的数据卷将不会收到 ConfigMap 更新。

### 在 Pod 中的容器之间共享进程命名空间

此页面展示如何为 Pod 配置进程命名空间共享。 当启用进程命名空间共享时，容器中的进程对同一 Pod 中的所有其他容器都是可见的。

可以使用此功能来配置协作容器，比如日志处理 sidecar 容器， 或者对那些不包含诸如 shell 等调试实用工具的镜像进行故障排查。

#### 配置 Pod

使用 Pod `.spec` 中的 `shareProcessNamespace` 字段可以启用进程命名空间共享。例如：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  shareProcessNamespace: true
  containers:
  - name: nginx
    image: nginx
  - name: shell
    image: busybox:1.28
    securityContext:
      capabilities:
        add:
        - SYS_PTRACE
    stdin: true
    tty: true
```

1. 在集群中创建 `nginx` Pod：

   ```shell
   $ kubectl apply -f https://k8s.io/examples/pods/share-process-namespace.yaml
   ```

2. 获取容器 `shell`，执行 `ps`：

   ```shell
   $ kubectl attach -it nginx -c shell
   If you don't see a command prompt, try pressing enter.
   / # ps ax
   PID   USER     TIME  COMMAND
       1 65535     0:00 /pause
       7 root      0:00 nginx: master process nginx -g daemon off;
      37 101       0:00 nginx: worker process
      38 101       0:00 nginx: worker process
      39 101       0:00 nginx: worker process
      40 root      0:00 sh
      46 root      0:00 ps ax
   ```

可以在其他容器中对进程发出信号。例如，发送 `SIGHUP` 到 `nginx` 以重启工作进程。 此操作需要 `SYS_PTRACE` 权能。

```shell
# 在 “shell” 容器中运行以下命令
kill -HUP 7   # 如有必要，更改 “7” 以匹配 nginx 领导进程的 PID
ps ax
```

输出类似于：

```
PID   USER     TIME  COMMAND
    1 65535     0:00 /pause
    7 root      0:00 nginx: master process nginx -g daemon off;
   40 root      0:00 sh
   47 101       0:00 nginx: worker process
   48 101       0:00 nginx: worker process
   49 101       0:00 nginx: worker process
   50 root      0:00 ps ax
```

甚至可以使用 `/proc/$pid/root` 链接访问另一个容器的文件系统。

```shell
# 在 “shell” 容器中运行以下命令
# 如有必要，更改 “7” 为 Nginx 进程的 PID
head /proc/7/root/etc/nginx/nginx.conf
```

输出类似于：

```

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;

```

#### 理解进程命名空间共享

Pod 共享许多资源，因此它们共享进程命名空间是很有意义的。 不过，有些容器可能希望与其他容器隔离，因此了解这些差异很重要：

1. **容器进程不再具有 PID 1。** 在没有 PID 1 的情况下，一些容器拒绝启动 （例如，使用 `systemd` 的容器)，或者拒绝执行 `kill -HUP 1` 之类的命令来通知容器进程。 在具有共享进程命名空间的 Pod 中，`kill -HUP 1` 将通知 Pod 沙箱（在上面的例子中是 `/pause`）。

2. **进程对 Pod 中的其他容器可见。** 这包括 `/proc` 中可见的所有信息， 例如作为参数或环境变量传递的密码。这些仅受常规 Unix 权限的保护。

3. **容器文件系统通过 `/proc/$pid/root` 链接对 Pod 中的其他容器可见。** 这使调试更加容易， 但也意味着文件系统安全性只受文件系统权限的保护。

### 创建静态 Pod

[创建静态 Pod | Kubernetes](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/static-pod/)
