//
//  AppDelegate.swift
//  YunMove
//

import AppKit

// 应用代理负责串起菜单、权限提示和窗口操作监听。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissionGuide = AccessibilityPermissionGuide()
    private let windowController = AXWindowController()
    private lazy var modifierMonitor = ModifierMonitor(windowController: windowController)
    private let statusMenuController = StatusMenuController()
    private var permissionPollingTimer: Timer?
    private var permissionPollingAttempts = 0
    private var workspaceObservers: [NSObjectProtocol] = []
    private var accessibilityFeaturesEnabled = false
    private var suspendedForSystemState = false

    // 应用启动后先显示菜单栏入口，再根据权限状态决定是否启用快捷键。
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenu()
        configureSystemStateObservers()
        statusMenuController.show()

        if permissionGuide.isTrusted(prompt: true) {
            enableAccessibilityFeatures()
        } else {
            statusMenuController.updatePermissionStatus(false)
            showAccessibilityPermissionGuide()
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // 退出前停止定时器和监听，避免留下无效的全局事件观察者。
    func applicationWillTerminate(_ notification: Notification) {
        stopPermissionPolling()
        removeSystemStateObservers()
        modifierMonitor.stop()
        windowController.reset()
    }

    // 菜单控制器只负责 UI，真正的动作回到 AppDelegate 执行。
    private func configureMenu() {
        statusMenuController.openSettingsHandler = { [weak self] in
            self?.openAccessibilitySettings()
        }

        statusMenuController.checkPermissionHandler = { [weak self] in
            self?.checkAccessibilityPermissionFromMenu()
        }

        statusMenuController.diagnoseWindowHandler = { [weak self] in
            self?.diagnoseCurrentWindow()
        }

        statusMenuController.quitHandler = { [weak self] in
            self?.exit()
        }
    }

    // 权限可用后更新菜单状态并启动全局快捷键监听。
    private func enableAccessibilityFeatures() {
        stopPermissionPolling()
        accessibilityFeaturesEnabled = true
        statusMenuController.updatePermissionStatus(true)

        guard !suspendedForSystemState else {
            return
        }

        modifierMonitor.start()
    }

    // 权限失效或退出时统一停掉监听和缓存。
    private func disableAccessibilityFeatures(updateMenu: Bool) {
        accessibilityFeaturesEnabled = false
        modifierMonitor.stop()
        windowController.reset()

        if updateMenu {
            statusMenuController.updatePermissionStatus(false)
        }
    }

    // 用户手动点击“检查权限”时，重新读取系统授权状态。
    private func checkAccessibilityPermissionFromMenu() {
        guard permissionGuide.isTrusted(prompt: false) else {
            disableAccessibilityFeatures(updateMenu: true)
            showAccessibilityPermissionGuide()
            return
        }

        enableAccessibilityFeatures()
    }

    // 从菜单触发一次窗口诊断，帮助判断当前 App 为什么不能移动或缩放。
    private func diagnoseCurrentWindow() {
        guard permissionGuide.isTrusted(prompt: false) else {
            disableAccessibilityFeatures(updateMenu: true)
            showMessage(title: "当前窗口诊断", message: "尚未授予辅助功能权限，无法读取当前窗口。请先打开辅助功能设置并启用 YunDrag。")
            return
        }

        let report = windowController.diagnosticReport(at: currentMousePosition())
        showMessage(title: "当前窗口诊断", message: report)
    }

    // 使用简单弹窗显示诊断或状态说明。
    private func showMessage(title: String, message: String) {
        RunLoop.main.perform(inModes: [.default]) { [weak self] in
            Task { @MainActor [weak self] in
                self?.presentMessage(title: title, message: message)
            }
        }
    }

    // 真正弹出消息框；调用方应先把展示动作延后到默认 RunLoop mode。
    private func presentMessage(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    // 权限不足时弹出说明，并提供打开系统设置或退出的选择。
    private func showAccessibilityPermissionGuide() {
        RunLoop.main.perform(inModes: [.default]) { [weak self] in
            Task { @MainActor [weak self] in
                self?.presentAccessibilityPermissionGuide()
            }
        }
    }

    // 真正弹出权限说明；启动或菜单 action 中都不要直接同步调用它。
    private func presentAccessibilityPermissionGuide() {
        permissionGuide.show(
            openSettingsHandler: { [weak self] in
                self?.openAccessibilitySettings()
            },
            quitHandler: { [weak self] in
                self?.exit()
            }
        )
    }

    // 打开系统设置后开始轮询，这样用户授权后不用再回菜单手动检查。
    private func openAccessibilitySettings() {
        permissionGuide.openSettings()
        startPermissionPolling()
    }

    // 最多轮询两分钟；授权成功会自动停止。
    private func startPermissionPolling() {
        stopPermissionPolling()
        permissionPollingAttempts = 0

        let timer = Timer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(permissionPollingTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        permissionPollingTimer = timer
    }

    // 停止权限轮询，并重置次数，便于下次重新开始。
    private func stopPermissionPolling() {
        permissionPollingTimer?.invalidate()
        permissionPollingTimer = nil
        permissionPollingAttempts = 0
    }

    // 系统睡眠、锁屏或屏幕休眠时暂停监听，减少后台常驻工作。
    private func configureSystemStateObservers() {
        let center = NSWorkspace.shared.notificationCenter
        let suspendNotifications: [Notification.Name] = [
            NSWorkspace.willSleepNotification,
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification
        ]
        let resumeNotifications: [Notification.Name] = [
            NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification
        ]

        workspaceObservers = suspendNotifications.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.suspendAccessibilityFeaturesForSystemState()
                }
            }
        } + resumeNotifications.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.resumeAccessibilityFeaturesForSystemState()
                }
            }
        }
    }

    // 移除系统状态通知观察者。
    private func removeSystemStateObservers() {
        let center = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers {
            center.removeObserver(observer)
        }

        workspaceObservers.removeAll()
    }

    // 暂停时不改变权限菜单，只停止全局监听和 AX 缓存。
    private func suspendAccessibilityFeaturesForSystemState() {
        guard accessibilityFeaturesEnabled, !suspendedForSystemState else {
            return
        }

        suspendedForSystemState = true
        modifierMonitor.stop()
        windowController.reset()
        AppLog.app.info("Suspended accessibility features for system state")
    }

    // 系统恢复后重新确认权限，仍然授权才恢复快捷键监听。
    private func resumeAccessibilityFeaturesForSystemState() {
        guard suspendedForSystemState else {
            return
        }

        suspendedForSystemState = false
        guard accessibilityFeaturesEnabled else {
            return
        }

        guard permissionGuide.isTrusted(prompt: false) else {
            disableAccessibilityFeatures(updateMenu: true)
            AppLog.accessibility.info("Accessibility permission is no longer trusted after system resume")
            return
        }

        modifierMonitor.start()
        AppLog.app.info("Resumed accessibility features after system state change")
    }

    // 定时检查辅助功能授权是否已经生效。
    @objc private func permissionPollingTimerFired(_ timer: Timer) {
        permissionPollingAttempts += 1

        guard permissionPollingAttempts <= 120 else {
            stopPermissionPolling()
            AppLog.accessibility.info("Stopped accessibility permission polling after timeout")
            return
        }

        guard permissionGuide.isTrusted(prompt: false) else {
            statusMenuController.updatePermissionStatus(false)
            return
        }

        AppLog.accessibility.info("Accessibility permission became trusted")
        enableAccessibilityFeatures()
    }

    // 菜单中的退出入口会先清理内部状态，再终止应用。
    private func exit() {
        stopPermissionPolling()
        disableAccessibilityFeatures(updateMenu: false)
        statusMenuController.cancelTracking()
        NSApp.terminate(nil)
    }
}
