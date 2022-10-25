---
title: "在 Kubernetes 上部署 Harbor"
#excerpt: ""
permalink: /kubernetes/deploy-harbor-on-kubernetes/
toc: true
#toc_label: ""
#toc_icon: "cog"
categories: 
  - kubernetes
  - harbor
tags:
  - kubernetes
  - harbor
---

本文使用 helm 在 kubernetes 中快速安装 harbor

官方文档：[Deploying Harbor with High Availability via Helm](https://goharbor.io/docs/2.6.0/install-config/harbor-ha-helm/)

## 下载 Chart

下载 Harbor helm chart：

```bash
$ helm repo add harbor https://helm.goharbor.io
$ helm fetch harbor/harbor --untar
```

## 自定义配置

自定义 chart 配置

1. 创建 `my-values.yaml` 文件

2. 在其中加入以下内容

   ```yaml
   expose:
     tls:
       certSource: secret
       secret:
         # 使用自己域名的 TLS 证书和私钥
         secretName: aluopy-cn-tls-secret
         notarySecretName: szhtxx-tls-secret
   
     ingress:
       hosts:
         core: registry.szhtxx.cn
         notary: notary.szhtxx.cn
       className: nginx
   
   externalURL: https://registry.szhtxx.cn
   
   persistence:
     resourcePolicy: ""
     persistentVolumeClaim:
       registry:
         storageClass: nfs-client-1
       chartmuseum:
         storageClass: nfs-client-1
       jobservice:
         jobLog:
           storageClass: nfs-client-1
         scanDataExports:
           storageClass: nfs-client-1
       database:
         storageClass: nfs-client-1
       redis:
         storageClass: nfs-client-1
       trivy:
         storageClass: nfs-client-1
   
   harborAdminPassword: "Harbor_123#!"
   
   database:
     #type: external
     internal:
       password: "P_ostgres#5432"
     #external:
     #  host: postgresql.harbor.svc.cluster.local
     #  username: postgres
     #  password: P_ostgres#5432
   #redis:
     #type: external
     #external:
     #  addr: redis.harbor.svc.cluster.local:6379
     #  password: R_edis#6379
   ```

## 创建 TLS Secret

创建指定域名的 TLS Secret

1. 创建 `aluopy-cn-tls-secret.yaml` 文件

2. 添加如下内容

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: aluopy-cn-tls-secret
     namespace: harbor
     labels:
       app.kubernetes.io/name: harbor
   type: kubernetes.io/tls
   data:
     tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0F...
     tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkF...
   ```

3. 应用清单创建 secret

   ```shell
   $ kubectl apply -f aluopy-cn-tls-secret.yaml
   ```

4. 查看创建的 secret

   ```shell
   $ kubectl get secret -n harbor aluopy-cn-tls-secret
   ```

## 安装 Harbor

在 `harbor` 命名空间中安装名为 `harbor` 的 Harbor helm chart。

```shell
$ helm install harbor -n harbor -f my-values.yaml ./harbor
```

## 验证安装

等待几分钟后查看相关组件运行状态。

查看 helm 发布版本信息

```shell
$ helm list -n harbor
NAME  	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART        	APP VERSION
harbor	harbor   	1       	2022-10-25 12:57:09.644992822 +0800 CST	deployed	harbor-1.10.1	2.6.1
```

查看 pod 状态

```shell
$ kubectl get pod -n harbor 
NAME                                    READY   STATUS    RESTARTS      AGE
harbor-chartmuseum-676bb649c9-zzvqt     1/1     Running   0             97m
harbor-core-55b9bfcc5-xg6nb             1/1     Running   0             97m
harbor-database-0                       1/1     Running   0             97m
harbor-jobservice-785fb9df6f-vd5np      1/1     Running   4 (96m ago)   97m
harbor-notary-server-6d98854874-48pmb   1/1     Running   1 (97m ago)   97m
harbor-notary-signer-59f9f45448-c9tpm   1/1     Running   1 (96m ago)   97m
harbor-portal-67d8547c5f-pnm67          1/1     Running   0             97m
harbor-redis-0                          1/1     Running   0             97m
harbor-registry-578b765c4c-d955j        2/2     Running   0             97m
harbor-trivy-0                          1/1     Running   0             97m
```

查看 service 信息

```shell
$ kubectl get svc -n harbor 
NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
harbor-chartmuseum     ClusterIP   10.96.197.134   <none>        80/TCP              100m
harbor-core            ClusterIP   10.96.217.14    <none>        80/TCP              100m
harbor-database        ClusterIP   10.96.240.199   <none>        5432/TCP            100m
harbor-jobservice      ClusterIP   10.96.136.137   <none>        80/TCP              100m
harbor-notary-server   ClusterIP   10.96.30.247    <none>        4443/TCP            100m
harbor-notary-signer   ClusterIP   10.96.195.47    <none>        7899/TCP            100m
harbor-portal          ClusterIP   10.96.76.215    <none>        80/TCP              100m
harbor-redis           ClusterIP   10.96.13.34     <none>        6379/TCP            100m
harbor-registry        ClusterIP   10.96.134.113   <none>        5000/TCP,8080/TCP   100m
harbor-trivy           ClusterIP   10.96.63.150    <none>        8080/TCP            100m
```

查看 ingress 信息

```
$ kubectl get ingress -n harbor 
NAME                    CLASS   HOSTS                ADDRESS         PORTS     AGE
harbor-ingress          nginx   registry.aluopy.cn   192.168.30.30   80, 443   101m
harbor-ingress-notary   nginx   notary.aluopy.cn     192.168.30.30   80, 443   101m
```

## Harbor Portal

浏览器访问：https://registry.aluopy.cn

用户名/密码：`admin/Harbor_123#!`