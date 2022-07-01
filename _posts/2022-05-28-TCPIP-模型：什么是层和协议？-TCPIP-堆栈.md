---
title: "TCP/IP 模型：什么是层和协议？ TCP/IP 堆栈"
excerpt: ""
permalink: /network/tcp-ip-model/
#canonical_url: ""
toc: true
#toc_label: ""
#toc_icon: "cog"
#toc_sticky: false
#search: false
#header:
#  image: /assets/images/image-filename.jpg
#  image_description: "A description of the image"
#  caption: "Photo credit: [**Unsplash**](https://unsplash.com)"
#actions:
#  - label: "More Info"
#    url: "https://unsplash.com"
classes: wide
categories: network
tags:
  - network
  - tcp/ip
  - tcp
---

**ProTip:**  From [Guru99](https://www.guru99.com/)✨
{: .notice--info}

## 什么是 TCP/IP 模型？

TCP/IP 模型可帮助您确定特定计算机应如何连接到 Internet 以及数据应如何在它们之间传输。当多个计算机网络连接在一起时，它可以帮助您创建虚拟网络。 TCP/IP 模型的目的是允许远距离通信。

TCP/IP 代表 Transmission Control Protocol（传输控制协议）/ Internet Protocol（互联网协议）。 TCP/IP 堆栈专门设计为通过不可靠的互联网提供高度可靠和端到端字节流的模型。

## TCP 特性

这里，是 TCP IP 协议的基本特征：

- 支持灵活的 TCP/IP 架构
- 向网络添加更多系统很容易
- 在 TCP IP 协议套件中，网络在源机器和目标机器正常运行之前保持不变
- TCP 是一种面向连接的协议
- TCP 提供了可靠性，并确保乱序到达的数据应该重新排序
- TCP 允许您实现流量控制，因此发送方永远不会用数据压倒接收方

## 四层 TCP/IP 模型

在本 TCP/IP 教程中，我们将解释 TCP/IP 模型中的不同层及其功能：

![](https://aluopy.github.io/assets/images/TCPIPModelW1.webp)

<div align = "center">TCP/IP Conceptual Layers</div>

TCP IP 模型的功能分为四层，每一层都包含特定的协议。

TCP/IP 是一种分层的服务器架构系统，其中每一层都根据要执行的特定功能进行定义。所有这四个 TCP IP 层协同工作，将数据从一层传输到另一层。

- Application Layer（应用层）
- Transport Layer（传输层）
- Internet Layer（互联网层/网络层）
- Network Interface（网络接口层）

![](https://aluopy.github.io/assets/images/TCPIPModelW2.webp)

<div align = "center">Four Layers of TCP/IP model</div>

## 应用层

应用层与应用程序交互，是 OSI 模型的最高层次。应用层是最接近最终用户的OSI层。这意味着 OSI 应用层允许用户与其他软件应用程序进行交互。

应用层与软件应用程序交互以实现通信组件。应用程序对数据的解释总是超出 OSI 模型的范围。

应用层的示例是文件传输、电子邮件、远程登录等应用程序。

**应用层的功能**：

- 应用层帮助您识别通信伙伴、确定资源可用性和同步通信
- 它允许用户登录到远程主机
- 该层提供各种电子邮件服务
- 此应用程序提供分布式数据库源和对有关各种对象和服务的全局信息的访问

## 传输层

传输层建立在网络层之上，以便提供从源系统机器上的进程到目标系统上的进程的数据传输。它使用单个或多个网络托管，并且还保持服务质量功能。

它决定了应将多少数据发送到何处以及以何种速率发送。该层建立在从应用层接收到的消息之上。它有助于确保数据单元按顺序无误地交付。

传输层通过流量控制、错误控制以及分段或解除分段来帮助您控制链路的可靠性。

传输层还提供数据传输成功的确认，并在没有发生错误的情况下发送下一个数据。 TCP 是传输层最著名的例子。

**传输层的重要功能**：

- 它将从会话层接收到的消息划分为段，并对它们进行编号以形成序列
- 传输层确保将消息传递到目标机器上的正确进程
- 它还确保整个消息到达时没有任何错误，否则应该重新传输

## 互联网层

互联网层是 TCP/IP 模型的 TCP/IP 层的第二层。它也被称为网络层。该层的主要工作是从任何网络发送数据包，并且任何计算机仍然可以到达目的地，而不管它们采取的路线如何。

互联网层提供了在各种网络的帮助下将可变长度数据序列从一个节点传输到另一个节点的功能和程序方法。

网络层的消息传递不提供任何保证是可靠的网络层协议。

属于网络层的层管理协议有：

1. Routing protocols（路由协议）
2. Multicast group management（组播组管理）
3. Network-layer address assignment（网络层地址分配）

## 网络接口层

网络接口层是四层 TCP/IP 模型的这一层。该层也称为网络访问层。它可以帮助您定义如何使用网络发送数据的详细信息。

它还包括如何通过直接与网络介质（如同轴、光纤、同轴电缆、光纤或双绞线电缆）连接的硬件设备以光学方式向比特发送信号。

网络层是数据线的组合，在 OSI 参考模型一文中定义。这一层定义了数据应该如何通过网络物理发送。该层负责同一网络上两个设备之间的数据传输。

**OSI 和 TCP/IP 模型之间的差异**

![](https://aluopy.github.io/assets/images/TCPIPModelW3.webp)

<div align = "center">Difference between OSI and TCP/IP model</div>

以下是 [OSI 和 TCP/IP 模型](https://aluopy.cn/network/difference-tcp-ip-vs-osi-model/)之间的一些重要区别：

| OSI 模型                                                     | TCP/IP 模型                                           |
| ------------------------------------------------------------ | ----------------------------------------------------- |
| 它是由 ISO（国际标准组织）开发的                             | 它由 ARPANET（高级研究计划署网络）开发                |
| OSI 模型明确区分了接口、服务和协议                           | TCP/IP 在服务、接口和协议之间没有任何明确的区分点     |
| OSI 指的是开放系统互连                                       | TCP 指的是传输控制协议                                |
| OSI 使用网络层来定义路由标准和协议                           | TCP/IP 仅使用 Internet 层                             |
| OSI 遵循垂直方法                                             | TCP/IP 遵循横向方法                                   |
| [OSI 模型](https://aluopy.cn/network/layers-of-osi-model/)使用两个独立的物理层和数据链路层来定义底层的功能 | TCP/IP 仅使用一层（链路）                             |
| OSI 层有七层                                                 | TCP/IP 有四层                                         |
| OSI 模型中，传输层只是面向连接的                             | TCP/IP 模型的一层既是面向连接的，也是无连接的         |
| 在 OSI 模型中，数据链路层和物理层是分开的层                  | 在 TCP 中，物理链路和数据链路都组合为单个主机到网络层 |
| 会话层和表示层不是 TCP 模型的一部分                          | TCP 模型中没有会话层和表示层                          |
| 它是在 Internet 出现之后定义的                               | 它是在互联网出现之前定义的                            |
| OSI 标头的最小大小为 5 个字节                                | 最小标头大小为 20 字节                                |

## 最常见的 TCP/IP 协议

一些广泛使用的最常见的 TCP/IP 协议是：

### TCP

传输控制协议是一个互联网协议套件，它将消息分解成 TCP 段并在接收端重新组装它们。

### IP

也称为 [IP 地址](https://aluopy.cn/network/types-of-ip-addresses/)的 Internet 协议地址是一个数字标签。它被分配给连接到使用 IP 进行通信的计算机网络的每个设备。它的路由功能允许互联互通，本质上建立了互联网。 IP 与 TCP 的组合允许在目标和源之间建立虚拟连接。

### HTTP

超文本传输协议是万维网的基础。它用于将网页和其他此类资源从 HTTP 服务器或 Web 服务器传输到 Web 客户端或 HTTP 客户端。每当您使用 Google Chrome 或 Firefox 等网络浏览器时，您都在使用网络客户端。它有助于 HTTP 传输您从远程服务器请求的网页。

### SMTP

SMTP 代表简单邮件传输协议。这种支持电子邮件的协议被称为简单邮件传输协议。此协议可帮助您将数据发送到另一个电子邮件地址。

### SNMP

SNMP 代表简单网络管理协议。它是一个框架，用于通过使用 TCP/IP 协议来管理 Internet 上的设备。

### DNS

DNS 代表域名系统。用于唯一标识主机与 Internet 的连接的 IP 地址。但是，用户更喜欢使用名称而不是该 DNS 的地址。

### TELNET

TELNET 代表终端网络。它建立本地和远程计算机之间的连接。它以您可以在远程系统上模拟本地系统的方式建立连接。

### FTP

FTP 代表文件传输协议。它是一种最常用的标准协议，用于将文件从一台机器传输到另一台机器。

## TCP/IP 模型的优点

以下是使用 TCP/IP 模型的优点/好处：

- 它可以帮助您在不同类型的计算机之间建立/设置连接
- 它独立于操作系统运行
- 它支持许多路由协议
- 它使组织之间的互联互通成为可能
- TCP/IP 模型具有高度可扩展的客户端-服务器体系结构
- 它可以独立操作
- 支持多种路由协议
- 它可用于在两台计算机之间建立连接

## TCP/IP 模型的缺点

下面是使用 TCP/IP 模型的一些缺点：

- TCP/IP 是一个设置和管理复杂的模型
- TCP/IP 的浅层/开销高于 IPX (Internetwork Packet Exchange)
- 在此，模型传输层不保证数据包的传递
- 替换 TCP/IP 中的协议并不容易
- 它与它的服务、接口和协议没有明确的分离

## 概括

- TCP/IP 模型的完整形式解释为传输控制协议/互联网协议。
- TCP支持灵活的架构
- 应用层与应用程序交互，是 OSI 模型的最高层次。
- Internet 层是 TCP/IP 模型的第二层。它也被称为网络层。
- 传输层建立在网络层之上，以便提供从源系统机器上的进程到目标系统上的进程的数据传输。

- 网络接口层是四层 TCP/IP 模型的这一层。该层也称为网络访问层。

- OSI 模型由 ISO（国际标准组织）开发，而 TCP/IP 模型由 ARPANET（高级研究计划署网络）开发。

- 也称为 IP 地址的 Internet 协议地址是一个数字标签。

- HTTP 是万维网的基础。

- SMTP代表简单邮件传输协议，支持电子邮件被称为简单邮件传输

- SNMP 代表简单网络管理协议。

- DNS 代表域名系统。

- TELNET 代表终端网络。它建立本地和远程计算机之间的连接

- FTP 代表文件传输协议。它是一种最常用的标准协议，用于将文件从一台机器传输到另一台机器。

- TCP/IP 模型的最大好处是它可以帮助您在不同类型的计算机之间建立/建立连接。

- TCP/IP 是一个设置和管理复杂的模型。

- **TCP/IP 层有哪些不同类型？**

  TCP/IP 层有四种类型

  1. Application layer（应用层）
  2. Transport layer（传输层）
  3. Internet layer（互联网层/网络层）
  4. Network interface（网络接口）