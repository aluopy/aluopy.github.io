---
title: "Helm Quickstart"
toc: true
categories: Helm
tags:
  - kubernetes
  - helm
---

[Helm](https://helm.sh/zh/docs/) 致力于成为k8s集群的应用包管理工具，希望像linux 系统的`RPM` `DPKG`那样成功；确实在k8s上部署复杂一点的应用很麻烦，需要管理很多yaml文件（configmap,controller,service,rbac,pv,pvc等等），而helm能够整齐管理这些文档：版本控制，参数化安装，方便的打包与分享等。

在 helm 中有三个关键概念：Chart，Repo 及 Release

- ***Chart***: 一系列 k8s 资源集合的命名，它包含一系列 k8s 资源配置文件的模板与参数，可供灵活配置
- ***Repo***: 即 chart 的仓库，其中有很多个 chart 可供选择，如官方 helm/charts
- ***Release***: 当一个 Chart 部署后生成一个 release

建议积累一定k8s经验以后再去使用helm；对于初学者来说手工去配置那些yaml文件对于快速学习k8s的设计理念和运行原理非常有帮助，而不是直接去使用helm，面对又一层封装与复杂度。本文基于helm 3（建议版本）。

## 安装 helm

在官方repo下载 [release 版本](https://github.com/helm/helm/releases)中自带的二进制文件即可（以 Linux amd64 为例）

```bash
$ wget https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz
$ tar zxvf helm-v3.6.3-linux-amd64.tar.gz
$ mv ./linux-amd64/helm /usr/bin
```

## 添加相关 Repo

当安装好了Helm之后，可以通过 `helm repo add` 添加 chart 仓库。从 [Artifact Hub](https://artifacthub.io/packages/search?kind=0) 中查找有效的Helm chart仓库。

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
```

当添加完成，您将可以看到被安装的 charts 列表：

```bash
$ helm search repo bitnami
NAME                                        	CHART VERSION	APP VERSION  	DESCRIPTION
bitnami/bitnami-common                      	0.0.9        	0.0.9        	DEPRECATED Chart with custom templates used in ...
bitnami/airflow                             	10.2.5       	2.1.2        	Apache Airflow is a platform to programmaticall...
bitnami/apache                              	8.5.9        	2.4.48       	Chart for Apache HTTP Server                      
bitnami/argo-cd                             	0.1.2        	2.0.4        	Declarative, GitOps continuous delivery tool fo...
... ...
```

添加官方稳定的 charts 仓库：

```bash
$ helm repo add stable https://charts.helm.sh/stable
```

> 如果在国内有网络问题，可以使用阿里云镜像：
>
> ```bash
> $ helm repo add stable https://apphub.aliyuncs.com/stable
> ```

列出所有本地添加的 chart 仓库

```bash
$ helm repo list
NAME   	URL                               
bitnami	https://charts.bitnami.com/bitnami
stable 	https://apphub.aliyuncs.com/stable
```

另外，对于一些大软件公司也会维护自己的 Chart 仓库，如 `gitlab`，`elasti`

- elastic：https://hub.helm.sh/charts/elastic
- gitlab：https://hub.helm.sh/charts/gitlab

## 查找 Charts

`helm search`：查找 Charts

Helm 自带一个强大的搜索命令，可以用来从两种来源中进行搜索：

- `helm search hub` 从 [Artifact Hub](https://artifacthub.io/) 中查找并列出 helm charts。 Artifact Hub中存放了大量不同的仓库。
- `helm search repo` 从你添加（使用 `helm repo add`）到本地 helm 客户端中的仓库中进行查找。该命令基于本地数据进行搜索，无需连接互联网。

通过运行 `helm search hub` 命令查找公开可用的charts：

```bash
$ helm search hub mysql
URL                                               	CHART VERSION	APP VERSION 	DESCRIPTION           
https://artifacthub.io/packages/helm/choerodon/...	8.5.1        	8.5.1       	Chart to create a Highly available MySQL cluster  
https://artifacthub.io/packages/helm/bitnami-ak...	8.7.2        	8.0.25      	Chart to create a Highly available MySQL cluster  
https://artifacthub.io/packages/helm/bitnami/mysql	8.7.2        	8.0.25      	Chart to create a Highly available MySQL cluster
... ...
```

通过运行 `helm search repo` 命令查找本地可用的charts：

```bash
$ helm search repo mysql
NAME                            	CHART VERSION	APP VERSION	DESCRIPTION                             
bitnami/mysql                   	8.7.2        	8.0.25     	Chart to create a Highly available MySQL cluster  
stable/mysql                    	1.6.9        	5.7.30     	DEPRECATED - Fast, reliable, scalable, and easy...
stable/mysqldump                	2.6.1        	2.4.1      	A Helm chart to help backup MySQL databases usi...
... ...
```

查看 chart 基本信息：

```bash
# helm show all bitnami/mysql 获取关于该chart的所有信息
$ helm show chart bitnami/mysql
annotations:
  category: Database
apiVersion: v2
appVersion: 8.0.25
dependencies:
- name: common
  repository: https://charts.bitnami.com/bitnami
  tags:
  - bitnami-common
  version: 1.x.x
description: Chart to create a Highly available MySQL cluster
home: https://github.com/bitnami/charts/tree/master/bitnami/mysql
icon: https://bitnami.com/assets/stacks/mysql/img/mysql-stack-220x234.png
keywords:
- mysql
- database
- sql
- cluster
- high availability
maintainers:
- email: containers@bitnami.com
  name: Bitnami
name: mysql
sources:
- https://github.com/bitnami/bitnami-docker-mysql
- https://mysql.com
version: 8.7.2
```

## 安装 Chart

`helm install`：安装一个 helm 包

### 快速安装

Helm 可以通过多种途径查找和安装 chart， 但最简单的是安装官方的 `bitnami` charts。

```bash
$ helm repo update              # 更新charts列表
$ helm install aluo-blog bitnami/wordpress
NAME: aluo-blog
LAST DEPLOYED: Wed Jul 21 14:31:48 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES: ...

$ helm list
NAME      	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART           	APP VERSION
aluo-blog 	default  	1       	2021-07-21 14:31:48.531922937 +0800 CST	deployed	wordpress-11.1.5	5.7.2
```

> 现在`mysql` chart 已经安装。注意安装chart时创建了一个新的 *release* 对象。上述发布被命名为 `aluo-mysql`。 （如果想让Helm生成一个名称，删除发布名称并使用`--generate-name`，如：`helm install bitnami/mysql --generate-name`）

可以使用 `helm status` 来追踪 release 的状态，或是重新读取配置信息：

```bash
$ helm status aluo-blog
NAME: aluo-blog
LAST DEPLOYED: Wed Jul 21 14:31:48 2021
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES: ...
```

### 安装前自定义 chart

上述安装方式只会使用 chart 的默认配置选项。很多时候，我们需要自定义 chart 来指定我们想要的配置。

使用 `helm show values` 可以查看 chart 中的可配置选项：

```bash
$ helm show values bitnami/wordpress
## @section Global parameters
## Global Docker image parameters
## Please, note that this will override the image parameters, including dependencies, configured to use the global value
## Current available global Docker image parameters: imageRegistry, imagePullSecrets and storageClass
##
global:
  imageRegistry:
  ## E.g.
  ## imagePullSecrets:
  ##   - myRegistryKeySecretName
  ##
  imagePullSecrets: []
  storageClass:
... ...
## Bitnami WordPress image
## ref: https://hub.docker.com/r/bitnami/wordpress/tags/
##
image:
  registry: docker.io
  repository: bitnami/wordpress
  tag: 5.7.2-debian-10-r45
... ...
mariadb:
  ## @param mariadb.enabled Deploy a MariaDB server to satisfy the applications database requirements
  ## To use an external database set this to false and configure the `externalDatabase.*` parameters
  ##
  enabled: true
  ## @param mariadb.architecture MariaDB architecture. Allowed values: `standalone` or `replication`
  ##
  architecture: standalone
  ## MariaDB Authentication parameters
  ##
  auth:
    rootPassword: ""
    database: bitnami_wordpress
    username: bn_wordpress
    password: ""
... ...
```

然后，你可以使用 YAML 格式的文件覆盖上述任意配置项，并在安装过程中使用该文件。

```bash
$ echo '{mariadb.auth.database: user0db, mariadb.auth.username: user0}' > values.yaml
$ helm install -f values.yaml bitnami/wordpress --generate-name
```

上述命令将为 MariaDB 创建一个名称为 `user0` 的默认用户，并且授予该用户访问新建的 `user0db` 数据库的权限。**chart 中的其他默认配置保持不变**。

安装过程中有两种方式传递配置数据：

- `--values` (或 `-f`)：使用 YAML 文件覆盖配置。可以指定多次，优先使用最右边的文件。
- `--set`：通过命令行的方式对指定项进行覆盖。

如果同时使用两种方式，则 `--set` 中的值会被合并到 `--values` 中，但是 `--set` 中的值优先级更高。在`--set` 中覆盖的内容会被被保存在 ConfigMap 中。可以通过 `helm get values <release-name>` 来查看指定 release 中 `--set` 设置的值。也可以通过运行 `helm upgrade` 并指定 `--reset-values` 字段来清除 `--set` 中设置的值。

### 更多安装方法

`helm install` 命令可以从多个来源进行安装：

- chart 的仓库（如上所述）
- 本地 chart 压缩包（`helm install foo foo-0.1.1.tgz`）
- 解压后的 chart 目录（`helm install foo path/to/foo`）
- 完整的 URL（`helm install foo https://example.com/charts/foo-1.2.3.tgz`）

### Redis安装示例

helm3 安装命令与 helm2 稍有变化，个人习惯先下载对应charts到本地然后按照固定目录格式安装，以创建一个redis集群举例：

- 创建 redis-cluster 目录

```bash
mkdir -p /opt/charts/redis-cluster
cd /opt/charts/redis-cluster
```

- 下载最新stalbe/redis-ha

```bash
helm repo update
helm pull stable/redis-ha
```

- 解压 charts，复制 values.yaml设置

```bash
tar zxvf redis-ha-*.tgz
cp redis-ha/values.yaml .
```

- 创建 start.sh 脚本记录启动命令

```bash
cat > start.sh << EOF
#!/bin/sh
set -x

ROOT=$(cd `dirname $0`; pwd)
cd $ROOT

helm install redis \
	--create-namespace \
	--namespace dependency \
	-f ./values.yaml \
	./redis-ha
EOF
```

- 查看当前目录结构如下

```bash
tree .
.
├── redis-ha		# redis-ha 原始charts目录
├── start.sh		# 启动命名脚本
└── values.yaml		# 个性化参数配置
```

- 修改当前目录的 values.yaml 为你的个性化配置

```bash
#举例values.yaml 配置如下，没有启用PV
#cat values.yaml
image:
  repository: redis
  tag: 5.0.6-alpine

replicas: 2

## Redis specific configuration options
redis:
  port: 6379
  masterGroupName: "mymaster"       # must match ^[\\w-\\.]+$) and can be templated
  config:
    ## For all available options see http://download.redis.io/redis-stable/redis.conf
    min-replicas-to-write: 1
    min-replicas-max-lag: 5   # Value in seconds
    maxmemory: "4g"       # Max memory to use for each redis instance. Default is unlimited.
    maxmemory-policy: "allkeys-lru"  # Max memory policy to use for each redis instance. Default is volatile-lru.
    repl-diskless-sync: "yes"
    rdbcompression: "yes"
    rdbchecksum: "yes"

  resources:
    requests:
      memory: 200Mi
      cpu: 100m
    limits:
      memory: 4000Mi

## Sentinel specific configuration options
sentinel:
  port: 26379
  quorum: 1

  resources:
    requests:
      memory: 200Mi
      cpu: 100m
    limits:
      memory: 200Mi

hardAntiAffinity: true

## Configures redis with AUTH (requirepass & masterauth conf params)
auth: false

persistentVolume:
  enabled: false

hostPath:
  path: "/data/mcs-redis/{{ .Release.Name }}"
```

- 执行安装

```bash
bash ./start.sh
```

- 查看安装

```bash
helm ls -A
NAME 	NAMESPACE 	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
redis	dependency	1       	2020-05-28 20:57:31.166002853 +0800 CST	deployed	redis-ha-4.4.4	5.0.6

# 查看k8s上资源
kubectl get pod,svc -n dependency
NAME                          READY   STATUS    RESTARTS   AGE
pod/redis-redis-ha-server-0   2/2     Running   0          119s
pod/redis-redis-ha-server-1   2/2     Running   0          104s

NAME                                TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)              AGE
service/redis-redis-ha              ClusterIP   None          <none>        6379/TCP,26379/TCP   119s
service/redis-redis-ha-announce-0   ClusterIP   10.68.41.65   <none>        6379/TCP,26379/TCP   119s
service/redis-redis-ha-announce-1   ClusterIP   10.68.64.49   <none>        6379/TCP,26379/TCP   119s
```