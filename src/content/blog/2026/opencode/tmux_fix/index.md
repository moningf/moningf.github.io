---
title: '修复 OpenCode 在 tmux 中的滚动问题'
publishDate: '2026-03-14T21:26:06+08:00'
description: '通过调整 tmux 鼠标滚轮绑定，修复 OpenCode 中无法正常上下滚动的问题。'
heroImage: { src: './feature.png', alt: 'OpenCode 与 tmux' }
tags:
  - OpenCode
  - tmux
  - Vibe Coding
language: '中文'
draft: false
---

问题出现原因：
在 Tmux 中上下移动会进入 Vi 模式，在此模式下，它是将整个页面当成 vi 的一个 buffer 对待，因此可以通过设置发送的信息解决，通过 Ai 有如下配置：

```
bind -n WheelUpPane if-shell -F -t = "#{==:#{pane_current_command},opencode}" \
    "send-keys PgUp" \
    "if-shell -F -t = '#{alternate_on}' \
        'send-keys -M' \
        'select-pane -t =; copy-mode -e; send-keys -M'"

bind -n WheelDownPane if-shell -F -t = "#{==:#{pane_current_command},opencode}" \
    "send-keys PgDn" \
    "if-shell -F -t = '#{alternate_on}' \
        'send-keys -M' \
        'select-pane -t =; send-keys -M'"
```
