---
title: 'Niri + Noctalia：在 Arch Linux 上搭建桌面环境'
publishDate: '2025-12-26T10:12:46+08:00'
description: '记录在 Arch Linux 上安装和配置 Niri、Noctalia、输入法与 NVIDIA 环境的过程。'
heroImage: { src: './feature1.png', alt: 'Niri 桌面环境' }
tags:
  - Arch
  - Niri
  - Linux
language: '中文'
draft: false
---

首先,我们要知道: niri作为一个窗口管理器, 是没有完整的桌面环境, 因此需要自己额外配置, 目前有两种主流的方式:

- 一种是用户自己配置所有所需部件(比如: waybar rofi dunst之类的)
- 另一种则是直接使用别人写好的quickshell,实现开箱即用的效果(也是在niri官方[快速入门文档](https://github.com/YaLTeR/niri/wiki/Getting-Started)中所推荐的)

## 安装

这里我们采用的是第二种[noctalia](https://github.com/noctalia-dev/noctalia-shell)(和niri推荐的[dms](https://github.com/AvengeMedia/DankMaterialShell)类似)
如果你是arch的话,直接运行以下命令即可安装

```shell
sudo pacman -Syu niri xwayland-satellite xdg-desktop-portal-gnome xdg-desktop-portal-gtk alacritty
yay -S noctalia-shell
```

此外,我习惯使用的一些软件如下:

```shell
yay -S kitty timeshift hyprlock swayidle polkit-gnome fcitx5-im fcitx5-chinese-addons
```

- kitty 和alacritty类似的终端模拟器
- timeshift 一个系统备份和回溯工具
- hyprlock hyprland下的锁屏软件
- swayidle 用于检测系统长时间操作实现自动休眠等功能
- polkit-gnome 用于身份认证

## 启动

在终端下输入`niri-session`简单体验一下niri吧~

## 配置 Niri

niri的配置文件默认在$HOME目录的.config/niri下,使用的是[kdl语法](https://kdl.dev/)

我习惯使用kitty, 所以进入niri配置文件, 将alacritty修改成kitty

```vim
- Mod+Return hotkey-overlay-title="Open a Terminal: alacritty" { spawn "alacritty"; }
+ Mod+Return hotkey-overlay-title="Open a Terminal: kitty" { spawn "kitty"; }
```

配置一下niri的开机启动,将下面代码加入niri配置文件中

```vim
spawn-at-startup "fcitx5"
spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
spawn-sh-at-startup "qs -c noctalia-shell"
spawn-sh-at-startup "/usr/bin/swayidle -w timeout 601 'niri msg action power-off-monitors' timeout 600 'hyprlock' before-sleep 'hyprlock'"
```

在该配置中,有两点需要注意一下:

1. 因为n卡的原因,我没有配置长时间自动休眠,如有需要,自行去修改一下swayidle的配置
2. hyprlock的锁屏需要自己配置一下

## 配置 Niri 开机自启动

我这里使用的是greetd,使用 `sudo pacman -S greetd` 安装即可
然后配置一下greetd的配置文件 `/etc/greetd/config.toml` 将最后一行的username换成你自己的名字即可

```
[terminal]
vt = 1

[default_session]
command = "niri-session"

user = "username"
```

greetd的开机自启动

```shell
sudo systemctl enable greetd
sudo systemctl disable getty@tty1
```

现在重启就可以体验你全新的 niri 了

## FAQ

### N 卡用户的 Niri 内存占用过高

在`/etc/nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json`文件内写入一下内容:

```vim
{
    "rules": [
        {
            "pattern": {
                "feature": "procname",
                "matches": "niri"
            },
            "profile": "Limit Free Buffer Pool On Wayland Compositors"
        }
    ],
    "profiles": [
        {
            "name": "Limit Free Buffer Pool On Wayland Compositors",
            "settings": [
                {
                    "key": "GLVidHeapReuseRatio",
                    "value": 0
                }
            ]
        }
    ]
}
```

具体参考niri的[官方文档](https://github.com/YaLTeR/niri/wiki/Getting-Started#nvidia)

### Noctalia 图标显示异常

参考noctalia[官方文档](https://docs.noctalia.dev/getting-started/faq/#configuration)
配置 `/etc/environment` 文件 ,加入下面一行即可

```vim
QT_QPA_PLATFORMTHEME=gtk3
```

### Fcitx5 输入法问题

同样配置 `/etc/environment` 文件

```vim
# X11或XWayland窗口需要
XMODIFIERS=@im=fcitx
# Qt窗口需要
QT_IM_MODULE=fcitx
```
