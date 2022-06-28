---
title: "Playbook 介绍"
permalink: /ansible/playbook-intro/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

playbook 剧本是由一个或多个 “play” 组成的列表。
play 的主要功能在于将预定义的一组主机，装扮成事先通过 ansible 中的 task 定义好的角色。Task 实际是调用 ansible 的一个 module，将多个 play 组织在一个playbook中，即可以让它们联合起来，按事先编排的机制执行预定义的动作。
Playbook 文件是采用YAML语言编写的。