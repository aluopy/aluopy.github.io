---
title: "Playbook 命令"
permalink: /ansible/playbook-command/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

格式：`ansible-playbook <filename.yml> ... [options]`

常见选项：

```shell
-C --check          # 只检测可能会发生的改变，但不真正执行操作
--list-hosts        # 列出运行任务的主机
--list-tags         # 列出 tag
--list-tasks        # 列出 task
--limit HostList    # 只针对主机列表 HostList 中的主机执行
-v -vv  -vvv        # 显示过程
```

示例：

```shell
$ ansible-playbook  file.yml  --check   # 只检测
$ ansible-playbook  file.yml  
$ ansible-playbook  file.yml  --limit websrvs
```
