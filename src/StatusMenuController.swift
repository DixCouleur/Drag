//
//  StatusMenuController.swift
//  YunMove
//

import AppKit

enum AccessibilityPermissionStatus: Equatable {
    case checking
    case notAuthorized
    case authorized
    case paused
    case unavailable

    var title: String {
        switch self {
        case .checking:
            "权限: 检查中"
        case .notAuthorized:
            "权限: 未授权"
        case .authorized:
            "权限: 已授权"
        case .paused:
            "权限: 已暂停"
        case .unavailable:
            "权限: 不可用"
        }
    }
}

// 管理菜单栏图标和下拉菜单。业务动作通过闭包交给 AppDelegate。
@MainActor
final class StatusMenuController: NSObject {
    var openSettingsHandler: (@MainActor @Sendable () -> Void)?
    var checkPermissionHandler: (@MainActor @Sendable () -> Void)?
    var diagnoseWindowHandler: (@MainActor @Sendable () -> Void)?
    var quitHandler: (@MainActor @Sendable () -> Void)?

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var permissionStatusItem: NSMenuItem?
    private var pendingPermissionStatus: AccessibilityPermissionStatus?

    // 创建状态栏图标和菜单项；多次调用不会重复创建。
    func show() {
        guard statusItem == nil else {
            return
        }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        configureStatusButton(statusItem.button)

        menu.removeAllItems()
        let permissionStatusItem = menu.addItem(withTitle: "权限: 检查中", action: nil, keyEquivalent: "")
        permissionStatusItem.isEnabled = false
        self.permissionStatusItem = permissionStatusItem

        let openSettingsItem = menu.addItem(withTitle: "打开辅助功能设置", action: #selector(openSettings), keyEquivalent: "")
        openSettingsItem.target = self

        let checkPermissionItem = menu.addItem(withTitle: "检查权限", action: #selector(checkPermission), keyEquivalent: "")
        checkPermissionItem.target = self

        menu.addItem(.separator())
        menu.addItem(withTitle: "移动: ⌃ + ⌘ + 鼠标移动", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "缩放: ⌃ + ⌥ + 鼠标移动", action: nil, keyEquivalent: "")
        let diagnoseWindowItem = menu.addItem(withTitle: "诊断当前窗口", action: #selector(diagnoseWindow), keyEquivalent: "")
        diagnoseWindowItem.target = self
        menu.addItem(.separator())

        let quitItem = menu.addItem(withTitle: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        statusItem.menu = menu
        self.statusItem = statusItem
    }

    // 配置菜单栏上的可点击按钮，目前使用原始云朵 emoji。
    private func configureStatusButton(_ button: NSStatusBarButton?) {
        guard let button else {
            return
        }

        button.title = "☁️"
        button.toolTip = "YunDrag"
    }

    // 根据辅助功能状态更新菜单中的提示文字。
    func updatePermissionStatus(_ status: AccessibilityPermissionStatus) {
        guard permissionStatusItem?.title != status.title || pendingPermissionStatus != nil else {
            return
        }

        pendingPermissionStatus = status
        performDeferredMenuUpdate { [weak self] in
            guard let self else {
                return
            }

            guard pendingPermissionStatus == status else {
                return
            }

            permissionStatusItem?.title = status.title
            pendingPermissionStatus = nil
        }
    }

    // 退出前取消菜单追踪，避免菜单还打开时直接终止造成状态异常。
    func cancelTracking() {
        statusItem?.menu?.cancelTracking()
    }

    // 菜单 action 等回到默认 RunLoop mode 后执行，避免菜单布局过程中同步弹窗或改 UI。
    private func performDeferredMenuAction(_ handler: (@MainActor @Sendable () -> Void)?) {
        guard let handler else {
            return
        }

        menu.cancelTracking()
        performDeferredMenuUpdate(handler)
    }

    // 菜单可能正在追踪鼠标，所有菜单 UI 改动和动作都延后到默认 RunLoop mode。
    private func performDeferredMenuUpdate(_ update: @escaping @MainActor @Sendable () -> Void) {
        RunLoop.main.perform(inModes: [.default]) {
            Task { @MainActor in
                update()
            }
        }
    }

    // 以下 Objective-C 选择器由 NSMenuItem 调用，再转发给外部闭包。
    @objc private func openSettings() {
        performDeferredMenuAction(openSettingsHandler)
    }

    @objc private func checkPermission() {
        performDeferredMenuAction(checkPermissionHandler)
    }

    @objc private func diagnoseWindow() {
        performDeferredMenuAction(diagnoseWindowHandler)
    }

    @objc private func quit() {
        performDeferredMenuAction(quitHandler)
    }
}
