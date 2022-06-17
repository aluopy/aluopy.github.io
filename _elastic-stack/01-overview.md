---
title: "Overview"
permalink: /elastic-stack/overview/
excerpt: "How to quickly install and setup elastic-stack for use docker."
last_modified_at: 2022-05-07T08:48:05-04:00
redirect_from:
  - /theme-setup/
toc: false
---

[Elastic Stack](https://www.elastic.co/cn/elastic-stack/) 核心产品包括 Elasticsearch、Kibana、Beats 和 Logstash（也称为 [ELK Stack](https://www.elastic.co/cn/what-is/elk-stack)）。能够安全可靠地获取任何来源、任何格式的数据，然后实时地对数据进行搜索、分析和可视化。

- [Elasticsearch](https://www.elastic.co/cn/what-is/elasticsearch) 是一个分布式的免费开源搜索和分析引擎，适用于包括文本、数字、地理空间、结构化和非结构化数据等在内的所有类型的数据。它的特点有：分布式，零配置，自动发现，索引自动分片，索引副本机制，restful风格接口，多数据源，自动搜索负载等。
- [Logstash](https://www.elastic.co/cn/logstash/) 是免费且开放的服务器端数据处理管道，能够从多个来源采集数据，转换数据，然后将数据发送到诸如 Elasticsearch 等“存储库”中。
- [Kibana](https://www.elastic.co/cn/kibana/) 是一个免费且开放的用户界面，能够让您对 Elasticsearch 数据进行可视化，并让您在 Elastic Stack 中进行导航。您可以进行各种操作，从跟踪查询负载，到理解请求如何流经您的整个应用，都能轻松完成。
- [Beats](https://www.elastic.co/cn/beats/) 是一个免费且开放的平台，集合了多种单一用途数据采集器。它们从成百上千或成千上万台机器和系统向 Logstash 或 Elasticsearch 发送数据。

这些不同的组件一起最常用于监控、故障排除和保护 IT 环境（尽管 ELK 堆栈还有更多用例，例如商业智能和 Web 分析）。 Beats 和 Logstash 负责数据收集和处理，Elasticsearch 索引和存储数据，Kibana 提供用于查询数据和可视化数据的用户界面。

Elastic Stack 是 ELK Stack 的更新换代产品。

