---
title: "HTTP 与 HTTPS：HTTP 和 HTTPS 有什么区别？完整形式"
excerpt: ""
permalink: /network/difference-http-vs-https/
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
  - http
  - https
---

**ProTip:**  From [Guru99](https://www.guru99.com/)✨
{: .notice--info}

在本 HTTPS 与 HTTP 教程中，我们将了解 HTTP 和 HTTPS 之间的区别。

## 什么是 HTTP?

HTTP 的完整形式是超文本传输协议。 HTTP 提供了一套规则和标准来管理任何信息如何在万维网上传输。 HTTP 为 Web 浏览器和服务器进行通信提供了标准规则。

HTTP 是建立在 TCP 之上的应用层网络协议。 HTTP 使用超文本结构化文本，它在包含文本的节点之间建立逻辑链接。它也被称为“无状态协议”，因为每个命令都是单独执行的，不使用先前运行命令的引用。

## 什么是 HTTPS？

HTTPS 代表安全的超文本传输协议。它是 HTTP 的高度先进和安全的版本。它使用端口号。 443 用于数据通信。它通过使用 SSL 加密整个通信来实现安全交易。它是 SSL/TLS 协议和 HTTP 的组合。它提供网络服务器的加密和安全标识。

HTTP 还允许您在服务器和浏览器之间创建安全的加密连接。它提供了数据的双向安全性。这可以帮助您保护潜在的敏感信息不被盗。

在 HTTPS 协议中，SSL 事务是在基于密钥的加密算法的帮助下进行协商的。该密钥的强度通常为 40 或 128 位。

接下来在本教程中，我们将了解主要的 HTTP 和 HTTPS 区别。

**Note:** 

- HTTP 缺乏加密数据的安全机制，而 HTTPS 提供 SSL 或 TLS 数字证书来保护服务器和客户端之间的通信。
- HTTP 在应用层运行，而 HTTPS 在传输层运行。
- HTTP 默认在 80 端口上运行，而 HTTPS 默认在 443 端口上运行。
- HTTP 以纯文本传输数据，而 HTTPS 以密文（加密文本）传输数据。
- HTTP 比 HTTPS 快，因为 HTTPS 消耗计算能力来加密通信通道。
{: .notice--warning}

## HTTPS 的优势

- 在大多数情况下，通过 HTTPS 运行的站点将进行重定向。因此，即使您输入 HTTP://，它也会通过安全连接重定向到 https
- 它允许用户执行安全的电子商务交易，例如网上银行
- SSL 技术保护任何用户并建立信任
- 一个独立的机构验证证书所有者的身份。因此，每个 SSL 证书都包含有关证书所有者的唯一、经过身份验证的信息

## HTTP 的限制

- 没有隐私，因为任何人都可以看到内容
- 数据完整性是一个大问题，因为有人可以更改内容。这就是为什么 HTTP 协议是一种不安全的方法，因为没有使用加密方法
- 不清楚你在说谁。任何拦截请求的人都可以获得用户名和密码

## HTTPS 的限制

- HTTPS 协议无法阻止从浏览器缓存的页面中窃取机密信息
- SSL 数据只能在网络传输期间进行加密。所以无法清除浏览器内存中的文字
- HTTPS 会增加组织的计算开销和网络开销

![](https://aluopy.github.io/assets/images/HTTPvsHTTPS1.webp)

<div align = "center">HTTP 和 HTTPS 协议的区别</div>

## HTTP 和 HTTPS 之间的区别

下表演示了 HTTP 和 HTTPS 之间的区别：

| Parameter | HTTP                                                         | HTTPS                                                        |
| --------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 协议      | 它是超文本传输协议                                           | 它是一种安全的超文本传输协议                                 |
| 安全      | 它的安全性较低，因为数据可能容易受到黑客攻击                 | 它旨在防止黑客访问关键信息。它对此类攻击是安全的             |
| Port      | 默认使用 80 端口                                             | 默认情况下使用端口 443                                       |
| URL       | HTTP URL 以 http:// 开头                                     | HTTPS URL 以 https:// 开头                                   |
| 用于      | 它非常适合为博客等信息消费而设计的网站                       | 如果网站需要收集信用卡号等隐私信息，那么它是一种更安全的协议 |
| 加扰      | HTTP 不会扰乱要传输的数据。这就是为什么黑客更有可能获得传输的信息 | HTTPS 在传输前对数据进行加扰。在接收端，它解扰以恢复原始数据。因此，传输的信息是安全的，无法被黑客入侵 |
| 协议      | 它在 [TCP/IP]() 级别运行                                     | HTTPS 没有任何单独的协议。它使用 HTTP 运行，但使用加密的 TLS/SSL 连接。 |
| 域名验证  | HTTP 网站不需要 SSL                                          | HTTPS 需要 SSL 证书                                          |
| 数据加密  | HTTP 网站不使用加密                                          | HTTPS 网站使用数据加密                                       |
| 搜索排名  | HTTP 不会提高搜索排名                                        | HTTPS 有助于提高搜索排名                                     |
| 速度      | 快                                                           | 比 HTTP 慢                                                   |
| 漏洞      | 易受黑客攻击                                                 | 它是高度安全的，因为数据在通过网络看到之前已被加密           |

## 用于 HTTPS 的 SSL/TLS 证书类型

现在在这个 HTTPS 和 HTTP 区别教程中，我们将介绍与 HTTPS 一起使用的 SSL/TLS 证书的类型：

### Domain Validation:

域验证验证申请证书的人是域名的所有者。这种类型的验证通常需要几分钟到几个小时。

### Organization Validation:

证书颁发机构不仅验证域的所有权，还验证所有者的身份。这意味着可能会要求所有者提供个人身份证明文件以证明其身份。

### Extended Validation:

扩展验证是最高级别的验证。它包括验证域名所有权、所有者身份以及业务注册证明。

