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
        modifierMonitor.stop()
        windowController.reset()
    }

    private func configureMenu() {
        statusMenuController.openSettingsHandler = { [weak self] in
            self?.permissionGuide.openSettings()
        }

        statusMenuController.checkPermissionHandler = { [weak self] in
            self?.checkAccessibilityPermissionFromMenu()
        }

        statusMenuController.quitHandler = { [weak self] in
            self?.exit()
        }
    }

    private func enableAccessibilityFeatures() {
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
                self?.permissionGuide.openSettings()
            },
            quitHandler: { [weak self] in
                self?.exit()
            }
        )
    }

    private func exit() {
        modifierMonitor.stop()
        windowController.reset()
        statusMenuController.cancelTracking()
        NSApp.terminate(nil)
    }
}
