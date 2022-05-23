---
title: "NGINX Ingress Controller"
excerpt: "ingress-nginx 是 Kubernetes 的入口控制器，使用 NGINX 作为反向代理和负载均衡器。"
toc: true
---

## Overview

ingress-nginx 是 Kubernetes 的入口控制器，使用 NGINX 作为反向代理和负载均衡器。

[Learn more about Ingress on the main Kubernetes documentation site](https://kubernetes.io/docs/concepts/services-networking/ingress/).

- [NGINX Ingress Controller (github.com)](https://github.com/kubernetes/ingress-nginx)
- [NGINX Ingress Controller (kubernetes.github.io)](https://kubernetes.github.io/ingress-nginx/deploy/)

## Deploy

### github 获取配置文件

https://github.com/kubernetes/ingress-nginx/blob/main/deploy/static/provider/baremetal/deploy.yaml

> **environment**: Bare metal clusters

配置文件默认使用 Deployment 方式部署，并通过 nodeport 对外暴露服务，本文以 **<font color="#A52A2A">DaemonSet</font>** 方式部署，pod 直接使用 **<font color="#A52A2A">主机网络</font>**，并配合 **<font color="#A52A2A">nodeSelector</font>** 指定运行节点。

### 选择部署节点

给需要运行 **nginx-ingress-controller** 的 node 打标签，一般选择2~3个 node，能形成高可用负载均衡即可。

```bash
# 本集群节点信息
$ kubectl get node
NAME      STATUS   ROLES                  AGE   VERSION
master    Ready    control-plane,master   8d    v1.23.5
worker1   Ready    worker                 8d    v1.23.5
worker2   Ready    worker                 8d    v1.23.5

$ kubectl label node worker1 aluopy/ingress-controller=true
node/worker1 labeled
$ kubectl label node worker2 aluopy/ingress-controller=true
node/worker2 labeled
```

### 修改配置文件

- `Deployment` --> `DaemonSet`
- `NodePort` --> `ClusterIP`（可以也建议直接删掉 `ingress-nginx-controller` Service）
- 添加 `template.spec.hostNetwork: true`
- 修改 `image` 为阿里云镜像（3个地方，两种镜像）
- 添加 `template.spec.nodeSelector.aluo/ingress-controller: "true"`

### 部署

```bash
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/kubernetes/master/best-practice/resource/services-networking/ingress-nginx.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
serviceaccount/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
configmap/ingress-nginx-controller created
service/ingress-nginx-controller created
service/ingress-nginx-controller-admission created
daemonset.apps/ingress-nginx-controller created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
```

查看资源信息

```shell
$ kubectl get all -n ingress-nginx
NAME                                       READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create-kb7mw   0/1     Completed   0          103s
pod/ingress-nginx-admission-patch-86wbp    0/1     Completed   2          103s
pod/ingress-nginx-controller-48hfs         1/1     Running     0          103s
pod/ingress-nginx-controller-9rmmp         1/1     Running     0          103s

NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/ingress-nginx-controller             ClusterIP   10.100.79.172   <none>        80/TCP,443/TCP   103s
service/ingress-nginx-controller-admission   ClusterIP   10.111.83.125   <none>        443/TCP          103s

NAME                                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                    AGE
daemonset.apps/ingress-nginx-controller   2         2         2       2            2           aluopy/ingress-controller=true   103s

NAME                                       COMPLETIONS   DURATION   AGE
job.batch/ingress-nginx-admission-create   1/1           8s         103s
job.batch/ingress-nginx-admission-patch    1/1           16s        103s
```

以上同时会创建一个名为 nginx 的 ingressclass

```shell
$ kubectl get ingressclass
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       12m
```

## Access test

### 准备后端服务

准备用于测试的后端服务 `nginx`、`tomcat`

#### nginx服务

```bash
$ cat > nginx-svc-deploy.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
  name: nginx
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
EOF

$ kubectl apply -f nginx-svc-deploy.yaml 
service/nginx created
deployment.apps/nginx created
```

#### tomcat 服务

```bash
$ cat > tomcat-svc-deploy.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: tomcat
  name: tomcat
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: tomcat

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: tomcat
  name: tomcat
spec:
  replicas: 2
  selector:
    matchLabels:
      app: tomcat
  template:
    metadata:
      labels:
        app: tomcat
    spec:
      containers:
      - image: tomcat
        name: tomcat
EOF

$ kubectl apply -f tomcat-svc-deploy.yaml 
service/tomcat created
deployment.apps/tomcat created
```

### 创建 Ingress 资源

```bash
$ cat > ingress-apps.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-apps
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  # 上面创建的 ingressclass 的名称 nginx
  ingressClassName: nginx
  rules:
  - host: aluo.k8s.io
    http:
      paths:
      - path: /nginx
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
      - path: /tomcat
        pathType: Prefix
        backend:
          service:
            name: tomcat
            port:
              number: 8080
EOF

$ kubectl apply -f ingress-apps.yaml 
ingress.networking.k8s.io/ingress-apps created

$ kubectl get ing
NAME           CLASS   HOSTS         ADDRESS                       PORTS   AGE
ingress-apps   nginx   aluo.k8s.io   192.168.56.57,192.168.56.58   80      2m46s
```

### 测试访问

```bash
# 在测试的服务器上添加主机映射
$ cat >> /etc/hosts << EOF
192.168.56.58 aluo.k8s.io
EOF


$ curl aluo.k8s.io/nginx
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>


$ curl aluo.k8s.io/tomcat
<!doctype html><html lang="en"><head><title>HTTP Status 404 – Not Found</title><style type="text/css">body {font-family:Tahoma,Arial,sans-serif;} h1, h2, h3, b {color:white;background-color:#525D76;} h1 {font-size:22px;} h2 {font-size:16px;} h3 {font-size:14px;} p {font-size:12px;} a {color:black;} .line {height:1px;background-color:#525D76;border:none;}</style></head><body><h1>HTTP Status 404 – Not Found</h1><hr class="line" /><p><b>Type</b> Status Report</p><p><b>Description</b> The origin server did not find a current representation for the target resource or is not willing to disclose that one exists.</p><hr class="line" /><h3>Apache Tomcat/10.0.14</h3></body></html>
```

## Troubleshooting

[ingress-nginx/troubleshooting.md (github.com)](https://github.com/kubernetes/ingress-nginx/blob/fc38b9f2aa2d68ee00c417cf97e727b77a00c175/docs/troubleshooting.md)
