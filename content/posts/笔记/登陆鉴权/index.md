---
authors: ["Moningf"]
date : '2025-12-27T10:50:39+08:00'
title : 'Cookie、Session 与 JWT —— 发展与用途'
# featureImage : "img/feature1.png"
showWordCount : true
showReadingTime : true
showComments : false
tags: ["笔记"]
# categories: [" "]
draft : false
---



## 一、问题背景：HTTP 无状态

* HTTP 天生无状态：服务器无法区分多次请求是否来自同一用户
* 实际需求：登录态、购物车、个性化设置
* 解决思路：**在多次请求之间携带或保存“状态”**

---

## 二、Cookie（第一代方案）

### 1. 出现背景

* 1994 年 Netscape 提出
* 目标：让浏览器在多次请求中携带少量信息

### 2. 本质

* 存储位置：**客户端（浏览器）**
* 形式：键值对（key=value）
* 浏览器会自动保存、自动携带

### 3. 典型用途

* 用户偏好（主题、语言）
* 会话标识（如 sessionId）
* 访问统计

### 4. 优缺点

**优点**

* 简单
* 浏览器原生支持

**缺点**

* 数据在客户端，可被查看和篡改
* 不适合存敏感信息
* 单个 Cookie 大小有限（约 4KB）

> 结论：**Cookie 本身不适合作为“可信身份存储”**

---

## 三、Session（第二代方案）

### 1. 出现背景

* 为解决 Cookie 不安全的问题
* 目标：状态由服务器统一管理

### 2. 核心思想

* **用户状态存在服务器**
* 客户端只保存一个 sessionId（通常通过 Cookie）

```
浏览器：JSESSIONID=ABC123
服务器：ABC123 → 用户信息
```

### 3. 工作流程

1. 用户登录
2. 服务器创建 Session
3. 生成 sessionId
4. 通过 Cookie 返回给浏览器
5. 后续请求自动携带 sessionId

### 4. 典型用途

* 传统 Web 网站
* 后台管理系统
* 企业内部系统

### 5. 优缺点

**优点**

* 安全性高（敏感数据在服务器）
* 可主动失效、强制下线
* 逻辑清晰，易理解

**缺点**

* 服务器有状态
* 集群需要 Session 共享（如 Redis）
* 扩展成本较高

---

## 四、Session 的瓶颈（Web 形态变化）

### 1. 新变化

* 用户规模扩大
* 服务器集群化
* 前后端分离、移动端兴起

### 2. 暴露的问题

* 负载均衡下 Session 不一致
* Session 粘性或共享增加复杂度
* 不适合纯 API / 微服务场景

---

## 五、JWT（第三代方案）

### 1. 出现背景

* 前后端分离
* REST API
* 微服务架构

### 2. 核心思想

* **服务器不存用户状态**
* 用户每次请求都携带“自包含凭证”

> 从“服务器记住你” → “你自己证明你是谁”

### 3. JWT 结构

* Header：算法、类型
* Payload：用户信息、过期时间（Base64 编码）
* Signature：防篡改签名

```
Header.Payload.Signature
```

### 4. 使用方式

* 登录成功后返回 JWT
* 客户端保存（localStorage / Cookie）
* 请求时放入 Header

```
Authorization: Bearer <token>
```

### 5. 优缺点

**优点**

* 服务器无状态
* 天然支持集群、微服务
* 适合 API、移动端

**缺点**

* 无法主动失效（只能等过期）
* 泄露风险高（必须 HTTPS）
* Payload 不可存敏感信息

---

## 六、三者对比总结

| 维度    | Cookie | Session | JWT       |
| ----- | ------ | ------- | --------- |
| 存储位置  | 客户端    | 服务器     | 客户端       |
| 是否有状态 | 否      | 是       | 否         |
| 安全性   | 低      | 高       | 中         |
| 扩展性   | 高      | 低       | 高         |
| 主动失效  | 否      | 是       | 否         |
| 适用场景  | 辅助     | 传统 Web  | API / 微服务 |

---

## 七、现实中的组合使用

### 1. Cookie + Session（经典）

* 服务端渲染页面
* Java Web / JSP / Thymeleaf

### 2. JWT + Header（主流）

* 前后端分离
* REST API

### 3. JWT + Refresh Token（常见折中）

* 短期 JWT
* 长期 Refresh Token 存 Redis / Session

---

## 八、核心理解

* **Cookie**：传递信息的载体
* **Session**：服务器集中管理状态
* **JWT**：客户端自带凭证，服务器只校验

> 三者不是简单的新旧替代，而是不同 Web 时代下的最优解
