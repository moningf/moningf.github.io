---
title: 'B 站 OBS 直播方法'
publishDate: '2026-02-16T19:14:07+08:00'
description: '记录通过浏览器用户脚本在 B 站网页端使用 OBS 开播的配置过程。'
tags:
  - Bilibili
  - OBS
language: '中文'
draft: false
---

通过油猴脚本在网页端直接开播

## 第一步：下载浏览器插件

浏览器插件 Tampermonkey ：

- [Tampermonkey](https://www.tampermonkey.net/)

## 第二步：下载用户脚本

所需脚本的源码仓库为 [ProgramRipper/BLiveWeb](https://github.com/ProgramRipper/BLiveWeb)。

[下载用户脚本](https://ghfast.top/https://raw.githubusercontent.com/ProgramRipper/BLiveWeb/refs/heads/master/lib/index.user.js)

## 第三步：直播

下载好插件之后就可以在B站网页端正常开播，5000粉丝限制目前没有影响。

![B 站网页端直播界面](./image.png)
