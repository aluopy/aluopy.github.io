---
title: "K8S 中的 command 和 args 与 Docker 中的 CMD 和 ENTRYPOINT"
#excerpt: ""
permalink: /kubernetes/command-args-cmd-entrypoint/
toc: true
#toc_label: ""
#toc_icon: "cog"
categories: 
  - kubernetes
tags:
  - kubernetes
  - docker
---

## 字段说明

下表显示了两个 Dockerfile 指令的等效 pod manifest 字段：

| Dockerfile   | Pod manifest | Description                                                  |
| ------------ | ------------ | ------------------------------------------------------------ |
| `ENTRYPOINT` | `command`    | 在容器中运行的可执行文件。除了可执行文件之外，它还可能包含参数 |
| `CMD`        | `args`       | 传递给用 `ENTRYPOINT` 指令或 `command` 字段指定的命令的额外参数 |

## Cmd & Entrypoint

### `CMD`

CMD 指令有三种形式：

- `CMD ["executable", "param1", "param2"]` (*exec* 形式，这是首选形式)
- `CMD ["param1","param2"]` (*作为 ENTRYPOINT 的默认参数*)
- `CMD command param1 param2` (*shell* 形式)

一个 `Dockerfile` 中只能有一条 `CMD` 指令，如果有多个 `CMD` 指令，那么只有最后一个 `CMD` 指令会生效。

**`CMD` 的主要目的是为一个正在执行的容器提供默认值**。这些默认值可以包括一个可执行文件，也可以省略可执行文件，在这种情况下，必须同时指定一个 `ENTRYPOINT` 指令。

如果 `CMD` 被用来为 `ENTRYPOINT` 指令提供默认参数，那么 `CMD` 和 `ENTRYPOINT` 指令都应该用 JSON 数组格式指定。

> **Note**
>
> exec 形式被解析为 JSON 数组，这意味着必须在单词周围使用双引号（"），而不是单引号（'）。

与 *shell* 形式不同，*exec* 形式不调用命令 shell。这意味着正常的 shell 处理不会发生。例如，`CMD [ "echo", "$HOME"]` 不会对 `$HOME` 进行变量替换。如果你想进行 shell 处理，那么要么使用 *shell* 形式，要么直接执行一个shell，例如。`CMD [ "sh", "-c", "echo $HOME" ]` 。当使用 *exec* 形式并直接执行 shell 时，就像 *shell* 形式的情况一样，是 shell 在做环境变量扩展，而不是 docker。

当在 *shell* 或 *exec* 格式中使用时，CMD 指令设置运行镜像时要执行的命令。

如果使用 CMD 的 *shell* 形式，那么 `<command>` 将在 `/bin/sh -c` 中执行：

```dockerfile
FROM ubuntu
CMD echo "This is a test." | wc -
```

如果想在没有 shell 的情况下运行 `<command>`，那么必须将命令表达为一个 JSON 数组，并给出可执行文件的完整路径。这种数组形式是 `CMD` 的首选格式。任何额外的参数必须在数组中单独表示为字符串。

```dockerfile
FROM ubuntu
CMD ["/usr/bin/wc","--help"]
```

如果希望容器每次都运行相同的可执行文件，那么应该考虑将 `ENTRYPOINT` 与 `CMD` 结合使用。参见[ENTRYPOINT](#ENTRYPOINT)。

如果指定参数给 `docker run`，那么它们将覆盖 `CMD` 中指定的默认值。

> **Note**
>
> 不要把 `RUN`和 `CMD` 混淆。`RUN` 实际上是运行一个命令并提交结果；`CMD` 在构建时不执行任何东西，但为镜像指定预定的命令。简而言之，`RUN` 是在 `docker build` 时运行，`CMD` 是在 `docker run` 时运行。

### `ENTRYPOINT`

ENTRYPOINT 有两种形式：

- `ENTRYPOINT ["executable", "param1", "param2"]` (*exec* 形式，这是首选形式)
- `ENTRYPOINT command param1 param2` (*shell* 形式)

一个 `ENTRYPOINT` 允许你配置一个将作为可执行文件运行的容器。

例如，下面是启动 nginx 的默认内容，监听端口为80：

```shell
$ docker run -i -t --rm -p 80:80 nginx
```

`docker run <image>` 的命令行参数将被附加在 *exec* 形式的 `ENTRYPOINT` 的所有元素之后，并将覆盖所有使用 `CMD` 指定的元素。这允许将参数传递给入口点，即 `docker run <image> -d` 将传递 `-d` 参数给入口点。可以使用 `docker run --entrypoint` 标志来覆盖 `ENTRYPOINT` 指令。

*shell* 形式可以防止使用任何 `CMD` 或运行命令行参数，但缺点是你的 `ENTRYPOINT` 将作为 `/bin/sh -c` 的一个子命令启动，它不传递信号。这意味着可执行文件不会是容器的 `PID 1` --也不会收到 Unix 信号--所以你的可执行文件不会收到来自 `docker stop <container>` 的 `SIGTERM`。

只有 `Dockerfile` 中的最后一条 `ENTRYPOINT` 指令才有效果。

#### Exec 形式 ENTRYPOINT 示例

可以使用 `ENTRYPOINT` 的 *exec* 形式来设置相当稳定的默认命令和参数，然后使用 `CMD` 的任一形式来设置更可能被改变的额外默认值。

```dockerfile
FROM ubuntu
ENTRYPOINT ["top", "-b"]
CMD ["-c"]
```

当运行这个容器时，可以看到 `top` 是唯一的进程：

```shell
$ docker run -it --rm --name test  top -H

top - 08:25:00 up  7:27,  0 users,  load average: 0.00, 0.01, 0.05
Threads:   1 total,   1 running,   0 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.1 us,  0.1 sy,  0.0 ni, 99.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem:   2056668 total,  1616832 used,   439836 free,    99352 buffers
KiB Swap:  1441840 total,        0 used,  1441840 free.  1324440 cached Mem

  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND
    1 root      20   0   19744   2336   2080 R  0.0  0.1   0:00.04 top
```

为了进一步检查结果，可以使用 `docker exec`：

```shell
$ docker exec -it test ps aux

USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  2.6  0.1  19752  2352 ?        Ss+  08:24   0:00 top -b -H
root         7  0.0  0.1  15572  2164 ?        R+   08:25   0:00 ps aux
```

可以用 `docker stop test` 来优雅地请求关闭 `top`。

下面的 `Dockerfile` 显示了使用 `ENTRYPOINT` 在前台运行 Apache（即，作为 `PID 1`）。

```dockerfile
FROM debian:stable
RUN apt-get update && apt-get install -y --force-yes apache2
EXPOSE 80 443
VOLUME ["/var/www", "/var/log/apache2", "/etc/apache2"]
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
```

如果要为单个可执行文件编写启动脚本，你可以通过使用 `exec` 和 `gosu` 命令确保最终的可执行文件收到 Unix 信号。

```shell
#!/usr/bin/env bash
set -e

if [ "$1" = 'postgres' ]; then
    chown -R postgres "$PGDATA"

    if [ -z "$(ls -A "$PGDATA")" ]; then
        gosu postgres initdb
    fi

    exec gosu postgres "$@"
fi

exec "$@"
```

最后，如果要在关机时做一些额外的清理工作（或者与其他容器通信），或者协调多个可执行文件，可能需要确保 `ENTRYPOINT` 脚本接收 Unix 信号，将它们传递出去，然后再做一些工作。

```shell
#!/bin/sh
# Note: 我是用 sh 写的，所以它在 busybox 容器中也能工作。

# 如果要在服务停止后进行手动清理，请使用 trap,
#     或者需要在一个容器中启动多个服务
trap "echo TRAPed signal" HUP INT QUIT TERM

# 在这里启动后台服务
/usr/sbin/apachectl start

echo "[hit enter key to exit] or run 'docker stop <container>'"
read

# 在此停止服务和清理
echo "stopping apache"
/usr/sbin/apachectl stop

echo "exited $0"
```

如果使用 `docker run -it --rm -p 80:80 --name test apache` 运行这个镜像，就可以用 `docker exec` 或 `docker top` 检查容器的进程，然后要求脚本停止 Apache。

```shell
$ docker exec -it test ps aux

USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0   4448   692 ?        Ss+  00:42   0:00 /bin/sh /run.sh 123 cmd cmd2
root        19  0.0  0.2  71304  4440 ?        Ss   00:42   0:00 /usr/sbin/apache2 -k start
www-data    20  0.2  0.2 360468  6004 ?        Sl   00:42   0:00 /usr/sbin/apache2 -k start
www-data    21  0.2  0.2 360468  6000 ?        Sl   00:42   0:00 /usr/sbin/apache2 -k start
root        81  0.0  0.1  15572  2140 ?        R+   00:44   0:00 ps aux

$ docker top test

PID                 USER                COMMAND
10035               root                {run.sh} /bin/sh /run.sh 123 cmd cmd2
10054               root                /usr/sbin/apache2 -k start
10055               33                  /usr/sbin/apache2 -k start
10056               33                  /usr/sbin/apache2 -k start

$ /usr/bin/time docker stop test

test
real	0m 0.27s
user	0m 0.03s
sys	0m 0.03s
```

> **Note**
>
> 可以使用 `--entrypoint` 覆盖 `ENTRYPOINT` 设置，但这只能将二进制文件设置为 `exec`（不会使用 `sh -c`）。

#### Shell 形式 ENTRYPOINT 示例

可以为 `ENTRYPOINT` 指定一个普通字符串，它将在 `/bin/sh -c` 中执行。这种形式将使用 shell 处理来替代 shell 环境变量，并将忽略任何 `CMD` 或 `docker run` 命令行参数。为了确保 `docker stop` 会对任何长期运行的`ENTRYPOINT` 可执行文件发出正确的信号，需要记住用 `exec` 启动它。

```dockerfile
FROM ubuntu
ENTRYPOINT exec top -b
```

当运行这个镜像时，会看到单一的 `PID 1` 进程：

```shell
$ docker run -it --rm --name test top

Mem: 1704520K used, 352148K free, 0K shrd, 0K buff, 140368121167873K cached
CPU:   5% usr   0% sys   0% nic  94% idle   0% io   0% irq   0% sirq
Load average: 0.08 0.03 0.05 2/98 6
  PID  PPID USER     STAT   VSZ %VSZ %CPU COMMAND
    1     0 root     R     3164   0%   0% top -b
```

在 docker 停止时干净利落地退出：

```shell
$ /usr/bin/time docker stop test

test
real	0m 0.20s
user	0m 0.02s
sys	0m 0.04s
```

如果忘记在 `ENTRYPOINT` 的开头加上 `exec`：

```dockerfile
FROM ubuntu
ENTRYPOINT top -b
CMD -- --ignored-param1
```

然后可以运行它（给它一个名字以备下一步使用）：

```shell
$ docker run -it --name test top --ignored-param2

top - 13:58:24 up 17 min,  0 users,  load average: 0.00, 0.00, 0.00
Tasks:   2 total,   1 running,   1 sleeping,   0 stopped,   0 zombie
%Cpu(s): 16.7 us, 33.3 sy,  0.0 ni, 50.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   1990.8 total,   1354.6 free,    231.4 used,    404.7 buff/cache
MiB Swap:   1024.0 total,   1024.0 free,      0.0 used.   1639.8 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
    1 root      20   0    2612    604    536 S   0.0   0.0   0:00.02 sh
    6 root      20   0    5956   3188   2768 R   0.0   0.2   0:00.00 top
```

可以从 `top` 的输出中看到，指定的 `ENTRYPOINT` 不是 `PID 1`。

如果再运行 `docker stop test`，容器将不会干净地退出-- `stop` 命令将在超时后被迫发送 `SIGKILL`：

```shell
$ docker exec -it test ps waux

USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.4  0.0   2612   604 pts/0    Ss+  13:58   0:00 /bin/sh -c top -b --ignored-param2
root         6  0.0  0.1   5956  3188 pts/0    S+   13:58   0:00 top -b
root         7  0.0  0.1   5884  2816 pts/1    Rs+  13:58   0:00 ps waux

$ /usr/bin/time docker stop test

test
real	0m 10.19s
user	0m 0.04s
sys 	0m 0.03s
```

### `CMD` 和 `ENTRYPOINT` 的互动方式

`CMD` 和 `ENTRYPOINT` 指令都定义了在运行容器时要执行的命令。有一些规则描述了它们的合作。

1. Dockerfile 应该至少指定 `CMD` 或 `ENTRYPOINT` 命令中的一个。
2. 当把容器作为一个可执行文件使用时，应该定义 `ENTRYPOINT`。
3. `CMD` 应该被用作定义 `ENTRYPOINT` 命令的默认参数或在容器中执行临时命令的一种方式。
4. 当用其他参数运行容器时，`CMD` 将被覆盖。

下表显示了不同的 `ENTRYPOINT` / `CMD` 组合会执行什么命令：

| Description                    | No ENTRYPOINT                | ENTRYPOINT exec_entry p1_entry    | ENTRYPOINT [“exec_entry”, “p1_entry”]            |
| ------------------------------ | ---------------------------- | --------------------------------- | ------------------------------------------------ |
| **No CMD**                     | 错误，不允许                 | `/bin/sh -c exec_entry p1_entry`  | `exec_entry p1_entry`                            |
| **CMD ["exec_cmd", "p1_cmd"]** | `exec_cmd p1_cmd`            | `/bin/sh -c exec_entry p1_entry`  | ` exec_entry p1_entry exec_cmd p1_cmd`           |
| **CMD exec_cmd p1_cmd**        | `/bin/sh -c exec_cmd p1_cmd` | ` /bin/sh -c exec_entry p1_entry` | `exec_entry p1_entry /bin/sh -c exec_cmd p1_cmd` |

> **Note**
>
> 如果 `CMD` 是从 base image 中定义的，设置 `ENTRYPOINT` 将把 `CMD` 重置为一个空值。在这种情况下，`CMD` 必须在当前镜像中定义才有价值。

## Command & args

### 创建 Pod 时设置命令及参数

创建 Pod 时，可以为其下的容器设置启动时要执行的命令及其参数。如果要设置命令，就填写在配置文件的 `command` 字段下，如果要设置命令的参数，就填写在配置文件的 `args` 字段下。 一旦 Pod 创建完成，该命令及其参数就无法再进行更改了。

如果在配置文件中设置了容器启动时要执行的命令及其参数，那么容器镜像中自带的命令与参数将会被覆盖而不再执行。 如果配置文件中只是设置了参数，却没有设置其对应的命令，那么容器镜像中自带的命令会使用该新参数作为其执行时的参数。

创建 Pod 设置命令及参数示例。本示例中，将创建一个只包含单个容器的 Pod。在此 Pod 配置文件中设置了一个命令与两个参数：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: command-demo
  labels:
    purpose: demonstrate-command
spec:
  containers:
  - name: command-demo-container
    image: debian
    command: ["printenv"]
    args: ["HOSTNAME", "KUBERNETES_PORT"]
  restartPolicy: OnFailure
```

查询 Pod 日志，显示了 `HOSTNAME` 与 `KUBERNETES_PORT` 这两个环境变量的值：

```bash
command-demo
tcp://10.3.240.1:443
```

### 使用环境变量来设置参数

```yaml
env:
- name: MESSAGE
  value: "hello world"
command: ["/bin/echo"]
args: ["$(MESSAGE)"]
```

这意味着你可以将那些用来设置环境变量的方法应用于设置命令的参数，其中包括了 [ConfigMap](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-pod-configmap/) 与 [Secret](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/)。

> **说明：**
>
> 环境变量需要加上括号，类似于 `"$(VAR)"`。这是在 `command` 或 `args` 字段使用变量的格式要求。

### 在 shell 中执行命令

有时候，你需要在 Shell 脚本中运行命令。 例如，你要执行的命令可能由多个命令组合而成，或者它就是一个 Shell 脚本。 这时，就可以通过如下方式在 Shell 中执行命令：

```yaml
command: ["/bin/sh"]
args: ["-c", "while true; do echo hello; sleep 10;done"]
```

## `command`, `args` 字段与 `CMD`, `ENTRYPOINT`  指令的互动方式

当覆盖默认的 `ENTRYPOINT` 和 `CMD` 时，将应用以下规则：

- 如果不为容器提供 `command` 或 `args` 参数，则使用 Dockerfile 中定义的默认值。
- 如果提供 `command` 但没有提供 `args` 参数，则仅使用提供的 `command`（不带任何参数）。Dockerfile 中定义的默认 `ENTRYPOINT`  和 `CMD` 将被忽略。
- 如果仅为容器提供 `args`，则 Dockerfile 中定义的默认 `ENTRYPOINT` 将和提供的 `args` 一起运行。
- 如果提供 `command` 和 `args`，则将忽略 Dockerfile 中定义的默认 `ENTRYPOINT` 和默认 `CMD`。`command` 与 `args` 一起运行。

| Image ENTRYPOINT | Image CMD   | Container command | Container args | Command run      |
| ---------------- | ----------- | ----------------- | -------------- | ---------------- |
| `[/ep-1]`        | `[foo bar]` | `<not set>`       | `<not set>`    | `[ep-1 foo bar]` |
| `[/ep-1]`        | `[foo bar]` | `[/ep-2]`         | `<not set>`    | `[ep-2]`         |
| `[/ep-1]`        | `[foo bar]` | `<not set>`       | `[zoo boo]`    | `[ep-1 zoo boo]` |
| `[/ep-1]`        | `[foo bar]` | `[/ep-2]`         | `[zoo boo]`    | `[ep-2 zoo boo]` |