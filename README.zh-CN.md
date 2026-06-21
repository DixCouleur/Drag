# YunDrag 简体中文说明

[English](README.md)

YunDrag 是一个轻量级 macOS 菜单栏工具，用来直接移动或调整鼠标指针下方的窗口。它基于 macOS 辅助功能 API，因此可以跨应用操作窗口，不需要额外窗口边框或控制面板。

## 功能

- 按住 `Control + Command` 并移动鼠标：移动鼠标下方窗口。
- 按住 `Control + Option` 并移动鼠标：调整鼠标下方窗口大小。
- 作为菜单栏应用运行，不显示 Dock 图标。
- 菜单中显示辅助功能权限状态，并提供打开系统设置的入口。

## 环境要求

- macOS 12.4 或更高版本。
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

## GitHub Actions Release

仓库已包含 GitHub Actions workflow，会在 push、pull request 和手动触发时构建 Release app。推送版本 tag 后，会创建或更新 GitHub Release，并上传 macOS DMG：

```sh
git tag v1.8.2
git push origin v1.8.2
```

打开生成的 DMG，把 `YunDrag.app` 拖到 `Applications` 快捷方式中即可安装。

默认情况下，GitHub Actions 会构建未签名 app。未签名构建每次更新后都可能重新要求辅助功能权限，因为 macOS 无法把它们匹配到稳定的代码签名身份。即使没有 Apple Developer ID，也可以用自签名的本地代码签名证书让 release 构建的身份稳定：

```sh
cat > /tmp/yundrag-codesign.cnf <<'EOF'
[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[ req_distinguished_name ]
CN = YunDrag Local Code Signing

[ v3_req ]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = codeSigning
EOF

openssl req -new -newkey rsa:2048 -nodes \
  -keyout YunDragLocalSigning.key \
  -x509 -days 3650 \
  -out YunDragLocalSigning.crt \
  -config /tmp/yundrag-codesign.cnf \
  -sha256

openssl pkcs12 -export \
  -name "YunDrag Local Code Signing" \
  -inkey YunDragLocalSigning.key \
  -in YunDragLocalSigning.crt \
  -out YunDragLocalSigning.p12

base64 -i YunDragLocalSigning.p12 | pbcopy
```

在 GitHub 仓库中添加这些 Secrets：

- `MACOS_CODESIGN_CERTIFICATE_BASE64`：上面复制出来的 base64 文本。
- `MACOS_CODESIGN_CERTIFICATE_PASSWORD`：导出 `.p12` 时输入的密码。

第一次切换到这张证书签名的构建时，仍然需要重新授予一次辅助功能权限。之后只要一直用同一张证书签名，后续版本应该会保持同一个 TCC 身份。这不是 Apple 公证，所以首次启动时 macOS 仍可能显示 Gatekeeper 提示。面向公开分发时，建议使用 Developer ID 签名和公证。

## 使用方法

启动 `YunDrag.app` 后，按提示授予辅助功能权限。如果权限尚未生效，可以点击菜单栏图标，选择 `打开辅助功能设置`；在系统设置中启用 YunDrag 后，应用会自动检测权限并启用快捷键。

授权成功后，按住对应快捷键并移动鼠标，即可移动或调整当前鼠标下方的窗口。

## 项目结构

- `src/`：Swift 源码，包括应用代理、菜单控制器、权限引导、辅助功能窗口控制器、快捷键监听和几何辅助方法。
- `Assets.xcassets/`：应用图标资源。
- `YunDrag.xcodeproj/`：Xcode 项目和共享 schemes。

## 开发说明

当前没有 XCTest target。修改窗口移动、缩放或权限流程后，需要在已启用辅助功能权限的 macOS 环境中手动验证两个快捷键。
