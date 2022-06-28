---
title: "Troubleshooting"
permalink: /ansible/troubleshooting/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

## Ansible 节点过多超时解决方法

Ansible 管理的节点过多导致的超时问题解决方法：默认情况下，Ansible 将尝试并行管理 playbook 中所有的机器。对于滚动更新用例，可以使用 serial 关键字定义 Ansible 一次应管理多少主机，还可以将 serial 关键字指定为百分比，表示每次并行执行的主机数占总数的比例。

示例：

```yaml
# vim test_serial.yml
---
- hosts: all
  serial: 2  # 每次只同时处理2个主机
  gather_facts: False

  tasks:
    - name: task one
      comand: hostname
    - name: task two
      command: hostname
```

示例：

```yaml
- name: test serail
  hosts: all
  serial: "20%"  # 每次只同时处理20%的主机
```

