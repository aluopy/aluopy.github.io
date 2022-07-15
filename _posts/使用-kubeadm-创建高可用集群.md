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
| w1     | 192.168.20.13  | 2C4G     | Worker node   | CentOS Linux release 7.6.1810 (Core) |
| w2     | 192.168.20.187 | 2C4G     | Worker node   | CentOS Linux release 7.6.1810 (Core) |

## 系统初始化设置

### 修改主机名称添加主机映射

修改主机名称

```shell
$ hostnamectl set-hostname $NODE-NAME
```

> **`NODE-NAME`**：表示将要命名给各节点的主机名

添加主机映射

```shell
$ cat <<EOF | sudo tee -a /etc/hosts
192.168.20.17  m1
192.168.20.18  m2
192.168.20.19  m3
192.168.20.13  w1
192.168.20.187 w2
EOF
```

### 确保每个节点上 MAC 地址和 product_uuid 的唯一性

- 使用命令 `ip link` 或 `ifconfig -a` 来获取网络接口的 MAC 地址
- 使用 `sudo cat /sys/class/dmi/id/product_uuid` 命令对 product_uuid 校验

一般来讲，硬件设备会拥有唯一的地址，但是有些虚拟机的地址可能会重复。 Kubernetes 使用这些值来唯一确定集群中的节点。 如果这些值在每个节点上不唯一，可能会导致安装 [失败](https://github.com/kubernetes/kubeadm/issues/31)。

### 检查网络适配器

如果有一个以上的网络适配器，同时 Kubernetes 组件通过默认路由不可达，我们建议预先添加 IP 路由规则，这样 Kubernetes 集群就可以通过对应的适配器完成连接。

### 允许 iptables 检查桥接流量

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

### 安装 IPVS 所需的内核模块

查看 ipvs 所需的内核模块否加载

```shell
$ lsmod | grep ip_vs
```

加载 ipvs 所需的内核模块

```shell
$ modprobe -- ip_vs
$ modprobe -- ip_vs_rr
$ modprobe -- ip_vs_wrr
$ modprobe -- ip_vs_sh
$ modprobe -- nf_conntrack_ipv4
```

### 开启 IP 转发

```shell
$ echo 1 > /proc/sys/net/ipv4/ip_forward
```

### 防火墙设置

内网环境可以直接关闭防火墙。如需开启防火墙，启用某些必要的端口后才能使 Kubernetes 的各组件相互通信。

#### 方式一：关闭系统防火墙

所有节点关闭系统防火墙

```shell
$ systemctl stop firewalld
```

#### 方式二：启用所需端口

> **注意：**使用的 Pod 网络插件也可能需要开启某些特定端口。由于各个 Pod 网络插件的功能都有所不同， 请参阅他们各自文档中对端口的要求。

##### 检查所需端口

###### 控制面

| 协议 | 方向 | 端口范围  | 目的                    | 使用者               |
| ---- | ---- | --------- | ----------------------- | -------------------- |
| TCP  | 入站 | 6443      | Kubernetes API server   | 所有                 |
| TCP  | 入站 | 2379-2380 | etcd server client API  | kube-apiserver, etcd |
| TCP  | 入站 | 10250     | Kubelet API             | 自身, 控制面         |
| TCP  | 入站 | 10259     | kube-scheduler          | 自身                 |
| TCP  | 入站 | 10257     | kube-controller-manager | 自身                 |

尽管 etcd 的端口也列举在控制面的部分，但也可以在外部自己托管 etcd 集群或者自定义端口。

###### 工作节点

| 协议 | 方向 | 端口范围    | 目的               | 使用者       |
| ---- | ---- | ----------- | ------------------ | ------------ |
| TCP  | 入站 | 10250       | Kubelet API        | 自身, 控制面 |
| TCP  | 入站 | 30000-32767 | NodePort Services† | 所有         |

† [NodePort Services](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/) 的默认端口范围。

所有默认端口都可以重新配置。当使用自定义的端口时，需要打开这些端口来代替这里提到的默认端口。

一个常见的例子是 API 服务器的端口有时会配置为443。或者你也可以使用默认端口，把 API 服务器放到一个监听443 端口的负载均衡器后面，并且路由所有请求到 API 服务器的默认端口。

##### 启用所需端口

在所有节点上启用各自所需的端口

```shell
# 控制平面节点
$ firewall-cmd --permanent --add-port=6443/tcp
$ firewall-cmd --permanent --add-port=2379-2380/tcp
$ firewall-cmd --permanent --add-port=10250/tcp
$ firewall-cmd --permanent --add-port=10257/tcp
$ firewall-cmd --permanent --add-port=10259/tcp

# 工作节点
$ firewall-cmd --permanent --add-port=10250/tcp
$ firewall-cmd --permanent --add-port=30000-32767/tcp
```

### 禁用交换分区

为了保证 kubelet 正常工作，**必须**禁用交换分区

```bash
# 临时禁用
$ swapoff -a
# 永久禁用
$ sed -ri 's/.*swap.*/#&/' /etc/fstab
```

### 禁用 SELinux

将 SELinux 设置为 permissive 模式（相当于将其禁用），禁用 SELinux 是允许容器访问主机文件系统所必需的，这些操作是为了例如 Pod 网络工作正常。

```bash
$ setenforce 0
$ sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

## 安装容器运行时

本文选择 containerd 作为容器运行时，其他常见的容器运行时安装请参考：[容器运行时 \| Kubernetes](https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/)

### 安装 containerd

#### Step 1：安装 containerd

本文使用二进制方式安装 containerd，下载官方二进制文件 [Releases · containerd/containerd (github.com)](https://github.com/containerd/containerd/releases)

```shell
$ wget https://github.com/containerd/containerd/releases/download/v1.6.6/containerd-1.6.6-linux-amd64.tar.gz
$ wget https://github.com/containerd/containerd/releases/download/v1.6.6/containerd-1.6.6-linux-amd64.tar.gz.sha256sum

# 验证其 sha256sum
$ shasum -a 256 -c containerd-1.6.6-linux-amd64.tar.gz.sha256sum 
containerd-1.6.6-linux-amd64.tar.gz: OK
```

在 `/usr/local/` 下解压

```shell
$ tar Cxzvf /usr/local containerd-1.6.6-linux-amd64.tar.gz
bin/
bin/containerd-shim
bin/containerd
bin/containerd-shim-runc-v1
bin/containerd-stress
bin/containerd-shim-runc-v2
bin/ctr
```

生成配置文件，containerd 的默认配置文件为 `/etc/containerd/config.toml`，可以通过如下命令生成一个默认的配置文件

```shell
$ mkdir /etc/containerd
$ containerd config default > /etc/containerd/config.toml
```

systemd 管理 containerd

```shell
$ mkdir /usr/local/lib/systemd/system -p
$ curl -fsSL https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /usr/local/lib/systemd/system/containerd.service
```

启动 containerd

```shell
$ systemctl daemon-reload
$ systemctl enable --now containerd
```

查看 containerd 版本信息

```shell
$ ctr version
Client:
  Version:  v1.6.6
  Revision: 10c12954828e7c7c9b6e0ea9b0c02b01407d3ae1
  Go version: go1.17.11

Server:
  Version:  v1.6.6
  Revision: 10c12954828e7c7c9b6e0ea9b0c02b01407d3ae1
  UUID: ba9fdc06-7734-485d-9b64-2376c7eae82c
```

#### Step 2：安装 runc

下载 `runc.<ARCH>` 二进制文件 [Releases · opencontainers/runc (github.com)](https://github.com/opencontainers/runc/releases)

```shell
$ wget https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.amd64
$ wget https://github.com/opencontainers/runc/releases/download/v1.1.3/runc.sha256sum

$ shasum -a 256 -c -s runc.sha256sum
runc.amd64: OK
...
```

将其安装为 `/usr/local/sbin/runc`

```shell
$ install -m 755 runc.amd64 /usr/local/sbin/runc
```

#### Step 3：安装 CNI 插件

下载 `cni-plugins-<OS>-<ARCH>-<VERSION>.tgz` 存档 [Releases · containernetworking/plugins (github.com)](https://github.com/containernetworking/plugins/releases)

```shell
$ wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
$ wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz.sha512

$ shasum -a 512 -c cni-plugins-linux-amd64-v1.1.1.tgz.sha512
cni-plugins-linux-amd64-v1.1.1.tgz: OK
```

在 `/opt/cni/bin` 下解压

```shell
$ mkdir -p /opt/cni/bin
$ tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
./
./macvlan
./static
./vlan
./portmap
./host-local
./vrf
./bridge
./tuning
./firewall
./host-device
./sbr
./loopback
./dhcp
./ptp
./ipvlan
./bandwidth
```

#### 配置 `systemd` cgroup 驱动程序

结合 `runc` 使用 `systemd` cgroup 驱动，在 `/etc/containerd/config.toml` 中设置 `SystemdCgroup = true`

```shell
$ sed -i 's,SystemdCgroup = false,SystemdCgroup = true,' /etc/containerd/config.toml
```

重启 containerd

```shell
$ systemctl restart containerd
```

#### 重载沙箱（pause）镜像

设置 `sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.6"`

```shell
$ sed -ri 's,(.*sandbox_image = ).*,\1"registry.aliyuncs.com/google_containers/pause:3.6",' /etc/containerd/config.toml
```

重启 containerd

```shell
$ systemctl restart containerd
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
$ yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
$ systemctl enable --now kubelet
```

> 以上安装命令默认安装最新版本，安装指定版本：`yum install -y kubelet-1.20.0 kubeadm-1.20.0 kubectl-1.20.0`

## 为 kube-apiserver 创建负载均衡器

本文使用 [**kube-vip**](https://kube-vip.io/docs/) 为 Kubernetes 集群提供高可用负载均衡服务，kube-vip 将作为静态 pod 在控制平面节点上运行。

kube-vip 为 Kubernetes 集群提供了一个虚拟 IP 和负载均衡器，用于控制平面（用于构建高可用性集群）和 LoadBalancer 类型的 Kubernetes 服务，而不依赖任何外部硬件或软件。

该项目最初旨在为 Kubernetes 提供弹性控制平面，但后来扩展到为 Kubernetes 集群中的服务资源提供相同的功能。

### 生成清单

为了更轻松地使用 kube-vip 中的各种功能，我们可以使用 kube-vip 容器本身来生成我们的静态 Pod 清单。为此，我们将 kube-vip 映像作为容器运行，并为我们想要启用的功能传入各种标志。

以下操作在集群所有控制平面节点执行

#### 设置配置细节

我们使用环境变量来预定义要提供给 kube-vip 的输入值。

```bash
$ export VIP=192.168.20.236
$ export INTERFACE=ens192
$ KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
# 手动设置
#$ export KVVERSION=v0.4.4
```

#### 创建清单

为容器运行时创建别名，本文使用的是 containerd，所以创建命令如下

```bash
$ alias kube-vip="ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"
```

> **containerd**：`alias kube-vip="ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip"`

创建一个清单，该清单启动 kube-vip，使用 leaderElection 方法和 ARP 提供控制平面 VIP 和 Kubernetes 服务管理。当这个实例被选举为领导者时，它会将 vip 绑定到指定的接口。这与 LoadBalancer 类型的服务的行为相同。

```bash
$ kube-vip manifest pod \
    --interface $INTERFACE \
    --address $VIP \
    --controlplane \
    --services \
    --arp \
    --leaderElection | tee /etc/kubernetes/manifests/kube-vip.yaml
```

生成的 ARP 清单示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  name: kube-vip
  namespace: kube-system
spec:
  containers:
  - args:
    - manager
    env:
    - name: vip_arp
      value: "true"
    - name: port
      value: "6443"
    - name: vip_interface
      value: ens192
    - name: vip_cidr
      value: "32"
    - name: cp_enable
      value: "true"
    - name: cp_namespace
      value: kube-system
    - name: vip_ddns
      value: "false"
    - name: vip_leaderelection
      value: "true"
    - name: vip_leaseduration
      value: "5"
    - name: vip_renewdeadline
      value: "3"
    - name: vip_retryperiod
      value: "1"
    - name: vip_address
      value: 192.168.20.236
    image: ghcr.io/kube-vip/kube-vip:v0.4.4
    imagePullPolicy: Always
    name: kube-vip
    resources: {}
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_RAW
    volumeMounts:
    - mountPath: /etc/kubernetes/admin.conf
      name: kubeconfig
  hostAliases:
  - hostnames:
    - kubernetes
    ip: 127.0.0.1
  hostNetwork: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/admin.conf
    name: kubeconfig
status: {}
```

## 部署高可用 etcd 集群（本文未使用）

默认情况下，kubeadm 在每个控制平面节点上运行一个本地 etcd 实例。也可以使用外部的 etcd 集群，并在不同的主机上提供 etcd 实例。以下创建一个由三个成员组成的高可用外部 etcd 集群，该集群在创建过程中可被 kubeadm 使用。

### 建立集群

一般来说，是在一个节点上生成所有证书并且只分发这些 *必要* 的文件到其它节点上。

1. 将 kubelet 配置为 etcd 的服务管理器

   > 在要运行 etcd 的所有主机上执行此操作

   由于 etcd 是首先创建的，因此你必须通过创建具有更高优先级的新文件来覆盖 kubeadm 提供的 kubelet 单元文件。

   ```shell
   $ cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
   [Service]
   ExecStart=
   # 将下面的 "systemd" 替换为你的容器运行时所使用的 cgroup 驱动。
   # kubelet 的默认值为 "cgroupfs"。
   # 如果需要的话，将 "--container-runtime-endpoint " 的值替换为一个不同的容器运行时。
   ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --cgroup-driver=systemd
   Restart=always
   EOF
   
   $ systemctl daemon-reload
   $ systemctl restart kubelet
   ```

   检查 kubelet 的状态以确保其处于运行状态：

   ```shell
   $ systemctl status kubelet
   ```

2. 为 kubeadm 创建配置文件

   使用以下脚本为每个将要运行 etcd 成员的主机生成一个 kubeadm 配置文件

   ```shell
   # 使用你的主机 IP 替换 HOST0、HOST1 和 HOST2 的 IP 地址
   export HOST0=192.168.20.17
   export HOST1=192.168.20.18
   export HOST2=192.168.20.19
   
   # 使用你的主机名更新 NAME0、NAME1 和 NAME2
   export NAME0="m1"
   export NAME1="m2"
   export NAME2="m3"
   
   # 创建临时目录来存储将被分发到其它主机上的文件
   mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/
   
   HOSTS=(${HOST0} ${HOST1} ${HOST2})
   NAMES=(${NAME0} ${NAME1} ${NAME2})
   
   for i in "${!HOSTS[@]}"; do
   HOST=${HOSTS[$i]}
   NAME=${NAMES[$i]}
   cat << EOF > /tmp/${HOST}/kubeadmcfg.yaml
   ---
   apiVersion: "kubeadm.k8s.io/v1beta3"
   kind: InitConfiguration
   nodeRegistration:
       name: ${NAME}
   localAPIEndpoint:
       advertiseAddress: ${HOST}
   ---
   apiVersion: "kubeadm.k8s.io/v1beta3"
   kind: ClusterConfiguration
   etcd:
       local:
           serverCertSANs:
           - "${HOST}"
           peerCertSANs:
           - "${HOST}"
           extraArgs:
               initial-cluster: ${NAMES[0]}=https://${HOSTS[0]}:2380,${NAMES[1]}=https://${HOSTS[1]}:2380,${NAMES[2]}=https://${HOSTS[2]}:2380
               initial-cluster-state: new
               name: ${NAME}
               listen-peer-urls: https://${HOST}:2380
               listen-client-urls: https://${HOST}:2379
               advertise-client-urls: https://${HOST}:2379
               initial-advertise-peer-urls: https://${HOST}:2380
   EOF
   done
   ```

3. 生成证书颁发机构

   如果已经拥有 CA，那么直接复制 CA 的 `crt` 和 `key` 文件到 `/etc/kubernetes/pki/etcd/ca.crt` 和 `/etc/kubernetes/pki/etcd/ca.key`。 复制完这些文件后继续“为每个成员创建证书”。

   如果还没有 CA，则在 `$HOST0`（为 kubeadm 生成配置文件的位置）上运行此命令。

   ```shell
   $ kubeadm init phase certs etcd-ca
   [certs] Generating "etcd/ca" certificate and key
   ```

   这一操作创建如下两个文件：

   - `/etc/kubernetes/pki/etcd/ca.crt`
   - `/etc/kubernetes/pki/etcd/ca.key`

4. 为每个成员创建证书

   ```shell
   kubeadm init phase certs etcd-server --config=/tmp/${HOST2}/kubeadmcfg.yaml
   kubeadm init phase certs etcd-peer --config=/tmp/${HOST2}/kubeadmcfg.yaml
   kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
   kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
   cp -R /etc/kubernetes/pki /tmp/${HOST2}/
   # 清理不可重复使用的证书
   find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete
   
   kubeadm init phase certs etcd-server --config=/tmp/${HOST1}/kubeadmcfg.yaml
   kubeadm init phase certs etcd-peer --config=/tmp/${HOST1}/kubeadmcfg.yaml
   kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
   kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
   cp -R /etc/kubernetes/pki /tmp/${HOST1}/
   find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete
   
   kubeadm init phase certs etcd-server --config=/tmp/${HOST0}/kubeadmcfg.yaml
   kubeadm init phase certs etcd-peer --config=/tmp/${HOST0}/kubeadmcfg.yaml
   kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
   kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
   # 不需要移动 certs 因为它们是给 HOST0 使用的
   
   # 清理不应从此主机复制的证书
   find /tmp/${HOST2} -name ca.key -type f -delete
   find /tmp/${HOST1} -name ca.key -type f -delete
   ```

5. 复制证书和 kubeadm 配置

   证书已生成，现在将它们移动到对应的主机。

   ```shell
   USER=root
   HOST=${HOST1}
   scp -r /tmp/${HOST}/* ${USER}@${HOST}:/etc/kubernetes/
   ssh ${USER}@${HOST}
   USER@HOST $ sudo -Es
   root@HOST $ chown -R root:root pki
   root@HOST $ mv pki /etc/kubernetes/
   ```

6. 确保所有拷贝的文件都存在

   `$HOST0` 所需文件的完整列表如下：

   ```
   /tmp/${HOST0}
   └── kubeadmcfg.yaml
   ---
   /etc/kubernetes/pki
   ├── apiserver-etcd-client.crt
   ├── apiserver-etcd-client.key
   └── etcd
       ├── ca.crt
       ├── ca.key
       ├── healthcheck-client.crt
       ├── healthcheck-client.key
       ├── peer.crt
       ├── peer.key
       ├── server.crt
       └── server.key
   ```

   在 `$HOST1` 上：

   ```
   $HOME
   └── kubeadmcfg.yaml
   ---
   /etc/kubernetes/pki
   ├── apiserver-etcd-client.crt
   ├── apiserver-etcd-client.key
   └── etcd
       ├── ca.crt
       ├── healthcheck-client.crt
       ├── healthcheck-client.key
       ├── peer.crt
       ├── peer.key
       ├── server.crt
       └── server.key
   ```

   在 `$HOST2` 上：

   ```
   $HOME
   └── kubeadmcfg.yaml
   ---
   /etc/kubernetes/pki
   ├── apiserver-etcd-client.crt
   ├── apiserver-etcd-client.key
   └── etcd
       ├── ca.crt
       ├── healthcheck-client.crt
       ├── healthcheck-client.key
       ├── peer.crt
       ├── peer.key
       ├── server.crt
       └── server.key
   ```

7. 创建静态 Pod 清单

   在每台主机上运行 `kubeadm` 命令来生成 etcd 使用的静态清单

   ```shell
   root@HOST0 $ kubeadm init phase etcd local --config=/tmp/${HOST0}/kubeadmcfg.yaml
   root@HOST1 $ kubeadm init phase etcd local --config=$HOME/kubeadmcfg.yaml
   root@HOST2 $ kubeadm init phase etcd local --config=$HOME/kubeadmcfg.yaml
   ```

8. 可选：检查集群运行状况

   ```shell
   $ docker run --rm -it \
   --net host \
   -v /etc/kubernetes:/etc/kubernetes k8s.gcr.io/etcd:${ETCD_TAG} etcdctl \
   --cert /etc/kubernetes/pki/etcd/peer.crt \
   --key /etc/kubernetes/pki/etcd/peer.key \
   --cacert /etc/kubernetes/pki/etcd/ca.crt \
   --endpoints https://${HOST0}:2379 endpoint health --cluster
   ...
   https://[HOST0 IP]:2379 is healthy: successfully committed proposal: took = 16.283339ms
   https://[HOST1 IP]:2379 is healthy: successfully committed proposal: took = 19.44402ms
   https://[HOST2 IP]:2379 is healthy: successfully committed proposal: took = 35.926451ms
   ```

   - 将 `${ETCD_TAG}` 设置为你的 etcd 镜像的版本标签，例如 `3.4.3-0`。 要查看 kubeadm 使用的 etcd 镜像和标签，请执行 `kubeadm config images list --kubernetes-version ${K8S_VERSION}`， 例如，其中的 `${K8S_VERSION}` 可以是 `v1.17.0`。
   - 将 `${HOST0}` 设置为要测试的主机的 IP 地址。

## 初始化 K8S 集群

### 初始化主控制平面

本文通过一份配置文件而不是使用命令行参数来配置 `kubeadm init` 命令， 一些更加高级的功能只能够通过配置文件设定。 这份配置文件通过 `--config` 选项参数指定的， 它必须包含 `ClusterConfiguration` 结构，并可能包含更多由 `---\n` 分隔的结构。 在某些情况下，可能不允许将 `--config` 与其他标志混合使用。详情请查看：[kubeadm config \| Kubernetes](https://kubernetes.io/zh-cn/docs/reference/setup-tools/kubeadm/kubeadm-config/)

**Step 1：**准备 `kubeadm init` 命令的配置文件：`kubeadm-config.yaml`

```yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
# nodeRegistration:
  # name: m1
  # criSocket: /run/containerd/containerd.sock
localAPIEndpoint:
  advertiseAddress: 192.168.20.17
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: stable
# 可以指定 TCP 端口号，会覆盖 bindPort
# 如果不指定端口号，则使用 bindPort
# controlPlaneEndpoint: 192.168.20.236:8443
controlPlaneEndpoint: 192.168.20.236
apiServer:
  certSANs:
  - m1
  - m2
  - m3
  - 192.168.20.17
  - 192.168.20.18
  - 192.168.20.19
  - vip.mycluster.local
  - 192.168.20.236
  - 127.0.0.1
  extraArgs:
    authorization-mode: Node,RBAC
  timeoutForControlPlane: 4m0s
clusterName: kubernetes
certificatesDir: /etc/kubernetes/pki
imageRepository: registry.aliyuncs.com/google_containers
etcd:
  # one of local or external
  local:
    dataDir: /var/lib/etcd
  # external:
    # endpoints:
    # - 192.168.20.17:2379
    # - 192.168.20.18:2379
    # - 192.168.20.19:2379
    # caFile: /etcd/kubernetes/pki/etcd/etcd-ca.crt
    # certFile: /etcd/kubernetes/pki/etcd/etcd.crt
    # keyFile: /etcd/kubernetes/pki/etcd/etcd.key
networking:
  serviceSubnet: 10.96.0.0/16
  podSubnet: 10.244.0.0/24
  dnsDomain: cluster.local
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
```

**Step 2：**初始化主控制平面

```bash
$ kubeadm init --config kubeadm-config.yaml --upload-certs
...
You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join 192.168.20.236:6443 --token 6srrq0.6u4zm8l9owxdtfaf \
	--discovery-token-ca-cert-hash sha256:f8a28591178ab71055be992835eda2ecf7b88e446405d016644c9847108c03d4 \
	--control-plane --certificate-key 552030cbc5d9560094e1e0c1fec20e26ee239e4baa3791c7dfc5b4b02ae3081c

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.20.236:6443 --token 6srrq0.6u4zm8l9owxdtfaf \
	--discovery-token-ca-cert-hash sha256:f8a28591178ab71055be992835eda2ecf7b88e446405d016644c9847108c03d4
```

> `--upload-certs` 标志用来将在所有控制平面实例之间的共享证书上传到集群。主控制平面的证书被加密并上传到 `kubeadm-certs` Secret 中。
>
> 重新上传证书并生成新的解密密钥：`kubeadm init phase upload-certs --upload-certs`

### 其余控制平面加入集群

在其余的控制平面执行以下命令加入集群

```shell
$ kubeadm join 192.168.20.236:6443 --token 6srrq0.6u4zm8l9owxdtfaf \
	--discovery-token-ca-cert-hash sha256:f8a28591178ab71055be992835eda2ecf7b88e446405d016644c9847108c03d4 \
	--control-plane --certificate-key 552030cbc5d9560094e1e0c1fec20e26ee239e4baa3791c7dfc5b4b02ae3081c
```

### 安装工作节点

在所有工作节点上执行以下命令加入集群

```shell
$ kubeadm join 192.168.20.236:6443 --token 6srrq0.6u4zm8l9owxdtfaf \
	--discovery-token-ca-cert-hash sha256:f8a28591178ab71055be992835eda2ecf7b88e446405d016644c9847108c03d4
```

## 配置 kubectl 命令

### 配置使用 kubectl 命令

- **非 root 用户**

  ```shell
  $ mkdir -p $HOME/.kube
  $ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  $ sudo chown $(id -u):$(id -g) $HOME/.kube/config
  ```

- **root 用户**

  ```shell
  $ echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/profile
  $ source /etc/profile
  ```

### 启动 kubectl 自动补全

kubectl 的 Bash 补全脚本可以用命令 `kubectl completion bash` 生成。 在 shell 中导入（Sourcing）补全脚本，将启用 kubectl 自动补全功能。补全脚本依赖于工具 [**bash-completion**](https://github.com/scop/bash-completion)， 所以要先安装它。

```shell
# 检查 bash-completion 是否已安装
$ type _init_completion

# 安装 bash-completion
$ yum install bash-completion -y
$ source /usr/share/bash-completion/bash_completion

# 启动 kubectl 自动补全
# 当前用户
# $ echo 'source <(kubectl completion bash)' >>~/.bashrc
# 系统全局
$ kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

# 如果 kubectl 有关联的别名，可以扩展 shell 补全来适配此别名
$ echo 'alias k=kubectl' >>~/.bashrc
$ echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
```

> **说明：**
>
> bash-completion 负责导入 `/etc/bash_completion.d` 目录中的所有补全脚本。
>
> 重新加载 shell 后，kubectl 自动补全功能即可生效。

## 安装 Pod 网络附加组件

### 安装 calico

Calico 是一个开源网络和网络安全解决方案，适用于容器、虚拟机和基于本地主机的工作负载。 Calico 支持广泛的平台，包括 Kubernetes、OpenShift、Mirantis Kubernetes Engine (MKE)、OpenStack 和裸机服务。

本文使用 etcd 数据存储安装 Calico

1. 下载 etcd 的 Calico yaml 文件

   ```shell
   $ curl https://projectcalico.docs.tigera.io/manifests/calico-etcd.yaml -o calico.yaml
   ```

2. 在名为 calico-etcd-secrets 的 Secret 中，填充 etcd-key、etcd-cert、etcd-ca 的值（对应证书 base64 加密数据）

   通过 kubeadm 安装的 k8s 集群，对应的证书文件位置：

   - **etcd-key**：`/etc/kubernetes/pki/etcd/server.key`
   - **etcd-cert**：`/etc/kubernetes/pki/etcd/server.crt`
   - **etcd-ca**：`/etc/kubernetes/pki/etcd/ca.crt`

   ```shell
   # 证书 base64 加密数据
   $ cat /etc/kubernetes/pki/etcd/server.key | base64 -w 0
   $ cat /etc/kubernetes/pki/etcd/server.crt | base64 -w 0
   $ cat /etc/kubernetes/pki/etcd/ca.key | base64 -w 0
   ```

3. 在名为 calico-config 的 ConfigMap 中，将 etcd_endpoints 的值设置为 etcd 服务器的 IP 地址和端口；编辑 etcd 证书文件在 calico pod 中的挂载路径（路径自行设置）

   ```yaml
   ...
   kind: ConfigMap
   apiVersion: v1
   metadata:
     name: calico-config
     ...
   data:
     etcd_endpoints: "https://192.168.20.17:2379,https://192.168.20.18:2379,https://192.168.20.19:2379"
     etcd_ca: "/calico-secrets/etcd-ca"
     etcd_cert: "/calico-secrets/etcd-cert"
     etcd_key: "/calico-secrets/etcd-key"
     ...
   ...
   ```

   > *提示：可以使用逗号作为分隔符指定多个 etcd_endpoint*

4. 设置 pod CIDR，取消注释 CALICO_IPV4POOL_CIDR 变量，并将其设置为与您选择的 pod CIDR 相同的值

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
   ```

   
