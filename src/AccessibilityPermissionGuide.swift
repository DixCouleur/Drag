//
//  AccessibilityPermissionGuide.swift
//  YunMove
//

import AppKit
import ApplicationServices

@MainActor
final class AccessibilityPermissionGuide {
    func isTrusted(prompt: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func openSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        if !NSWorkspace.shared.open(url) {
            AppLog.accessibility.error("Failed to open Accessibility settings")
        }
    }

    func show(openSettingsHandler: () -> Void, quitHandler: () -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "YunDrag 需要辅助功能权限来读取鼠标下的窗口，并移动或调整窗口大小。请在系统设置 > 隐私与安全性 > 辅助功能中启用 YunDrag，授权生效后应用会自动启用快捷键。"
        alert.addButton(withTitle: "打开辅助功能设置")
        alert.addButton(withTitle: "稍后")
        alert.addButton(withTitle: "退出")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            openSettingsHandler()
        case .alertThirdButtonReturn:
            quitHandler()
        default:
            break
        }
    }
}
