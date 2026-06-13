//
//  AccessibilityPermissionGuide.swift
//  YunMove
//

import AppKit
import ApplicationServices

enum AccessibilityReadiness: Equatable {
    case ready
    case notAuthorized
    case unavailable(String)
}

// 封装辅助功能权限检查、系统设置跳转和权限提示弹窗。
@MainActor
final class AccessibilityPermissionGuide {
    private weak var activeAlertWindow: NSWindow?
    private var lastReadinessFailureMessage: String?

    // 读取系统辅助功能授权状态；prompt 为 true 时系统可能弹出授权提示。
    func isTrusted(prompt: Bool) -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    // 信任状态不等于 AX 一定可读；授权后做一次最小系统级 AX 读取验证。
    func readiness(prompt: Bool) -> AccessibilityReadiness {
        guard isTrusted(prompt: prompt) else {
            lastReadinessFailureMessage = nil
            return .notAuthorized
        }

        return verifySystemWideAccessibilityRead()
    }

    // 打开“隐私与安全性 > 辅助功能”设置页，方便用户给 YunDrag 授权。
    func openSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        if !NSWorkspace.shared.open(url) {
            AppLog.accessibility.error("Failed to open Accessibility settings")
        }
    }

    // 用简单弹窗解释为什么需要权限，并把按钮动作交给调用方处理。
    func show(openSettingsHandler: () -> Void, quitHandler: () -> Void) {
        if let activeAlertWindow {
            activeAlertWindow.makeKeyAndOrderFront(nil)
            return
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "YunDrag 需要辅助功能权限来读取鼠标下的窗口，并移动或调整窗口大小。请在系统设置 > 隐私与安全性 > 辅助功能中启用 YunDrag，授权生效后应用会自动启用快捷键。"
        alert.addButton(withTitle: "打开辅助功能设置")
        alert.addButton(withTitle: "稍后")
        alert.addButton(withTitle: "退出")

        activeAlertWindow = alert.window
        defer {
            if activeAlertWindow === alert.window {
                activeAlertWindow = nil
            }
        }

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            openSettingsHandler()
        case .alertThirdButtonReturn:
            quitHandler()
        default:
            break
        }
    }

    // 授权在弹窗显示期间生效时，关闭旧提示避免继续显示“需要权限”。
    func dismissActivePrompt() {
        guard let activeAlertWindow else {
            return
        }

        NSApp.stopModal(withCode: .alertSecondButtonReturn)
        activeAlertWindow.close()
        self.activeAlertWindow = nil
    }

    private func verifySystemWideAccessibilityRead() -> AccessibilityReadiness {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedApplicationValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApplicationValue
        )

        guard error == .success else {
            let message = "AX 读取焦点应用失败: \(error.rawValue)"
            return unavailableReadiness(message)
        }

        guard let focusedApplicationValue else {
            let message = "AX 焦点应用为空"
            return unavailableReadiness(message)
        }

        guard CFGetTypeID(focusedApplicationValue) == AXUIElementGetTypeID() else {
            let message = "AX 焦点应用类型异常"
            return unavailableReadiness(message)
        }

        lastReadinessFailureMessage = nil
        return .ready
    }

    private func unavailableReadiness(_ message: String) -> AccessibilityReadiness {
        if lastReadinessFailureMessage != message {
            AppLog.accessibility.error("\(message, privacy: .public)")
            lastReadinessFailureMessage = message
        }

        return .unavailable(message)
    }
}
