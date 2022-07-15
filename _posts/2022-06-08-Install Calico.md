---
title: "Install Calico"
permalink: /kubernetes/install-calico/
excerpt: "Get Calico up and running in your Kubernetes cluster."
toc: true
#toc_label: "Install Calico"
#toc_icon: "cog"
categories: kubernetes
tags:
  - kubernetes
  - calico
  - network
---

## What is Calico?

Calico 是一个开源网络和网络安全解决方案，适用于容器、虚拟机和基于本地主机的工作负载。 Calico 支持广泛的平台，包括 Kubernetes、OpenShift、Mirantis Kubernetes Engine (MKE)、OpenStack 和裸机服务。

无论您选择使用 Calico 的 eBPF 数据平面还是 Linux 的标准网络管道，Calico 都能提供超快的性能和真正的云原生可扩展性。 Calico 为开发人员和集群运营商提供一致的体验和一组功能，无论是在公共云或本地、单个节点上还是跨数千个节点集群上运行。

## [Install Calico](https://projectcalico.docs.tigera.io/getting-started/)

### 使用 etcd 数据存储安装 Calico

[Install Calico networking and network policy for on-premises deployments (tigera.io)](https://projectcalico.docs.tigera.io/getting-started/kubernetes/self-managed-onprem/onpremises#install-calico-with-etcd-datastore)

1. 下载 etcd 的 Calico yaml 文件。

   ```shell
   $ curl https://projectcalico.docs.tigera.io/manifests/calico-etcd.yaml -o calico.yaml
   ```

2. 在名为 calico-etcd-secrets 的 Secret 中，填充 etcd-key、etcd-cert、etcd-ca 的值（对应证书 base64 加密数据）。

   通过 kubeadm 安装的 k8s 集群，对应的证书文件位置：

   - **etcd-key**：`/etc/kubernetes/pki/etcd/server.key`,
   - **etcd-cert**：`/etc/kubernetes/pki/etcd/server.crt`,
   - **etcd-ca**：`/etc/kubernetes/pki/etcd/ca.crt`

   ```shell
   # 证书 base64 加密数据
   $ cat /etc/kubernetes/pki/etcd/server.key | base64 -w 0
   $ cat /etc/kubernetes/pki/etcd/server.crt | base64 -w 0
   $ cat /etc/kubernetes/pki/etcd/ca.key | base64 -w 0
   ```

3. 在名为 calico-config 的 ConfigMap 中，将 etcd_endpoints 的值设置为 etcd 服务器的 IP 地址和端口；编辑 etcd 证书文件在 calico pod 中的挂载路径（路径自行设置）。

   ```yaml
   ...
   kind: ConfigMap
   apiVersion: v1
   metadata:
     name: calico-config
     ...
   data:
     etcd_endpoints: "https://192.168.20.17:2379"
     etcd_ca: "/calico-secrets/etcd-ca"
     etcd_cert: "/calico-secrets/etcd-cert"
     etcd_key: "/calico-secrets/etcd-key"
     ...
   ...
   ```

   > 提示：可以使用逗号作为分隔符指定多个 etcd_endpoint。

4. 如果您使用的是 pod CIDR `192.168.0.0/16`，请跳到下一步。如果您在 kubeadm 中使用不同的 pod CIDR，则无需更改 - Calico 将根据运行配置自动检测 CIDR。对于其他平台，请确保取消注释清单中的 CALICO_IPV4POOL_CIDR 变量并将其设置为与您选择的 pod CIDR 相同的值。

   ```yaml
   ...
   kind: DaemonSet
   apiVersion: apps/v1
   metadata:
     name: calico-node
     namespace: kube-system
     ...
         containers:
           - name: calico-node
             image: docker.io/calico/node:v3.23.1
             ...
               - name: CALICO_IPV4POOL_CIDR
                 value: "10.244.0.0/16"
   ...
   ```

5. 使用以下命令应用清单

   ```shell
   $ kubectl apply -f calico.yaml
   ```

6. 查看 calico 运行状态

   ```shell
   $ kubectl get pod -n kube-system -o wide
   NAME                                       READY   STATUS    RESTARTS   AGE     IP              NODE   NOMINATED NODE   READINESS GATES
   calico-kube-controllers-7fcddf9954-vtl7g   1/1     Running   0          3h25m   192.168.20.18   w1     <none>           <none>
   calico-node-f4qw9                          1/1     Running   0          3h25m   192.168.20.19   w2     <none>           <none>
   calico-node-qs2lc                          1/1     Running   0          3h25m   192.168.20.18   w1     <none>           <none>
   calico-node-tsslv                          1/1     Running   0          3h25m   192.168.20.17   m1     <none>           <none>
   ```

   