# K8S-Best-Practice

## 实验环境

| NAME | ROLES         | VERSION | INTERNAL-IP   | RESOURCE-QUOTA | OS-IMAGE              | KERNEL-VERSION              | CONTAINER-RUNTIME |
| ---- | ------------- | ------- | ------------- | -------------- | --------------------- | --------------------------- | ----------------- |
| m1   | Control plane | v1.24.3 | 192.168.20.17 | 2C4G           | CentOS Linux 7 (Core) | 5.18.12-1.el7.elrepo.x86_64 | docker://20.10.17 |
| w1   | Worker node   | v1.24.3 | 192.168.20.18 | 2C4G           | CentOS Linux 7 (Core) | 5.18.12-1.el7.elrepo.x86_64 | docker://20.10.17 |
| w2   | Worker node   | v1.24.3 | 192.168.20.19 | 2C4G           | CentOS Linux 7 (Core) | 5.18.12-1.el7.elrepo.x86_64 | docker://20.10.17 |

## 安装工具

### kubectl

Kubernetes 命令行工具 [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/)，使得你可以对 Kubernetes 集群运行命令。 你可以使用 kubectl 来部署应用、监测和管理集群资源以及查看日志。

#### 安装 kubectl

##### 准备开始

kubectl 版本和集群版本之间的差异必须在一个小版本号内。 例如：v1.24 版本的客户端能与 v1.23、 v1.24 和 v1.25 版本的控制面通信。 用最新兼容版的 kubectl 有助于避免不可预见的问题。

在 Linux 系统中安装 kubectl 有如下几种方法：

- 用 curl 在 Linux 系统中安装 kubectl
- 用原生包管理工具安装
- 用其他包管理工具安装

##### 用 curl 在 Linux 系统中安装 kubectl

1. 下载最新发行版

   ```shell
   $ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   ```

2. 验证该可执行文件（可选步骤）

   下载 kubectl 校验和文件：

   ```shell
   $ curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
   ```

   基于校验和文件，验证 kubectl 的可执行文件：

   ```shell
   $ echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
   kubectl: OK
   ```

   > **说明：**
   >
   > 下载的 kubectl 与校验和文件版本必须相同。

3. 安装 kubectl

   ```shell
   $ install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

   > **说明：**
   >
   > 即使没有目标系统的 root 权限，仍然可以将 kubectl 安装到目录 `~/.local/bin` 中：
   >
   > ```bash
   > $ chmod +x kubectl
   > $ mkdir -p ~/.local/bin
   > $ mv ./kubectl ~/.local/bin/kubectl
   > # 之后将 ~/.local/bin 附加（或前置）到 $PATH
   > ```

4. 查看 kubectl 版本信息

   ```shell
   $ kubectl version --client
   WARNING: This version information is deprecated and will be replaced with the output from kubectl version --short.  Use --output=yaml|json to get the full version.
   Client Version: version.Info{Major:"1", Minor:"24", GitVersion:"v1.24.3", GitCommit:"aef86a93758dc3cb2c658dd9657ab4ad4afc21cb", GitTreeState:"clean", BuildDate:"2022-07-13T14:30:46Z", GoVersion:"go1.18.3", Compiler:"gc", Platform:"linux/amd64"}
   Kustomize Version: v4.5.4
   
   $ kubectl version --client --output=yaml
   clientVersion:
     buildDate: "2022-07-13T14:30:46Z"
     compiler: gc
     gitCommit: aef86a93758dc3cb2c658dd9657ab4ad4afc21cb
     gitTreeState: clean
     gitVersion: v1.24.3
     goVersion: go1.18.3
     major: "1"
     minor: "24"
     platform: linux/amd64
   kustomizeVersion: v4.5.4
   ```

##### 用原生包管理工具安装

添加阿里云 YUM 软件源

```shell
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

安装 kubectl

```shell
$ yum install -y kubectl
```

##### 用其他包管理工具安装

###### Snap

如果你使用的 Ubuntu 或其他 Linux 发行版，内建支持 [snap](https://snapcraft.io/docs/core/install) 包管理工具， 则可用 [snap](https://snapcraft.io/) 命令安装 kubectl

```shell
$ snap install kubectl --classic
$ kubectl version --client
```

###### Homebrew

如果你使用 Linux 系统，并且装了 [Homebrew](https://docs.brew.sh/Homebrew-on-Linux) 包管理工具， 则可以使用这种方式[安装](https://docs.brew.sh/Homebrew-on-Linux#install) kubectl

```shell
$ brew install kubectl
$ kubectl version --client
```

#### 配置 kubectl

配置使用 kubectl 命令，通过 kubeadm 安装的 k8s 集群配置如下：

**非 root 用户**

```shell
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**root 用户**

```shell
$ echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/profile
$ source /etc/profile
```

#### 验证 kubectl 配置

通过获取集群状态的方法，检查是否已恰当的配置了 kubectl：

```shell
$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.20.17:6443
CoreDNS is running at https://192.168.20.17:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

如果返回一个 URL，则意味着 kubectl 成功的访问到了集群。

如果命令 `kubectl cluster-info` 返回了 url，但还不能访问集群，那可以用以下命令来检查配置是否妥当：

```shell
$ kubectl cluster-info dump
```

#### 启动 kubectl 自动补全

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
$ echo 'alias k=kubectl' >>~/.bashrc && source ~/.bashrc
$ echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
```

> **说明：**
>
> bash-completion 负责导入 `/etc/bash_completion.d` 目录中的所有补全脚本。
>
> **重新加载 shell 后，kubectl 自动补全功能才生效**。

### kind



### minikube

### kubeadm
