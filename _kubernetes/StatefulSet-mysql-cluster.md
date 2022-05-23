---
title: "使用 StatefulSet 部署 MySQL 集群"
excerpt: "本文展示如何使用 StatefulSet 控制器部署 MySQL 集群。此例是多副本的 MySQL 数据库。 示例应用的拓扑结构有一个主服务器和多个副本，使用异步的基于行（Row-Based） 的数据复制。"
toc: true
---

本文展示如何使用 StatefulSet 控制器部署 MySQL 集群。此例是多副本的 MySQL 数据库。 示例应用的拓扑结构有一个主服务器和多个副本，使用异步的基于行（Row-Based） 的数据复制。

> **说明：** **这不是生产环境下配置**。 尤其注意，MySQL 设置都使用的是不安全的默认值，这是因为我们想把重点放在 Kubernetes 中运行有状态应用程序的一般模式上。

首先，描述一下我们想要部署的 “有状态应用”：

1. 是一个 “主从复制”（Maser-Slave Replication）的 MySQL 集群；
2. 有 1 个主节点（Master），多个从节点（Slave）；
3. 从节点需要能水平扩展；
4. 所有的写操作，只能在主节点上执行；读操作可以在所有节点上执行。

这是一个非常典型的主从模式的 MySQL 集群。在常规环境里，部署这样一个主从模式的 MySQL 集群的主要难点在于：如何让从节点能够拥有主节点的数据，即：如何配置主（Master）从（Slave）节点的复制与同步。

**第一步：将 Master 节点的数据备份到指定目录**

在安装好 MySQL 的 Master 节点之后，需要做的第一步工作，就是通过 XtraBackup 将 Master 节点的数据备份到指定目录。

> 备注：XtraBackup 是业界主要使用的开源 MySQL 备份和恢复工具。

这一步会自动在目标目录里生成一个备份信息文件，名叫：xtrabackup_binlog_info。这个文件一般会包含如下两个信息：

```shell
$ cat xtrabackup_binlog_info
TheMaster-bin.000001     481
```

这两个信息会在接下来配置 Slave 节点的时候用到。

**第二步：配置 Slave 节点**

Slave 节点在第一次启动前，需要先把 Master 节点的备份数据，连同备份信息文件，一起拷贝到自己的数据目录（/var/lib/mysql）下。然后，我们执行这样一句 SQL：

```shell
TheSlave|mysql> CHANGE MASTER TO
                MASTER_HOST='$masterip',
                MASTER_USER='xxx',
                MASTER_PASSWORD='xxx',
                MASTER_LOG_FILE='TheMaster-bin.000001',
                MASTER_LOG_POS=481;
```

其中，MASTER_LOG_FILE 和 MASTER_LOG_POS，就是该备份对应的二进制日志（Binary Log）文件的名称和开始的位置（偏移量），也正是 xtrabackup_binlog_info 文件里的那两部分内容（即：TheMaster-bin.000001 和 481）。

**第三步：启动 Slave 节点**

在这一步，我们需要执行这样一句 SQL：

```shell
TheSlave|mysql> START SLAVE;
```

这样，Slave 节点就启动了。它会使用备份信息文件中的二进制日志文件和偏移量，与主节点进行数据同步。

**第四步：在这个集群中添加更多的 Slave 节点**

需要注意的是，新添加的 Slave 节点的备份数据，来自于已经存在的 Slave 节点。所以，在这一步，我们需要将 Slave 节点的数据备份在指定目录。而这个备份操作会自动生成另一种备份信息文件，名叫：xtrabackup_slave_info。同样地，这个文件也包含了 MASTER_LOG_FILE 和 MASTER_LOG_POS 两个字段。然后，我们就可以执行跟前面一样的 “CHANGE MASTER TO” 和 “START SLAVE” 指令，来初始化并启动这个新的 Slave 节点了。

通过上面的叙述，我们不难看到，将部署 MySQL 集群的流程迁移到 Kubernetes 项目上，需要能够 “容器化” 地解决下面的 “三座大山”：

1. Master 节点和 Slave 节点需要有不同的配置文件（即：不同的 my.cnf）
2. Master 节点和 Slave 节点需要能够传输备份信息文件
3. 在 Slave 节点第一次启动之前，需要执行一些初始化 SQL 操作

而由于 MySQL 本身同时拥有拓扑状态（主从节点的区别）和存储状态（MySQL 保存在本地的数据），我们自然要通过 StatefulSet 来解决这 “三座大山” 的问题。

## 准备配置文件

MySQL 部署包含一个 ConfigMap、两个 Service 与一个 StatefulSet。

### ConfigMap

使用以下的 YAML 配置文件创建 ConfigMap ：

> [`application/mysql/mysql-configmap.yaml`](https://raw.githubusercontent.com/aluopy/kubernetes/master/best-practice/resource/mysql/mysql-configmap.yaml)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql
  labels:
    app: mysql
data:
  master.cnf: |
    # 主节点MySQL的配置文件
    [mysqld]
    log-bin    
  slave.cnf: |
    # 从节点MySQL的配置文件
    [mysqld]
    super-read-only
```

在这里，我们定义了 master.cnf 和 slave.cnf 两个 MySQL 的配置文件。

- master.cnf 开启了 `log-bin` ，即：使用二进制日志文件的方式进行主从复制，这是一个标准的设置。
- slave.cnf 开启了 `super-read-only` ，代表的是从节点会拒绝除了主节点的数据同步操作之外的所有写操作，即：它对用户是只读的。

而上述 ConfigMap 定义里的 data 部分，是 Key-Value 格式的。比如，master.cnf 就是这份配置数据的 Key，而 `“|”` 后面的内容，就是这份配置数据的 Value。这份数据将来挂载进 Master 节点对应的 Pod 后，就会在 Volume 目录里生成一个叫作 master.cnf 的文件。

### Service

使用以下 YAML 配置文件创建 Service ：

> [`application/mysql/mysql-services.yaml`](https://raw.githubusercontent.com/aluopy/kubernetes/master/best-practice/resource/mysql/mysql-services.yaml)

```yaml
# Headless service for stable DNS entries of StatefulSet members.
apiVersion: v1
kind: Service
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  ports:
  - name: mysql
    port: 3306
  clusterIP: None
  selector:
    app: mysql
---
# Client service for connecting to any MySQL instance for reads.
# For writes, you must instead connect to the master: mysql-0.mysql.
apiVersion: v1
kind: Service
metadata:
  name: mysql-read
  labels:
    app: mysql
spec:
  ports:
  - name: mysql
    port: 3306
  selector:
    app: mysql
```

可以看到，这两个 Service 都代理了所有携带 `app=mysql` 标签的 Pod，也就是所有的 MySQL Pod。端口映射都是用 Service 的 3306 端口对应 Pod 的 3306 端口。

不同的是，第一个名叫 “mysql” 的 Service 是一个 Headless Service（即：clusterIP= None）。所以它的作用，是通过为 Pod 分配 DNS 记录（`<Pod 名称>.mysql`）来固定它的拓扑状态，比如 “mysql-0.mysql” 和 “mysql-1.mysql” 这样的 DNS 名字。其中，编号为 0 的节点就是我们的主节点。

而第二个名叫 “mysql-read” 的 Service，则是一个常规的 Service。

并且我们规定，所有用户的读请求，都必须访问第二个 Service 被自动分配的 DNS 记录，即：“mysql-read”（当然，也可以访问这个 Service 的 VIP）。这样，读请求就可以被转发到任意一个 MySQL 的主节点或者从节点上。

而所有用户的写请求，则必须直接以 DNS 记录的方式访问到 MySQL 的主节点，也就是：“mysql-0.mysql“ 这条 DNS 记录。

### StatefulSet

最后，使用以下 YAML 配置文件创建 StatefulSet：

> [`application/mysql/mysql-statefulset.yaml`](https://raw.githubusercontent.com/aluopy/kubernetes/master/best-practice/resource/mysql/mysql-statefulset.yaml)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  serviceName: mysql
  replicas: 3
  template:
    metadata:
      labels:
        app: mysql
    spec:
      initContainers:
      - name: init-mysql
        image: mysql:5.7
        command:
        - bash
        - "-c"
        - |
          set -ex
          # 从Pod的序号，生成server-id
          [[ `hostname` =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          echo [mysqld] > /mnt/conf.d/server-id.cnf
          # 由于server-id=0有特殊含义，我们给ID加一个100来避开它
          echo server-id=$((100 + $ordinal)) >> /mnt/conf.d/server-id.cnf
          # 如果Pod序号是0，说明它是Master节点，从ConfigMap里把Master的配置文件拷贝到/mnt/conf.d/目录；
          # 否则，拷贝Slave的配置文件
          if [[ $ordinal -eq 0 ]]; then
            cp /mnt/config-map/master.cnf /mnt/conf.d/
          else
            cp /mnt/config-map/slave.cnf /mnt/conf.d/
          fi          
        volumeMounts:
        - name: conf
          mountPath: /mnt/conf.d
        - name: config-map
          mountPath: /mnt/config-map
      - name: clone-mysql
        image: registry.cn-shenzhen.aliyuncs.com/aluopy-k8s/xtrabackup:1.0
        command:
        - bash
        - "-c"
        - |
          set -ex
          # 拷贝操作只需要在第一次启动时进行，所以如果数据已经存在，跳过
          [[ -d /var/lib/mysql/mysql ]] && exit 0
          # Master节点(序号为0)不需要做这个操作
          [[ `hostname` =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          [[ $ordinal -eq 0 ]] && exit 0
          # 使用ncat指令，远程地从前一个节点拷贝数据到本地
          ncat --recv-only mysql-$(($ordinal-1)).mysql 3307 | xbstream -x -C /var/lib/mysql
          # 执行--prepare，这样拷贝来的数据就可以用作恢复了
          xtrabackup --prepare --target-dir=/var/lib/mysql          
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
          subPath: mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ALLOW_EMPTY_PASSWORD
          value: "1"
        ports:
        - name: mysql
          containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
          subPath: mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
        livenessProbe:
          exec:
            command: ["mysqladmin", "ping"]
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            # 通过 TCP 连接的方式进行健康检查
            command: ["mysql", "-h", "127.0.0.1", "-e", "SELECT 1"]
          initialDelaySeconds: 5
          periodSeconds: 2
          timeoutSeconds: 1
      - name: xtrabackup
        image: registry.cn-shenzhen.aliyuncs.com/aluopy-k8s/xtrabackup:1.0
        ports:
        - name: xtrabackup
          containerPort: 3307
        command:
        - bash
        - "-c"
        - |
          set -ex
          cd /var/lib/mysql

          # 从备份信息文件里读取 MASTER_LOG_FILEM 和 MASTER_LOG_POS 这两个字段的值，用来拼装集群初始化SQL
          if [[ -f xtrabackup_slave_info && "x$(<xtrabackup_slave_info)" != "x" ]]; then
            # 如果 xtrabackup_slave_info 文件存在且不为空，说明这个备份数据来自于另一个Slave节点。
            # 这种情况下，XtraBackup 工具在备份的时候，就已经在这个文件里自动生成了"CHANGE MASTER TO" SQL 语句。
            # 所以，我们只需要把这个文件重命名为 change_master_to.sql.in，后面直接使用即可。
            cat xtrabackup_slave_info | sed -E 's/;$//g' > change_master_to.sql.in
            # 所以，也就用不着 xtrabackup_binlog_info 了
            rm -f xtrabackup_slave_info xtrabackup_binlog_info
          elif [[ -f xtrabackup_binlog_info ]]; then
            # 如果只存在 xtrabackup_binlog_inf 文件，那说明备份来自于 Master 节点，
            # 我们就需要解析这个备份信息文件，读取所需的两个字段的值
            [[ `cat xtrabackup_binlog_info` =~ ^(.*?)[[:space:]]+(.*?)$ ]] || exit 1
            rm -f xtrabackup_binlog_info xtrabackup_slave_info
            # 把两个字段的值拼装成SQL，写入 change_master_to.sql.in 文件
            echo "CHANGE MASTER TO MASTER_LOG_FILE='${BASH_REMATCH[1]}',\
                  MASTER_LOG_POS=${BASH_REMATCH[2]}" > change_master_to.sql.in
          fi

          # 如果 change_master_to.sql.in，就意味着需要做集群初始化工作
          if [[ -f change_master_to.sql.in ]]; then
            # 但一定要先等 MySQL 容器启动之后才能进行下一步连接MySQL的操作
            echo "Waiting for mysqld to be ready (accepting connections)"
            until mysql -h 127.0.0.1 -e "SELECT 1"; do sleep 1; done

            echo "Initializing replication from clone position"
            # 使用 change_master_to.sql.in 的内容，也是就是前面拼装的 SQL，
            # 组成一个完整的初始化和启动 Slave 的 SQL 语句
            mysql -h 127.0.0.1 \
                  -e "$(<change_master_to.sql.in), \
                          MASTER_HOST='mysql-0.mysql', \
                          MASTER_USER='root', \
                          MASTER_PASSWORD='', \
                          MASTER_CONNECT_RETRY=10; \
                        START SLAVE;" || exit 1
            # 将文件 change_master_to.sql.in 改个名字，防止这个 Container 重启的时候，
            # 因为又找到了 change_master_to.sql.in，从而重复执行一遍这个初始化流程
            mv change_master_to.sql.in change_master_to.sql.orig
          fi

          # 使用 ncat 监听 3307 端口。它的作用是，在收到传输请求的时候，
          # 直接执行 "xtrabackup --backup" 命令，备份 MySQL 的数据并发送给请求者。
          exec ncat --listen --keep-open --send-only --max-conns=1 3307 -c \
            "xtrabackup --backup --slave-info --stream=xbstream --host=127.0.0.1 --user=root"          
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
          subPath: mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
      volumes:
      - name: conf
        emptyDir: {}
      - name: config-map
        configMap:
          name: mysql
  volumeClaimTemplates:
  - metadata:
      name: data
      annotations:
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: aluopy-sc
      resources:
        requests:
          storage: 10Gi
```

#### YAML 文件解读

##### InitContainer：`init-mysql`

根据节点的角色是 Master 还是 Slave 节点，为 Pod 分配对应的配置文件。此外，MySQL 还要求集群里的每个节点都有一个唯一的 ID 文件，名叫 server-id.cnf。

在这个名叫 `init-mysql` 的 InitContainer 的配置中，它从 Pod 的 hostname 里，读取到了 Pod 的序号，以此作为 MySQL 节点的 server-id。然后，init-mysql 通过这个序号，判断当前 Pod 到底是 Master 节点（即：序号为 0）还是 Slave 节点（即：序号不为 0），从而把对应的配置文件从 /mnt/config-map 目录拷贝到 /mnt/conf.d/ 目录下。

其中，文件拷贝的源目录 /mnt/config-map，正是 ConfigMap 在这个 Pod 的 Volume，如下所示：

```yaml
      ...
      # template.spec
      volumes:
      - name: conf
        emptyDir: {}
      - name: config-map
        configMap:
          name: mysql
```

通过这个定义，init-mysql 在声明了挂载 config-map 这个 Volume 之后，ConfigMap 里保存的内容，就会以文件的方式出现在它的 /mnt/config-map 目录当中。而文件拷贝的目标目录，即容器里的 /mnt/conf.d/ 目录，对应的则是一个名叫 conf 的、emptyDir 类型的 Volume。基于 Pod Volume 共享的原理，当 InitContainer 复制完配置文件退出后，后面启动的 MySQL 容器只需要直接声明挂载这个名叫 conf 的 Volume，它所需要的.cnf 配置文件已经出现在里面了。

##### InitContainer：`clone-mysql`

在 Slave Pod 启动前，从 Master 或者其他 Slave Pod 里拷贝数据库数据到自己的目录下。

在这个名叫 `clone-mysql` 的 InitContainer 里，我们使用的是 xtrabackup 镜像（它里面安装了 xtrabackup 工具）。

而在它的启动命令里，我们首先做了一个判断。即：当初始化所需的数据（/var/lib/mysql/mysql 目录）已经存在，或者当前 Pod 是 Master 节点的时候，不需要做拷贝操作。

接下来，clone-mysql 会使用 Linux 自带的 ncat 指令，向 DNS 记录为 `mysql-< 当前序号减1 >.mysql` 的 Pod，也就是当前 Pod 的前一个 Pod，发起数据传输请求，并且直接用 xbstream 指令将收到的备份数据保存在 /var/lib/mysql 目录下。

> 备注：3307 是一个特殊端口，运行着一个专门负责备份 MySQL 数据的辅助进程。后续会用到。

这个容器里的 /var/lib/mysql 目录，实际上正是一个名为 data 的 PVC，即：我们在前面声明的持久化存储。

这就可以保证，哪怕宿主机宕机了，我们数据库的数据也不会丢失。更重要的是，由于 Pod Volume 是被 Pod 里的容器共享的，所以后面启动的 MySQL 容器，就可以把这个 Volume 挂载到自己的 /var/lib/mysql 目录下，直接使用里面的备份数据进行恢复操作。

不过，clone-mysql 容器还要对 /var/lib/mysql 目录，执行一句 xtrabackup --prepare 操作，目的是让拷贝来的数据进入一致性状态，这样，这些数据才能被用作数据恢复。

至此，我们就通过 InitContainer 完成了对 “主、从节点间备份文件传输” 操作的处理过程

##### Sidecar 容器：xtrabackup

在 Slave 节点的 MySQL 容器第一次启动之前，执行初始化 SQL。

在这个名叫 xtrabackup 的 sidecar 容器的启动命令里，其实实现了两部分工作。

**第一部分工作，当然是 MySQL 节点的初始化工作**。这个初始化需要使用的 SQL，是 sidecar 容器拼装出来、保存在一个名为 `change_master_to.sql.in` 的文件里的，具体过程如下所示：

sidecar 容器首先会判断当前 Pod 的 /var/lib/mysql 目录下，是否有 xtrabackup_slave_info 这个备份信息文件。

- 如果有，则说明这个目录下的备份数据是由一个 Slave 节点生成的。这种情况下，XtraBackup 工具在备份的时候，就已经在这个文件里自动生成了 "CHANGE MASTER TO"  SQL 语句。所以，我们只需要把这个文件重命名为 change_master_to.sql.in，后面直接使用即可。
- 如果没有 xtrabackup_slave_info 文件、但是存在 xtrabackup_binlog_info 文件，那就说明备份数据来自于 Master 节点。这种情况下，sidecar 容器就需要解析这个备份信息文件，读取 MASTER_LOG_FILE 和 MASTER_LOG_POS 这两个字段的值，用它们拼装出初始化 SQL 语句，然后把这句 SQL 写入到 change_master_to.sql.in 文件中。

接下来，sidecar 容器就可以执行初始化了。从上面的叙述中可以看到，只要这个 change_master_to.sql.in 文件存在，那就说明接下来需要进行集群初始化操作。

所以，这时候，sidecar 容器只需要读取并执行 change_master_to.sql.in 里面的“CHANGE MASTER TO”指令，再执行一句 START SLAVE 命令，一个 Slave 节点就被成功启动了。

> 需要注意的是：Pod 里的容器（普通容器）并没有先后顺序，所以在执行初始化 SQL 之前，必须先执行一句 SQL（select 1）来检查一下 MySQL 服务是否已经可用。

当然，上述这些初始化操作完成后，我们还要删除掉前面用到的这些备份信息文件。否则，下次这个容器重启时，就会发现这些文件存在，所以又会重新执行一次数据恢复和集群初始化的操作，这是不对的。

同理，change_master_to.sql.in 在使用后也要被重命名，以免容器重启时因为发现这个文件存在又执行一遍初始化。

**在完成 MySQL 节点的初始化后，这个 sidecar 容器的第二个工作，则是启动一个数据传输服务。**

具体做法是：sidecar 容器会使用 ncat 命令启动一个工作在 3307 端口上的网络发送服务。一旦收到数据传输请求时，sidecar 容器就会调用 xtrabackup --backup 指令备份当前 MySQL 的数据，然后把这些备份数据返回给请求者。这就是为什么我们在 InitContainer 里定义数据拷贝的时候，访问的是 “上一个 MySQL 节点” 的 3307 端口。

值得一提的是，由于 sidecar 容器和 MySQL 容器同处于一个 Pod 里，所以它是直接通过 Localhost 来访问和备份 MySQL 容器里的数据的，非常方便。

至此，我们就完成了 Slave 节点第一次启动前的初始化工作。

##### MySQL 容器：mysql

在这个容器的定义里，我们使用了一个标准的 MySQL 5.7 的官方镜像。它的数据目录是 /var/lib/mysql，配置文件目录是 /etc/mysql/conf.d。

如果 MySQL 容器是 Slave 节点的话，它的数据目录里的数据，就来自于 InitContainer 从其他节点里拷贝而来的备份。它的配置文件目录 /etc/mysql/conf.d 里的内容，则来自于 ConfigMap 对应的 Volume。而它的初始化工作，则是由同一个 Pod 里的 sidecar 容器完成的。

另外，我们为它定义了一个 livenessProbe，通过 mysqladmin ping 命令来检查它是否健康；还定义了一个 readinessProbe，通过查询 SQL（select 1）来检查 MySQL 服务是否可用。当然，凡是 readinessProbe 检查失败的 MySQL Pod，都会从 Service 里被摘除掉。

至此，一个完整的主从复制模式的 MySQL 集群就定义完了。

## 准备持久卷

首先，我们需要在 Kubernetes 集群里创建满足条件的 PV

本文用 StorageClass 来完成这个操作。它的作用是自动地为集群里存在的每一个 PVC，调用存储插件（本文使用的 nfs-client-provisioner）创建对应的 PV，从而省去了我们手动创建 PV 的机械劳动。

```shell
$ kubectl get sc
NAME        PROVISIONER   RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
aluopy-sc   aluopy/nfs    Retain          Immediate           false                  3s
```

> 备注：在使用 nfs-client-provisioner 的情况下，mysql-statefulset.yaml 里的 volumeClaimTemplates 字段需要加上声明 storageClassName: aluopy-sc，才能使用到这个 nfs-client-provisioner 提供的持久化存储。

## 部署 MySQL

执行如下命令创建相关资源

```shell
$ kubectl apply -f https://raw.githubusercontent.com/aluopy/kubernetes/master/best-practice/resource/mysql/mysql-configmap.yaml
configmap/mysql created

$ kubectl apply -f https://raw.githubusercontent.com/aluopy/kubernetes/master/best-practice/resource/mysql/mysql-services.yaml
service/mysql created

$ kubectl apply -f https://raw.githubusercontent.com/aluopy/kubernetes/master/best-practice/resource/mysql/mysql-statefulset.yaml
statefulset.apps/mysql created
```

查看 pod 启动进度：

```shell
$ kubectl get pods -l app=mysql --watch
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   0/2     Pending   0          1s
mysql-0   0/2     Pending   0          2s
mysql-0   0/2     Init:0/2   0          2s
mysql-0   0/2     Init:1/2   0          4s
mysql-0   0/2     PodInitializing   0          5s
mysql-0   1/2     Running           0          6s
mysql-0   2/2     Running           0          20s
mysql-1   0/2     Pending           0          0s
mysql-1   0/2     Pending           0          0s
mysql-1   0/2     Pending           0          2s
mysql-1   0/2     Init:0/2          0          2s
mysql-1   0/2     Init:1/2          0          4s
mysql-1   0/2     Init:1/2          0          5s
mysql-1   0/2     PodInitializing   0          13s
mysql-1   1/2     Running           0          14s
mysql-1   2/2     Running           0          18s
mysql-2   0/2     Pending           0          0s
mysql-2   0/2     Pending           0          0s
mysql-2   0/2     Pending           0          2s
mysql-2   0/2     Init:0/2          0          2s
mysql-2   0/2     Init:1/2          0          4s
mysql-2   0/2     Init:1/2          0          5s
mysql-2   0/2     PodInitializing   0          13s
mysql-2   1/2     Running           0          14s
mysql-2   2/2     Running           0          18s
```

一段时间后，查看 pod 信息，所有 3 个 Pod 进入 Running 状态：

```shell
$ kubectl get pod -l app=mysql
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   2/2     Running   0          53s
mysql-1   2/2     Running   0          33s
mysql-2   1/2     Running   0          15s
```

查看 PV、PVC 信息：

```shell
$ kubectl get pvc,pv
NAME                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/data-mysql-0   Bound    pvc-ba68ba27-7dbc-4690-b622-61e5f09e26ed   10Gi       RWO            aluopy-sc      3m51s
persistentvolumeclaim/data-mysql-1   Bound    pvc-271dc7ef-7587-41ca-8f66-0f887820e699   10Gi       RWO            aluopy-sc      3m31s
persistentvolumeclaim/data-mysql-2   Bound    pvc-5db1a8eb-88fe-4b19-8775-9895dabd7ec1   10Gi       RWO            aluopy-sc      3m13s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
persistentvolume/pvc-271dc7ef-7587-41ca-8f66-0f887820e699   10Gi       RWO            Retain           Bound    default/data-mysql-1   aluopy-sc               3m31s
persistentvolume/pvc-5db1a8eb-88fe-4b19-8775-9895dabd7ec1   10Gi       RWO            Retain           Bound    default/data-mysql-2   aluopy-sc               3m13s
persistentvolume/pvc-ba68ba27-7dbc-4690-b622-61e5f09e26ed   10Gi       RWO            Retain           Bound    default/data-mysql-0   aluopy-sc               3m51s
```

## 发送客户端请求

接下来，我们可以尝试向这个 MySQL 集群发起请求，执行一些 SQL 操作来验证它是否正常：

```shell
$ kubectl run mysql-client --image=mysql:5.7 -i --rm --restart=Never --\
  mysql -h mysql-0.mysql <<EOF
CREATE DATABASE test;
CREATE TABLE test.messages (message VARCHAR(250));
INSERT INTO test.messages VALUES ('hello aluopy');
EOF
```

如上所示，我们通过启动一个容器，使用 MySQL client 执行了创建数据库和表、以及插入数据的操作。需要注意的是，我们连接的 MySQL 的地址必须是 `mysql-0.mysql`（即：Master 节点的 DNS 记录）。因为，只有 Master 节点才能处理写操作。

而通过连接 mysql-read 这个 Service，我们就可以用 SQL 进行读操作，如下所示：

```shell
$ kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never --\
  mysql -h mysql-read -e "SELECT * FROM test.messages"
If you don't see a command prompt, try pressing enter.
+--------------+
| message      |
+--------------+
| hello aluopy |
+--------------+
pod "mysql-client" deleted
```

为了演示 `mysql-read` 服务在服务器之间分配连接，你可以在循环中运行 `SELECT @@server_id`：

```shell
$ kubectl run mysql-client-loop --image=mysql:5.7 -i -t --rm --restart=Never --\
  bash -ic "while sleep 1; do mysql -h mysql-read -e 'SELECT @@server_id,NOW()'; done"
If you don't see a command prompt, try pressing enter.
+-------------+---------------------+
| @@server_id | NOW()               |
+-------------+---------------------+
|         100 | 2022-01-21 10:07:02 |
+-------------+---------------------+
+-------------+---------------------+
| @@server_id | NOW()               |
+-------------+---------------------+
|         101 | 2022-01-21 10:07:10 |
+-------------+---------------------+
+-------------+---------------------+
| @@server_id | NOW()               |
+-------------+---------------------+
|         102 | 2022-01-21 10:07:17 |
+-------------+---------------------+
... ...
```

## 扩展副本节点数量

使用 MySQL 复制，你可以通过添加副本节点来扩展读取查询的能力。 使用 StatefulSet，你可以使用单个命令执行此操作：

```shell
$ kubectl scale statefulset mysql --replicas=5
```

查看新的 Pod 的运行情况：

```shell
$ kubectl get pods -l app=mysql
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   2/2     Running   0          19m
mysql-1   2/2     Running   0          19m
mysql-2   2/2     Running   0          19m
mysql-3   2/2     Running   0          47s
mysql-4   2/2     Running   0          28s
```

这时候，你就会发现新的 Slave Pod mysql-3 和 mysql-4 被自动创建了出来。

而如果你像如下所示的这样，直接连接 mysql-3.mysql，即 mysql-3 这个 Pod 的 DNS 名字来进行查询操作：

```shell
$ kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never --\
  mysql -h mysql-3.mysql -e "SELECT * FROM test.messages"
If you don't see a command prompt, try pressing enter.
+--------------+
| message      |
+--------------+
| hello aluopy |
+--------------+
pod "mysql-client" deleted
```
