---
title: "Automation Intro"
permalink: /ansible/automation-intro/
excerpt: ""
last_modified_at: 2021-06-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
---

本书笔记根据[马哥教育](https://www.magedu.com/)发布的《[运维自动化之 Ansible](https://www.bilibili.com/video/BV1HZ4y1p7Bf?spm_id_from=333.999.0.0&vd_source=e719fc442af42e83e26536b3b52e620c)》视频教程整理而来。

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