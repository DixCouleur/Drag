//
//  StatusMenuController.swift
//  YunMove
//

import AppKit

@MainActor
final class StatusMenuController: NSObject {
    var openSettingsHandler: (() -> Void)?
    var checkPermissionHandler: (() -> Void)?
    var quitHandler: (() -> Void)?

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var permissionStatusItem: NSMenuItem?

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

    private func configureStatusButton(_ button: NSStatusBarButton?) {
        guard let button else {
            return
        }

        button.title = "☁️"
        button.toolTip = "YunDrag"
    }

    func updatePermissionStatus(_ accessibilityEnabled: Bool) {
        permissionStatusItem?.title = accessibilityEnabled ? "权限: 已授权" : "权限: 未授权"
    }

    func cancelTracking() {
        statusItem?.menu?.cancelTracking()
    }

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
