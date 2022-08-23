# 介绍

## 说明

SSDB 一个高性能的支持丰富数据结构的 NoSQL 数据库, 用于替代 Redis，底层数据库引擎为 Google 的 K-V 数据库 LevelDB 。Redis API 兼容, 支持 Redis 客户端 有部分命令不兼容。支持 String/List/Hash/Sorted Set 类型的 Value，不支持 Set 类型的 Value，TTL(expire) 仅支持 String 类型的 Value。

**注：**SSDB 只有在使用 SSD 的时候，才能获得较好的性能，HHD 下完全无法发挥性能

**注：**LevelDB 是一个高性能的嵌入式数据库，仅适用于高写入低读取的使用场景

## 官方说明

1. 标语
   - 一个高性能的支持丰富数据结构的 NoSQL 数据库, 用于替代 Redis.

2. 特性
   - 替代 Redis 数据库, Redis 的 100 倍容量
   - LevelDB 网络支持, 使用 C/C++ 开发
   - Redis API 兼容, 支持 Redis 客户端
   - 适合存储集合数据, 如 list, hash, zset...
   - 客户端 API 支持的语言包括: C++, PHP, Python, Java, Go
   - 持久化的队列服务
   - 主从复制, 负载均衡

3. 使用感想
   - 适合用来储存超大数据库
   - 并不能完全替代 Redis，写入性能和 Redis 还是有比较大的差距的
   - 不适合用来实现高速搜索引擎