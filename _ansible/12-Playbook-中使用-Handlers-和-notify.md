---
title: "Playbook 中使用 Handlers 和 notify"
permalink: /ansible/playbook-handlers-notify/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

Handlers 本质是 task list，类似于 MySQL 中的触发器触发的行为，其中的 task 与前述的 task 并没有本质上的不同，主要用于当关注的资源发生变化时，才会采取一定的操作。而 Notify 对应的 action 可用于在每个 play 的最后被触发，这样可避免多次有改变发生时每次都执行指定的操作，仅在所有的变化发生完成后一次性地执行指定操作。在 notify 中列出的操作成为 handler，也即 notify 中调用 handler 中定义的操作。

案例1：

```yaml
- hosts: websrvs
  remote_user: root

  tasks:
    - name: Install httpd
      yum: name=httpd state=present
    - name: Install configure file
      copy: src=files/httpd.conf dest=/etc/httpd/conf/
      notify: restart httpd
    - name: ensure apache is running
      service: name=httpd state=started enabled=yes
  
  handlers:
    - name: restart httpd
      service: name=httpd state=restarted
```

案例2：

```yaml
- hosts: webnodes
  vars:
    http_port: 80
    max_clients: 256
  remote_user: root
  
  tasks:
    - name: ensure apache is at the latest version
      yum: name=httpd state=latest
    - name: ensure apache is running
      service: name=httpd state=started
    - name: Install configure file
      copy: src=files/httpd.conf dest=/etc/httpd/conf/
      notify: restart httpd
  
  handlers:
      - name: restart httpd 
        service: name=httpd state=restarted
```

案例3：

```yaml
- hosts: websrvs
  remote_user: root
  
  tasks:
    - name: add group nginx
      tags: user
      user: name=nginx state=present
    - name: add user nginx
      user: name=nginx state=present group=nginx
    - name: Install Nginx
      yum: name=nginx state=present
    - name: config
      copy: src=/root/config.txt dest=/etc/nginx/nginx.conf
      notify:
        - Restart Nginx
        - Check Nginx Process
  
  handlers:
    - name: Restart Nginx
      service: name=nginx state=restarted enabled=yes
    - name: Check Nginx process
      shell: killall -0 nginx > /tmp/nginx.log
```

