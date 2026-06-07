//
//  AppDelegate.swift
//  YunMove
//

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissionGuide = AccessibilityPermissionGuide()
    private let windowController = AXWindowController()
    private lazy var modifierMonitor = ModifierMonitor(windowController: windowController)
    private let statusMenuController = StatusMenuController()
    private var permissionPollingTimer: Timer?
    private var permissionPollingAttempts = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenu()
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

    func applicationWillTerminate(_ notification: Notification) {
        stopPermissionPolling()
        modifierMonitor.stop()
        windowController.reset()
    }

    private func configureMenu() {
        statusMenuController.openSettingsHandler = { [weak self] in
            self?.openAccessibilitySettings()
        }

        statusMenuController.checkPermissionHandler = { [weak self] in
            self?.checkAccessibilityPermissionFromMenu()
        }

        statusMenuController.quitHandler = { [weak self] in
            self?.exit()
        }
    }

    private func enableAccessibilityFeatures() {
        stopPermissionPolling()
        statusMenuController.updatePermissionStatus(true)
        modifierMonitor.start()
    }

    private func checkAccessibilityPermissionFromMenu() {
        guard permissionGuide.isTrusted(prompt: false) else {
            statusMenuController.updatePermissionStatus(false)
            showAccessibilityPermissionGuide()
            return
        }

        enableAccessibilityFeatures()
    }

    private func showAccessibilityPermissionGuide() {
        permissionGuide.show(
            openSettingsHandler: { [weak self] in
                self?.openAccessibilitySettings()
            },
            quitHandler: { [weak self] in
                self?.exit()
            }
        )
    }

    private func openAccessibilitySettings() {
        permissionGuide.openSettings()
        startPermissionPolling()
    }

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

    private func stopPermissionPolling() {
        permissionPollingTimer?.invalidate()
        permissionPollingTimer = nil
        permissionPollingAttempts = 0
    }

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

    private func exit() {
        stopPermissionPolling()
        modifierMonitor.stop()
        windowController.reset()
        statusMenuController.cancelTracking()
        NSApp.terminate(nil)
    }
}
