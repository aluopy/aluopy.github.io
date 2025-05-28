---
title: "Kubernetes 证书更新"
#excerpt: ""
permalink: /kubernetes/k8s-cert-update
toc: true
#toc_label: ""
#toc_icon: "cog"
categories: kubernetes
tags:
  - kubernetes
  - certs
---

Kubernetes（K8S）是一个由多个组件组成的系统，其中很多组件都需要使用 TLS 证书进行安全通信。这些证书包括用于安全 kube-apiserver、kube-scheduler、kube-controller-manager、etcd、kubelet 等组件的证书。当这些证书过期或者需要更新时，就需要进行证书更新。

Kubernetes 的证书更新可以通过几种不同的方式进行，其中包括手动更新和自动更新两种主要方式：

- **手动更新：**手动更新证书通常涉及到生成新的证书和私钥，然后将它们放到正确的位置，并重启相关的 Kubernetes 组件。具体步骤可能会根据你的 Kubernetes 部署方式和配置有所不同。在更新证书之后，你需要确保所有的 Kubernetes 组件都能够访问新的证书，并且所有依赖于旧证书的客户端也能够接受新的证书。
- **自动更新（[证书轮转](https://kubernetes.io/zh-cn/docs/tasks/tls/certificate-rotation/ "证书轮转")）：**Kubernetes 1.8及以后的版本支持 kubelet 的 TLS Bootstrapping 功能，这项功能可以用于自动更新 kubelet 的客户端证书。通过这个功能，kubelet 可以在其客户端证书接近过期时自动请求新的证书。这个过程是由Kubernetes API 服务器和证书签发机构（Certificate Authority, CA）自动完成的。

> 为了启用 kubelet 的 TLS Bootstrapping，你需要在 kubelet 的配置中启用 RotateKubeletClientCertificate 特性门（feature gate），并确保你的集群有一个支持证书签发的证书签发机构。启用这个功能之后，kubelet 会在其客户端证书接近过期时自动申请新的证书，并使用新证书来与API服务器进行通信。

总的来说，Kubernetes 的证书更新是一个重要的安全维护步骤，可以通过手动更新或自动更新的方式来进行。不同的更新方式可能适用于不同的场景，具体选择哪种方式取决于你的具体需求和环境配置。

本文将介绍如何通过手动的方式来更新 Kubernetes 证书。

## 1. 查看证书

在 Master 节点上查看证书时间：

```shell
$ kubeadm certs check-expiration

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Apr 02, 2023 09:53 UTC   296d                                    no      
apiserver                  Apr 02, 2023 09:53 UTC   296d            ca                      no      
apiserver-kubelet-client   Apr 02, 2023 09:53 UTC   296d            ca                      no      
controller-manager.conf    Apr 02, 2023 09:53 UTC   296d                                    no      
front-proxy-client         Apr 02, 2023 09:53 UTC   296d            front-proxy-ca          no      
scheduler.conf             Apr 02, 2023 09:53 UTC   296d                                    no      

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Mar 30, 2032 09:53 UTC   9y              no      
front-proxy-ca          Mar 30, 2032 09:53 UTC   9y              no
```

> 低版本的集群下，执行命令会报错，可以执行命令: `kubeadm alpha certs check-expiration`

## 2. 备份文件

这里可以直接备份整个 Kubernetes 配置文件：

```shell
$ cp -r /etc/kubernetes /etc/kubernetes.old
```

## 3. 更新证书

在每个 Master 节点上执行如下命令更新证书：

```shell
$ kubeadm certs renew all

certificate embedded in the kubeconfig file for the admin to use and for kubeadm itself renewed
certificate for serving the Kubernetes API renewed
certificate for the API server to connect to kubelet renewed
certificate embedded in the kubeconfig file for the controller manager to use renewed
certificate for the front proxy client renewed
certificate embedded in the kubeconfig file for the scheduler manager to use renewed

Done renewing certificates. You must restart the kube-apiserver, kube-controller-manager, kube-scheduler and etcd, so that they can use the new certificates.
```

> 低版本集群执行: `kubeadm alpha certs renew all`

## 4. 重启服务

在每个 Master 节点上重启相关服务：

```shell
$ docker ps |egrep "k8s_kube-apiserver|k8s_kube-scheduler|k8s_kube-controller|k8s_etcd_etcd"|awk '{print $1}'|xargs docker restart
```

## 5. 更新 config 文件

```shell
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## 6. 验证更新

查看证书时间是否已更新：

```shell
$ kubeadm certs check-expiration
# 低版本集群
#$ kubeadm alpha certs check-expiration
```
