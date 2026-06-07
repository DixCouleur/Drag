//
//  StatusMenuController.swift
//  YunMove
//

import AppKit

// 管理菜单栏图标和下拉菜单。业务动作通过闭包交给 AppDelegate。
@MainActor
final class StatusMenuController: NSObject {
    var openSettingsHandler: (() -> Void)?
    var checkPermissionHandler: (() -> Void)?
    var quitHandler: (() -> Void)?

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var permissionStatusItem: NSMenuItem?

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
        menu.addItem(withTitle: "Move: ⌃ + ⌘ + 鼠标移动", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "Resize: ⌃ + ⌥ + 鼠标移动", action: nil, keyEquivalent: "")
        menu.addItem(.separator())

        let quitItem = menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
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

    // 根据辅助功能授权状态更新菜单中的提示文字。
    func updatePermissionStatus(_ accessibilityEnabled: Bool) {
        permissionStatusItem?.title = accessibilityEnabled ? "权限: 已授权" : "权限: 未授权"
    }

    // 退出前取消菜单追踪，避免菜单还打开时直接终止造成状态异常。
    func cancelTracking() {
        statusItem?.menu?.cancelTracking()
    }

    // 以下 Objective-C 选择器由 NSMenuItem 调用，再转发给外部闭包。
    @objc private func openSettings() {
        openSettingsHandler?()
    }

    @objc private func checkPermission() {
        checkPermissionHandler?()
    }

    @objc private func quit() {
        quitHandler?()
    }
}
