---
title: "Prometheus 安装与配置"
excerpt: "Prometheus、Alertmanager、Grafana 安装与配置，Alerting rules。"
toc: true
categories:
  - Prometheus
  - Alertmanager
  - Grafana
tags:
  - prometheus
  - alertmanager
  - grafana
  - alerting-rules
---

## Prometheus

- [Prometheus - Monitoring system & time series database](https://prometheus.io/)
- [Docs \| Prometheus](https://prometheus.io/docs/introduction/overview/)
- [Download \| Prometheus](https://prometheus.io/download/)

### 安装

[下载最新版本](https://prometheus.io/download) 的 propetheus，解压：

```shell
$ tar -C /usr/local/ -xvf prometheus-*.tar.gz
$ mv /usr/local/prometheus-* /usr/local/prometheus
```

### 使用 systemd 管理服务

```shell
$ cat > /usr/lib/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/
After=network.target
 
[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/prometheus/prometheus --config.file=/usr/local/prometheus/prometheus.yml --web.external-url=http://192.168.20.101:9090
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

> 查看所有可用的命令行标志： ```/usr/local/prometheus/prometheus -h```

### 启动服务

启动服务并验证服务是否已启动：

```shell
$ systemctl daemon-reload
$ systemctl enable prometheus
$ systemctl start prometheus
$ systemctl status prometheus

$ curl -m 1 -s -o /dev/null -w '%{http_code}\n' http://localhost:9090/graph
200
```

> `http://IP:9090`

## Alertmanager

- [Alerting overview | Prometheus](https://prometheus.io/docs/alerting/latest/overview/)
- [Download | Prometheus](https://prometheus.io/download/)

### 安装

[下载最新版本](https://prometheus.io/download) 的 alertmanager，解压：

```shell
$ tar -C /usr/local/ -xvf alertmanager-*.tar.gz
$ mv /usr/local/alertmanager-* /usr/local/alertmanager
```

### 使用 systemd 管理服务

```shell
$ cat > /usr/lib/systemd/system/alertmanager.service << EOF
[Unit]
Description=alertmanager
Documentation=https://prometheus.io/
After=network.target
 
[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/alertmanager/alertmanager --config.file=/usr/local/alertmanager/alertmanager.yml --web.external-url=http://192.168.20.103:9093
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

> 查看所有可用的命令行标志： ```/usr/local/alertmanager/alertmanager -h```

### 启动服务

启动服务并验证服务是否已启动：

```shell
$ systemctl daemon-reload
$ systemctl enable alertmanager
$ systemctl start alertmanager
$ systemctl status alertmanager

$ curl -m 1 -s -o /dev/null -w '%{http_code}\n' http://localhost:9093
200
```

> `http://IP:9093` 

## Grafana

- [Grafana: The open observability platform | Grafana Labs](https://grafana.com/)
- [Grafana documentation | Grafana Labs](https://grafana.com/docs/grafana/latest/)
- [Download Grafana | Grafana Labs](https://grafana.com/grafana/download)

### 安装

您可以从 yum 存储库中安装 grafana，手动使用 yum，使用 rpm，或通过下载二进制 [.tar.gz](https://grafana.com/grafana/download) 文件。

#### 从 YUM 存储库安装

从yum存储库安装。如果从 yum 存储库安装，则每次运行 `sudo yum update` 更新时都会自动更新 Grafana。

```shell
$ cat > /etc/yum.repos.d/grafana.repo << EOF
# For OSS releases
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
```

安装 Grafana：

```shell
$ sudo yum install grafana -y
```

#### 使用 RPM 安装

如果使用 RPM 安装，则需要为每个新版本手动更新 Grafana。

```shell
# Red Hat, CentOS, RHEL, and Fedora(64 Bit)
$ wget https://dl.grafana.com/oss/release/grafana-8.4.4-1.x86_64.rpm
$ sudo rpm -Uvh grafana-8.4.4-1.x86_64.rpm
```

### 启动服务

启动服务并验证服务是否已启动：

```shell
$ sudo systemctl daemon-reload
$ sudo systemctl enable grafana-server
$ sudo systemctl start grafana-server
$ sudo systemctl status grafana-server

$ curl -m 1 -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/login
200
```

# Configure

## Prometheus

Prometheus 配置是 YAML。 Prometheus 下载附带一个名为 prometheus.yml 的文件中的示例配置。

```yaml
global:
  scrape_interval: 20s
  scrape_timeout: 10s
  evaluation_interval: 20s
alerting:
  alertmanagers:
  - follow_redirects: true
    scheme: http
    timeout: 10s
    api_version: v2
    static_configs:
    - targets:
      - 192.168.20.103:9093
rule_files:
- /usr/local/prometheus/rules/*.yml
scrape_configs:
- job_name: prometheus
  honor_timestamps: true
  scrape_interval: 20s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  follow_redirects: true
  static_configs:
  - targets:
    - localhost:9090
- job_name: node_exporter_targets
  honor_timestamps: true
  scrape_interval: 20s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  follow_redirects: true
  file_sd_configs:
  - files:
    - /usr/local/prometheus/file_sd/targets-node.json
    refresh_interval: 1m
```

示例配置文件中有三个配置块：global、rule_files 和 scrape_configs

global 块控制 Prometheus 服务器的全局配置。我们有两种选择。第一个，scrape_interval，控制 Prometheus 抓取目标的频率。您可以为单个目标覆盖它。在这种情况下，全局设置是每 15 秒刮一次。 evaluation_interval 选项控制 Prometheus 评估规则的频率。 Prometheus 使用规则来创建新的时间序列并生成警报。

rule_files 块指定我们希望 Prometheus 服务器加载的任何规则的位置。目前我们没有任何规则。

最后一个块 scrape_configs 控制 Prometheus 监控的资源。由于 Prometheus 还将有关自身的数据公开为 HTTP 端点，因此它可以抓取和监控自己的健康状况。在默认配置中，有一个名为 prometheus 的作业，它会抓取 Prometheus 服务器公开的时间序列数据。该作业包含一个静态配置的目标，即端口 9090 上的 localhost。Prometheus 期望指标在 /metrics 路径上的目标上可用。所以这个默认作业是通过 URL 抓取：http://localhost:9090/metrics。

返回的时间序列数据将详细说明 Prometheus 服务器的状态和性能。

有关配置选项的完整规范，请参阅配置文档 [configuration documentation](https://prometheus.io/docs/operating/configuration).

## Alertmanager

### 配置文件详解

```shell
global:
  # 经过此时间后，如果尚未更新告警，则将告警声明为已恢复。(即prometheus没有向alertmanager发送告警了)
  resolve_timeout: 5m
  # 配置发送邮件信息
  smtp_smarthost: 'smtp.qq.com:465'
  smtp_from: '742899387@qq.com'
  smtp_auth_username: '742899387@qq.com'
  smtp_auth_password: 'password'
  smtp_require_tls: false

# 读取告警通知模板的目录。
templates: 
- '/etc/alertmanager/template/*.tmpl'

# 所有报警都会进入到这个根路由下，可以根据根路由下的子路由设置报警分发策略
route:
  # 先解释一下分组，分组就是将多条告警信息聚合成一条发送，这样就不会收到连续的报警了。
  # 将传入的告警按标签分组(标签在prometheus中的rules中定义)，例如：
  # 接收到的告警信息里面有许多具有cluster=A 和 alertname=LatencyHigh的标签，这些个告警将被分为一个组。
  #
  # 如果不想使用分组，可以这样写group_by: [...]
  group_by: ['alertname', 'cluster', 'service']

  # 第一组告警发送通知需要等待的时间，这种方式可以确保有足够的时间为同一分组获取多个告警，然后一起触发这个告警信息。
  group_wait: 30s

  # 发送第一个告警后，等待"group_interval"发送一组新告警。
  group_interval: 5m

  # 分组内发送相同告警的时间间隔。这里的配置是每3小时发送告警到分组中。举个例子：收到告警后，一个分组被创建，等待5分钟发送组内告警，如果后续组内的告警信息相同,这些告警会在3小时后发送，但是3小时内这些告警不会被发送。
  repeat_interval: 3h 

  # 这里先说一下，告警发送是需要指定接收器的，接收器在receivers中配置，接收器可以是email、webhook、pagerduty、wechat等等。一个接收器可以有多种发送方式。
  # 指定默认的接收器
  receiver: team-X-mails

  
  # 下面配置的是子路由，子路由的属性继承于根路由(即上面的配置)，在子路由中可以覆盖根路由的配置

  # 下面是子路由的配置
  routes:
  # 使用正则的方式匹配告警标签
  - match_re:
      # 这里可以匹配出标签含有service=foo1或service=foo2或service=baz的告警
      service: ^(foo1|foo2|baz)$
    # 指定接收器为team-X-mails
    receiver: team-X-mails
    # 这里配置的是子路由的子路由，当满足父路由的的匹配时，这条子路由会进一步匹配出severity=critical的告警，并使用team-X-pager接收器发送告警，没有匹配到的告警会由父路由进行处理。
    routes:
    - match:
        severity: critical
      receiver: team-X-pager

  # 这里也是一条子路由，会匹配出标签含有service=files的告警，并使用team-Y-mails接收器发送告警
  - match:
      service: files
    receiver: team-Y-mails
    # 这里配置的是子路由的子路由，当满足父路由的的匹配时，这条子路由会进一步匹配出severity=critical的告警，并使用team-Y-pager接收器发送告警，没有匹配到的会由父路由进行处理。
    routes:
    - match:
        severity: critical
      receiver: team-Y-pager

  # 该路由处理来自数据库服务的所有警报。如果没有团队来处理，则默认为数据库团队。
  - match:
      # 首先匹配标签service=database
      service: database
    # 指定接收器
    receiver: team-DB-pager
    # 根据受影响的数据库对告警进行分组
    group_by: [alertname, cluster, database]
    routes:
    - match:
        owner: team-X
      receiver: team-X-pager
      # 告警是否继续匹配后续的同级路由节点，默认false，下面如果也可以匹配成功，会向两种接收器都发送告警信息(猜测。。。)
      continue: true
    - match:
        owner: team-Y
      receiver: team-Y-pager


# 下面是关于inhibit(抑制)的配置，先说一下抑制是什么：抑制规则允许在另一个警报正在触发的情况下使一组告警静音。其实可以理解为告警依赖。比如一台数据库服务器掉电了，会导致db监控告警、网络告警等等，可以配置抑制规则如果服务器本身down了，那么其他的报警就不会被发送出来。

inhibit_rules:
#下面配置的含义：当有多条告警在告警组里时，并且他们的标签alertname,cluster,service都相等，如果severity: 'critical'的告警产生了，那么就会抑制severity: 'warning'的告警。
- source_match:  # 源告警(我理解是根据这个报警来抑制target_match中匹配的告警)
    severity: 'critical' # 标签匹配满足severity=critical的告警作为源告警
  target_match:  # 目标告警(被抑制的告警)
    severity: 'warning'  # 告警必须满足标签匹配severity=warning才会被抑制。
  equal: ['alertname', 'cluster', 'service']  # 必须在源告警和目标告警中具有相等值的标签才能使抑制生效。(即源告警和目标告警中这三个标签的值相等'alertname', 'cluster', 'service')


# 下面配置的是接收器
receivers:
# 接收器的名称、通过邮件的方式发送、
- name: 'team-X-mails'
  email_configs:
    # 发送给哪些人
  - to: 'team-X+alerts@example.org'
    # 是否通知已解决的警报
    send_resolved: true

# 接收器的名称、通过邮件和pagerduty的方式发送、发送给哪些人，指定pagerduty的service_key
- name: 'team-X-pager'
  email_configs:
  - to: 'team-X+alerts-critical@example.org'
  pagerduty_configs:
  - service_key: <team-X-key>

# 接收器的名称、通过邮件的方式发送、发送给哪些人
- name: 'team-Y-mails'
  email_configs:
  - to: 'team-Y+alerts@example.org'

# 接收器的名称、通过pagerduty的方式发送、指定pagerduty的service_key
- name: 'team-Y-pager'
  pagerduty_configs:
  - service_key: <team-Y-key>

# 一个接收器配置多种发送方式
- name: 'ops'
  webhook_configs:
  - url: 'http://prometheus-webhook-dingtalk.kube-ops.svc.cluster.local:8060/dingtalk/webhook1/send'
    send_resolved: true
  email_configs:
  - to: '742899387@qq.com'
    send_resolved: true
  - to: 'soulchild@soulchild.cn'
    send_resolved: true
```

### 接收器详细参数配置文档

- email: https://prometheus.io/docs/alerting/latest/configuration/#email_config
- webhook: https://prometheus.io/docs/alerting/latest/configuration/#webhook_config
- wechat: https://prometheus.io/docs/alerting/latest/configuration/#wechat_config
- pagerduty：https://prometheus.io/docs/alerting/latest/configuration/#pagerduty_config

## 「Alertmanager」- 将告警信息发往多个渠道（Slack, Email, …）

### 问题描述

在出现告警时，我们希望立即收到告警消息，而不希望出现过多的延迟。这点邮件告警是无法满足的，因为邮件通知是由客户端定期查找邮箱才触发的，而且部分邮件服务器也不一定支持 IDLE 命令，因此使用邮件告警无法保证消息的即时性。此外单一的告警渠道无法满足容错的要求，比如邮箱服务出现问题，我们将错过或无法收到告警信息。

鉴于此，除了使用邮件告警，我们还需要接入 IM 进行告警通知。这便涉及将告警信息发送到多个通知渠道。

该笔记将记录：在 Alertmanager 中，将告警消息发送到多个告警渠道的方法，以及注意事项、常见问题的处理。

### 解决方案

#### 方法一、通过 receiver 配置

在 receiver 中，单个条目能够包含多个告警渠道的配置：

```shell
receivers:
  - name: slack_and_email
    # Slack
    slack_configs:
      - api_url: '<THE_WEBHOOK_URL>'
        channel: '#general'
      - api_url: '<ANOTHER_WEBHOOK_URL>'
        channel: '#alerts'
    # Email
    email_configs:
      - to: 'k4nz@example.com'

route:
  receiver: slack_and_email
```

#### 方法二、通过 route continue 参数

```shell
# 首先，我们定义多个不同的 receiver 信息
receivers:
  - name: slack
    slack_configs:
      - api_url: THE_WEBHOOK_URL
        channel: '#general'
  - name: email
    email_configs:
      - to: 'k4nz@example.com'

# 然后，在 route 中通过 continue 参数，是告警消息进行多个匹配
route:
 receiver: slack  # Fallback，必须设置 receiver 字段
 routes:
   - match:
       severity: page
     receiver: slack
     continue: true
   - match:
       severity: page
     receiver: pagerduty
```

通常告警消息的 Lable 匹配 match 之后，不会继续向下匹配。通过 continue: true 能够使告警消息继续向下匹配。

### 参考资料

- [Sending alert notifications to multiple destinations – Robust Perception | Prometheus Monitoring Experts](https://www.robustperception.io/sending-alert-notifications-to-multiple-destinations)

# Rules

- [Awesome Prometheus alerts \| Collection of alerting rules (grep.to)](https://awesome-prometheus-alerts.grep.to/)

