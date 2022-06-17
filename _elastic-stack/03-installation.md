---
title: "ES 安装与配置"
permalink: /elastic-stack/installation/
last_modified_at: 2022-05-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: true
toc_label: "ES 安装与配置"
---

### 使用 docker 安装 es

本例使用的环境为 [Docker Desktop](https://www.docker.com/products/docker-desktop)

```shell
$ docker network create elastic
$ docker run --name es01 --net elastic -p 9200:9200 -p 9300:9300 -it docker.elastic.co/elasticsearch/elasticsearch:8.2.0
```

当第一次启动 Elasticsearch 时，以下安全配置会自动发生：

- 为传输层和 HTTP 层生成证书和密钥。
- 传输层安全 (TLS) 配置设置写入 elasticsearch.yml。
- 为弹性用户生成密码。
- 为 Kibana 生成一个注册令牌。

```
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-> Elasticsearch security features have been automatically configured!
-> Authentication is enabled and cluster connections are encrypted.

->  Password for the elastic user (reset with `bin/elasticsearch-reset-password -u elastic`):
  UxvzXfghlLA8G4tRIjeL

->  HTTP CA certificate SHA-256 fingerprint:
  1e07085b0198ad0590f08f77f16ccbd56308e932eb811a12a8125f7bdef56b64

->  Configure Kibana to use this cluster:
* Run Kibana and click the configuration link in the terminal when Kibana starts.
* Copy the following enrollment token and paste it into Kibana in your browser (valid for the next 30 minutes):
  eyJ2ZXIiOiI4LjIuMCIsImFkciI6WyIxNzIuMTguMC4yOjkyMDAiXSwiZmdyIjoiMWUwNzA4NWIwMTk4YWQwNTkwZjA4Zjc3ZjE2Y2NiZDU2MzA4ZTkzMmViODExYTEyYTgxMjVmN2JkZWY1NmI2NCIsImtleSI6IkFaS2NiNEVCU1FLNG1PVGtnbVJlOjNQV21IZEtSU3Bha3ZuUVFrYk9UM3cifQ==

-> Configure other nodes to join this cluster:
* Copy the following enrollment token and start new Elasticsearch nodes with `bin/elasticsearch --enrollment-token <token>` (valid for the next 30 minutes):
  eyJ2ZXIiOiI4LjIuMCIsImFkciI6WyIxNzIuMTguMC4yOjkyMDAiXSwiZmdyIjoiMWUwNzA4NWIwMTk4YWQwNTkwZjA4Zjc3ZjE2Y2NiZDU2MzA4ZTkzMmViODExYTEyYTgxMjVmN2JkZWY1NmI2NCIsImtleSI6Il81S2NiNEVCU1FLNG1PVGtnbU01Omk4THZCd2RHVFltdC1mYUZLdVZIWlEifQ==

  If you're running in Docker, copy the enrollment token and run:
  `docker run -e "ENROLLMENT_TOKEN=<token>" docker.elastic.co/elasticsearch/elasticsearch:8.2.0`
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
```

安装及运行 kibana

```shell
$ docker run --name kibana --net elastic -p 5601:5601 docker.elastic.co/kibana/kibana:8.2.0
...
i Kibana has not been configured.

Go to http://0.0.0.0:5601/?code=258592 to get started.




Your verification code is:  258 592
...
```

浏览器访问：http://0.0.0.0:5601/?code=258592

### 使用 docker compose 安装 es

#### 1）环境准备

在新的空目录中创建以下配置文件。这些文件也可以从 GitHub 上的 [elasticsearch](https://github.com/elastic/elasticsearch/tree/master/docs/reference/setup/install/docker) 存储库中获得。

**`.env`**

`.env` 文件设置运行 docker-compose.yml 配置文件时使用的环境变量。确保使用 ELASTIC_PASSWORD 和 KIBANA_PASSWORD 变量为 elastic 和 kibana_system 用户指定强密码。这些变量由 docker-compose.yml 文件引用。

```yml
# Password for the 'elastic' user (at least 6 characters)
ELASTIC_PASSWORD=elastic

# Password for the 'kibana_system' user (at least 6 characters)
KIBANA_PASSWORD=kibana

# Version of Elastic products
STACK_VERSION=8.2.0

# Set the node and cluster name
CLUSTER_NAME=elastdocker-cluster
NODE_NAME=elastdocker-node-0
INIT_MASTER_NODE=elastdocker-node-0

# Hostnames of master eligble elasticsearch instances. (matches compose generated host name)
DISCOVERY_SEEDS_HOSTS=elasticsearch

# Set to 'basic' or 'trial' to automatically start the 30-day trial
LICENSE=basic
#LICENSE=trial

# Port to expose Elasticsearch HTTP API to the host
ES_PORT=9200
#ES_PORT=127.0.0.1:9200

# Port to expose Kibana to the host
KIBANA_PORT=5601
#KIBANA_PORT=80

# Increase or decrease based on the available host memory (in bytes)
MEM_LIMIT=1073741824

# Project namespace (defaults to the current folder name if not set)
COMPOSE_PROJECT_NAME=elastic
```

**`docker-compose.yml`**

这个 `docker-compose.yml` 文件创建了一个启用了身份验证和网络加密的三节点安全 Elasticsearch 集群，以及一个安全连接到它的 Kibana 实例

> **Exposing ports**：如果您不想将端口 9200 暴露给外部主机，请将 `.env` 文件中的 `ES_PORT` 的值设置为 `127.0.0.1:9200` 之类的值。 Elasticsearch 将只能从主机本身访问。

```yml
version: "2.2"

services:
  setup:
    image: registry.cn-shenzhen.aliyuncs.com/aluo/elasticsearch:${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
    user: "0"
    command: >
      bash -c '
        if [ x${ELASTIC_PASSWORD} == x ]; then
          echo "Set the ELASTIC_PASSWORD environment variable in the .env file";
          exit 1;
        elif [ x${KIBANA_PASSWORD} == x ]; then
          echo "Set the KIBANA_PASSWORD environment variable in the .env file";
          exit 1;
        fi;
        if [ ! -f config/certs/ca.zip ]; then
          echo "Creating CA";
          bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
          unzip config/certs/ca.zip -d config/certs;
        fi;
        if [ ! -f config/certs/certs.zip ]; then
          echo "Creating certs";
          echo -ne \
          "instances:\n"\
          "  - name: elasticsearch\n"\
          "    dns:\n"\
          "      - elasticsearch\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          "  - name: kibana\n"\
          "    dns:\n"\
          "      - kibana\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          > config/certs/instances.yml;
          bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
          unzip config/certs/certs.zip -d config/certs;
        fi;
        echo "Setting file permissions"
        chown -R root:root config/certs;
        find . -type d -exec chmod 750 \{\} \;;
        find . -type f -exec chmod 640 \{\} \;;
        echo "Waiting for Elasticsearch availability";
        until curl -s --cacert config/certs/ca/ca.crt https://elasticsearch:9200 | grep -q "missing authentication credentials"; do sleep 30; done;
        echo "Setting kibana_system password";
        until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://elasticsearch:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;
        echo "All done!";
      '
    healthcheck:
      test: ["CMD-SHELL", "[ -f config/certs/elasticsearch/elasticsearch.crt ]"]
      interval: 1s
      timeout: 5s
      retries: 120

  elasticsearch:
    depends_on:
      setup:
        condition: service_healthy
    image: registry.cn-shenzhen.aliyuncs.com/aluo/elasticsearch:${STACK_VERSION}
    volumes:
      #- ./elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - certs:/usr/share/elasticsearch/config/certs
      - esdata:/usr/share/elasticsearch/data
    ports:
      - ${ES_PORT}:9200
    environment:
      - node.name=${NODE_NAME}
      - cluster.name=${CLUSTER_NAME}
      - cluster.initial_master_nodes=${INIT_MASTER_NODE}
      - discovery.seed_hosts=${DISCOVERY_SEEDS_HOSTS}
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/elasticsearch/elasticsearch.key
      - xpack.security.http.ssl.certificate=certs/elasticsearch/elasticsearch.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.http.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/elasticsearch/elasticsearch.key
      - xpack.security.transport.ssl.certificate=certs/elasticsearch/elasticsearch.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.license.self_generated.type=${LICENSE}
    mem_limit: ${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s --cacert config/certs/ca/ca.crt https://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  kibana:
    depends_on:
      elasticsearch:
        condition: service_healthy
    image: registry.cn-shenzhen.aliyuncs.com/aluo/kibana:${STACK_VERSION}
    volumes:
      #- ./kibana.yml:/usr/share/kibana/config/kibana.yml
      - certs:/usr/share/kibana/config/certs
      - kibanadata:/usr/share/kibana/data
    ports:
      - ${KIBANA_PORT}:5601
    environment:
      - SERVERNAME=kibana
      - ELASTICSEARCH_HOSTS=https://elasticsearch:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
      - ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=config/certs/ca/ca.crt
    mem_limit: ${MEM_LIMIT}
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 302 Found'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

volumes:
  certs:
    driver: local
  esdata:
    driver: local
  kibanadata:
    driver: local
```

#### 2）启动集群

创建并启动 Elasticsearch 和 Kibana 实例

```shell
$ docker-compose up -d
```

#### 3）测试访问

部署开始后，打开浏览器并导航到 http://localhost:5601 以访问 Kibana，您可以在其中加载示例数据并与集群交互。

#### 4）停止并删除部署

要停止集群，请运行 docker-compose down。当您使用 docker-compose up 重新启动集群时，Docker 卷中的数据会被保留并加载。

```shell
$ docker-compose down
```

要在停止集群时删除网络、容器和卷，请指定 -v 选项：

```shell
$ docker-compose down -v
```

### 使用 RPM 安装包安装 es

本文创建由 3 个节点组成的 elasticsearch 集群

#### Step 1：下载并安装 RPM

各节点分别执行如下命令下载并安装 RPM

```shell
$ wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.2.0-x86_64.rpm
$ wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.2.0-x86_64.rpm.sha512
$ shasum -a 512 -c elasticsearch-8.2.0-x86_64.rpm.sha512
$ sudo rpm --install elasticsearch-8.2.0-x86_64.rpm
```

> **NOTE**：在基于 systemd 的发行版上，安装脚本将尝试设置内核参数（例如 vm.max_map_count）；可以通过屏蔽 systemd-sysctl.service 单元来跳过此步骤。

#### Step 2：配置 Elasticsearch

修改各节点的 `/etc/elasticsearch/elasticsearch.yml` 配置文件

*es-logs-node1*

```yml
cluster.name: es-logs-cluster
node.name: es-logs-node1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 192.168.25.111
cluster.initial_master_nodes: ["es-logs-node1"]
#node.attr.my_rack_id: rack1
#cluster.routing.allocation.awareness.attributes: my_rack_id
#node.roles: [ master ]
```

*es-logs-node2*

```yml
cluster.name: es-logs-cluster
node.name: es-logs-node2
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 192.168.25.112
discovery.seed_hosts: ["192.168.25.111:9300","192.168.25.113:9300"]
#node.attr.my_rack_id: rack2
#node.roles: [ data, ingest ]
```

*es-logs-node3*

```yml
cluster.name: es-logs-cluster
node.name: es-logs-node3
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 192.168.25.113
discovery.seed_hosts: ["192.168.25.111:9300","192.168.25.112:9300"]
#node.attr.my_rack_id: rack3
#node.roles: [ data, ingest ]
```

#### Step 3：启动初始主节点，生成节点注册令牌

启动初始主节点 *es-logs-node1* ，然后会自动生成一个叫做 “es-logs-cluster” 的集群

```shell
$ sudo systemctl daemon-reload
$ sudo systemctl enable elasticsearch.service --now
```

在 *es-logs-node1* 节点执行以下命令，生成节点注册令牌

```shell
$ /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
eyJ2ZXIiOiI4LjIuMCIsImFkciI6WyIxOTIuMTY5LjYwLjUwOjkyMDAiXSwiZmdyIjoiMDdjOTU3MmVlNTMyNDJhYWRkODRhZTk2ODQ5MmZmZjM3Y2U5N2UxOGJmODA5YTVhMDQzMWNkNTE5ZTQ1NmM3ZSIsImtleSI6InhUS1R6NEFCcTV1VzJfWktMRU9zOmkyb0NneFRNUS1DZFAyc0tET193TXcifQ==
```

#### Step 4：重新配置其他节点以加入现有集群

在 *es-logs-node2*、*es-logs-node3* 节点执行以下命令，加入  “es-logs-cluster” 集群

```shell
$ /usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token eyJ2ZXIiOiI4LjIuMCIsImFkciI6WyIxOTIuMTY5LjYwLjUwOjkyMDAiXSwiZmdyIjoiMDdjOTU3MmVlNTMyNDJhYWRkODRhZTk2ODQ5MmZmZjM3Y2U5N2UxOGJmODA5YTVhMDQzMWNkNTE5ZTQ1NmM3ZSIsImtleSI6InhUS1R6NEFCcTV1VzJfWktMRU9zOmkyb0NneFRNUS1DZFAyc0tET193TXcifQ==
```

> 详细信息请查看[重新配置节点以加入现有集群](#重新配置节点以加入现有集群)

#### Step 5：启动其他节点

```shell
$ sudo systemctl daemon-reload
$ sudo systemctl enable elasticsearch.service --now
```

#### [重新配置节点以加入现有集群](https://www.elastic.co/guide/en/elasticsearch/reference/8.2/rpm.html#_reconfigure_a_node_to_join_an_existing_cluster_2)

安装 Elasticsearch 时，安装过程默认配置单节点集群。如果希望某个节点改为加入现有集群，请在**第一次启动新节点之前**在现有节点上生成一个注册令牌。

**1）**在现有集群中的任何节点上，生成节点注册令牌：

```shell
$ /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
eyJ2ZXIiOiI4LjIuMCIsImFkciI6WyIxOTIuMTY5LjYwLjUwOjkyMDAiXSwiZmdyIjoiMDdjOTU3MmVlNTMyNDJhYWRkODRhZTk2ODQ5MmZmZjM3Y2U5N2UxOGJmODA5YTVhMDQzMWNkNTE5ZTQ1NmM3ZSIsImtleSI6InhUS1R6NEFCcTV1VzJfWktMRU9zOmkyb0NneFRNUS1DZFAyc0tET193TXcifQ==
```

**2）**复制输出到您终端的注册令牌

**3）**在您的新 Elasticsearch 节点上，将注册令牌作为参数传递给 elasticsearch-reconfigure-node 工具：

```shell
$ /usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token eyJ2ZXIiOiI4LjIuMCIsImFkciI6WyIxOTIuMTY5LjYwLjUwOjkyMDAiXSwiZmdyIjoiMDdjOTU3MmVlNTMyNDJhYWRkODRhZTk2ODQ5MmZmZjM3Y2U5N2UxOGJmODA5YTVhMDQzMWNkNTE5ZTQ1NmM3ZSIsImtleSI6InhUS1R6NEFCcTV1VzJfWktMRU9zOmkyb0NneFRNUS1DZFAyc0tET193TXcifQ==
```

> **<font color="#FF0000">注意</font>**：**`elasticsearch-reconfigure-node`** 工具只是重新配置新节点使用现有集群生成的**注册令牌**以加入现有群集，具体配置项包含如下内容：
>
> - 初始安装默认的安全自动配置将从 `elasticsearch.yml` 删除
> - 初始安装默认的 [certs] 配置目录将被删除
> - 初始安装默认的安全自动配置相关的安全设置将从 `elasticsearch.keystore` 删除

Elasticsearch 现在配置为加入现有集群。

**4）**使用 systemd 启动新节点。

```shell
$ sudo systemctl enable elasticsearch.service --now
```

