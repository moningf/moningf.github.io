+++
date = '2026-03-14T21:26:06+08:00'
draft = false
title = '修复Opencode在Tmux下的移动问题'
tags=["vibe coding"]
# categories= ["all"]
# series=[""]
# series_order=1
description='修复OpenCode在Tmux中，不能正确的上下移动'
# summary=''
+++

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
