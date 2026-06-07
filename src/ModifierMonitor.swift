//
//  ModifierMonitor.swift
//  YunMove
//

import AppKit

// 监听全局修饰键变化，并在快捷键按住时持续读取鼠标移动量。
@MainActor
final class ModifierMonitor: NSObject {
    private let windowController: AXWindowController
    private var moveEnabled = false
    private var resizeEnabled = false
    private var capturedOperationMode: AXWindowController.OperationMode?
    private var mousePosition = CGPoint.zero
    private var mouseTimer: Timer?
    private var flagsMonitor: Any?

    init(windowController: AXWindowController) {
        self.windowController = windowController
        super.init()
    }

    // 启动全局 flagsChanged 监听；只有权限可用后才会调用。
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

    // 停止键盘监听和鼠标轮询，并清掉当前捕获的窗口。
    func stop() {
        stopMouseObserver()
        capturedOperationMode = nil
        windowController.clearTargetWindow()

        if let flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
            self.flagsMonitor = nil
        }
    }

    // 根据当前修饰键判断是移动模式还是缩放模式。
    private func handleModifierFlags(_ flags: NSEvent.ModifierFlags) {
        updateMode(for: flags)

        guard let operationMode = currentOperationMode else {
            stopMouseObserver()
            capturedOperationMode = nil
            windowController.clearTargetWindow()
            return
        }

        mousePosition = currentMousePosition()
        guard windowController.captureWindow(at: mousePosition, operationMode: operationMode) else {
            stopMouseObserver()
            capturedOperationMode = nil
            return
        }

        capturedOperationMode = operationMode
        startMouseObserver()
    }

    // 允许额外修饰键，但 Command 和 Option 同时按下时不进入任一模式，避免冲突。
    private func updateMode(for flags: NSEvent.ModifierFlags) {
        let hasControl = flags.contains(.control)
        let hasCommand = flags.contains(.command)
        let hasOption = flags.contains(.option)

        moveEnabled = hasControl && hasCommand && !hasOption
        resizeEnabled = hasControl && hasOption && !hasCommand
    }

    // 把当前修饰键状态转成窗口控制器需要的操作模式。
    private var currentOperationMode: AXWindowController.OperationMode? {
        if moveEnabled {
            return .move
        }

        if resizeEnabled {
            return .resize
        }

        return nil
    }

    // 鼠标移动没有直接的全局拖拽事件，这里用高频 Timer 采样位置变化。
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

    // 停止鼠标采样。
    private func stopMouseObserver() {
        mouseTimer?.invalidate()
        mouseTimer = nil
    }

    // Timer 回调只做一件事：根据当前鼠标位置更新目标窗口。
    @objc private func mouseTimerFired(_ timer: Timer) {
        updateTargetWindowForCurrentMousePosition()
    }

    // 计算鼠标偏移量，并把偏移应用到窗口位置或窗口尺寸。
    private func updateTargetWindowForCurrentMousePosition() {
        updateMode(for: currentModifierFlags())
        guard let operationMode = currentOperationMode else {
            stopMouseObserver()
            capturedOperationMode = nil
            windowController.clearTargetWindow()
            return
        }

        if operationMode != capturedOperationMode {
            handleModifierFlags(currentModifierFlags())
            return
        }

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

    // Timer 中主动读取当前修饰键，兜底处理 flagsChanged 事件丢失的情况。
    private func currentModifierFlags() -> NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(
            rawValue: UInt(CGEventSource.flagsState(.combinedSessionState).rawValue)
        ).intersection(.deviceIndependentFlagsMask)
    }
}
