---
authors: ["Moningf"]
date : '2026-01-28T14:32:56+08:00'
title : 'Neovim使用心得'
showWordCount : true
showReadingTime : true
# showComments : true
# series: ["Documentation"]
# series_order: 11
tags: ["Neovim"]
# categories: [" "]
draft : false
---
# Neovim 运行与配置加载机制简析

> 在我学习 Neovim 的过程中，逐渐对它的启动流程和配置加载机制有了一些理解，分享一下共大家阅读。
> 如有理解不对的，欢迎在评论区指正

---

## 一、Neovim 配置加载结构

常见的 Neovim 配置目录结构如下：

```
~/.config/nvim/
├── init.lua                  # Neovim 启动入口
├── lua/
│   ├── config/               # 核心配置
│   │   ├── options.lua       # vim.opt / vim.o
│   │   ├── keymaps.lua       # 快捷键
│   │   ├── autocmds.lua      # 自动命令
│   │   └── lazy.lua          # Lazy.nvim 插件管理器
│   │
│   └── plugins/              # 插件配置
│       ├── ui.lua            # UI 类插件
│       ├── lsp.lua           # LSP / mason
│       ├── cmp.lua           # 自动补全
│       ├── treesitter.lua    # 语法高亮
│       └── init.lua          # 插件入口
│
└── after/                    # 启动后加载
    └── ftplugin/
        └── python.lua
```

---

## 二、Neovim 启动时做了什么？

### init.lua：启动入口

* `init.lua` 是 Neovim **默认且唯一的启动入口**
* 启动后，Neovim 会自动加载：

  ```
  ~/.config/nvim/init.lua
  ```

在 `init.lua` 中写的任何 Lua 代码都会**立即执行**。

---

### lua/ 目录与模块机制

* `lua/` 目录 **本身并不是 runtimepath 的一项**
* 但它是 **runtimepath 中目录的子目录**
* Neovim 在 `require()` 时，会自动在所有 `runtimepath/lua/` 下查找模块

例如：

```lua
require("config.options")
```

Neovim 实际查找的是：

```text
~/.config/nvim/lua/config/options.lua
```

可以通过下面命令查看当前 runtimepath：

```vim
:set rtp?
```

---

### after/ 目录的作用

`after/` 目录用于**覆盖或补充已有配置**，加载顺序在最后：

* 在所有 `runtimepath` 加载完成后
* 自动加载 `after/` 目录中的内容
---

## 三、配置拆分与加载方式

在 `init.lua` 中，通常只保留最少逻辑：

```lua
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
```
---

## 四、插件是如何被加载的？（以 Lazy.nvim 为例）

`lazy.nvim` 的核心职责是：

1. **自动下载插件**
2. **将插件路径加入 runtimepath**
3. **控制插件加载时机（懒加载）**

```lua
require("lazy").setup({
  { "nvim-treesitter/nvim-treesitter", event = "BufReadPost" },
  { "neovim/nvim-lspconfig", ft = "lua" },
})
```

当插件被加载后：

* 插件目录会被加入 `rtp`
* 插件中的：

  * `plugin/*.lua`
  * `lua/*.lua`
  * `after/*.lua`

都会按规则参与加载


---

## 五、Neovim Lua API 简介

Neovim 提供了一套完整的底层 API：

官方文档

* API 文档：[https://neovim.io/doc/user/api.html#api](https://neovim.io/doc/user/api.html#api)

底层 API 调用方式类似：

```lua
vim.api.nvim_set_keymap(...)
vim.api.nvim_buf_set_lines(...)
```

---

### 更推荐的 Lua 高级接口

由于底层 API 较为繁琐，Neovim 提供了更友好的 Lua 封装：

* `vim.o` / `vim.opt`：设置选项
* `vim.fn`：调用 Vimscript 函数
* `vim.cmd()`：执行 Vim 命令
* `vim.keymap.set()`：设置快捷键

示例：

```lua
vim.opt.number = true
vim.keymap.set("n", "<leader>w", ":w<CR>")
# 如果不用vim.o的话,下面的方式过于繁琐
vim.api.nvim_set_option_value('number',true,{})
vim.api.nvim_set_keymap(
  "n",
  "<leader>w",
  ":w<CR>",
  { noremap = true, silent = true }
)
```
> 因此，在 Neovim 配置中，更推荐优先使用 Lua API

---

## 六、小技巧

### 查看和设置选项
是一个非常友好的选项浏览界面,方便配置option
```vim
:options
```
---

