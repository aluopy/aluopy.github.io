---
title: "kube-prometheus 部署"
#excerpt: ""
permalink: /prometheus/deploy-kube-prometheus/
toc: true
#toc_label: ""
#toc_icon: "cog"
categories: 
  - prometheus
tags:
  - prometheus
  - prometheus-operator
  - kube-prometheus
  - alertmanager
  - grafana
  - node-exporter
  - prometheus-adapter
  - kube-state-metrics
  - blackbox-exporter
---

## 概览

### Prometheus

[Prometheus](https://prometheus.io/) 是一个开源的系统监控和警报工具包，最初在 [SoundCloud](https://soundcloud.com/) 建立。自2012年成立以来，许多公司和组织都采用了 Prometheus，该项目有一个非常活跃的开发者和用户[社区](https://prometheus.io/community/)。它现在是一个独立的开源项目，独立于任何公司进行维护。为了强调这一点，并明确项目的治理结构，Prometheus 在2016年加入了云原生计算基金会（[Cloud Native Computing Foundation](https://cncf.io/)），成为继 [Kubernetes](https://kubernetes.io/) 之后的第二个托管项目。

Prometheus 以时间序列数据的形式收集和存储其指标，也就是说，指标信息与记录的时间戳一起存储，同时还有被称为标签的可选键值对。

首先需要明确指出的是，Kubernetes 项目的监控体系曾经非常繁杂，在社区中也有很多方案。但这套体系发展到今天，已经完全演变成了以 Prometheus 项目为核心的一套统一的方案。

实际上，Prometheus 项目是当年 CNCF 基金会起家时的“第二把交椅”。而这个项目发展到今天，已经全面接管了 Kubernetes 项目的整套监控体系。

比较有意思的是，Prometheus 项目与 Kubernetes 项目一样，也来自于 Google 的 Borg 体系，它的原型系统，叫作 BorgMon，是一个几乎与 Borg 同时诞生的内部监控系统。而 Prometheus 项目的发起原因也跟 Kubernetes 很类似，都是希望通过对用户更友好的方式，将 Google 内部系统的设计理念，传递给用户和开发者。

Prometheus 的架构和它的一些生态系统组件：

![](https://prometheus.io/assets/architecture.png) 

### Prometheus Operator

[Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) 使用 Kubernetes [custom resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) 来简化 Prometheus, Alertmanager 和相关监控组件的部署和配置。

### kube-prometheus

[kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) 提供了基于 Prometheus 和 Prometheus Operator 的完整集群监控栈的配置示例。这包括部署多个 Prometheus 和 Alertmanager 实例，收集节点指标的指标导出器（如 node_exporter），连接 Prometheus 和各种指标端点的 scrape 目标配置，以及用于通知集群中潜在问题的警报规则示例。

该软件包中包括的组件：

- The [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- Highly available [Prometheus](https://prometheus.io/)
- Highly available [Alertmanager](https://github.com/prometheus/alertmanager)
- [Prometheus node-exporter](https://github.com/prometheus/node_exporter)
- [Prometheus Adapter for Kubernetes Metrics APIs](https://github.com/kubernetes-sigs/prometheus-adapter)
- [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
- [Grafana](https://grafana.com/)

### CustomResourceDefinitions

Prometheus Operator 的一个核心功能是监控 Kubernetes API 服务器对特定对象的更改，并确保当前的 Prometheus部署与这些对象相符。Operator 对以下自定义资源定义（CRD）采取行动：

- **`Prometheus`**, 定义了一个期望的 Prometheus 部署。
- **`Alertmanager`**, 定义了一个期望的 Alertmanager 部署。
- **`ThanosRuler`**, 定义了一个理想的 Thanos Ruler 部署。
- **`ServiceMonitor`**, 其中声明性地指定应如何监控 Kubernetes services。Operator 根据 API server 中对象的当前状态自动生成 Prometheus 的 scrape 配置。
- **`PodMonitor`**, 其中声明性地指定了应如何监控 pod 组。Operator 会根据 API server 中对象的当前状态自动生成 Prometheus 的 scrape 配置。
- **`Probe`**, 其中声明性地指定应如何监控入口组或静态目标。Operator 会根据定义自动生成 Prometheus 的 scrape 配置。
- **`PrometheusRule`**, 其中定义了一套所需的 Prometheus 警报和/或记录规则s。Operator 生成一个规则文件，可由 Prometheus 实例使用。
- **`AlertmanagerConfig`**, 其中声明性地指定了Alertmanager 配置的子部分，允许将警报路由到自定义接收者，并设置抑制规则。

Prometheus Operator 自动检测 Kubernetes API server 中对上述任何对象的变化，并确保匹配的部署和配置保持同步。

## 获取 kube-prometheus 项目

从 GitHub 拉取 kube-prometheus：

```bash
$ git clone https://github.com/prometheus-operator/kube-prometheus.git
$ cd kube-prometheus/
```

或下载当前主分支的 zip 文件并解压其内容：

[github.com/prometheus-operator/kube-prometheus/archive/main.zip](https://github.com/prometheus-operator/kube-prometheus/archive/main.zip)

一旦你的机器上有了这些文件，就可以进入项目的根目录。

## 初始化设置

### 清单整理

这个项目的 Kubernetes 清单文件都放在 `manifests` 目录下，而且比较繁多，为了方便后续区分管理，将这些文件进行整理分类。

创建相应的文件夹：

```bash
$ cd manifests
$ mkdir -p alertmanager blackbox-exporter grafana kube-state-metrics node-exporter prometheus prometheus-adapter prometheus-operator prometheus-rule service-monitor
```

移动各文件到相应目录：

```bash
$ mv alertmanager-* alertmanager/
$ mv blackboxExporter-* blackbox-exporter/
$ mv grafana-* grafana/
$ mv *-serviceMonitor* service-monitor/
$ mv kubeStateMetrics-* kube-state-metrics/
$ mv nodeExporter-* node-exporter/
$ mv prometheus-*.yaml prometheus/
$ mv prometheusAdapter-* prometheus-adapter/
$ mv prometheusOperator-* prometheus-operator/
$ mv *-prometheusRule* prometheus-rule/
```

移动完毕后目录结构如下：

```bash
$ tree ../manifests/
../manifests/
├── alertmanager
│   ├── alertmanager-alertmanager.yaml
│   ├── alertmanager-networkPolicy.yaml
│   ├── alertmanager-podDisruptionBudget.yaml
│   ├── alertmanager-prometheusRule.yaml
│   ├── alertmanager-secret.yaml
│   ├── alertmanager-serviceAccount.yaml
│   ├── alertmanager-serviceMonitor.yaml
│   └── alertmanager-service.yaml
├── blackbox-exporter
│   ├── blackboxExporter-clusterRoleBinding.yaml
│   ├── blackboxExporter-clusterRole.yaml
│   ├── blackboxExporter-configuration.yaml
│   ├── blackboxExporter-deployment.yaml
│   ├── blackboxExporter-networkPolicy.yaml
│   ├── blackboxExporter-serviceAccount.yaml
│   ├── blackboxExporter-serviceMonitor.yaml
│   └── blackboxExporter-service.yaml
├── grafana
│   ├── grafana-config.yaml
│   ├── grafana-dashboardDatasources.yaml
│   ├── grafana-dashboardDefinitions.yaml
│   ├── grafana-dashboardSources.yaml
│   ├── grafana-deployment.yaml
│   ├── grafana-networkPolicy.yaml
│   ├── grafana-prometheusRule.yaml
│   ├── grafana-pvc.yaml
│   ├── grafana-serviceAccount.yaml
│   ├── grafana-serviceMonitor.yaml
│   └── grafana-service.yaml
├── kube-state-metrics
│   ├── kubeStateMetrics-clusterRoleBinding.yaml
│   ├── kubeStateMetrics-clusterRole.yaml
│   ├── kubeStateMetrics-deployment.yaml
│   ├── kubeStateMetrics-networkPolicy.yaml
│   ├── kubeStateMetrics-prometheusRule.yaml
│   ├── kubeStateMetrics-serviceAccount.yaml
│   └── kubeStateMetrics-service.yaml
├── node-exporter
│   ├── nodeExporter-clusterRoleBinding.yaml
│   ├── nodeExporter-clusterRole.yaml
│   ├── nodeExporter-daemonset.yaml
│   ├── nodeExporter-networkPolicy.yaml
│   ├── nodeExporter-prometheusRule.yaml
│   ├── nodeExporter-serviceAccount.yaml
│   └── nodeExporter-service.yaml
├── prometheus
│   ├── prometheus-clusterRoleBinding.yaml
│   ├── prometheus-clusterRole.yaml
│   ├── prometheus-networkPolicy.yaml
│   ├── prometheus-podDisruptionBudget.yaml
│   ├── prometheus-prometheusRule.yaml
│   ├── prometheus-prometheus.yaml
│   ├── prometheus-roleBindingConfig.yaml
│   ├── prometheus-roleBindingSpecificNamespaces.yaml
│   ├── prometheus-roleConfig.yaml
│   ├── prometheus-roleSpecificNamespaces.yaml
│   ├── prometheus-serviceAccount.yaml
│   └── prometheus-service.yaml
├── prometheus-adapter
│   ├── prometheusAdapter-apiService.yaml
│   ├── prometheusAdapter-clusterRoleAggregatedMetricsReader.yaml
│   ├── prometheusAdapter-clusterRoleBindingDelegator.yaml
│   ├── prometheusAdapter-clusterRoleBinding.yaml
│   ├── prometheusAdapter-clusterRoleServerResources.yaml
│   ├── prometheusAdapter-clusterRole.yaml
│   ├── prometheusAdapter-configMap.yaml
│   ├── prometheusAdapter-deployment.yaml
│   ├── prometheusAdapter-networkPolicy.yaml
│   ├── prometheusAdapter-podDisruptionBudget.yaml
│   ├── prometheusAdapter-roleBindingAuthReader.yaml
│   ├── prometheusAdapter-serviceAccount.yaml
│   └── prometheusAdapter-service.yaml
├── prometheus-operator
│   ├── prometheusOperator-clusterRoleBinding.yaml
│   ├── prometheusOperator-clusterRole.yaml
│   ├── prometheusOperator-deployment.yaml
│   ├── prometheusOperator-networkPolicy.yaml
│   ├── prometheusOperator-prometheusRule.yaml
│   ├── prometheusOperator-serviceAccount.yaml
│   └── prometheusOperator-service.yaml
├── prometheus-rule
│   ├── kubePrometheus-prometheusRule.yaml
│   └── kubernetesControlPlane-prometheusRule.yaml
├── service-monitor
│   ├── kubernetesControlPlane-serviceMonitorApiserver.yaml
│   ├── kubernetesControlPlane-serviceMonitorCoreDNS.yaml
│   ├── kubernetesControlPlane-serviceMonitorKubeControllerManager.yaml
│   ├── kubernetesControlPlane-serviceMonitorKubelet.yaml
│   ├── kubernetesControlPlane-serviceMonitorKubeScheduler.yaml
│   ├── kubeStateMetrics-serviceMonitor.yaml
│   ├── nodeExporter-serviceMonitor.yaml
│   ├── prometheusAdapter-serviceMonitor.yaml
│   ├── prometheusOperator-serviceMonitor.yaml
│   └── prometheus-serviceMonitor.yaml
└── setup
    ├── 0alertmanagerConfigCustomResourceDefinition.yaml
    ├── 0alertmanagerCustomResourceDefinition.yaml
    ├── 0podmonitorCustomResourceDefinition.yaml
    ├── 0probeCustomResourceDefinition.yaml
    ├── 0prometheusCustomResourceDefinition.yaml
    ├── 0prometheusruleCustomResourceDefinition.yaml
    ├── 0servicemonitorCustomResourceDefinition.yaml
    ├── 0thanosrulerCustomResourceDefinition.yaml
    └── namespace.yaml

11 directories, 94 files
```

### 镜像修改

由于这个堆栈的一些镜像来自 `registry.k8s.io` 镜像仓库，国内无法访问，所以需要修改为国内的镜像。

```bash
# kube-state-metrics
$ sed -i "s,image: registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.7.0,image: registry.cn-shenzhen.aliyuncs.com/aluopyy/kube-state-metrics:v2.7.0," kube-state-metrics/kubeStateMetrics-deployment.yaml

# prometheus-adapter
$ sed -i "s,image: registry.k8s.io/prometheus-adapter/prometheus-adapter:v0.10.0,image: registry.cn-shenzhen.aliyuncs.com/aluopyy/prometheus-adapter:v0.10.0," prometheus-adapter/prometheusAdapter-deployment.yaml
```

### 数据持久化配置

kube-prometheus 默认是通过 `emptyDir` 进行挂载的，`emptyDir` 挂载的数据的生命周期和 Pod 生命周期一致，如果 Pod 挂掉了，那么数据也就丢失了，这也就是为什么我们重建 Pod 后之前的数据就没有了的原因，所以这里修改它的持久化配置。

#### Prometheus 持久化

prometheus 是使用的 StatefulSet 方式部署的，所以直接将 StorageClass 配置到 yaml 文件里面，在 `prometheus/prometheus-prometheus.yaml` 文件最下面添加持久化配置：

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  labels:
    app.kubernetes.io/component: prometheus
    app.kubernetes.io/instance: k8s
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 2.41.0
  name: k8s
  namespace: monitoring
spec:
  alerting:
    alertmanagers:
    - apiVersion: v2
      name: alertmanager-main
      namespace: monitoring
      port: web
  enableFeatures: []
  externalLabels: {}
  image: quay.io/prometheus/prometheus:v2.41.0
  nodeSelector:
    kubernetes.io/os: linux
  podMetadata:
    labels:
      app.kubernetes.io/component: prometheus
      app.kubernetes.io/instance: k8s
      app.kubernetes.io/name: prometheus
      app.kubernetes.io/part-of: kube-prometheus
      app.kubernetes.io/version: 2.41.0
  podMonitorNamespaceSelector: {}
  podMonitorSelector: {}
  probeNamespaceSelector: {}
  probeSelector: {}
  replicas: 2
  resources:
    requests:
      memory: 400Mi
  ruleNamespaceSelector: {}
  ruleSelector: {}
  securityContext:
    fsGroup: 2000
    runAsNonRoot: true
    runAsUser: 1000
  serviceAccountName: prometheus-k8s
  serviceMonitorNamespaceSelector: {}
  serviceMonitorSelector: {}
  version: 2.41.0
  # 添加如下配置
  storage:
    volumeClaimTemplate:
      spec:
        storageClassName: nfs-client-2
        resources:
          requests:
            storage: 10Gi
```

#### Grafana 持久化

由于 Grafana 是使用的 Deployment 方式部署的，所以提前为其创建一个 PVC，新建 `grafana/grafana-pvc.yaml` 文件内容如下：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana
  namespace: monitoring
spec:
  storageClassName: nfs-client-2
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

应用 `grafana/grafana-pvc.yaml` 文件，创建 PVC：

```bash
$ kubectl apply -f grafana/grafana-pvc.yaml
```

修改 `grafana/grafana-deployment.yaml` 文件持久化配置，应用上面的 PVC：

```yaml
# 将 emptyDir 修改为使用上面创建的 PVC: grafana
... ...
      volumes:
      #- emptyDir: {}
      - persistentVolumeClaim:
          claimName: grafana
        name: grafana-storage
... ...
```

## 部署 kube-prometheus

创建 namespace 和 CRDs：

```bash
$ kubectl create -f setup/
```

安装 prometheus-operator：

```
$ kubectl apply -f prometheus-operator/
```

查看 Pod，等待 pod 正常启动后再进行下一步：

```bash
$ kubectl get pod -n monitoring
NAME                                   READY   STATUS    RESTARTS   AGE
prometheus-operator-5cd6dbfd4f-r9bwf   2/2     Running   0          20h
```

安装其他组件：

```bash
$ kubectl apply -f alertmanager/
$ kubectl apply -f blackbox-exporter/
$ kubectl apply -f grafana/
$ kubectl apply -f node-exporter/
$ kubectl apply -f kube-state-metrics/
$ kubectl apply -f prometheus/
$ kubectl apply -f prometheus-adapter/
$ kubectl apply -f prometheus-rule/
$ kubectl apply -f service-monitor/
```

查看 pod 状态：

```bash
$ kubectl get pod -n monitoring 
NAME                                   READY   STATUS    RESTARTS   AGE
alertmanager-main-0                    2/2     Running   0          20h
alertmanager-main-1                    2/2     Running   0          20h
alertmanager-main-2                    2/2     Running   0          20h
blackbox-exporter-6fd586b445-crgmj     3/3     Running   0          20h
grafana-7b4c5698c8-5knnk               1/1     Running   0          20h
kube-state-metrics-745b5d8dc9-d9qq9    3/3     Running   0          20h
node-exporter-2k9f8                    2/2     Running   0          19h
... ...
node-exporter-zxsg6                    2/2     Running   0          19h
prometheus-adapter-7f957d749d-59fln    1/1     Running   0          20h
prometheus-adapter-7f957d749d-9c6n8    1/1     Running   0          20h
prometheus-k8s-0                       2/2     Running   0          20h
prometheus-k8s-1                       2/2     Running   0          20h
prometheus-operator-5cd6dbfd4f-r9bwf   2/2     Running   0          20h
```

## 使用 Ingress 暴露 Prometheus 相关服务

默认情况下，限制访问 prometheus 组件的 NetworkPolicies 被添加，修改相应的 NetworkPolicies 使 prometheus 相关组件能够被访问。

在 `prometheus/prometheus-networkPolicy.yaml`, `alertmanager/alertmanager-networkPolicy.yaml`, `grafana/grafana-networkPolicy.yaml` 文件中的相应位置添加如下内容：

```yaml
...
  ingress:
  - from:
    # 在 NetworkPolicies 中添加 Ingress 命名空间
    - namespaceSelector:
        matchLabels:
          app.kubernetes.io/name: ingress-nginx
...
```

应用更改：

```bash
$ kubectl apply -f prometheus/prometheus-networkPolicy.yaml -f alertmanager/alertmanager-networkPolicy.yaml -f grafana/grafana-networkPolicy.yaml
```

新建 `prometheus-stack-ingress.yaml` 文件内容如下：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-stack
  namespace: monitoring
  labels:
    app.kubernetes.io/name: prometheus-stack
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/affinity: cookie
spec:
  ingressClassName: nginx
  rules:
  - host: prometheus.mydomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-k8s
            port:
              number: 9090
  - host: alertmanager.mydomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: alertmanager-main
            port:
              number: 9093
  - host: grafana.mydomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
```

应用 yaml 文件，创建 ingress 资源：

```bash
$ kubectl apply -f prometheus-stack-ingress.yaml
```

查看 ingress 资源：

```bash
$ kubectl get ingress -n monitoring 
NAME               CLASS   HOSTS                                                           ADDRESS         PORTS   AGE
prometheus-stack   nginx   prometheus.mydomain.com,alertmanager.mydomain.com,grafana.mydomain.com   192.168.30.30   80      19h
```

添加域名解析测试访问。

## K8S-Prometheus 监控体系汇总

安装好 Prometheus 之后，我们就可以按照 Metrics 数据的来源，来对 Kubernetes 的监控体系做一个汇总了。

- **第一种 Metrics，是宿主机的监控数据**。这部分数据的提供，需要借助一个由 Prometheus 维护的 [Node Exporter](https://github.com/prometheus/node_exporter) 工具。一般来说，Node Exporter 会以 DaemonSet 的方式运行在宿主机上。其实，所谓的 Exporter，就是代替被监控对象来对 Prometheus 暴露出可以被“抓取”的 Metrics 信息的一个辅助进程。

  而 Node Exporter 可以暴露给 Prometheus 采集的 Metrics 数据， 也不单单是节点的负载（Load）、CPU 、内存、磁盘以及网络这样的常规信息，它的 Metrics 指标可以说是“包罗万象”，你可以查看[这个列表](https://github.com/prometheus/node_exporter#enabled-by-default)来感受一下。

- **第二种 Metrics，是来自于 Kubernetes 的 API Server、kubelet 等组件的 /metrics API**。除了常规的 CPU、内存的信息外，这部分信息还主要包括了各个组件的核心监控指标。比如，对于 API Server 来说，它就会在 /metrics API 里，暴露出各个 Controller 的工作队列（Work Queue）的长度、请求的 QPS 和延迟数据等等。这些信息，是检查 Kubernetes 本身工作情况的主要依据。

- **第三种 Metrics，是 Kubernetes 相关的监控数据**。这部分数据，一般叫作 Kubernetes 核心监控数据（core metrics）。这其中包括了 Pod、Node、容器、Service 等主要 Kubernetes 核心概念的 Metrics。

  其中，容器相关的 Metrics 主要来自于 kubelet 内置的 cAdvisor 服务。在 kubelet 启动后，cAdvisor 服务也随之启动，而它能够提供的信息，可以细化到每一个容器的 CPU 、文件系统、内存、网络等资源的使用情况。

  需要注意的是，这里提到的 Kubernetes 核心监控数据，其实使用的是 Kubernetes 的一个非常重要的扩展能力，叫作 Metrics Server。

## Troubleshooting

### prometheus-adapter: failed querying node metrics

kube-prometheus 安装后，`kubectl top nodes/pods` 停止工作。

```bash
$ kubectl get apiservice v1beta1.metrics.k8s.io
NAME                     SERVICE                         AVAILABLE   AGE
v1beta1.metrics.k8s.io   monitoring/prometheus-adapter   True        24h

$ kubectl top node
error: metrics not available yet

$ kubectl top pod -n monitoring 
error: Metrics not available for pod monitoring/alertmanager-main-0, age: 18h9m40.422618556s
```

`prometheus-adapter` log：

```bash
E0914 02:18:28.625558       1 provider.go:284] failed querying node metrics: unable to fetch node CPU metrics: unable to execute query: Get "http://prometheus-k8s.monitoring.svc:9090/api/v1/query?query=sum+by+%28node%29+%28%0A++1+-+irate%28%0A++++node_cpu_seconds_total%7Bmode%3D%22idle%22%7D%5B60s%5D%0A++%29%0A++%2A+on%28namespace%2C+pod%29+group_left%28node%29+%28%0A++++node_namespace_pod%3Akube_pod_info%3A%7Bnode%3D~%22m1%7Cw1%7Cw2%22%7D%0A++%29%0A%29%0Aor+sum+by+%28node%29+%28%0A++1+-+irate%28%0A++++windows_cpu_time_total%7Bmode%3D%22idle%22%2C+job%3D%22windows-exporter%22%2Cnode%3D~%22m1%7Cw1%7Cw2%22%7D%5B4m%5D%0A++%29%0A%29%0A&time=1663121878.624": dial tcp 10.96.221.253:9090: i/o timeout
```

遇到这个问题，可以通过添加如下 NetworkPolicy 解决：

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  labels:
    app.kubernetes.io/component: prometheus
    app.kubernetes.io/instance: k8s
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 2.41.0
  name: prometheus-k8s-adapter
  namespace: monitoring
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus-adapter
    ports:
    - port: 9090
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/component: prometheus
      app.kubernetes.io/instance: k8s
      app.kubernetes.io/name: prometheus
      app.kubernetes.io/part-of: kube-prometheus
  policyTypes:
  - Egress
  - Ingress
status: {}
```

## Reference documentation

- [Prometheus - Monitoring system & time series database](https://prometheus.io/)
- [prometheus-operator/prometheus-operator: Prometheus Operator creates/configures/manages Prometheus clusters atop Kubernetes (github.com)](https://github.com/prometheus-operator/prometheus-operator)
- [prometheus-operator/kube-prometheus: Use Prometheus to monitor Kubernetes and applications running on Kubernetes (github.com)](https://github.com/prometheus-operator/kube-prometheus)
- [Prometheus Operator - Running Prometheus on Kubernetes (prometheus-operator.dev)](https://prometheus-operator.dev/)
- [kubernetes-sigs/prometheus-adapter: An implementation of the custom.metrics.k8s.io API using Prometheus (github.com)](https://github.com/kubernetes-sigs/prometheus-adapter)
- [blog-example/Kubernetes/k8s-kube-promethues at master · zuozewei/blog-example (github.com)](https://github.com/zuozewei/blog-example/tree/master/Kubernetes/k8s-kube-promethues)
- [《 深入剖析 Kubernetes 》](https://time.geekbang.org/column/article/72281)
- [Update network policy to get metrics from adapter by gabrielb77 · Pull Request #1870 · prometheus-operator/kube-prometheus (github.com)](https://github.com/prometheus-operator/kube-prometheus/pull/1870)
- [prometheus-adapter: failed querying node metrics · Issue #1764 · prometheus-operator/kube-prometheus (github.com)](https://github.com/prometheus-operator/kube-prometheus/issues/1764)

