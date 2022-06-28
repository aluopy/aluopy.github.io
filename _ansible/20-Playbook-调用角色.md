---
title: "Playbook 调用角色"
permalink: /ansible/roles-in-playbook/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

**调用角色方法1：**

```yaml
---
- hosts: websrvs
  remote_user: root
  roles:
    - mysql
    - memcached
    - nginx   
```

**调用角色方法2：**

键 role 用于指定角色名称，后续的 k/v 用于传递变量给角色

```yaml
---
- hosts: all
  remote_user: root
  roles:
    - mysql
    - { role: nginx, username: nginx }
```

**调用角色方法3：**

还可基于条件测试实现角色调用

```yaml
---
- hosts: all
  remote_user: root
  roles:
    - { role: nginx, username: nginx, when: ansible_distribution_major_version == ‘7’  }
```

