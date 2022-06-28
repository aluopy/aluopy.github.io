---
title: "Playbook 中使用 tags 组件"
permalink: /ansible/playbook-tags/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

在 playbook 文件中，可以利用 tags 组件为特定的 task 指定标签，当在执行 playbook 时，可以选择只执行特定 tags 的 task ，而非整个 playbook 文件。多个 task 可以使用同一个 tags 。

示例：

```yaml
- hosts: websrvs
  remote_user: root
  gather_facts: no
  
  tasks:
    - name: Install httpd
      yum: name=httpd state=present
      tags: install 
    - name: Install configure file
      copy: src=files/httpd.conf dest=/etc/httpd/conf/
      tags: conf
    - name: start httpd service
      tags: service
      service: name=httpd state=started enabled=yes
```

指定执行 `conf`、`service` 两个 tags 的 task

```shell
$ ansible-playbook –t conf,service httpd.yml
```

