---
title: "记一次 Spring Security 循环依赖的“八股变成现实”"
publishDate: '2026-10-14T17:22:06+08:00'
description: "在学习 Spring Security 时，第一次遇到的循环依赖问题。"
tags: ["Spring Security", "Spring Boot", "后端开发", "踩坑记"]
categories: ["后端技术"]
draft: false
---

>在学习 Spring Security 时，写代码写着写着，竟然第一次迎来了传说中的**循环依赖**。那一刻，真的有一种“八股文变成现实”的奇妙感觉。

### 事情是这样的

当时的依赖调用链是这样的：

`UserDetailsService` -> `UserService` -> `AuthenticationManager` -> `UserDetailsService`

当时写代码没想那么多，用 MyBatis-Plus 图省事，直接把 `UserService` 注入到了 `UserDetailsService` 里面。结果项目一启动，不出意外地直接报错报红了。

### 几种解决方法

针对这个问题，大概有这么几种处理方式：

1. **注入 `UserMapper`**
   * 不再通过 `UserService` 绕一圈，直接在 `UserDetailsService` 里注入 `UserMapper` 查库。
   * **优缺点**：最简单直接。但从分层来看，安全层直接穿透到了 DAO 层，绕过了业务层。

2. **使用 `@Lazy` 延迟加载**
   * 在注入时加上 `@Lazy`，让 Spring 用代理对象打破初始化闭环。
   * **优缺点**：改动最小，不过感觉有点治标不治本。

3. **提取单独的 `LoginService`**
   * 把包含 `AuthenticationManager` 认证逻辑的部分抽离成一个独立的 `LoginService`。
   * **优缺点**：结构最清爽，职责划分得比较开。

### 总结

要说哪个更好，感觉如果想让代码更规范一点，**提取单独的 `LoginService`** 应该是更好的选择了。

只能说，很多八股文里的东西没踩过坑还真体会不到，撞一次南墙印象就深刻了。
