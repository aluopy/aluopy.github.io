## 配置 Pods 和容器

### 为容器和 Pod 分配内存资源

此页面展示如何将内存**请求**（request）和内存**限制**（limit）分配给一个容器。 我们保障容器拥有它请求数量的内存，但不允许使用超过限制数量的内存。

#### 准备开始

- 拥有一个 Kubernetes 的集群
- 已安装 kubectl 命令行工具
- 集群至少有两个工作节点（建议）
- 集群已启用 metrics-server 服务

#### 创建命名空间

创建一个命名空间，以便将本练习中创建的资源与集群的其余部分隔离。

```shell
$ kubectl create namespace mem-example
namespace/mem-example created
```

#### 指定内存请求和限制

要为容器指定内存请求，请在容器资源清单中包含 `resources：requests` 字段。 同理，要指定内存限制，请包含 `resources：limits`。

创建一个拥有一个容器的 Pod。 容器将会请求 100 MiB 内存，并且内存会被限制在 200 MiB 以内。Pod 的配置文件：

```yaml
# resource/pod/memory-request-limit.yaml 
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

开始创建 Pod：

```shell
$ kubectl apply -f https://k8s.io/examples/pods/resource/memory-request-limit.yaml --namespace=mem-example
```

