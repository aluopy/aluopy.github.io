---
title: "TCP 三次握手 (SYN, SYN-ACK,ACK)"
excerpt: ""
permalink: /network/tcp-3-way-handshake/
toc: true
#toc_label: ""
#toc_icon: "cog"
categories: network
tags:
  - network
  - tcp
---

**ProTip:**  From [Guru99](https://www.guru99.com/)✨
{: .notice--info}

## TCP 三次握手

三次握手或 TCP 三次握手是在 TCP/IP 网络中用于在服务器和客户端之间建立连接的过程。这是一个三步过程，需要客户端和服务器在真正的数据通信过程开始之前交换同步和确认数据包。

三次握手过程的设计方式是两端帮助您同时发起、协商和分离 TCP 套接字连接。它允许您同时在两个方向上传输多个 TCP 套接字连接。

## TCP 消息类型

| Message | Description                                            |
| ------- | ------------------------------------------------------ |
| Syn     | 用于启动和建立连接。它还可以帮助您在设备之间同步序列号 |
| ACK     | 帮助向对方确认它已收到 SYN                             |
| SYN-ACK | 来自本地设备的 SYN 消息和早期数据包的 ACK              |
| FIN     | 用于终止连接                                           |

## TCP 三次握手过程

TCP 流量以三次握手开始。在这个 TCP 握手过程中，客户端需要通过请求与服务器的通信会话来发起会话：

![](https://aluopy.github.io/assets/images/TCP3WayHand1.webp) 

<div align = "center">3 way Handshake Diagram</div>

- **Step 1：**第一步，客户端与服务器建立连接。它发送一个带有 SYN 的段，并通知服务器客户端应该开始通信，以及它的序列号应该是什么。
- **Step 2：**在此步骤中，服务器使用 SYN-ACK 信号集响应客户端请求。 ACK 帮助您表示收到的段的响应，SYN 表示它应该能够从段开始的序列号。
- **Step 3：**在这最后一步中，客户端确认服务器的响应，并且他们都创建了稳定的连接将开始实际的数据传输过程。

## Real-world Example

![](https://aluopy.github.io/assets/images/TCP3WayHand2.webp) 

这是一个简单的三次握手过程示例，它由三个步骤组成：

- 主机 X 通过向其主机目的地发送 TCP SYN 数据包来开始连接。数据包包含一个随机序列号（例如，4321），它指示主机 X 应传输的数据的序列号的开始。
- 之后，服务器将收到数据包，并用它的序列号进行响应。它的响应还包括确认号，即主机 X 的序列号加 1（这里为 4322）。
- 主机 X 通过发送确认号来响应服务器，该确认号主要是服务器的序列号，加 1。

数据传输过程结束后，TCP 会自动终止两个独立端点之间的连接。

## 总结

- 3 次握手或 TCP 3 次握手是在 TCP/IP 网络中用于在服务器和客户端之间建立连接的过程
- syn 用于发起和建立连接
- ACK 有助于向对方确认它已收到 SYN
- SYN-ACK 是来自本地设备的 SYN 消息和早期数据包的 ACK
- FIN 用于终止连接
- TCP握手过程，客户端需要通过请求与 Server 进行通信会话来发起会话
- 第一步，客户端与服务器建立连接
- 在这第二步中，服务器使用 SYN-ACK 信号集响应客户端请求
- 在这最后一步中，客户端确认服务器的响应
- TCP 自动终止两个独立端点之间的连接