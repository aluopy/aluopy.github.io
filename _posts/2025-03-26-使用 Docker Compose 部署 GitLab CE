---
title: "使用 Docker Compose 部署 GitLab CE"
toc: true
toc_label: "使用 Docker Compose 部署 GitLab CE"
toc_icon: "cog"
categories: gitlab
permalink: /gitlab/gitlab-docker
excerpt: "在现代软件开发中，GitLab 作为一个功能完整的 DevOps 平台，为团队提供了代码管理、CI/CD、项目管理等一站式解决方案。本文将详细介绍如何使用 Docker Compose 部署 GitLab CE（社区版），并采用外部 Nginx 代理的架构设计，实现更灵活的部署方案。"
tags:
  - gitlab
  - docker-compose
---

## 前言

在现代软件开发中，GitLab 作为一个功能完整的 DevOps 平台，为团队提供了代码管理、CI/CD、项目管理等一站式解决方案。本文将详细介绍如何使用 Docker Compose 部署 GitLab CE（社区版），并采用外部 Nginx 代理的架构设计，实现更灵活的部署方案。

## 架构设计

本次部署采用以下架构：

- **GitLab CE**: 运行在 Docker 容器中，禁用内置 Nginx
- **外部 Nginx**: 作为反向代理，处理 SSL 终止
- **网络通信**: Nginx 与 GitLab 之间使用 HTTP 通信

这种架构的优势：

- 统一的反向代理管理
- 更好的资源利用率
- 便于维护和扩展

## 环境准备

### 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 4GB RAM（推荐 8GB+）
- 至少 20GB 磁盘空间

### 创建项目目录

```bash
mkdir gitlab-docker
cd gitlab-docker
mkdir config logs data
```

## Docker Compose 配置详解

创建 `docker-compose.yml` 文件：

```yaml
# 此配置文件禁用了 HTTPS 访问，TLS/SSL 由外部 Nginx 终止，Nginx 到 GitLab 使用 HTTP。如需启用 HTTPS，取消注释 9443 端口映射。
# 此配置文件禁用了捆绑安装 nginx，使用外部统一 nginx 代理
services:
  gitlab:
    image: gitlab/gitlab-ce:17.9.2-ce.0
    container_name: gitlab
    restart: always
    hostname: 'gitlab.aluopy.cn'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.aluopy.cn'
        nginx['enable'] = false
        web_server['external_users'] = ['root', 'nginx', 'gitlab']
        gitlab_rails['gitlab_ssh_host'] = 'gitlab.aluopy.cn'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
        gitlab_rails['trusted_proxies'] = ['192.168.20.210']
        gitlab_rails['max_attachment_size'] = 2048
        gitlab_rails['time_zone'] = 'Asia/Shanghai'
        gitlab_workhorse['listen_network'] = "tcp"
        gitlab_workhorse['listen_addr'] = "0.0.0.0:9080"
        # 内存优化
        gitlab_rails['rack_attack_git_basic_auth'] = {
          'enabled' => true,
          'ip_whitelist' => ["127.0.0.1"],
          'maxretry' => 10,
          'findtime' => 60,
          'bantime' => 3600
        }
        gitlab_rails['env'] = {
          'GITLAB_RAILS_RACK_TIMEOUT' => 300
        }
        puma['worker_processes'] = 2
        puma['min_threads'] = 1
        puma['max_threads'] = 8
        puma['per_worker_max_memory_mb'] = 1200
        sidekiq['concurrency'] = 9
        postgresql['shared_buffers'] = "1024MB"
        postgresql['max_worker_processes'] = 8
    ports:
      - '9080:9080'
      #- '9443:443'
      - '2222:22'
    volumes:
      - './config:/etc/gitlab'
      - './logs:/var/log/gitlab'
      - './data:/var/opt/gitlab'
      - '/etc/localtime:/etc/localtime:ro'
    shm_size: '256m'
    privileged: true
```

## 配置参数详解

### 基础配置

- **hostname**: 设置 GitLab 的主机名，影响内部服务通信
- **external_url**: 外部访问的完整 URL
- **nginx['enable'] = false**: 禁用内置 Nginx，使用外部代理

### 网络配置

- **gitlab_workhorse**: 配置为监听所有接口的 9080 端口
- **trusted_proxies**: 信任的代理服务器 IP，确保正确获取客户端真实 IP
- **gitlab_ssh_host**: SSH 访问的主机名
- **gitlab_shell_ssh_port**: SSH 端口映射

### 性能优化配置

#### Puma Web 服务器优化

```ruby
puma['worker_processes'] = 2          # 工作进程数
puma['min_threads'] = 1               # 最小线程数
puma['max_threads'] = 8               # 最大线程数
puma['per_worker_max_memory_mb'] = 1200  # 每个工作进程最大内存
```

#### Sidekiq 后台任务优化

```ruby
sidekiq['concurrency'] = 9            # 并发任务数
```

#### PostgreSQL 数据库优化

```ruby
postgresql['shared_buffers'] = "1024MB"    # 共享缓冲区
postgresql['max_worker_processes'] = 8     # 最大工作进程
```

#### 安全配置

```ruby
gitlab_rails['rack_attack_git_basic_auth'] = {
  'enabled' => true,
  'ip_whitelist' => ["127.0.0.1"],
  'maxretry' => 10,      # 最大重试次数
  'findtime' => 60,      # 时间窗口（秒）
  'bantime' => 3600      # 封禁时间（秒）
}
```

## 外部 Nginx 配置

参考官方文档：https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/nginx

## 部署步骤

### 1. 启动 GitLab 容器

```bash
docker-compose up -d
```

### 2. 查看启动日志

```bash
docker-compose logs -f gitlab
```

### 3. 等待初始化完成

GitLab 首次启动需要 5-10 分钟进行初始化，可以通过以下命令检查状态：

```bash
docker exec -it gitlab gitlab-ctl status
```

### 4. 获取初始 root 密码

```bash
docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

### 5. 配置并启动 Nginx

```bash
sudo systemctl reload nginx
```

## 访问和初始配置

1. 访问 `https://gitlab.aluopy.cn`
2. 使用用户名 `root` 和获取到的初始密码登录
3. 立即修改 root 密码
4. 配置管理员邮箱和其他基础设置

## 常用维护命令

### 查看服务状态

```bash
docker exec -it gitlab gitlab-ctl status
```

### 重新配置 GitLab

```bash
docker exec -it gitlab gitlab-ctl reconfigure
```

### 备份数据

```bash
docker exec -it gitlab gitlab-backup create
```

### 修复文件系统权限

```bash
docker exec -it gitlab update-permissions
```

### 查看日志

```bash
# 查看所有日志
docker-compose logs gitlab

# 查看实时日志
docker-compose logs -f gitlab

# 查看特定服务日志
docker exec -it gitlab tail -f /var/log/gitlab/gitlab-rails/production.log
```

## 性能监控

### 内存使用监控

```bash
docker stats gitlab
```

### GitLab 内置监控

访问 `https://gitlab.aluopy.cn/admin/system_info` 查看系统信息。

## 故障排除

### 常见问题

1. **容器启动失败**
   - 检查端口是否被占用
   - 确认目录权限是否正确
   - 查看容器日志排查具体错误
2. **502 Bad Gateway**
   - 确认 GitLab 服务是否完全启动
   - 检查 Nginx 配置是否正确
   - 验证网络连通性
3. **SSH 连接问题**
   - 确认 2222 端口映射是否正常
   - 检查防火墙设置
   - 验证 SSH 密钥配置

## 安全建议

1. **定期更新**: 保持 GitLab 版本更新，及时修复安全漏洞
2. **备份策略**: 制定定期备份计划，确保数据安全
3. **访问控制**: 配置适当的用户权限和项目可见性
4. **SSL 配置**: 使用强加密算法和最新的 TLS 协议
5. **监控告警**: 设置系统监控和异常告警

## 结语

通过本文的配置，我们成功部署了一个高性能、易维护的 GitLab CE 实例。这种架构不仅提供了良好的性能表现，还为后续的扩展和维护奠定了坚实基础。在实际使用中，可以根据具体需求调整配置参数，以获得最佳的使用体验。

记住定期备份数据，监控系统性能，确保 GitLab 服务的稳定运行。如有问题，可以查看日志文件或参考 GitLab 官方文档进行排查。
