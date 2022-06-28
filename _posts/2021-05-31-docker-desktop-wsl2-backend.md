---
title: "Docker Desktop WSL 2 backend"
toc: true
toc_label: Docker Desktop WSL 2 backend
toc_icon: "cog"
categories: Docker
tags:
  - docker
  - docker-desktop
---

适用于 Linux 的 Windows 子系统 (WSL) 2 引入了重大的体系结构更改，因为它是由 Microsoft 构建的完整 Linux 内核，允许 Linux 发行版运行而无需管理虚拟机。借助在 WSL 2 上运行的 Docker Desktop，用户可以利用 Linux 工作区，而不必同时维护 Linux 和 Windows 构建脚本。此外，WSL 2 改进了文件系统共享、启动时间，并允许 Docker Desktop 用户访问一些很酷的新功能。

Docker Desktop 使用 WSL 2 中的动态内存分配功能，极大地改善了资源消耗。这意味着，Docker Desktop 仅使用所需数量的 CPU 和内存资源，同时使 CPU 和内存密集型任务（例如构建容器）运行得更快。

此外，使用 WSL 2，冷启动后启动 Docker 守护程序所需的时间明显加快。与之前版本的 Docker Desktop 中几乎一分钟相比，启动 Docker 守护程序只需不到 10 秒。

## Prerequisites

在安装 Docker Desktop WSL 2 后端之前，您必须完成以下步骤：

1. 安装 Windows 10 版本 1903 或更高版本或 Windows 11。
2. 在 Windows 上启用 WSL 2 功能。有关详细说明，请参阅 [Microsoft documentation](https://docs.microsoft.com/en-us/windows/wsl/install-win10)。
3. 下载并安装 [Linux kernel update package](https://docs.microsoft.com/windows/wsl/wsl2-kernel)。

## Download

下载 [Docker Desktop for Windows](https://desktop.docker.com/win/main/amd64/Docker Desktop Installer.exe).

## Install

在安装 Docker Desktop 版本之前，请确保您已完成 Prerequisites 部分中描述的步骤。

1. 按照通常的安装说明安装 Docker Desktop。如果您运行的是受支持的系统，Docker Desktop 会在安装过程中提示您启用 WSL 2。阅读屏幕上显示的信息并启用 WSL 2 以继续。

2. 从 Windows 开始菜单启动 Docker Desktop。

3. 从 Docker 菜单中，选择 **Settings** > **General**。

4. 选中 **Use WSL 2 based engine** 复选框。

   如果您在支持 WSL 2 的系统上安装了 Docker Desktop，则默认情况下会启用此选项。

5. 单击 **Apply & Restart**。

而已！现在 docker 命令将使用新的 WSL 2 引擎在 Windows 上运行。

## 在 WSL 2 发行版中启用 Docker 支持

WSL 2 为 Windows 添加了对“Linux 发行版”的支持，其中每个发行版的行为都类似于 VM，只是它们都运行在单个共享的 Linux 内核之上。

Docker Desktop 不需要安装任何特定的 Linux 发行版。 docker CLI 和 UI 在 Windows 上都可以正常工作，无需任何额外的 Linux 发行版。然而，为了获得最佳的开发者体验，我们建议至少安装一个额外的发行版并通过以下方式启用 Docker 支持：

1. 确保分发在 WSL 2 模式下运行。 WSL 可以在 v1 或 v2 模式下运行分发。

   要检查 WSL 模式，请运行：

   ```powershell
   $ wsl.exe -l -v
     NAME                   STATE           VERSION
   * docker-desktop-data    Running         2
     docker-desktop         Running         2
     CentOS7                Running         2
     CentOS8                Running         1
   ```

   要将现有的 Linux 发行版升级到 v2（比如上面的 CentOS8），请运行：

   ```powershell
   $ wsl.exe --set-version CentOS8 2
   ```

   要将 v2 设置为将来安装的默认版本，请运行：

   ```powershell
   $ wsl.exe --set-default-version 2
   ```

2. 当 Docker Desktop 启动时，转到 **Settings** > **Resources** > **WSL Integration**。

   他将在您的默认 WSL 发行版上启用 Docker-WSL 集成。要更改默认 WSL 发行版，请运行

   ```powershell
   $ wsl --set-default <distro name>
   ```

   例如，要将 Ubuntu 设置为您的默认 WSL 发行版，请运行 `wsl --set-default ubuntu`。

   或者，选择您希望启用 Docker-WSL 集成的任何其他发行版。

   > **注意：**
   >
   > 在您的发行版中运行的 Docker-WSL 集成组件依赖于 glibc。在运行基于 musl 的发行版（例如 Alpine Linux）时，这可能会导致问题。 Alpine 用户可以使用 alpine-pkg-glibc 包将 glibc 与 musl 一起部署以运行集成。

3. 单击 **Apply & Restart**。

> **注意：**
>
> Docker Desktop 安装了 2 个专用的内部 Linux 发行版 docker-desktop 和 docker-desktop-data。第一个（docker-desktop）用于运行 Docker 引擎（dockerd），而第二个（docker-desktop-data）存储容器和图像。两者都不能用于一般开发。