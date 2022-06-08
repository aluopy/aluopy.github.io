---
title: "Github Container registry"
excerpt: "您可以在使用包命名空间 https://ghcr.io 的容器注册表中存储和管理 Docker 和 OCI 映像。"
toc: true
toc_label: "Github Container registry"
toc_icon: "cog"
categories: Github Container-registry
tags:
  - github
  - gitHub-packages
  - container-registry
  - github-container-registry
---

您可以在使用包命名空间 https://ghcr.io 的容器注册表中存储和管理 Docker 和 OCI 映像。

## 关于 Container registry 支持

Container Registry 目前支持以下容器镜像格式：

- [Docker Image Manifest V2, Schema 2](https://docs.docker.com/registry/spec/manifest-v2-2/)
- [Open Container Initiative (OCI) Specifications](https://github.com/opencontainers/image-spec)

安装或发布 Docker 镜像时，容器注册表支持外部层，例如 Windows 镜像。

## Container registry 身份验证

要在 GitHub Actions 工作流程中对容器注册表进行身份验证，请使用 `GITHUB_TOKEN` 以获得最佳安全性和体验。如果您的工作流程使用个人访问令牌 (PAT) 对 `ghcr.io` 进行身份验证，那么我们强烈建议您更新工作流程以使用 `GITHUB_TOKEN`。

有关使用个人访问令牌更新对 ghcr.io 进行身份验证的工作流的指南，请参阅 "[Upgrading a workflow that accesses `ghcr.io`](https://docs.github.com/cn/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions#upgrading-a-workflow-that-accesses-ghcrio)."

有关 GITHUB_TOKEN 的更多信息，请参阅 "[Authentication in a workflow](https://docs.github.com/cn/actions/reference/authentication-in-a-workflow#using-the-github_token-in-a-workflow)."

如果您在操作中使用容器注册表，请遵循 "[Security hardening for GitHub Actions](https://docs.github.com/cn/actions/getting-started-with-github-actions/security-hardening-for-github-actions#considering-cross-repository-access)" 中的安全最佳实践。

### 创建个人访问令牌 (PAT)

1. 登录 GitHub 个人主页
2. 单击个人资料照片，然后单击 **Settings（设置）**
3. 在左侧栏中，单击 **Developer settings（开发者设置）**
4. 在左侧边栏中，单击 **Personal access tokens（个人访问令牌）**
5. 单击 **Generate new token（生成新令牌）**
6. 给你的令牌一个描述性的名字

7. 设置令牌有效期

8. 设置令牌权限范围，选择 **write:packages** 和 **delete:packages**

   要使用令牌从命令行访问存储库，请选择 repo，选择 `write:packages`（会自动选择 `repo`）

   相关权限说明：

   - *read:packages* 将包上传到 GitHub Package Registry

   - *write:packages* 从 GitHub Package Registry 下载包
   - *delete:packages* 从 GitHub Package Registry 删除包

9. 单击 **Generate token（生成令牌）**

   > 警告：将令牌视为密码并对其保密。使用 API 时，使用令牌作为环境变量，而不是将它们硬编码到程序中。

### 保存个人访问令牌 (PAT)

建议将 PAT 保存为环境变量

```shell
$ export CR_PAT=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
```

使用适用于容器类型的 CLI，登录 ghcr.io 上的 Container registry service

```shell
$ echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

## 将镜像推送到 Container registry

```shell
$ docker images
REPOSITORY                                               TAG       IMAGE ID       CREATED         SIZE
calico/kube-controllers                                  v3.23.1   4d33632489a4   3 weeks ago     135MB
calico/cni                                               v3.23.1   90d97aa939bb   3 weeks ago     262MB
calico/node                                              v3.23.1   fbfd04bbb7f4   3 weeks ago     219MB
registry.aliyuncs.com/google_containers/kube-proxy       v1.23.1   b46c42588d51   5 months ago    112MB
registry.aliyuncs.com/google_containers/pause            3.6       6270bb605e12   9 months ago    683kB
registry.cn-shenzhen.aliyuncs.com/aluo/jessie-dnsutils   1.3       97044d2d6d5c   21 months ago   253MB

$ docker tag 97044d2d6d5c ghcr.io/aluopy/dnsutils:1.3
$ docker push ghcr.io/aluopy/dnsutils:1.3
```

## 从 Container registry 拉取镜像

### 通过摘要拉取

为确保始终使用相同的镜像，可以通过 `digest` SHA 值指定要提取的确切容器镜像版本

查找 digest SHA 值

```shell
$ docker inspect ghcr.io/aluopy/dnsutils:1.3 | grep @sha256
            "ghcr.io/aluopy/dnsutils@sha256:ab8b7ea33f85101e228fe024e00bd5ab5473ce4a5c1a0a4f635e0f8efeaa27ba",
```

根据需要在本地删除镜像

```shell
$ docker rmi ghcr.io/aluopy/dnsutils:1.3
```

拉取镜像名称后带有`@YOUR_SHA_VALUE` 的容器镜像

```shell
$ docker pull ghcr.io/aluopy/dnsutils@sha256:ab8b7ea33f85101e228fe024e00bd5ab5473ce4a5c1a0a4f635e0f8efeaa27ba
```

> 这种方式拉取的镜像，`docker images` 命令显示的 TAG 为 `<none>`

### 按名称拉取

```shell
$ docker pull ghcr.io/aluopy/dnsutils
```

> 默认拉取 `ghcr.io/aluopy/dnsutils:latest`

### 按名称和版本拉取

```shell
$ docker pull ghcr.io/aluopy/dnsutils:1.3
```

### 按名称和最新版本拉取

```shell
$ docker pull ghcr.io/aluopy/dnsutils:latest
```

