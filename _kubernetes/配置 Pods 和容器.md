---
title: "配置 Pods 和容器"
excerpt: "本文展示如何将内存请求（request）和内存限制（limit）分配给一个容器。我们保障容器拥有它请求数量的内存，但不允许使用超过限制数量的内存。"
toc: true
toc_label: "配置 Pods 和容器"
toc_icon: "cog"
categories: Kubernetes
tags:
  - kubernetes
  - pod
  - Container
---

## 为容器和 Pod 分配内存资源