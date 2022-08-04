## 配置 Pods 和容器

### 为容器和 Pod 分配内存资源

此节展示如何将内存**请求**（request）和内存**限制**（limit）分配给一个容器。 我们保障容器拥有它请求数量的内存，但不允许使用超过限制数量的内存。

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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/memory-request-limit.yaml --namespace=mem-example
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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/memory-request-limit-2.yaml --namespace=mem-example
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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/memory-request-limit-3.yaml --namespace=mem-example
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

本节展示如何为容器设置 CPU **request（请求）** 和 CPU **limit（限制）**。 容器使用的 CPU 不能超过所配置的限制。 如果系统有空闲的 CPU 时间，则可以保证给容器分配其所请求数量的 CPU 资源。

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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/cpu-request-limit.yaml --namespace=cpu-example
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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/cpu-request-limit-2.yaml --namespace=cpu-example
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

本节介绍怎样配置 Pod 让其获得特定的服务质量（QoS）类。Kubernetes 使用 QoS 类来决定 Pod 的调度和驱逐策略。

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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/qos-pod.yaml --namespace=qos-example
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
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/qos-pod-2.yaml --namespace=qos-example
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
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/qos-pod-3.yaml --namespace=qos-example
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
$ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/qos-pod-4.yaml --namespace=qos-example
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

本节展示了如何为节点指定扩展资源（Extended Resource）。 扩展资源允许集群管理员发布节点级别的资源，这些资源在不进行发布的情况下无法被 Kubernetes 感知。

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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/extended-resource-pod.yaml
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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/extended-resource-pod-2.yaml
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

此节展示了如何配置 Pod 以使用卷进行存储。

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
   $ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/redis.yaml
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

本节将介绍如何配置 Pod 使用 [PersistentVolumeClaim](https://kubernetes.io/zh-cn/docs/concepts/storage/persistent-volumes/) 作为存储。 以下是该过程的总结：

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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/pv-volume.yaml
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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/pv-claim.yaml
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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/pv-pod.yaml
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

本节介绍怎样通过`projected` 卷将现有的多个卷资源挂载到相同的目录。 当前，`secret`、`configMap`、`downwardAPI` 和 `serviceAccountToken` 卷可以被投射。

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
   $ kubectl create -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/projected.yaml
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
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/aluopy.github.io/master/resource/pod/security-context.yaml
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

> 输出显示进程以用户 1000 运行，即 `runAsUser` 所设置的值；输出显示 `/data/demo` 目录的组 ID 为 2000，即 `fsGroup` 的设置值；输出显示新创建文件 `testfile` 的组 ID 为 2000，也就是 `fsGroup` 所设置的值；运行 `id` 命令后，从输出中会看到 `gid` 值为 3000，也就是 `runAsGroup` 字段的值。 如果 `runAsGroup` 被忽略，则 `gid` 会取值 0（root），而进程就能够与 root 用户组所拥有以及要求 root 用户组访问权限的文件交互。

#### 为 Pod 配置卷访问权限和属主变更策略

[为 Pod 或容器配置安全上下文 | Kubernetes](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/security-context/#为-pod-配置卷访问权限和属主变更策略)
