---
title: "Kubernetes Knowledge Graph"
excerpt: "Kubernetes 知识图谱。"
toc: true
categories: Kubernetes
tags:
  - kubernetes
---

## 进阶指南

### 组件

#### 核心组件

- [etcd](https://etcd.io/docs/)

- [kube-apiserver](https://www.kubernetes.org.cn/3119.html)

- kube-controller-manager

- kube-scheduler

- kube-proxy

- docker

#### 附加组件

- DNS

  - [kube-dns](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/dns)
  - [coredns](https://github.com/coredns/deployment/tree/master/kubernetes)

- Ingress Controller

  - [traefik](https://docs.traefik.io/user-guide/kubernetes/)
  - [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx)
  - [Nginx Plus](https://github.com/nginxinc/kubernetes-ingress)
  - [HAProxy Ingress](https://github.com/jcmoraisjr/haproxy-ingress)
  - [AppsCode Voyager](https://appscode.com/products/voyager/)
  - [contour](https://github.com/heptio/contour)
  - [Cloudflare Warp Ingress](https://github.com/cloudflare/cloudflare-ingress-controller)
  - [F5 Big IP Controller](https://github.com/F5Networks/k8s-bigip-ctlr)
  - [Gloo](https://github.com/solo-io/gloo)
  - [gRPC Load balancing](https://github.com/soeirosantos/nginx-k8s-grpc)
  - [Kong](https://github.com/Kong/kubernetes-ingress-controller)
  - [nghttpx Ingress Controller](https://github.com/zlabjp/nghttpx-ingress-lb)
  - [Ambassador](https://www.getambassador.io/)
  - [Skipper](https://opensource.zalando.com/skipper/)

- [Heapster](https://github.com/kubernetes/heapster)

- [Dashboard](https://github.com/kubernetes/dashboard)

- [Kubernator](https://github.com/smpio/kubernator)

- [Federation](https://kubernetes.io/docs/concepts/cluster-administration/federation/)

- [eventrouter](https://github.com/heptiolabs/eventrouter)

  event 持久化

### 资源对象

#### [Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod/)

- [Init Container](https://k8smeetup.github.io/docs/concepts/workloads/pods/init-containers/)
- [Pod Security Policy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)
- [Pod Lifecycle](https://k8smeetup.github.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [Pod Hook](https://k8smeetup.github.io/docs/concepts/containers/container-lifecycle-hooks/)
- [Pod Preset](https://kubernetes.io/docs/concepts/workloads/pods/podpreset/)
- [Disruption](https://k8smeetup.github.io/docs/concepts/workloads/pods/disruptions/)
- [Resource Quota](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [liveness 和 readiness](https://kubernetes.io/zh/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

#### 集群配置

- [Node](https://kubernetes.io/docs/concepts/architecture/nodes/)
- [Namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Label](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/labels/)
- [Annotation](https://kubernetes.io/zh/docs/concepts/overview/working-with-objects/annotations/)
- [Taint 和 Toleration](https://kubernetes.io/zh/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [亲和性（Affinity）和反亲和性（anti-affinity）](https://kubernetes.io/zh/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/)
- [Garbage Collection](https://kubernetes.io/zh/docs/concepts/architecture/garbage-collection/)

#### 控制器

- [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

- [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)

- [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

- [ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)

- [Job](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/)

- [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

- [cron-hpa-controller](https://github.com/hex108/cron-hpa-controller)

  定时弹性伸缩

- [Escalator](https://github.com/atlassian/escalator)

  自动横向扩展

#### 服务发现

- [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

#### 身份与权限控制

- [Service Account](https://kubernetes.io/docs/admin/service-accounts-admin/)
- [Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
  - [kubernetes-network-policy-recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes)
- [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [RBAC](https://k8smeetup.github.io/docs/admin/authorization/rbac/)

#### 存储配置

- [Secret](https://kubernetes.io/docs/concepts/configuration/secret/)
- [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
- [Volume](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Local Volume](https://kubernetes.io/docs/concepts/storage/volumes/#local)
- [Storage Class](https://k8smeetup.github.io/docs/concepts/storage/storage-classes/)
- [Stork](https://github.com/libopenstorage/stork)

#### API 扩展

- [CustomResourceDefinition](https://kubernetes.io/docs/concepts/api-extension/custom-resources/)

- [Operator](https://coreos.com/operators/)

  - [awesome-operators](https://github.com/operator-framework/awesome-operators)

  - [Prometheus](https://github.com/coreos/prometheus-operator)

    - [ops-kube-alerting-rules-operator](https://github.com/MYOB-Technology/ops-kube-alerting-rules-operator) 【链接失效】

  - [Confluent Operator](https://www.confluent.io/confluent-operator/)

  - Kong API

  - [Kubernetes Operators](https://github.com/sapcc/kubernetes-operators)

  - [K8s Operator Workshop](https://github.com/lukebond/cc-au-k8s-operators-workshop)

  - [Cert Operator](https://github.com/giantswarm/cert-operator)

  - [Cert manager](https://github.com/kelseyhightower/kube-cert-manager)

  - [Operator Kit](https://github.com/rook/operator-kit)

  - [Container Linux Update Operator](https://github.com/coreos/container-linux-update-operator)

  - [DB Operator](https://github.com/k8sdb/operator)

  - [etcd](https://github.com/coreos/etcd-operator)

  - [Elasticsearch](https://github.com/upmc-enterprises/elasticsearch-operator)

  - [Memcached](https://github.com/kbst/memcached)

  - [MongoDB](https://github.com/kbst/mongodb)

  - [MySQL Operator](https://github.com/oracle/mysql-operator)

  - [PostgreSQL](https://github.com/CrunchyData/postgres-operator)

  - [Another PostgreSQL](https://github.com/zalando-incubator/postgres-operator)

  - [Kafka](https://github.com/krallistic/kafka-operator)

  - [Envoy Operator](https://github.com/solo-io/envoy-operator)

  - [rbac-manager](https://github.com/reactiveops/rbac-manager)

  - [Akrobateo](https://github.com/kontena/akrobateo)

    load balancer

- [Aggregated API Server](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/api-machinery/aggregated-api-servers.md)

- [custom-metrics-apiserver-ingress-nginx](https://github.com/isotoma/custom-metrics-apiserver-ingress-nginx)

- [metacontroller](https://github.com/GoogleCloudPlatform/metacontroller)

### 部署配置

- 单机部署

  - [minikube](https://github.com/kubernetes/minikube)

  - [kubeasz](https://github.com/gjmzj/kubeasz/blob/master/docs/quickStart.md)

  - [Sealos](https://github.com/fanux/sealos)

    一条命令安装所有依赖 👋

- 集群部署

  - [Sealos](https://github.com/fanux/sealos)

    一条命令部署 Kubernetes 高可用集群 👋

  - [Breeze](https://github.com/wise2c-devops/playbook) 【链接失效】

  - [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/)

  - [Kubespray](https://github.com/kubernetes-incubator/kubespray)

  - [LinuxKit](https://github.com/linuxkit/kubernetes)

  - [kubeasz](https://github.com/gjmzj/kubeasz)

- [部署 Windows 节点](https://kubernetes.io/zh/docs/tasks/administer-cluster/kubeadm/adding-windows-nodes/)

  v1.9 开始升级为 beta 版

- [Kubernetes on Azure](https://docs.microsoft.com/zh-cn/azure/aks/)

### 插件扩展

- CNI

  - [Flannel](https://github.com/coreos/flannel)

  - [Weave Net](https://github.com/weaveworks/weave)

  - [Contiv](https://contiv.github.io/)

  - [Calico](https://www.projectcalico.org/)

  - [OVN](https://github.com/openvswitch/ovn-kubernetes)

  - [SR-IOV](https://github.com/Intel-Corp/sriov-cni)

  - [Romana](https://github.com/romana/romana)

  - [OpenContrail](https://github.com/michaelhenkel/opencontrail-cni-plugin)

  - [Canal](https://github.com/projectcalico/canal)

  - [kuryr-kubernetes](https://github.com/openstack/kuryr-kubernetes)

  - [Cilium](https://github.com/cilium/cilium)

  - [CNI-Genie](https://github.com/Huawei-PaaS/CNI-Genie)

    华为 PaaS 团队推出

  - [Kube-router](http://github.com/cloudnativelabs/kube-router)

  - [Nuage](https://github.com/nuagenetworks/nuage-kubernetes)

  - [Multus-cni](https://github.com/Intel-Corp/multus-cni)

  - [Virtlet](https://github.com/Mirantis/virtlet)

    虚拟机

- [CSI](https://kubernetes.io/docs/concepts/storage/volumes/#csi)

  Kubernetes 1.9 引入

  - [Ceph](https://github.com/ceph/ceph-csi)

- [CRI](https://www.yangcs.net/posts/container-runtime/)

  - Docker
  - [HyperContainer](https://github.com/kubernetes/frakti)
  - [Runc](https://github.com/opencontainers/runc)
    - [cri-containerd](https://github.com/containerd/cri)
    - [cri-o](https://www.yangcs.net/posts/cri-o/)
  - [gVisor](https://github.com/google/gvisor)
  - [Rkt](https://github.com/kubernetes-incubator/rktlet)
  - [Mirantis](https://github.com/Mirantis/virtlet)
  - [Infranetes](https://github.com/apporbit/infranetes)

- [Scheduler 扩展](https://kubernetes.io/docs/concepts/overview/extending/#scheduler-extensions)

  - [Sticky Node Scheduler](https://github.com/philipn/kubernetes-sticky-node-scheduler)
  - [ksched](https://github.com/coreos/ksched)
  - [kube-node-index-prioritizing-scheduler](https://github.com/mumoshu/kube-node-index-prioritizing-scheduler)

- [Device 插件](https://kubernetes.io/docs/concepts/cluster-administration/device-plugins/)

- [keepalived-vip](https://github.com/aledbf/kube-keepalived-vip)

- [External DNS](https://github.com/kubernetes-incubator/external-dns)

- [kubevirt](https://github.com/kubevirt/kubevirt)

  - [Helm](https://helm.sh/)
    - [Helmfile](https://github.com/roboll/helmfile)
  - Service mesh
    - [Istio](https://istio.io/)
      - Envoy
        - 文档
          - [LearnEnvoy](https://www.learnenvoy.io/)
          - [Envoy 官方文档中文版](https://servicemesher.github.io/envoy/)
          - [Envoy 官方文档](https://www.envoyproxy.io/docs/envoy/latest)
        - 大牛
      - 工具
        - [Fortio](https://github.com/istio/fortio)
        - [outlier-istio](https://github.com/hekike/outlier-istio)
    - [Linkerd](https://linkerd.io/)
    - [Conduit](https://conduit.io/)
  - 持续集成
    - [Jenkins](https://jenkins.io/)
    - [Drone](https://drone.io/)
    - [Apollo](https://github.com/logzio/apollo)
  - CI/CD
    - [Skaffold](https://github.com/GoogleCloudPlatform/skaffold)
    - [Jenkins X](http://jenkins-x.io/)
    - [Spinnaker](https://www.spinnaker.io/)
    - [Kubernetes Pipeliner](https://github.com/namely/k8s-pipeliner)
    - [Draft](https://draft.sh/)
    - [Forge](https://forge.sh/)
    - [Flux](https://www.weave.works/oss/flux/)
    - [GitKube](https://gitkube.sh/)
    - [KubeCI](https://www.kubeci.io/)
    - [Keel](https://github.com/keel-hq/keel)
    - [Brigade](https://docs.brigade.sh/)
  - [Kompose](http://kompose.io/)
  - 灰度发布
    - [Shipper](https://github.com/bookingcom/shipper)

### 服务治理

## Kubernetes 周边项目

### 客户端

#### 桌面客户端

- [Lens](https://fuckcloudnative.io/posts/lens/)

  力荐！

- [Kubernetic](https://kubernetic.com/)

#### 移动客户端

- [Cabin](https://github.com/bitnami/cabin)

- [Kubenav](https://github.com/kubenav/kubenav)

  力荐！

### Dashboard

- [KubeSphere](https://github.com/kubesphere/kubesphere)
- [Kuboard](https://kuboard.cn/)
- [K8Dash](https://github.com/herbrandson/k8dash)
- [Octant](https://github.com/vmware/octant)
- [fist](https://github.com/fanux/fist)
- [konstellate](https://github.com/containership/konstellate)

### 多集群管理

- [KubeSphere](https://github.com/kubesphere/kubesphere)
- [Gardener](https://gardener.cloud/)
- [Aptomi](https://github.com/Aptomi/aptomi)

### 大数据与机器学习

- [Spark](https://github.com/kweisamx/spark-on-kubernetes)
- [Kubeflow](https://github.com/kubeflow/kubeflow)
- [mxnet-operator](https://github.com/deepinsight/mxnet-operator)
- [seldon-core](https://github.com/SeldonIO/seldon-core)
- [FfDL](https://github.com/IBM/FfDL)

### Serverless 架构

- [OpenFaaS](https://github.com/openfaas/faas)
- [FaaS-netes](https://github.com/openfaas/faas-netes)
- [Funktion](https://github.com/fabric8io/funktion)
- [Fission](https://github.com/fabric8io/funktion)
- [Kubeless](https://github.com/skippbox/kubeless)
- [OpenWhisk](https://github.com/openwhisk)
- [Iron.io](https://www.iron.io/)
- [Nuclio](https://github.com/nuclio/nuclio)
- [Virtual Kubelet](https://github.com/virtual-kubelet/virtual-kubelet)

### PaaS 平台

- [KubeSphere](https://github.com/kubesphere/kubesphere)
- [Rancher](https://rancher.com/)
- [Openshift Origin](http://www.openshift.org/)
- [Kel](http://www.kelproject.com/)
- [IBM Bluemix Container Service](https://www.ibm.com/cloud/container-service)
- [Hasura](https://hasura.io/)
- [teresa](https://github.com/luizalabs/teresa)

### 企业级产品

- [CoreOS Tectonic](https://coreos.com/tectonic/)
- [OpenShift - Container Platform](http://www.openshift.com/container-platform/index.html)
- [SUSE Container as a Service](http://www.suse.com/betaprogram/caasp-beta/)
- [Canonical Distribution of Kubernetes - CDK](https://www.ubuntu.com/kubernetes)

### 命令行工具

- [click](https://github.com/databricks/click)

- [kubeman](https://github.com/walmartlabs/kubeman)

  kubectl 替代品

- [kube-prompt](https://github.com/c-bata/kube-prompt)

  交互式命令行工具

- [Kube-shell](https://github.com/cloudnativelabs/kube-shell)

  交互式命令行工具

- [Kubebot](https://github.com/harbur/kubebot)

- [kubectx](https://github.com/ahmetb/kubectx/)

  快速切换上下文环境

- [kubens](https://github.com/ahmetb/kubectx/blob/master/kubens)

  快速切换 namespace

- [StackStorm](https://github.com/StackStorm/st2)

  StackStorm（又名“IFTTT for Ops”）是用于自动修复、安全响应、故障排除、部署等的事件驱动自动化。包括规则引擎、工作流、具有 6000 多个操作的 160 个集成包

- [kubectld](https://github.com/rancher/kubectld)

  暴露 kubectl create/apply/get 逻辑的简单到令人尴尬的微服务

- [Kubectl Aliases](https://github.com/ahmetb/kubectl-aliases)

  以编程的方式生成方便的 kubectl 别名

- [Vikube](https://github.com/c9s/vikube.vim)

  在 vim 中操作 Kubernetes

- [kube-ps1](https://github.com/jonmosco/kube-ps1)

  shell 提示信息

- [kube-tmux](https://github.com/jonmosco/kube-tmux)

- [kubensx](https://github.com/shyiko/kubensx)

  快速切换上下文环境

- [Kubetail](https://github.com/johanhaleby/kubetail)

  查看多个容器日志

- [stern](https://github.com/wercker/stern)

  查看多个容器日志

- [kubeval](https://github.com/garethr/kubeval)

  yaml 和 json 语法检查

- [Kube YAML validations](https://learnk8s.io/validating-kubernetes-yaml)

  yaml 语法在线检查

- [ksort](http://github.com/superbrothers/ksort)

  按照类型对 yaml 排序

- [Ksd](https://github.com/ashleyschuett/kubernetes-secret-decode)

  解码 Secret

- [kubectl-service-plugin](https://github.com/superbrothers/kubectl-service-plugin)

- [kubectl-plugins](https://github.com/jordanwilson230/kubectl-plugins)

  插件大全

- 简化 kubernetes 部署定义
  - [Kedge](http://kedgeproject.org/)
  - [Koki Short](https://docs.koki.io/short/)
  
- [Kustomize](https://github.com/kubernetes-sigs/kustomize)

  定制 yaml

- [kube-score](https://github.com/zegl/kube-score)

  分析资源对象并提出改进建议

- [kubespy](https://github.com/pulumi/kubespy)

  实时观察资源变化

- [kube-capacity](https://github.com/robscott/kube-capacity)

  查看资源请求与限制

### 监控项目

- [Datadog](http://www.datadoghq.com/)

- [Node Problem Detector](https://github.com/kubernetes/node-problem-detector#start-daemonset)

- [eventrouter](https://github.com/heptiolabs/eventrouter)

  将 events 转发到指定的接收器

- [Grafana Kubernetes App](https://github.com/grafana/kubernetes-app)

- [Heapster](https://github.com/kubernetes/heapster)

- [Kubernetes Operational View](https://github.com/hjacobs/kube-ops-view)

- [Kubewatch](https://github.com/bitnami-labs/kubewatch)

- [Prometheus](http://prometheus.io/)
  
  - [thanos](https://github.com/improbable-eng/thanos)
  
    高可用
  
- [Loki](https://github.com/grafana/loki)

  日志

- [Sysdig Monitoring](https://sysdig.com/)

- [Weave Scope](http://www.weave.works/products/weave-scope/)

- [Cockpit](http://cockpit-project.org/guide/latest/feature-kubernetes.html)

- [Searchlight](https://github.com/appscode/searchlight)

- [IngressMonitorController](https://github.com/stakater/IngressMonitorController)

### 测试

- [k8s-testsuite](https://github.com/mrahbar/k8s-testsuite)

  网络和负载测试

- [Test-Infra](https://github.com/kubernetes/test-infra)

- [Sonobuoy](https://github.com/heptio/sonobuoy)

- [PowerfulSeal](https://github.com/bloomberg/powerfulseal)

  杀死目标 Pod 和机器来测试你的软件可靠性

- [Kubesquash](https://github.com/solo-io/kubesquash)

  debug 工具

- [Kubectl-debug](https://github.com/aylei/kubectl-debug)

  debug 工具

- [kboom](https://github.com/mhausenblas/kboom)

  压测

### 自愈合

- [Node-problem-detector](https://github.com/kubernetes/node-problem-detector)

  检测集群问题

- [Draino](https://github.com/negz/draino)

  根据节点状态自动剔除 Kubernetes 节点

- [K8s-cleanup](https://github.com/onfido/k8s-cleanup)

  清理集群资源

- [Remediation Collection](https://kubedex.com/collection/remediation/)

  修复工具集合

## Kubernetes 素材

### 书籍

- [Kubernetes 权威指南](https://book.douban.com/subject/26902153/)
- [Kubernetes Cookbook](https://www.packtpub.com/virtualization-and-cloud/kubernetes-cookbook-second-edition)
- [DevOps with Kubernetes](https://www.packtpub.com/virtualization-and-cloud/devops-kubernetes)
- 免费电子书
  - [kubernetes handbook](https://jimmysong.io/kubernetes-handbook/)
  - [Kubernets 指南](https://legacy.gitbook.com/book/feisky/kubernetes/details)
  - [Istio 官方文档中文版](https://legacy.gitbook.com/book/doczhcn/istio/details)
  - [SDN 网络指南](https://legacy.gitbook.com/book/feisky/sdn/details)
  - [Helm 用户指南](https://whmzsu.github.io/helm-doc-zh-cn/)

### 视频

- [使用 Kubernetes 进行可扩展微服务](https://cn.udacity.com/course/scalable-microservices-with-kubernetes--ud615)
- [IBM Cloud: Deploying Microservices with Kubernetes](https://www.coursera.org/learn/deploy-micro-kube-ibm-cloud)
- [Kubernetes 中基于策略的资源分配](https://www.kubernetes.org.cn/2902.html)
- [使用 client-go 控制原生及拓展的 Kubernetes API](https://www.kubernetes.org.cn/1283.html)
- [Introduction to Kubernetes](https://www.edx.org/course/introduction-to-kubernetes)

### 系列教程

- [Kubernetes Tutorials by Kubernetes Team](http://kubernetes.io/docs/tutorials/)
- [Kubernetes By Example by OpenShift Team](http://kubernetesbyexample.com/)
- [Kubernetes Tutorial by Tutorialspoint](http://www.tutorialspoint.com/kubernetes/)
- [Kubernetes integration with Spring Cloud](https://github.com/spring-cloud-incubator/spring-cloud-kubernetes)

### 在线实验环境

- [Katacoda](https://www.katacoda.com/courses/kubernetes)
- [Kubernetes Bootcamp](https://kubernetesbootcamp.github.io/kubernetes-bootcamp/)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)
- [Redhat 提供的 Istio 在线交互式教学](https://learn.openshift.com/servicemesh)

### 博客

- [云原生实验室](https://fuckcloudnative.io/)
- [Kubernetes Blog](https://kubernetesbootcamp.github.io/kubernetes-bootcamp/)
- [Tony Bai](https://tonybai.com/)
- [伪架构师](http://blog.fleeto.us/)

## Kubernetes 社区

- [KubeSphere 中文社区](https://kubesphere.com.cn/)

- [Kubernetes 中文社区](https://www.kubernetes.org.cn/)

- [Istio 中文社区](http://www.servicemesh.cn/?/topic/Istio)
- [KubeWeekly](http://kube.news/)
- [Stackoverflow](https://stackoverflow.com/questions/tagged/kubernetes)
- [Kubernetes 论坛](https://discuss.kubernetes.io/)
- 邮件列表
  - [user discussion and Q&A](https://groups.google.com/forum/#!forum/kubernetes-users)
  - [developer/contributor discussion](https://groups.google.com/forum/#!forum/kubernetes-dev)
- 会议
  - [Kubecon](http://events.linuxfoundation.org/events/kubecon)
  - [Container Camp](http://container.camp/)
  - [GCP Next](http://cloudnext.withgoogle.com/)
  - [Docker Con](http://dockercon.com/)
  - [Devoxx](http://devoxx.com/)
  - [ContainerDays](https://containerdays.io/)

## 原文链接

[云原生实验室 - Kubernetes\|Docker\|Istio\|Envoy\|Hugo\|Golang\|云原生 (icloudnative.io)](https://icloudnative.io/)