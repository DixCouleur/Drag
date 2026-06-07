//
//  ModifierMonitor.swift
//  YunMove
//

import AppKit

@MainActor
final class ModifierMonitor: NSObject {
    private let windowController: AXWindowController
    private var moveEnabled = false
    private var resizeEnabled = false
    private var mousePosition = CGPoint.zero
    private var mouseTimer: Timer?
    private var flagsMonitor: Any?

    init(windowController: AXWindowController) {
        self.windowController = windowController
        super.init()
    }

    func start() {
        guard flagsMonitor == nil else {
            return
        }

        guard windowController.prepareSystemWideElement() else {
            return
        }

        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            Task { @MainActor [weak self] in
                self?.handleModifierFlags(flags)
            }
        }
    }

    func stop() {
        stopMouseObserver()
        windowController.clearTargetWindow()

        if let flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
            self.flagsMonitor = nil
        }
    }

    private func handleModifierFlags(_ flags: NSEvent.ModifierFlags) {
        moveEnabled = flags == [.control, .command]
        resizeEnabled = flags == [.control, .option]

        guard moveEnabled || resizeEnabled else {
            stopMouseObserver()
            windowController.clearTargetWindow()
            return
        }

        mousePosition = currentMousePosition()
        guard windowController.captureWindow(at: mousePosition) else {
            stopMouseObserver()
            return
        }

        startMouseObserver()
    }

    private func startMouseObserver() {
        guard mouseTimer == nil else {
            return
        }

        let timer = Timer(
            timeInterval: 1.0 / 144.0,
            target: self,
            selector: #selector(mouseTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        mouseTimer = timer
    }

    private func stopMouseObserver() {
        mouseTimer?.invalidate()
        mouseTimer = nil
    }

    @objc private func mouseTimerFired(_ timer: Timer) {
        updateTargetWindowForCurrentMousePosition()
    }

    private func updateTargetWindowForCurrentMousePosition() {
        guard windowController.hasTargetWindow else {
            return
        }

        let newMousePosition = currentMousePosition()
        let moveOffset = newMousePosition - mousePosition
        guard mousePosition != newMousePosition else {
            return
        }

        if moveEnabled {
            windowController.moveWindow(by: moveOffset)
        }

        if resizeEnabled {
            windowController.resizeWindow(by: moveOffset)
        }

        mousePosition = newMousePosition
    }
}
