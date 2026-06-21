# YunDrag

[简体中文](README.zh-CN.md)

YunDrag is a lightweight macOS menu bar utility for moving and resizing windows directly under the mouse pointer. It uses macOS Accessibility APIs, so it can work across applications without adding window chrome or extra panels.

## Features

- Move the window under the cursor with `Control + Command + mouse movement`.
- Resize the window under the cursor with `Control + Option + mouse movement`.
- Runs as a menu bar app with no Dock icon.
- Provides an Accessibility permission status item and a shortcut to System Settings.

## Requirements

- macOS 12.4 or later.
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

## GitHub Actions Release

The repository includes a GitHub Actions workflow that builds the Release app on push, pull request, and manual dispatch. Push a version tag to create or update a GitHub Release with a macOS DMG:

```sh
git tag v1.8.1
git push origin v1.8.1
```

Open the generated DMG and drag `YunDrag.app` into the `Applications` shortcut.

By default, GitHub Actions builds an unsigned app. Unsigned builds can ask for Accessibility permission again after each update because macOS cannot match them to a stable code-signing identity. Without an Apple Developer ID, you can still make update identity stable by signing release builds with a self-signed local code-signing certificate:

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

Add these GitHub repository secrets:

- `MACOS_CODESIGN_CERTIFICATE_BASE64`: the base64 text copied above.
- `MACOS_CODESIGN_CERTIFICATE_PASSWORD`: the password used when exporting the `.p12`.

The first build signed with this certificate still needs a fresh Accessibility grant. Later builds signed with the same certificate should keep the same TCC identity. This is not Apple notarization, so macOS may still show Gatekeeper warnings on first launch. For public distribution, use Developer ID signing and notarization.

## Usage

Launch `YunDrag.app`, then grant Accessibility permission when prompted. If permission is not active yet, open the menu bar item and choose `打开辅助功能设置`; after enabling YunDrag in System Settings, the app detects the permission and enables shortcuts automatically.

The app watches modifier-key changes globally. Hold the relevant shortcut, move the mouse, and the target window follows or resizes.

## Project Structure

- `src/` contains Swift source files for the app delegate, menu controller, permission guide, Accessibility window controller, modifier monitor, and geometry helpers.
- `Assets.xcassets/` contains the app icon assets.
- `YunDrag.xcodeproj/` contains the Xcode project and shared schemes.

## Development Notes

There is currently no XCTest target. For behavior changes, verify manually with Accessibility permission enabled and test both move and resize shortcuts.
