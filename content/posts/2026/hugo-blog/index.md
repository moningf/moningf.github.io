+++
date = '2026-02-14T13:37:12+08:00'
draft = false
title = '博客折腾记录'
tags = ['Blog']
+++

# Hugo 安装与使用

## 安装 Hugo
 先决条件：
 1. Git
	 - 使用[Hugo Modules] 功能
	 - 将主题作为Git子模块安装
 2. Go
 3. Dart Sass
	 - 使用最新的Sass语言特性时被用于将Sass转换为CSS

安装：
{{< tabs >}}

    {{< tab label="ArchLinux" >}}

    ```bash
    sudo pacman -S hugo
    ```
    {{< /tab >}}

    {{< tab label="macOS" >}}
    ```bash
    brew install hugo
    ```
    {{< /tab >}}

    {{< tab label="Ubuntu" >}}
    ```bash
    sudo snap install hugo
    ```
    {{< /tab >}}

{{< /tabs >}}

## 快速起步
创建目录
```sh
# 创建站点
hugo new site blog
# 进入目录
cd blog
# Git仓库初始化
git init
# 将主题以 Git 子模块的形式加入
git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/anank
# 在配置文件中加入主题配置
echo "theme = 'ananke'" >> hugo.toml
# 启动 Hugo 开发服务器
hugo server
```

添加内容
```sh
# 在 content/posts 文件夹内创建文件
hugo new content/posts/my-first-post.md
# 启动 Hugo 开发服务器（-D 表示显示草稿）
hugo server --buildDrafts
hugo server -D
```

配置 Hugo

```text title:'在 hugo.toml 文件中配置'
baseURL = 'https://example.org/'
languageCode = 'en-us'
title = '我的新 Hugo 网站'
theme = 'ananke'
```

1. 为您的生产网站设置 `baseURL`。该值必须以协议开头，并以斜杠结尾，如上所示。
2. 将 `languageCode` 设置为您的语言和地区。
3. 为您的生产网站设置 `title`。

启动 Hugo 的开发服务器以查看更改，记得包含草稿内容。

```text
hugo server -D
```

## 发布网站

发布”网站时，Hugo 会在项目根目录的 `public` 目录中创建整个静态网站。其中包括 HTML 文件和像图像、CSS 文件和 JavaScript 文件这样的资源。

当您发布网站时，通常不希望包含[草稿、将来或过期内容]。命令很简单。

```text
hugo
```



# 主题配置

我使用的主题是 BlowFish 。

## 基础配置
首先，将主题内`themes/blowfish/config/_default/`文件夹内的文件复制到`config/_default/`文件夹内
```text
config
└── _default
    ├── hugo.toml              --核心与基础配置
    ├── languages.zh-CN.toml   --语言与作者信息
    ├── menus.zh-CN.toml       --中文版网站的导航菜单
    ├── markup.toml            --控制 Markdown 如何转换成 HTML
    ├── module.toml            --用于 Hugo Modules（Go 模块）的配置
    └── params.toml            --Blowfish 主题特有的外观和功能配置
```

**为什么这样分类？**
这种分类方式对应 Hugo 配置中的*根键 (Root Keys)*：
*   params.toml 里的内容等同于在主文件中写 [params]。
*   markup.toml 里的内容等同于写 [markup]。
*   languages.zh-CN.toml 等同于 [languages.zh-CN]。
