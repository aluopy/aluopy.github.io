---

---

[Kustomize](https://github.com/kubernetes-sigs/kustomize) 是一个独立的工具，用来通过 kustomization 文件 定制 Kubernetes 对象。

从 1.14 版本开始，`kubectl` 也开始支持使用 kustomization 文件来管理 Kubernetes 对象。 要查看包含 kustomization 文件的目录中的资源，执行下面的命令：

```shell
$ kubectl kustomize <kustomization_directory>
```

要应用这些资源，使用参数 `--kustomize` 或 `-k` 标志来执行 `kubectl apply`：

```shell
$ kubectl apply -k <kustomization_directory>
```

## Kustomize 概述

Kustomize 是一个用来定制 Kubernetes 配置的工具。它提供以下功能特性来管理 应用配置文件：

- 从其他来源生成资源
- 为资源设置贯穿性（Cross-Cutting）字段
- 组织和定制资源集合

### 生成资源

ConfigMap 和 Secret 包含其他 Kubernetes 对象（如 Pod）所需要的配置或敏感数据。 ConfigMap 或 Secret 中数据的来源往往是集群外部，例如某个 `.properties` 文件或者 SSH 密钥文件。 Kustomize 提供 `secretGenerator` 和 `configMapGenerator`，可以基于文件或字面值来生成 Secret 和 ConfigMap。

#### configMapGenerator

要基于文件来生成 ConfigMap，可以在 `configMapGenerator` 的 `files` 列表中添加表项。 下面是一个根据 `.properties` 文件中的数据条目来生成 ConfigMap 的示例：

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

所生成的 ConfigMap 可以使用下面的命令来检查：

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

要从 env 文件生成 ConfigMap，请在 `configMapGenerator` 中的 `envs` 列表中添加一个条目。 这也可以用于通过省略 `=` 和值来设置本地环境变量的值。

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

可以使用以下命令检查生成的 ConfigMap：

```shell
BAZ=Qux kubectl kustomize ./
apiVersion: v1
data:
  BAZ: Qux
  FOO: Bar
kind: ConfigMap
metadata:
  name: my-configmap-2-892ghb99c8
```

> **说明：** `.env` 文件中的每个变量在生成的 ConfigMap 中成为一个单独的键。 这与之前的示例不同，前一个示例将一个名为 `.properties` 的文件（及其所有条目）嵌入到同一个键的值中。

ConfigMap 也可基于字面的键值偶对来生成。要基于键值偶对来生成 ConfigMap， 在 `configMapGenerator` 的 `literals` 列表中添加表项。下面是一个例子，展示 如何使用键值偶对中的数据条目来生成 ConfigMap 对象：

```shell
$ cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: my-configmap-3
  literals:
  - FOO=Bar
  - NAME=Aluo
EOF
```

可以用下面的命令检查所生成的 ConfigMap：

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
          name: my-configmap-1-75d5h98d2d
        name: config
```

> 生成的 Deployment 将通过名称引用生成的 ConfigMap：`my-configmap-1-75d5h98d2d`

#### secretGenerator

你可以基于文件或者键值偶对来生成 Secret。要使用文件内容来生成 Secret， 在 `secretGenerator` 下面的 `files` 列表中添加表项。 下面是一个根据文件中数据来生成 Secret 对象的示例：

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

所生成的 Secret 如下：

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

要基于键值偶对字面值生成 Secret，先要在 `secretGenerator` 的 `literals` 列表中添加表项。下面是基于键值偶对中数据条目来生成 Secret 的示例：

```shell
$ cat <<EOF >./kustomization.yaml
secretGenerator:
- name: my-secret-2
  literals:
  - username=admin
  - password=Aisino
EOF
```

所生成的 Secret 如下：

```shell
$ kubectl kustomize ./
apiVersion: v1
data:
  password: QWlzaW5v
  username: YWRtaW4=
kind: Secret
metadata:
  name: my-secret-2-dk9mgcb22d
type: Opaque
```

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
$ apiVersion: v1
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

所生成的 ConfigMap 和 Secret 都会包含内容哈希值后缀。 这是为了确保内容发生变化时，所生成的是新的 ConfigMap 或 Secret。 要禁止自动添加后缀的行为，用户可以使用 `generatorOptions`。 除此以外，为生成的 ConfigMap 和 Secret 指定贯穿性选项也是可以的。

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

运行 `kubectl kustomize ./` 来查看所生成的 ConfigMap：

```yaml
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

### 组织和定制资源

## 基准（Bases）与覆盖（Overlays）

## 使用 Kustomize 来应用、查看和删除对象

## Kustomize 功能特性列表

## Kustomize 安装