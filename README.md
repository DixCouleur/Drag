# YunDrag

[简体中文](README.zh-CN.md)

YunDrag is a lightweight macOS menu bar utility for moving and resizing windows directly under the mouse pointer. It uses macOS Accessibility APIs, so it can work across applications without adding window chrome or extra panels.

## Features

- Move the window under the cursor with `Control + Command + mouse movement`.
- Resize the window under the cursor with `Control + Option + mouse movement`.
- Runs as a menu bar app with no Dock icon.
- Provides an Accessibility permission status item and a shortcut to System Settings.

## Requirements

- macOS 15.6 or later.
- Xcode with the macOS SDK.
- Accessibility permission enabled for YunDrag.

## Build

List project schemes:

```sh
rtk xcodebuild -list -project YunDrag.xcodeproj
```

Build Debug:

```sh
rtk xcodebuild -project YunDrag.xcodeproj -scheme debug -configuration Debug build
```

Build Release:

```sh
rtk xcodebuild -project YunDrag.xcodeproj -scheme release -configuration Release build
```

## Usage

Launch `YunDrag.app`, then grant Accessibility permission when prompted. If permission is not active yet, open the menu bar item and choose `打开辅助功能设置`; after enabling YunDrag in System Settings, choose `检查权限`.

The app watches modifier-key changes globally. Hold the relevant shortcut, move the mouse, and the target window follows or resizes.

## Project Structure

- `src/` contains Swift source files for the app delegate, menu controller, permission guide, Accessibility window controller, modifier monitor, and geometry helpers.
- `Assets.xcassets/` contains the app icon assets.
- `YunDrag.xcodeproj/` contains the Xcode project and shared schemes.

## Development Notes

There is currently no XCTest target. For behavior changes, verify manually with Accessibility permission enabled and test both move and resize shortcuts.
