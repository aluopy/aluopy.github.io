---
title: "keepalived 双主模式"
excerpt: ""
toc: false
toc_label: "keepalived 双主模式"
toc_icon: "cog"
categories: keepalived
tags:
  - keepalived
---

**keepalived 安装**

```shell
$ yum -y install keepalived
```

**keepalived 双主配置**

```
# A主机配置
global_defs {
      router_id a_nginx  #主机标识
}
vrrp_script chk_http_port {
script "/etc/keepalived/check_nginx.sh"   #检测脚本
interval 2
}
vrrp_instance a_nginx_vip01 {
      state MASTER    #身份未master
      interface bond1  #网卡
      virtual_router_id 180  #虚拟路由的id
      priority 100    #优先级
      advert_int 1   #同步状态检查的时间间隔
      authentication {             #配置授权，方式为明文密码
            auth_type PASS
            auth_pass wangpu123
      } 
      virtual_ipaddress {        #配置vip的地址
            10.16.16.206/20
      }
      unicast_src_ip 10.16.16.12       #关闭组播，使用单播通信，源ip为10.16.16.12
      unicast_peer {       #对端ip为10.16.16.13
            10.16.16.13
      }
track_script {            #检测脚本
       chk_http_port
}
}
vrrp_instance a_nginx_vip02 {
      state BACKUP
      interface bond1
      virtual_router_id 181
      priority 99
      advert_int 1
      authentication {
            auth_type PASS
            auth_pass wangpu123
      }
      virtual_ipaddress {
            10.16.16.207/20
      }
      unicast_src_ip 10.16.16.12
      unicast_peer {
            10.16.16.13
      }
track_script {
       chk_http_port
}
}

# B主机配置
global_defs {
      router_id b_nginx
}
vrrp_script chk_http_port {
script "/etc/keepalived/check_nginx.sh"
interval 2
}
vrrp_instance a_nginx_vip01 {
      state BACKUP
      interface bond1
      virtual_router_id 180
      priority 99
      advert_int 1
      authentication {
            auth_type PASS
            auth_pass wangpu123
      }
      virtual_ipaddress {
            10.16.16.206/20
      }
      unicast_src_ip 10.16.16.13
      unicast_peer {
            10.16.16.12
      }
track_script {
       chk_http_port
}
}
vrrp_instance a_nginx_vip02 {
      state  MASTER
      interface bond1
      virtual_router_id 181
      priority 100
      advert_int 1
      authentication {
            auth_type PASS
            auth_pass wangpu123
      }
      virtual_ipaddress {
            10.16.16.207/20
      }
      unicast_src_ip 10.16.16.13
      unicast_peer {
            10.16.16.12
      }
track_script {
       chk_http_port
}
}
```

