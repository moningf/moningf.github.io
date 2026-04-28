+++
date = '2026-04-28T14:46:50+08:00'
draft = false
title = 'Linux 下配置 OCS 网课助手'
tags = ['Linux', 'OCS', '浏览器脚本']
# categories = ['Linux']
description = '记录 Linux 环境下配置 OCS 网课助手的过程，包括 Arch Linux 与 Debian 系发行版的安装方式。'
# summary = 'Linux 环境下配置 OCS 网课助手的记录。'
+++

## 前言

最近在 Linux 桌面环境下尝试运行 OCS 网课助手时，发现官方教程主要面向普通桌面用户，对 Linux 下不同浏览器路径、扩展权限、脚本管理器兼容性等问题没有展开说明。

因此，这篇文章主要记录我在 Linux 环境下配置 OCS 网课助手的过程，重点放在安装、路径配置和发行版差异上。

> 声明：本文仅记录 Linux 环境下配置浏览器脚本运行环境的过程，不提供绕过课程平台规则、自动完成课程任务或规避学习要求的指导。使用相关工具前，请确认符合所在学校、课程平台与课程教师的规定。

---

## 一、OCS 是什么？

OCS，全称 Online Course Script，是一个运行在浏览器脚本管理器中的网课辅助脚本。根据官方说明，它可以通过脚本猫、油猴等脚本管理器运行，并支持多个网课平台。

本文不展开具体课程平台的使用流程，只关注 Linux 环境下如何使用。
{{< github repo="ocsjs/ocsjs" showThumbnail=false >}}

---

## 二、如何使用？

>[!note]使用前须知
> 需要在设置里将浏览器路径设置为 `/opt/ocs-desktop/resources/bin/chrome/chrome/chrome` 才能正常使用。

### Arch Linux
在这里非常感谢 [syhanjin](https://github.com/syhanjin)，打包了 aur 包 [ocs-desktop-bin](https://aur.archlinux.org/packages/ocs-desktop-bin)。
当时也是困惑了我很久，最后在 [Issue](https://github.com/ocsjs/ocs-desktop/issues/57) 中发现这个包, 目前还可以正常使用。

通过下面命令安装即可
```bash
yay -S ocs-desktop-bin
```

### Debian 系
根据 AUR 包中的安装逻辑，我整理了一个 Debian 系发行版可用的配置脚本。该脚本主要用于下载并放置 OCS Desktop 所需文件，同时创建必要的启动入口。
> 目前只在我自己的环境中测试过，使用前建议先阅读脚本内容。
```bash
# 赋予 setup_ocs.sh 有运行权限
chmod +x setup_ocs.sh
# 运行
./setup_ocs.sh
```

{{< button href="/scripts/setup_ocs.sh" target="_self" >}}
下载脚本文件
{{< /button >}}

