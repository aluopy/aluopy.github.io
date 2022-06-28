---
title: "Ansible Automation"
permalink: /ansible/ansible-automation/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---

**ProTip:**  本书笔记根据[马哥教育](https://www.magedu.com/)发布的《[运维自动化之 Ansible](https://www.bilibili.com/video/BV1HZ4y1p7Bf?spm_id_from=333.999.0.0&vd_source=e719fc442af42e83e26536b3b52e620c)》视频教程整理而来✨
{: .notice--info}

本书内容大纲：

- **运维自动化发展历程及技术应用**
- **Ansible 命令使用**
- **Ansible 常用模块详解**
- **YAML 语法简介**
- **Ansible playbook 基础**
- **Playbook 变量、tags、handlers 使用**
- **Playbook 模板 templates**
- **Playbook 条件判断 when**
- **Playbook 字典 with_items**
- **Ansible Roles**

## 自动化运维应用场景

### 云计算运维工程师核心职能

![](https://aluopy.github.io/assets/images/ansible-01.png)
![](https://aluopy.github.io/assets/images/ansible-02.jpg)
![](https://aluopy.github.io/assets/images/ansible-03.jpg)
**相关工具**

- 代码管理（SCM）：GitHub、GitLab、BitBucket、SubVersion
- 构建工具：maven、Ant、Gradle
- 自动部署：Capistrano、CodeDeploy
- 持续集成（CI）：Jenkins、Travis
- 配置管理：Ansible、SaltStack、Chef、Puppet
- 容器：Docker、Podman、LXC、第三方厂商如 AWS
- 编排：Kubernetes、Core、Apache Mesos
- 服务注册与发现：Zookeeper、etcd、Consul
- 脚本语言：python、ruby、shell
- 日志管理：ELK、Logentries
- 系统监控：Prometheus、Zabbix、Datadog、Graphite、Ganglia、Nagios
- 性能监控：AppDynamics、New Relic、Splunk
- 压力测试：JMeter、Blaze Meter、loader.io
- 应用服务器：Tomcat、JBoss、IIS
- Web服务器：Apache、Nginx
- 数据库：MySQL、Oracle、PostgreSQL 等关系型数据库；mongoDB、redis 等 NoSQL 数据库
- 项目管理（PM）：Jira、Asana、Taiga、Trello、Basecamp、Pivotal Tracker

### 运维职业发展路线

![](https://aluopy.github.io/assets/images/ansible-04.jpg) 

**运维的未来是什么？**
**一切皆自动化**

“运维的未来是，让研发人员能够借助工具、自动化和流程，并且让他们能够在运维干预极少的情况下部署和运营服务，从而实现自助服务。每个角色都应该努力使工作实现自动化。”——《运维的未来》

### 企业实际应用场景分析

![](https://aluopy.github.io/assets/images/ansible-05.png) 

#### Dev开发环境

使用者：程序员
功能：程序员个人的办公电脑或项目的开发测试环境，部署开发软件，测试个人或项目整体的 BUG 的环境
管理者：程序员

#### 测试环境

使用者：QA 测试工程师
功能：测试经过 Dev 环境测试通过的软件的功能和性能，判断是否达到项目的预期目标，生成测试报告
管理者：运维
说明：测试环境往往有多套,测试环境满足测试功能即可，不宜过多
1、测试人员希望测试环境有多套,公司的产品多产品线并发，即多个版本，意味着多个版本同步测试
2、通常测试环境有多少套和产品线数量保持一样

#### 预发布环境

使用者：运维
功能：使用和生产环境一样的数据库，缓存服务等配置，测试是否正常

#### 发布环境

包括代码发布机，有些公司为堡垒机（安全屏障）
使用者：运维
功能：发布代码至生产环境
管理者：运维（有经验）
发布机：往往需要有2台（主备）

#### 生产环境

使用者：运维，少数情况开放权限给核心开发人员，极少数公司将权限完全开放给开发人员并其维护
功能：对用户提供公司产品的服务
管理者：只能是运维
生产环境服务器数量：一般比较多，且应用非常重要。往往需要自动工具协助部署配置应用

#### 灰度环境

属于生产环境的一部分
使用者：运维
功能：在全量发布代码前将代码的功能面向少量精准用户发布的环境,可基于主机或用户执行灰度发布
案例：共100台生产服务器，先发布其中的10台服务器，这10台服务器就是灰度服务器
管理者：运维
灰度环境：往往该版本功能变更较大，为保险起见特意先让一部分用户优化体验该功能，待这部分用户使用没有重大问题的时候，再全量发布至所有服务器。

### 程序发布

**程序发布要求：**
不能导致系统故障或造成系统完全不可用
不能影响用户体验

**预发布验证：**
新版本的代码先发布到服务器（跟线上环境配置完全相同，只是未接入到调度器）

**灰度发布：**
基于主机，用户，业务

**发布路径：**
`/webapp/tuangou`
`/webapp/tuangou-1.1`
`/webapp/tuangou-1.2`

**发布过程：**

1. 在调度器上下线一批主机(标记为 maintenance 状态)
2. 关闭服务
3. 部署新版本的应用程序
4. 启动服务
5. 在调度器上启用这一批服务器

**自动化灰度发布：**

- 脚本
- 发布平台

### 自动化运维应用场景

- 文件传输
- 应用部署
- 配置管理
- 任务流编排

### 常用自动化运维工具

- **Ansible：**python，Agentless，中小型应用环境
- **Saltstack：**python，一般需部署 agent，执行效率更高
- **Puppet：**ruby, 功能强大，配置复杂，重型，适合大型环境
- **Fabric：**python，agentless
- **Chef：**ruby，国内应用少
- **Cfengine**
- **func**

## Ansible 介绍和架构

公司计划在年底做一次大型市场促销活动，全面冲刺下交易额，为明年的上市做准备。公司要求各业务组对年底大促做准备，运维部要求所有业务容量进行三倍的扩容，并搭建出多套环境可以共开发和测试人员做测试，运维老大为了在年底有所表现，要求运维部门同学尽快实现，当你接到这个任务时，有没有更快的解决方案？

### Ansible 发展史

Ansible 作者 Michael DeHaan（ Cobbler 与 Func 作者），Ansible 的名称来自科幻小说《安德的游戏》中跨越时空的即时通信工具，使用它可以在相距数光年的距离，远程实时控制前线的舰队战斗。2012年3月9日发布0.0.1版，2015年10月17日被 Red Hat 以1.5亿美元收购。
官方网站：[https://www.ansible.com](http://www.yunweipai.com/go?_=a49e019ca3aHR0cHM6Ly93d3cuYW5zaWJsZS5jb20v)
官方文档：[https://docs.ansible.com](http://www.yunweipai.com/go?_=beb2e5d97daHR0cHM6Ly9kb2NzLmFuc2libGUuY29tLw%3D%3D)

### Ansible 特性

- 模块化：调用特定的模块完成特定任务，支持自定义模块，可使用任何编程语言写模块
- Paramiko（python 对 ssh 的实现），PyYAML，Jinja2（模板语言）三个关键模块
- 基于 Python 语言实现
- 部署简单，基于 python 和 SSH (默认已安装)，agentless，无需代理不依赖 PKI（无需 ssl）
- 安全，基于 OpenSSH
- 幂等性：一个任务执行1遍和执行 n 遍效果一样，不因重复执行带来意外情况
- 支持 playbook 编排任务，YAML 格式，编排任务，支持丰富的数据结构
- 较强大的多层解决方案 role

### Ansible 架构

#### Ansible 组成

![](https://aluopy.github.io/assets/images/ansible-06.png)
组合 INVENTORY、API、MODULES、PLUGINS 的绿框，可以理解为是 ansible 命令工具，其为核心执行工具。

- INVENTORY：Ansible 管理主机的清单 `/etc/anaible/hosts`
- MODULES：Ansible 执行命令的功能模块，多数为内置核心模块，也可自定义
- PLUGINS：模块功能的补充，如连接类型插件、循环插件、变量插件、过滤插件等，该功能不常用
- API：供第三方程序调用的应用程序编程接口

#### Ansible 命令执行来源

- USER 普通用户，即 SYSTEM ADMINISTRATOR
- PLAYBOOKS：任务剧本（任务集），编排定义 Ansible 任务集的配置文件，由 Ansible 顺序依次执行，通常是 JSON 格式的 YML 文件
- CMDB（配置管理数据库） API 调用
- PUBLIC/PRIVATE CLOUD API 调用
- USER -> Ansible Playbook -> Ansibile

#### 注意事项

- 执行 ansible 的主机一般称为主控端，中控，master 或堡垒机
- 主控端 Python 版本需要2.6或以上
- 被控端 Python 版本小于2.4，需要安装 python-simplejson
- 被控端如开启 SELinux 需要安装 libselinux-python
- windows 不能做为主控端

