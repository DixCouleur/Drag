# Repository Guidelines

## Project Structure & Module Organization

This repository contains a small macOS Objective-C app built with Xcode.

- `YunDrag.xcodeproj/` holds the Xcode project and shared schemes.
- `src/` contains application source files: `main.m`, `AppDelegate.*`, and `utils.*`.
- `Assets.xcassets/` contains app icon resources and asset catalog metadata.

Keep app behavior in `AppDelegate` unless a helper is reusable across files; place reusable Accessibility or geometry helpers in `utils.*`.

## Build, Test, and Development Commands

Use the local `rtk` wrapper for shell commands.

- `rtk xcodebuild -list -project YunDrag.xcodeproj` lists targets, build configurations, and schemes.
- `rtk xcodebuild -project YunDrag.xcodeproj -scheme debug -configuration Debug build` builds the Debug app.
- `rtk xcodebuild -project YunDrag.xcodeproj -scheme release -configuration Release build` builds the Release app.
- `rtk xcodebuild -project YunDrag.xcodeproj -scheme debug clean` removes Xcode build products for the debug scheme.

There is no app runner script in this checkout. Launch from Xcode or from the built `.app` bundle.

## Coding Style & Naming Conventions

Use Objective-C conventions already present in `src/`: 4-space indentation, braces on method or function declaration lines, descriptive Cocoa-style method names, and lower camelCase for properties and helper functions. Keep comments short and useful; existing source comments are mostly Chinese, so prefer Chinese for nearby explanatory comments unless the surrounding file moves to English.

Manage Core Foundation objects explicitly. Release copied or created values with `CFRelease` after use, and check `AXError` return values before using Accessibility API results.

## Testing Guidelines

No XCTest target or test directory is currently present. For changes to window movement, resizing, or Accessibility behavior, verify manually on macOS with Accessibility permission enabled for the app. When adding tests, create an XCTest target in `YunDrag.xcodeproj`, name test files `*Tests.m`, and document the new `xcodebuild test` command here.

## Commit & Pull Request Guidelines

This checkout does not include `.git` metadata, so no local commit message pattern can be inferred. Use concise, imperative commit subjects such as `Fix resize offset handling` or `Update app icon assets`.

Pull requests should include a short behavior summary, manual verification steps, and screenshots or screen recordings for menu bar, permission prompt, or visible interaction changes. Link related issues when available.

## Security & Configuration Tips

The app depends on macOS Accessibility permissions. Do not hard-code user-specific paths or permissions workarounds. Avoid logging sensitive window titles or user content when expanding Accessibility diagnostics.
