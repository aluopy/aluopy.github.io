---
title: "使用 Kustomize 对 Kubernetes 对象进行声明式管理"
permalink: /kubernetes/kustomize/
#excerpt: ""
toc: true
#toc_label: "kubernetes-metrics-server"
#toc_icon: "cog"
categories: kubernetes
tags:
  - kubernetes
  - Kustomize
---

[Kustomize](https://github.com/kubernetes-sigs/kustomize) 是一个独立的工具，用来通过 kustomization 文件定制 Kubernetes 对象。

## Kustomize 简介

> **TL;DR**
>
> - Kustomize 帮助以无模板的方式自定义配置文件
> - Kustomize 提供了许多方便的方法，例如生成器，使定制更容易
> - Kustomize 使用补丁在已经存在的标准配置文件上引入特定于环境的更改，而不会干扰它

Kustomize 提供了一种无需模板和 DSL 即可自定义 Kubernetes 资源配置的解决方案。

Kustomize 允许您自定义原始的、无模板的 YAML 文件以用于多种用途，而原始 YAML 保持不变且可按原样使用。

Kustomize 针对 Kubernetes；它理解并可以修补 Kubernetes 风格的 API 对象。就像 make，它所做的事情是在一个文件中声明的，它就像 sed，它发出编辑过的文本。

从 1.14 版本开始，`kubectl` 开始支持使用 kustomization 文件来管理 Kubernetes 对象。 要查看包含 kustomization 文件的目录中的资源，执行下面的命令：

```shell
$ kubectl kustomize <kustomization_directory>
```

要应用这些资源，使用参数 `--kustomize` 或 `-k` 标志来执行 `kubectl apply`：

```shell
$ kubectl apply -k <kustomization_directory>
```

## Kustomize 使用

Kustomize 是一个用来定制 Kubernetes 配置的工具。它提供以下功能特性来管理应用配置文件：

- 从其他来源生成资源
- 为资源设置贯穿性（Cross-Cutting）字段
- 组织和定制资源集合

### 生成资源

ConfigMap 和 Secret 包含其他 Kubernetes 对象（如 Pod）所需要的配置或敏感数据。 ConfigMap 或 Secret 中数据的来源往往是集群外部，例如某个 `.properties` 文件或者 SSH 密钥文件。 Kustomize 提供 `secretGenerator` 和 `configMapGenerator`，可以基于文件或字面值来生成 Secret 和 ConfigMap。

#### configMapGenerator

##### 基于普通文件（`files`）

要基于普通文件来生成 ConfigMap，可以在 `configMapGenerator` 的 `files` 列表中添加表项。 下面是一个根据 `.properties` 文件中的数据条目来生成 ConfigMap 的示例：

```shell
# 生成一个  application.properties 文件
$ cat <<EOF >application.properties
FOO=Bar
NAME=Aluopy
EOF

$ cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: my-configmap-1
  files:
  - application.properties
EOF
```

查看生成的 ConfigMap：

```shell
$ kubectl kustomize ./
apiVersion: v1
data:
  application.properties: |
    FOO=Bar
    NAME=Aluopy
kind: ConfigMap
metadata:
  name: my-configmap-1-g5mm9h67b4
```

##### 基于 `env` 文件（`envs`）

要从 env 文件生成 ConfigMap，可以在 `configMapGenerator` 中的 `envs` 列表中添加一个条目。 这也可以用于通过省略 `=` 和值来设置本地环境变量的值。

建议谨慎使用本地环境变量填充功能 —— 用补丁覆盖通常更易于维护。 当无法轻松预测变量的值时，从环境中设置值可能很有用，例如 git SHA。

下面是一个用来自 `.env` 文件的数据生成 ConfigMap 的例子：

```shell
# 创建一个 .env 文件
# BAZ 将使用本地环境变量 $BAZ 的取值填充
$ cat <<EOF >.env
FOO=Bar
BAZ
EOF

$ cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: my-configmap-2
  envs:
  - .env
EOF
```

查看生成的 ConfigMap：

```shell
$ BAZ=Qux kubectl kustomize ./
apiVersion: v1
data:
  BAZ: Qux
  FOO: Bar
kind: ConfigMap
metadata:
  name: my-configmap-2-892ghb99c8
```

> **说明：** `.env` 文件中的每个变量在生成的 ConfigMap 中成为一个单独的键。 这与之前的示例不同，前一个示例将一个名为 `.properties` 的文件（及其所有条目）嵌入到同一个键的值中。

##### 基于字面值（`literals`）

ConfigMap 也可基于字面的键值对来生成。要基于键值对来生成 ConfigMap， 在 `configMapGenerator` 的 `literals` 列表中添加表项。下面是一个例子，展示 如何使用键值对中的数据条目来生成 ConfigMap 对象：

```shell
$ cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: my-configmap-3
  literals:
  - FOO=Bar
  - NAME=Aluo
EOF
```

查看生成的 ConfigMap：

```shell
$ kubectl kustomize ./
apiVersion: v1
data:
  FOO: Bar
  NAME: Aluo
kind: ConfigMap
metadata:
  name: my-configmap-3-gbdm2t4kkh
```

##### 使用生成的 ConfigMap

要在 Deployment 中使用生成的 ConfigMap，使用 configMapGenerator 的名称对其进行引用。 Kustomize 将自动使用生成的名称替换该名称。

这是使用生成的 ConfigMap 的 deployment 示例：

```shell
# 创建一个 application.properties 文件
$ cat <<EOF >application.properties
FOO=Bar
NAME=Aluo
EOF

$ cat <<EOF >deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: config
          mountPath: /config
      volumes:
      - name: config
        configMap:
          # 引用名字为 my-configmap-1 的 configMapGenerator
          name: my-configmap-1
EOF

$ cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
configMapGenerator:
- name: my-configmap-1
  files:
  - application.properties
EOF
```

生成 ConfigMap 和 Deployment：

```shell
$ kubectl kustomize ./
apiVersion: v1
data:
  application.properties: |
    FOO=Bar
    NAME=Aluo
kind: ConfigMap
metadata:
  name: my-configmap-1-75d5h98d2d
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: my-app
  name: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - image: nginx
        name: app
        volumeMounts:
        - mountPath: /config
          name: config
      volumes:
      - configMap:
          # 自动使用生成的名称替换之前定义的名称
          name: my-configmap-1-75d5h98d2d
        name: config
```

> 生成的 Deployment 将通过名称引用生成的 ConfigMap：`my-configmap-1-75d5h98d2d`

#### secretGenerator

可以基于文件或者键值对来生成 Secret。

##### 基于普通文件（`files`）

要使用普通文件内容来生成 Secret， 在 `secretGenerator` 下面的 `files` 列表中添加表项。 下面是一个根据文件中数据来生成 Secret 对象的示例：

```shell
# 创建一个 password.txt 文件
$ cat <<EOF >./password.txt
username=admin
password=Aisino
EOF

$ cat <<EOF >./kustomization.yaml
secretGenerator:
- name: my-secret-1
  files:
  - password.txt
EOF
```

查看生成的 Secret：

```shell
$ kubectl kustomize ./
apiVersion: v1
data:
  password.txt: dXNlcm5hbWU9YWRtaW4KcGFzc3dvcmQ9QWlzaW5vCg==
kind: Secret
metadata:
  name: my-secret-1-5hbtb9kck2
type: Opaque
```

##### 基于 `env` 文件（`envs`）

要从 env 文件生成 Secret，可以在 `secretGenerator` 中的 `envs` 列表中添加一个条目。

下面是一个用来自 `.env` 文件的数据生成 Secret 的例子：

```shell
# 创建一个 .env 文件
# password 将使用本地环境变量 $password 的取值填充
$ cat <<EOF >.env
username=admin
password
EOF

$ cat <<EOF >./kustomization.yaml
secretGenerator:
- name: my-secret-2
  envs:
  - .env
EOF
```

查看生成的 Secret：

```shell
$ password=Aisino kubectl kustomize ./
apiVersion: v1
data:
  password: QWlzaW5v
  username: YWRtaW4=
kind: Secret
metadata:
  name: my-secret-2-dk9mgcb22d
type: Opaque
```

##### 基于字面值（`literals`）

要基于键值对字面值生成 Secret，先要在 `secretGenerator` 的 `literals` 列表中添加表项。下面是基于键值对中数据条目来生成 Secret 的示例：

```shell
$ cat <<EOF >./kustomization.yaml
secretGenerator:
- name: my-secret-3
  literals:
  - username=admin
  - password=Aisino
EOF
```

查看生成的 Secret：

```shell
$ kubectl kustomize ./
apiVersion: v1
data:
  password: QWlzaW5v
  username: YWRtaW4=
kind: Secret
metadata:
  name: my-secret-3-dk9mgcb22d
type: Opaque
```

##### 使用生成的 Secrets

与 ConfigMaps 一样，生成的 Secrets 可以通过引用 secretGenerator 的名称在部署中使用：

```shell
# 创建一个 password.txt 文件
$ cat <<EOF >./password.txt
username=admin
password=Aisino
EOF

$ cat <<EOF >deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: password
          mountPath: /secrets
      volumes:
      - name: password
        secret:
          secretName: my-secret-1
EOF

$ cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
secretGenerator:
- name: my-secret-1
  files:
  - password.txt
EOF
```

生成 Secrets 和 Deployment：

```shell
$ kubectl kustomize ./
apiVersion: v1
data:
  password.txt: dXNlcm5hbWU9YWRtaW4KcGFzc3dvcmQ9QWlzaW5vCg==
kind: Secret
metadata:
  name: my-secret-1-5hbtb9kck2
type: Opaque
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: my-app
  name: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - image: nginx
        name: app
        volumeMounts:
        - mountPath: /secrets
          name: password
      volumes:
      - name: password
        secret:
          secretName: my-secret-1-5hbtb9kck2
```

#### generatorOptions

所生成的 ConfigMap 和 Secret 都会包含内容哈希值后缀。 这将保证每次修改数据时生成一个新的 ConfigMap 或 Secret。 要禁止自动添加后缀的行为，可以使用 `generatorOptions`。 除此以外，为生成的 ConfigMap 和 Secret 指定贯穿性选项也是可以的。

```shell
$ cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: my-configmap-3
  literals:
  - FOO=Bar
generatorOptions:
  disableNameSuffixHash: true
  labels:
    type: generated
  annotations:
    note: generated
EOF
```

运行 `kubectl kustomize ./` 查看所生成的 ConfigMap：

```shell
$ kubectl kustomize ./
apiVersion: v1
data:
  FOO: Bar
kind: ConfigMap
metadata:
  annotations:
    note: generated
  labels:
    type: generated
  name: my-configmap-3
```

### 设置贯穿性字段

在项目中为所有 Kubernetes 对象设置贯穿性字段是一种常见操作。 贯穿性字段的一些使用场景如下：

- 为所有资源设置相同的名字空间
- 为所有对象添加相同的前缀或后缀
- 为对象添加相同的标签集合
- 为对象添加相同的注解集合

下面是一个例子：

```shell
# 创建一个 deployment.yaml
$ cat <<EOF >./deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
EOF

$ cat <<EOF >./kustomization.yaml
namespace: my-namespace
namePrefix: dev-
nameSuffix: "-001"
commonLabels:
  app: bingo
commonAnnotations:
  oncallPager: 800-555-1212
resources:
- deployment.yaml
EOF
```

执行 `kubectl kustomize ./` 查看这些字段都被设置到 Deployment 资源上：

```shell
$ kubectl kustomize ./
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    oncallPager: 800-555-1212
  labels:
    app: bingo
  name: dev-nginx-deployment-001
  namespace: my-namespace
spec:
  selector:
    matchLabels:
      app: bingo
  template:
    metadata:
      annotations:
        oncallPager: 800-555-1212
      labels:
        app: bingo
    spec:
      containers:
      - image: nginx
        name: nginx
```

### 组织和定制资源

一种常见的做法是在项目中构造资源集合并将其放到同一个文件或目录中管理。 Kustomize 提供基于不同文件来组织资源并向其应用补丁或者其他定制的能力。

#### 组织

Kustomize 支持组合不同的资源。`kustomization.yaml` 文件的 `resources` 字段定义配置中要包含的资源列表。你可以将 `resources` 列表中的路径设置为资源配置文件的路径。下面是由 Deployment 和 Service 构成的 NGINX 应用的示例：

```shell
# 创建 deployment.yaml 文件
$ cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# 创建 service.yaml 文件
$ cat <<EOF > service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  labels:
    run: my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
EOF

# 创建 kustomization.yaml 来组织以上两个资源
$ cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
- service.yaml
EOF
```

查看组合的资源：

```shell
$ kubectl kustomize ./
apiVersion: v1
kind: Service
metadata:
  labels:
    run: my-nginx
  name: my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - image: nginx
        name: my-nginx
        ports:
        - containerPort: 80
```

#### 定制

补丁文件（Patches）可以用来对资源执行不同的定制。 Kustomize 通过 `patchesStrategicMerge` 和 `patchesJson6902` 支持不同的打补丁机制。`patchesStrategicMerge` 的内容是一个文件路径的列表，其中每个文件都应可解析为 [策略性合并补丁（Strategic Merge Patch）](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-api-machinery/strategic-merge-patch.md)。 补丁文件中的名称必须与已经加载的资源的名称匹配。 建议构造规模较小的、仅做一件事情的补丁。

##### patchesStrategicMerge

构造一个补丁来增加 Deployment 的副本个数；构造另外一个补丁来设置内存限制。

```shell
# 创建 deployment.yaml 文件
$ cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# 生成一个补丁 increase_replicas.yaml
$ cat <<EOF > increase_replicas.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 3
EOF

# 生成另一个补丁 set_memory.yaml
$ cat <<EOF > set_memory.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  template:
    spec:
      containers:
      - name: my-nginx
        resources:
          limits:
            memory: 512Mi
EOF

$ cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
patchesStrategicMerge:
- increase_replicas.yaml
- set_memory.yaml
EOF
```

执行 `kubectl kustomize ./` 来查看 Deployment：

```shell
$ kubectl kustomize ./
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - image: nginx
        name: my-nginx
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: 512Mi
```

##### patchesJson6902

并非所有资源或者字段都支持策略性合并补丁。为了支持对任何资源的任何字段进行修改， Kustomize 提供通过 `patchesJson6902` 来应用 [JSON 补丁](https://tools.ietf.org/html/rfc6902) 的能力。为了给 JSON 补丁找到正确的资源，需要在 `kustomization.yaml` 文件中指定资源的 组（group）、版本（version）、类别（kind）和名称（name）。 例如，为某 Deployment 对象增加副本个数的操作也可以通过 `patchesJson6902` 来完成：

```shell
# 创建一个 deployment.yaml 文件
$ cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# 创建一个 JSON 补丁文件
$ cat <<EOF > patch.yaml
- op: replace
  path: /spec/replicas
  value: 3
EOF

# 创建一个 kustomization.yaml
$ cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml

patchesJson6902:
- target:
    group: apps
    version: v1
    kind: Deployment
    name: my-nginx
  path: patch.yaml
EOF
```

执行 `kubectl kustomize ./` 以查看 `replicas` 字段被更新：

```shell
$ kubectl kustomize ./
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - image: nginx
        name: my-nginx
        ports:
        - containerPort: 80
```

##### images

除了补丁之外，Kustomize 还提供定制容器镜像或者将其他对象的字段值注入到容器中的能力，并且不需要创建补丁。 例如，你可以通过在 `kustomization.yaml` 文件的 `images` 字段设置新的镜像来更改容器中使用的镜像。

```shell
$ cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

$ cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
images:
- name: nginx
  newName: my.image.registry/nginx
  newTag: 1.4.0
EOF
```

执行 `kubectl kustomize ./` 以查看所使用的镜像已被更新：

```shell
$ kubectl kustomize ./
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - image: my.image.registry/nginx:1.4.0
        name: my-nginx
        ports:
        - containerPort: 80
```

##### vars

有些时候，Pod 中运行的应用可能需要使用来自其他对象的配置值。 例如，某 Deployment 对象的 Pod 需要从环境变量或命令行参数中读取读取 Service 的名称。 由于在 `kustomization.yaml` 文件中添加 `namePrefix` 或 `nameSuffix` 时 Service 名称可能发生变化，建议不要在命令参数中硬编码 Service 名称。 对于这种使用场景，Kustomize 可以通过 `vars` 将 Service 名称注入到容器中。

```shell
# 创建一个 deployment.yaml 文件（引用此处的文档分隔符）
$ cat <<'EOF' > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        command: ["start", "--host", "$(MY_SERVICE_NAME)"]
EOF

# 创建一个 service.yaml 文件
$ cat <<EOF > service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  labels:
    run: my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
EOF

$ cat <<EOF >./kustomization.yaml
namePrefix: dev-
nameSuffix: "-001"

resources:
- deployment.yaml
- service.yaml

vars:
- name: MY_SERVICE_NAME
  objref:
    kind: Service
    name: my-nginx
    apiVersion: v1
EOF
```

执行 `kubectl kustomize ./` 以查看注入到容器中的 Service 名称是 `dev-my-nginx-001`：

```shell
$ kubectl kustomize ./
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-my-nginx-001
spec:
  replicas: 2
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - command:
        - start
        - --host
        - dev-my-nginx-001
        image: nginx
        name: my-nginx
```

## 基准（Bases）与覆盖（Overlays）

Kustomize 中有 **基准（bases）** 和 **覆盖（overlays）** 的概念区分。 **基准** 是包含 `kustomization.yaml` 文件的一个目录，其中包含一组资源及其相关的定制。 基准可以是本地目录或者来自远程仓库的目录，只要其中存在 `kustomization.yaml` 文件即可。 **覆盖** 也是一个目录，其中包含将其他 kustomization 目录当做 `bases` 来引用的 `kustomization.yaml` 文件。 **基准**不了解覆盖的存在，且可被多个覆盖所使用。 覆盖则可以有多个基准，且可针对所有基准中的资源执行组织操作，还可以在其上执行定制。

```shell
# 创建一个包含基准的目录 
$ mkdir base
# 创建 base/deployment.yaml
$ cat <<EOF > base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
EOF

# 创建 base/service.yaml 文件
$ cat <<EOF > base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  labels:
    run: my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
EOF

# 创建 base/kustomization.yaml
$ cat <<EOF > base/kustomization.yaml
resources:
- deployment.yaml
- service.yaml
EOF
```

此基准可在多个覆盖中使用。你可以在不同的覆盖中添加不同的 `namePrefix` 或其他贯穿性字段。下面是两个使用同一基准的覆盖：

```shell
$ mkdir dev
$ cat <<EOF > dev/kustomization.yaml
bases:
- ../base
namePrefix: dev-
EOF

$ mkdir prod
$ cat <<EOF > prod/kustomization.yaml
bases:
- ../base
namePrefix: prod-
EOF
```

查看对应的覆盖：

```shell
$ kubectl kustomize dev/
apiVersion: v1
kind: Service
metadata:
  labels:
    run: my-nginx
  name: dev-my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dev-my-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - image: nginx
        name: my-nginx
        
$ kubectl kustomize prod/
apiVersion: v1
kind: Service
metadata:
  labels:
    run: my-nginx
  name: prod-my-nginx
spec:
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prod-my-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      run: my-nginx
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - image: nginx
        name: my-nginx
```

## 使用 Kustomize 来应用、查看和删除对象

在 `kubectl` 命令中使用 `--kustomize` 或 `-k` 参数来识别被 `kustomization.yaml` 所管理的资源。 注意 `-k` 要指向一个 kustomization 目录。例如：

```shell
$ kubectl apply -k <kustomization 目录>/
```

假定使用下面的 `kustomization.yaml`，

```shell
# 创建 deployment.yaml 文件
$ cat <<EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

# 创建 kustomization.yaml
$ cat <<EOF >./kustomization.yaml
namePrefix: dev-
commonLabels:
  app: my-nginx
resources:
- deployment.yaml
EOF
```

执行下面的命令来应用 Deployment 对象 `dev-my-nginx`：

```shell
$ kubectl apply -k ./
deployment.apps/dev-my-nginx created
```

运行下面的命令之一来查看 Deployment 对象 `dev-my-nginx`：

```shell
$ kubectl get -k ./
$ kubectl describe -k ./
```

执行下面的命令来比较 Deployment 对象 `dev-my-nginx` 与清单被应用之后集群将处于的状态：

```shell
$ kubectl diff -k ./
```

执行下面的命令删除 Deployment 对象 `dev-my-nginx`：

```shell
$ kubectl delete -k ./
deployment.apps "dev-my-nginx" deleted
```

## Kustomize 功能特性列表

| 字段                  | 类型                                                         | 解释                                                         |
| --------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| namespace             | string                                                       | 为所有资源添加名字空间                                       |
| namePrefix            | string                                                       | 此字段的值将被添加到所有资源名称前面                         |
| nameSuffix            | string                                                       | 此字段的值将被添加到所有资源名称后面                         |
| commonLabels          | map[string]string                                            | 要添加到所有资源和选择算符的标签                             |
| commonAnnotations     | map[string]string                                            | 要添加到所有资源的注解                                       |
| resources             | []string                                                     | 列表中的每个条目都必须能够解析为现有的资源配置文件           |
| configMapGenerator    | \[][ConfigMapArgs](https://github.com/kubernetes-sigs/kustomize/blob/master/api/types/configmapargs.go#L7) | 列表中的每个条目都会生成一个 ConfigMap                       |
| secretGenerator       | \[][SecretArgs](https://github.com/kubernetes-sigs/kustomize/blob/master/api/types/secretargs.go#L7) | 列表中的每个条目都会生成一个 Secret                          |
| generatorOptions      | [GeneratorOptions](https://github.com/kubernetes-sigs/kustomize/blob/master/api/types/generatoroptions.go#L7) | 更改所有 ConfigMap 和 Secret 生成器的行为                    |
| bases                 | []string                                                     | 列表中每个条目都应能解析为一个包含 kustomization.yaml 文件的目录 |
| patchesStrategicMerge | []string                                                     | 列表中每个条目都能解析为某 Kubernetes 对象的策略性合并补丁   |
| patchesJson6902       | \[][Patch](https://github.com/kubernetes-sigs/kustomize/blob/master/api/types/patch.go#L10) | 列表中每个条目都能解析为一个 Kubernetes 对象和一个 JSON 补丁 |
| vars                  | \[][Var](https://github.com/kubernetes-sigs/kustomize/blob/master/api/types/var.go#L19) | 每个条目用来从某资源的字段来析取文字                         |
| images                | \[][Image](https://github.com/kubernetes-sigs/kustomize/blob/master/api/types/image.go#L8) | 每个条目都用来更改镜像的名称、标记与/或摘要，不必生成补丁    |
| configurations        | []string                                                     | 列表中每个条目都应能解析为一个包含 [Kustomize 转换器配置](https://github.com/kubernetes-sigs/kustomize/tree/master/examples/transformerconfigs) 的文件 |
| crds                  | []string                                                     | 列表中每个条目都应能够解析为 Kubernetes 类别的 OpenAPI 定义文件 |

## 附：Kustomize 命令

### Kustomize 安装

通过下载预编译的二进制文件来安装 Kustomize

适用于 linux、MacOs 和 Windows 的各种版本的二进制文件发布在 [releases page](https://github.com/kubernetes-sigs/kustomize/releases).

以下脚本检测您的操作系统并将适当的 kustomize 二进制文件下载到您当前的工作目录。

```bash
$ curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
```

**此脚本不适用于 ARM 架构**。如果你想安装 ARM 二进制文件，请到发布页面找到 URL。

### Kustomize 使用

#### 1）创建 `kustomization` 文件

 在包含 YAML 资源文件（部署、服务、配置映射等）的某个目录中，创建一个 kustomization 文件。

该文件应声明这些资源，以及适用于它们的任何自定义，例如添加一个通用标签。

文件结构：

```
~/someApp
├── deployment.yaml
├── kustomization.yaml
└── service.yaml
```

此目录中的资源可能是其他人配置的分支。如果是这样，您可以轻松地从源材料中变基以捕获改进，因为您不直接修改资源。

使用以下命令生成自定义 YAML：

```shell
$ kustomize build ~/someApp
```

YAML 可以直接应用于集群：

```shell
$ kustomize build ~/someApp | kubectl apply -f -
```

#### 2）使用叠加（Overlays）创建变体

使用修改公共基础的覆盖来管理配置的传统变体（如开发、登台和生产）。

文件结构：

```
~/someApp
├── base
│   ├── deployment.yaml
│   ├── kustomization.yaml
│   └── service.yaml
└── overlays
    ├── development
    │   ├── cpu_count.yaml
    │   ├── kustomization.yaml
    │   └── replica_count.yaml
    └── production
        ├── cpu_count.yaml
        ├── kustomization.yaml
        └── replica_count.yaml
```

从上面的步骤 (1) 中获取工作，将其移动到名为 base 的 someApp 子目录中，然后将 `overlays` 放置在同级目录中。

覆盖只是另一种自定义，指的是基础，并指的是应用于该基础的补丁。

这种安排使您可以轻松地使用 git 管理您的配置。`base` 可能有来自其他人管理的上游存储库的文件。`overlays` 可能位于您拥有的存储库中。

生成 YAML

```sh
$ kustomize build ~/someApp/overlays/production
```

YAML 可以直接应用于集群：

```sh
$ kustomize build ~/someApp/overlays/production | kubectl apply -f -
```