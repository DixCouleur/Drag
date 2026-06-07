# Repository Guidelines

## Project Structure & Module Organization

This repository contains a small macOS Swift menu bar app built with Xcode.

- `YunDrag.xcodeproj/` holds the Xcode project and shared schemes.
- `src/` contains Swift source: lifecycle, menu UI, permission prompts, Accessibility window operations, modifier tracking, and geometry helpers.
- `Assets.xcassets/` contains app icon resources and asset catalog metadata.
- `README.md` and `README.zh-CN.md` provide English and Simplified Chinese project introductions.

Keep module boundaries narrow. Put new menu actions in `StatusMenuController`, Accessibility API work in `AXWindowController`, and lifecycle coordination in `AppDelegate`.

## Build, Test, and Development Commands

Use the local `rtk` wrapper for shell commands.

- `rtk xcodebuild -list -project YunDrag.xcodeproj` lists targets, build configurations, and schemes.
- `rtk xcodebuild -project YunDrag.xcodeproj -scheme debug -configuration Debug build` builds the Debug app.
- `rtk xcodebuild -project YunDrag.xcodeproj -scheme release -configuration Release build` builds the Release app.
- `rtk xcodebuild -project YunDrag.xcodeproj -scheme debug clean` removes Xcode build products for the debug scheme.

Launch from Xcode or the built `.app` bundle.

## Coding Style & Naming Conventions

Use Swift 6 with 4-space indentation, lower camelCase for methods and properties, and UpperCamelCase for types. Prefer `final` classes for concrete controllers. Keep AppKit-facing controllers `@MainActor`.

For Accessibility and Core Foundation APIs, check `AXError` before using returned values and compare `CFTypeID` before casting opaque AX objects. Keep comments short and focused on non-obvious AX or threading behavior.

## Testing Guidelines

No XCTest target exists. For movement, resizing, or permission changes, verify manually on macOS with Accessibility permission enabled. When adding tests, create an XCTest target, name files `*Tests.swift`, and document the `rtk xcodebuild test` command here.

## Commit & Pull Request Guidelines

Existing commits use concise imperative subjects such as `Improve accessibility permission guidance` and `Split app delegate responsibilities`. Follow that style and keep each commit focused.

Pull requests should include a short behavior summary, manual verification steps, and screenshots or screen recordings for menu bar, permission prompt, or visible interaction changes. Link related issues when available.

## Security & Configuration Tips

The app depends on macOS Accessibility permissions. Do not hard-code user-specific paths or permissions workarounds. Avoid logging sensitive window titles or user content when expanding Accessibility diagnostics.
