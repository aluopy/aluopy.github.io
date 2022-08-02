---
title: "Kubernetes YAML 模板"
permalink: /kubernetes/kubernetes-yaml-templates/
excerpt: ""
toc: true
#toc_label: ""
#toc_icon: "cog"
categories: kubernetes
tags:
  - kubernetes
  - yaml
---

## 1.1 Pod

| Yaml                                                         | Summary                                                   |
| ------------------------------------------------------------ | --------------------------------------------------------- |
| [pod/pod-dummy.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/pod/pod-dummy.yaml) | 启动一个带有死睡眠循环的虚拟 pod                          |
| [pod/pod-nginx.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/pod/pod-nginx.yaml) | 启动示例应用程序 pod(nginx)                               |
| [pod/pod-initcontainer-sysctl.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/pod/pod-initcontainer-sysctl.yaml) | 启动 Pod 时使用 initContainer 运行 sysctl                 |
| [pod/pod-healthcheck-nginx.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/pod/pod-healthcheck-nginx.yaml) | 使用 tcp 和 http healthcheck 启动 pod                     |
| [pod/pod-secrets.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/pod/pod-secrets.yaml) | Pod 使用 secrets 作为 volumes 或环境变量                  |
| [pod/pod-gitclone.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/pod/pod-gitclone.yaml) | Pod：使用 initContainer 作为 sidecar 来托管一个 git repo  |
| [pod/pod-hostaliases.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/pod/pod-hostaliases.yaml) | Pod：为 /etc/hosts 添加别名                               |
| [pod/pod-serviceaccount.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/pod/pod-serviceaccount.yaml) | 使用 serviceaccount 启动 pod，而不是默认的 serviceaccount |
| [pod/pod-handlers.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/pod/pod-handlers.yaml) | Pod 启动或停止时的事件                                    |

## 1.2 Volume

| Yaml                                                         | Summary                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [volume/volume-manual-pv.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/volume/volume-manual-pv.yaml) | 先创建 pv，再创建 pvc                                        |
| [volume/volume-mount-localpath.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/volume/volume-mount-localpath.yaml) | 将本地文件夹挂载到 pod                                       |
| [volume/volume-emptydir.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/volume/volume-emptydir.yaml) | 创建一个空文件夹，然后挂载到 pod                             |
| [volume/volume-ebs.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/volume/volume-ebs.yaml) | 将 EBS 卷挂载到在同一个 AZ 的亚马逊实例中运行的 pod          |
| [volume/volume-nfs.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/volume/volume-nfs.yaml) | 创建 nfs pv                                                  |
| [volume/volume-gcePersistentDisk.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/volume/volume-gcePersistentDisk.yaml) | 将 GCE 磁盘挂载到在同一个 AZ 的亚马逊实例中运行的 pod        |
| [volume/volume-digitalocean.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/volume/volume-digitalocean.yaml) | 在 DigitalOcean 中为您的 kubernetes 集群创建 DigitalOcean 卷 |
| Reference                                                    | [Link: volumes examples](https://github.com/kubernetes/examples/tree/master/staging/volumes) |

## 1.3 Service

| Yaml                                                         | Summary                       |
| ------------------------------------------------------------ | ----------------------------- |
| [service/service-loadbalancer.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/service/service-loadbalancer.yaml) | Service: loadbalancer         |
| [service/service-nodeport.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/service/service-nodeport.yaml) | Service: nodeport             |
| [service/service-ingress.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/service/service-ingress.yaml) | Service: ingress              |
| [service/service-clusterip-nginx.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/service/service-clusterip-nginx.yaml) | Service: nginx with clusterip |
| [service/service-cassandra.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/service/service-cassandra.yaml) | Service: cassandra            |

## 1.4 Configmap/Envs

| Yaml                                                         | Summary                                   |
| ------------------------------------------------------------ | ----------------------------------------- |
| [config/pod-configmap.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/config/pod-configmap.yaml) | 从文件创建 configmap，然后将其用作 pod 卷 |
| [config/pod-environment-var.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/config/pod-environment-var.yaml) | 启动一个 pod 传递环境变量                 |
| [config/pod-env-metada.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/config/pod-env-metada.yaml) | 向 pod 公开元数据                         |
| [config/configmap-plaintext.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/config/configmap-plaintext.yaml) | 用纯文本定义 configmap                    |

## 1.5 Security - RBAC

| Yaml                                                         | Summary                  |
| ------------------------------------------------------------ | ------------------------ |
| [rbac/serviceaccount-default.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/rbac/serviceaccount-default.yaml) | Serviceaccount：基本用法 |
| [rbac/rbac-default.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/rbac/rbac-default.yaml) | Serviceaccount：具体示例 |

## 1.6 Security - PodSecurityPolicy

| Yaml                                                         | Summary                                         |
| ------------------------------------------------------------ | ----------------------------------------------- |
| [podsecurity/securitycontext-user.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/podsecurity/securitycontext-user.yaml) | 在 pod 和容器级别配置用户 ID                    |
| [podsecurity/podsecurity-privileged.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/podsecurity/podsecurity-privileged.yaml) | 使用特权访问创建 pod 安全性                     |
| [podsecurity/podsecurity-restricted.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/podsecurity/podsecurity-restricted.yaml) | 创建具有受限访问权限的 pod 安全性，然后再应用它 |
| [podsecurity/podsecurity-enforce.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/podsecurity/podsecurity-enforce.yaml) | 通过定义角色和集群角色来实施策略安全            |
| [podsecurity/podsecurity-advanced.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/podsecurity/podsecurity-advanced.yaml) | 更复杂的 Pod 安全策略定义                       |
| [podsecurity/podsecurity-example.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/podsecurity/podsecurity-example.yaml) | 包含所有内容的完整示例                          |

## 1.7 Security - NetworkPolicy

| Yaml                                                         | Summary                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [networksecurity/networksecurity-denyall-ingress.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/networksecurity/networksecurity-denyall-ingress.yaml) | Allow all ingress                                            |
| [networksecurity/networksecurity-allowall-ingress.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/networksecurity/networksecurity-allowall-ingress.yaml) | Deny all ingress                                             |
| [networksecurity/networksecurity-denyall.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/networksecurity/networksecurity-denyall.yaml) | Deny all ingress and egress                                  |
| [networksecurity/networksecurity-pod.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/networksecurity/networksecurity-pod.yaml) | 白名单流量控制                                               |
| [networksecurity/networksecurity-complicated.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/networksecurity/networksecurity-complicated.yaml) | 综合网络策略示例                                             |
| [networksecurity/networksecurity-port.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/networksecurity/networksecurity-port.yaml) | 允许来自一个命名空间的 TCP 443                               |
| [networksecurity/networksecurity-deny-othernamespaces.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/networksecurity/networksecurity-deny-othernamespaces.yaml) | 拒绝来自其他命名空间的所有入口流量                           |
| [networksecurity/networksecurity-denyegress-exceptdns.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/networksecurity/networksecurity-denyegress-exceptdns.yaml) | 拒绝除 DNS 以外的所有出口流量                                |
| Reference                                                    | [GitHub: kubernetes-network-policy-recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes) |

## 1.8 Quota & Limits

| Yaml                                                         | Summary                                               |
| ------------------------------------------------------------ | ----------------------------------------------------- |
| [quota/limitrange-pvc-size.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/quota/limitrange-pvc-size.yaml) | LimitRange: PVC size                                  |
| [quota/limitrange-pvc-cumulative-size.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/quota/limitrange-pvc-cumulative-size.yaml) | ResourceQuota: pvc count and storage size             |
| [quota/limitrange-mem-size.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/quota/limitrange-mem-size.yaml) | LimitRange: Pod ram usage. Then apply it to namespace |

## 1.9 Deployment

| Yaml                                                         | Summary                      |
| ------------------------------------------------------------ | ---------------------------- |
| [deployment/deployment-nginx.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/deployment/deployment-nginx.yaml) | Deploy nginx with 2 replicas |
| [deployment/deployment-mysql.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/deployment/deployment-mysql.yaml) | Deploy mysql                 |

## 1.10 Statefulset

| Yaml                                                         | Summary                              |
| ------------------------------------------------------------ | ------------------------------------ |
| [statefulset/statefulset-nginx.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/statefulset/statefulset-nginx.yaml) | Statefulset: nginx                   |
| [statefulset/statefulset-single-mysql](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/statefulset/statefulset-single-mysql) | Statefulset: mysql                   |
| [statefulset/statefulset-replicated-cassandra.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/statefulset/statefulset-replicated-cassandra.yaml) | Statefulset: single cassandra        |
| [statefulset/statefulset-replicated-mysql](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/statefulset/statefulset-replicated-mysql) | Statefulset: cassandra with replicas |

## 1.11 Jobs & CronJob

| Yaml                                                         | Summary                  |
| ------------------------------------------------------------ | ------------------------ |
| [job/job-affinity.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/job/job-affinity.yaml) | 部署具有节点亲和性的 job |

## 1.12 HorizontalPodAutoscaler

| Yaml                                                         | Summary                                         |
| ------------------------------------------------------------ | ----------------------------------------------- |
| [hpa/hpa-nginx.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/hpa/hpa-nginx.yaml) | 为 nginx deployment 部署一个水平 pod 自动扩缩器 |

## 1.13 Adhoc

| Yaml                                                         | Summary          |
| ------------------------------------------------------------ | ---------------- |
| [namespace/ns-dummy.yaml](https://github.com/aluopy/kubernetes-yaml-templates/blob/master/namespace/ns-dummy.yaml) | 创建一个命名空间 |

## 1.14 Related Tools

| Name                                                         | Summary                      |
| ------------------------------------------------------------ | ---------------------------- |
| [GitHub: kubernetes-sigs/kustomize](https://github.com/kubernetes-sigs/kustomize) | Kubernetes YAML 配置的自定义 |

## 1.15 More Resources

License: Code is licensed under [MIT License](https://www.dennyzhang.com/wp-content/mit_license.txt).