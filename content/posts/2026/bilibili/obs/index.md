+++
date = '2026-02-16T19:14:07+08:00'
draft = false
title = 'B站OBS直播方法'
featureImage = 'img/bilibili.jpg'
tags=["bilibili"]
# tags=[]
# categories= ["all"]
# series=[""]
# series_order=1
description='本文介绍 bilibili 在粉丝低于 5000 时如何开播:通过油猴脚本'
# summary=''
+++
通过油猴脚本在网页端直接开播

### 第一步：下载浏览器插件
浏览器插件 Tampermonkey ：
- [Tampermonkey](https://www.tampermonkey.net/)
### 第二步：**下载油猴插件**

下面的仓库为所需插件的仓库
{{< github repo="ProgramRipper/BLiveWeb" showThumbnail=false >}}

{{< button href="https://ghfast.top/https://raw.githubusercontent.com/ProgramRipper/BLiveWeb/refs/heads/master/lib/index.user.js" target="_self" >}} 下载插件 {{< /button >}}
### 第三步：直播
下载好插件之后就可以在B站网页端正常开播，5000粉丝限制目前没有影响。
{{<figure src=image.png >}}
