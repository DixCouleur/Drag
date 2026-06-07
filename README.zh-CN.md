# YunDrag 简体中文说明

[English](README.md)

YunDrag 是一个轻量级 macOS 菜单栏工具，用来直接移动或调整鼠标指针下方的窗口。它基于 macOS 辅助功能 API，因此可以跨应用操作窗口，不需要额外窗口边框或控制面板。

## 功能

- 按住 `Control + Command` 并移动鼠标：移动鼠标下方窗口。
- 按住 `Control + Option` 并移动鼠标：调整鼠标下方窗口大小。
- 作为菜单栏应用运行，不显示 Dock 图标。
- 菜单中显示辅助功能权限状态，并提供打开系统设置的入口。

## 环境要求

- macOS 15.6 或更高版本。
- 安装 Xcode 和 macOS SDK。
- 为 YunDrag 启用辅助功能权限。

## 构建

查看项目 scheme：

```sh
rtk xcodebuild -list -project YunDrag.xcodeproj
```

构建 Debug 版本：

```sh
rtk xcodebuild -project YunDrag.xcodeproj -scheme debug -configuration Debug build
```

构建 Release 版本：

```sh
rtk xcodebuild -project YunDrag.xcodeproj -scheme release -configuration Release build
```

## 使用方法

启动 `YunDrag.app` 后，按提示授予辅助功能权限。如果权限尚未生效，可以点击菜单栏图标，选择 `打开辅助功能设置`；在系统设置中启用 YunDrag 后，再回到菜单中选择 `检查权限`。

授权成功后，按住对应快捷键并移动鼠标，即可移动或调整当前鼠标下方的窗口。

## 项目结构

- `src/`：Swift 源码，包括应用代理、菜单控制器、权限引导、辅助功能窗口控制器、快捷键监听和几何辅助方法。
- `Assets.xcassets/`：应用图标资源。
- `YunDrag.xcodeproj/`：Xcode 项目和共享 schemes。

## 开发说明

当前没有 XCTest target。修改窗口移动、缩放或权限流程后，需要在已启用辅助功能权限的 macOS 环境中手动验证两个快捷键。
