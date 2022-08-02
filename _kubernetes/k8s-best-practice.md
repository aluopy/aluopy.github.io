---
K8S-Best-Practice
---

## Node

Kubernetes 通过将容器放入在节点（Node）上运行的 Pod 中来执行你的工作负载。 节点可以是一个虚拟机或者物理机器，取决于所在的集群配置。 每个节点包含运行 Pods 所需的服务； 这些节点由控制面负责管理。

通常集群中会有若干个节点；而在一个学习用或者资源受限的环境中，你的集群中也可能 只有一个节点。

节点上的组件包括 kubelet、 容器运行时以及 kube-proxy。

```shell
# 查看集群中的 Node 信息
$ kubectl get nodes
$ kubectl get nodes -o wide

# 查看 w2 节点状态和其他细节信息
$ kubectl describe node w2

# 标记 w2 节点为不可调度
$ kubectl cordon w2

# 对 w2 节点进行清空操作，为节点维护做准备
$ kubectl drain w2

# 标记 w2 节点为可以调度
$ kubectl uncordon w2

# 显示给定节点的度量值
$ kubectl top node my-node

# 显示主控节点和服务的地址
$ kubectl cluster-info

# 将当前集群状态转储到标准输出
$ kubectl cluster-info dump

# 将当前集群状态输出到 /path/to/cluster-state
$ kubectl cluster-info dump --output-directory=/path/to/cluster-state

# 查看当前节点上存在的现有污点。
$ kubectl get nodes -o=custom-columns=NodeName:.metadata.name,TaintKey:.spec.taints[*].key,TaintValue:.spec.taints[*].value,TaintEffect:.spec.taints[*].effect

# 给节点 node1 增加一个污点，它的键名是 dedicated，键值是 special-user，效果是 NoSchedule
# 如果已存在具有指定键和效果的污点，则替换其值为指定值。
$ kubectl taint nodes node1 dedicated=special-user:NoSchedule
# 移除节点上的某个污点
$ kubectl taint nodes node1 dedicated=special-user:NoSchedule-

# 给节点打标签（角色标签）
$ kubectl label node m1 node-role.kubernetes.io/master=master
$ kubectl label node w1 node-role.kubernetes.io/worker=worker
```

## Pod

```shell
# 获取 pod 日志（标准输出）
$ kubectl logs my-pod
# 获取含 name=myLabel 标签的 Pods 的日志（标准输出）
$ kubectl logs -l name=myLabel
# 获取上个容器实例的 pod 日志（标准输出）
$ kubectl logs my-pod --previous
# 获取 Pod 容器的日志（标准输出, 多容器场景）
$ kubectl logs my-pod -c my-container
# 获取含 name=myLabel 标签的 Pod 容器日志（标准输出, 多容器场景）
$ kubectl logs -l name=myLabel -c my-container
# 获取 Pod 中某容器的上个实例的日志（标准输出, 多容器场景）
$ kubectl logs my-pod -c my-container --previous
# 流式输出 Pod 的日志（标准输出）
$ kubectl logs -f my-pod
# 流式输出 Pod 容器的日志（标准输出, 多容器场景）
$ kubectl logs -f my-pod -c my-container
# 流式输出含 name=myLabel 标签的 Pod 的所有日志（标准输出）
$ kubectl logs -f -l name=myLabel --all-containers
# 以交互式 Shell 运行 Pod
$ kubectl run -i --tty busybox --image=busybox:1.28 -- sh
# 在 “mynamespace” 命名空间中运行单个 nginx Pod
$ kubectl run nginx --image=nginx -n mynamespace
# 运行 nginx Pod 并将其规约写入到名为 pod.yaml 的文件
$ kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
  
# 挂接到一个运行的容器中
$ kubectl attach my-pod -i
# 在本地计算机上侦听端口 5000 并转发到 my-pod 上的端口 6000
$ kubectl port-forward my-pod 5000:6000
# 在已有的 Pod 中运行命令（单容器场景）
$ kubectl exec my-pod -- ls /
# 使用交互 shell 访问正在运行的 Pod (一个容器场景)
$ kubectl exec --stdin --tty my-pod -- /bin/sh
# 在已有的 Pod 中运行命令（多容器场景）
$ kubectl exec my-pod -c my-container -- ls /
# 显示给定 Pod 和其中容器的监控数据
$ kubectl top pod POD_NAME --containers
# 显示给定 Pod 的指标并且按照 'cpu' 或者 'memory' 排序
$ kubectl top pod POD_NAME --sort-by=cpu
# 列出所有容器的资源利用率
$ kubectl top pod --all-namespaces --containers=true
```

