//
//  AXWindowController.swift
//  YunMove
//

import ApplicationServices
import CoreGraphics
import Foundation

// 负责通过 macOS Accessibility API 找到鼠标下的窗口，并移动或调整它。
@MainActor
final class AXWindowController {
    private var systemWideElement: AXUIElement?
    private var targetWindow: AXUIElement?
    private var windowSize = CGSize.zero
    private var windowPosition = CGPoint.zero

    // ModifierMonitor 用它判断当前是否已经捕获到可操作窗口。
    var hasTargetWindow: Bool {
        targetWindow != nil
    }

    // 创建全局 AX 元素。后续从鼠标坐标查找元素都依赖它。
    func prepareSystemWideElement() -> Bool {
        if systemWideElement != nil {
            return true
        }

        systemWideElement = AXUIElementCreateSystemWide()
        return true
    }

    // 捕获鼠标当前位置下的窗口，优先走 AX，失败后走 CGWindow fallback。
    func captureWindow(at mousePosition: CGPoint) -> Bool {
        guard prepareSystemWideElement(), let systemWideElement else {
            return false
        }

        var targetElement: AXUIElement?
        let elementError = AXUIElementCopyElementAtPosition(
            systemWideElement,
            Float(mousePosition.x),
            Float(mousePosition.y),
            &targetElement
        )

        let targetWindow: AXUIElement?
        if elementError == .success, let targetElement {
            targetWindow = copyWindow(for: targetElement) ?? copyWindowFromCGWindow(at: mousePosition)
        } else {
            AppLog.accessibility.debug("Failed to get element at position: \(elementError.rawValue, privacy: .public)")
            targetWindow = copyWindowFromCGWindow(at: mousePosition)
        }

        guard let targetWindow else {
            clearTargetWindow()
            return false
        }

        self.targetWindow = targetWindow
        captureWindowFrame()
        return true
    }

    // 根据鼠标偏移移动窗口。
    func moveWindow(by offset: CGPoint) {
        guard targetWindow != nil else {
            return
        }

        windowPosition = windowPosition + offset
        updateWindowPosition(windowPosition)
    }

    // 根据鼠标偏移调整窗口大小。
    func resizeWindow(by offset: CGPoint) {
        guard targetWindow != nil else {
            return
        }

        windowSize = windowSize + offset
        updateWindowSize(windowSize)
    }

    // 清除当前捕获的目标窗口。
    func clearTargetWindow() {
        targetWindow = nil
    }

    // 应用退出或权限状态变化时，清理缓存的 AX 对象。
    func reset() {
        clearTargetWindow()
        systemWideElement = nil
    }

    // 从一个 AX 元素推导所属窗口：先读窗口属性，再向父级查找。
    private func copyWindow(for element: AXUIElement) -> AXUIElement? {
        if let window = copyWindowAttribute(from: element) {
            return window
        }

        return copyWindowByWalkingParents(from: element)
    }

    // AX 点查找失败时，用 CGWindow 列表找鼠标下最前面的普通窗口。
    private func copyWindowFromCGWindow(at point: CGPoint) -> AXUIElement? {
        guard let windowInfoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            AppLog.accessibility.debug("Failed to copy CG window list")
            return nil
        }

        let currentProcessID = ProcessInfo.processInfo.processIdentifier
        for windowInfo in windowInfoList {
            // CGWindow 只能告诉我们 pid 和屏幕矩形，真正移动仍然要回到 AXWindow。
            guard isCandidateWindowInfo(windowInfo, containing: point),
                  let ownerProcessID = ownerProcessID(from: windowInfo),
                  ownerProcessID != currentProcessID else {
                continue
            }

            let appElement = AXUIElementCreateApplication(ownerProcessID)
            guard let window = copyWindowFromApplication(appElement, at: point) else {
                continue
            }

            AppLog.accessibility.debug("Captured window through CG fallback for pid \(ownerProcessID, privacy: .public)")
            return window
        }

        return nil
    }

    // 许多控件会直接提供 kAXWindowAttribute，这是最稳的窗口获取路径。
    private func copyWindowAttribute(from element: AXUIElement) -> AXUIElement? {
        var windowValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, kAXWindowAttribute as CFString, &windowValue)
        guard error == .success else {
            if error != .attributeUnsupported, error != .noValue {
                AppLog.accessibility.debug("Failed to get window attribute: \(error.rawValue, privacy: .public)")
            }
            return nil
        }

        guard let window = axElement(from: windowValue) else {
            AppLog.accessibility.debug("Window attribute did not contain an AXUIElement")
            return nil
        }

        return window
    }

    // 有些 App 不提供窗口属性，只能从当前元素一路向父级查找 AXWindow。
    private func copyWindowByWalkingParents(from element: AXUIElement) -> AXUIElement? {
        var currentElement: AXUIElement? = element

        while let candidate = currentElement {
            var roleValue: CFTypeRef?
            let roleError = AXUIElementCopyAttributeValue(candidate, kAXRoleAttribute as CFString, &roleValue)
            guard roleError == .success, let role = roleValue as? String else {
                if roleError != .success {
                    AppLog.accessibility.debug("Failed to get role: \(roleError.rawValue, privacy: .public)")
                }
                return nil
            }

            if role == (kAXWindowRole as String) {
                return candidate
            }

            var parentValue: CFTypeRef?
            let parentError = AXUIElementCopyAttributeValue(candidate, kAXParentAttribute as CFString, &parentValue)
            guard parentError == .success, let parent = axElement(from: parentValue) else {
                if parentError != .success {
                    AppLog.accessibility.debug("Failed to get parent element: \(parentError.rawValue, privacy: .public)")
                }
                return nil
            }

            currentElement = parent
        }

        return nil
    }

    // 捕获窗口时记录初始位置和大小，后续移动/缩放都基于这两个值累计。
    private func captureWindowFrame() {
        guard let targetWindow else {
            return
        }

        if let position = copyPointAttribute(kAXPositionAttribute as CFString, from: targetWindow) {
            windowPosition = position
        }

        if let size = copySizeAttribute(kAXSizeAttribute as CFString, from: targetWindow) {
            windowSize = size
        }
    }

    // 把新的左上角坐标写回 AXWindow。
    private func updateWindowPosition(_ newPosition: CGPoint) {
        guard let targetWindow else {
            return
        }

        var position = newPosition
        guard let value = AXValueCreate(.cgPoint, &position) else {
            return
        }

        let error = AXUIElementSetAttributeValue(targetWindow, kAXPositionAttribute as CFString, value)
        if error != .success {
            AppLog.accessibility.debug("Failed to set window position: \(error.rawValue, privacy: .public)")
        }
    }

    // 把新的窗口尺寸写回 AXWindow。
    private func updateWindowSize(_ newSize: CGSize) {
        guard let targetWindow else {
            return
        }

        var size = newSize
        guard let value = AXValueCreate(.cgSize, &size) else {
            return
        }

        let error = AXUIElementSetAttributeValue(targetWindow, kAXSizeAttribute as CFString, value)
        if error != .success {
            AppLog.accessibility.debug("Failed to set window size: \(error.rawValue, privacy: .public)")
        }
    }

    // 只有确认 CFTypeID 是 AXUIElement 后才强转，避免错误类型崩溃。
    private func axElement(from value: CFTypeRef?) -> AXUIElement? {
        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        return (value as! AXUIElement)
    }

    // 只有确认 CFTypeID 是 AXValue 后才读取 CGPoint/CGSize。
    private func axValue(from value: CFTypeRef?) -> AXValue? {
        guard let value, CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        return (value as! AXValue)
    }

    // 根据 CGWindow 找到的进程，回到该 App 的 AX windows 中匹配鼠标所在窗口。
    private func copyWindowFromApplication(_ appElement: AXUIElement, at point: CGPoint) -> AXUIElement? {
        var windowsValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
        guard error == .success, let windows = windowsValue as? [AXUIElement] else {
            if error != .success {
                AppLog.accessibility.debug("Failed to get app windows: \(error.rawValue, privacy: .public)")
            }
            return nil
        }

        return windows.first { window in
            guard let frame = copyFrame(for: window) else {
                return false
            }

            return frame.insetBy(dx: -8.0, dy: -8.0).contains(point)
        }
    }

    // 读取窗口的 AXPosition 和 AXSize，组合成 CGRect。
    private func copyFrame(for window: AXUIElement) -> CGRect? {
        guard let position = copyPointAttribute(kAXPositionAttribute as CFString, from: window),
              let size = copySizeAttribute(kAXSizeAttribute as CFString, from: window) else {
            return nil
        }

        return CGRect(origin: position, size: size)
    }

    // 读取 CGPoint 类型的 AX 属性，例如窗口位置。
    private func copyPointAttribute(_ attribute: CFString, from element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let axValue = axValue(from: value) else {
            return nil
        }

        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else {
            return nil
        }

        return point
    }

    // 读取 CGSize 类型的 AX 属性，例如窗口尺寸。
    private func copySizeAttribute(_ attribute: CFString, from element: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let axValue = axValue(from: value) else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }

        return size
    }

    // 过滤掉桌面、透明层、极小窗口等不适合操作的 CGWindow 条目。
    private func isCandidateWindowInfo(_ windowInfo: [String: Any], containing point: CGPoint) -> Bool {
        guard integerValue(for: kCGWindowLayer, in: windowInfo) == 0,
              doubleValue(for: kCGWindowAlpha, in: windowInfo) ?? 1.0 > 0.0,
              let bounds = boundsValue(for: kCGWindowBounds, in: windowInfo),
              bounds.width > 1.0,
              bounds.height > 1.0 else {
            return false
        }

        return bounds.contains(point)
    }

    // 从 CGWindow 字典中读取窗口所属进程 pid。
    private func ownerProcessID(from windowInfo: [String: Any]) -> pid_t? {
        guard let processID = integerValue(for: kCGWindowOwnerPID, in: windowInfo) else {
            return nil
        }

        return pid_t(processID)
    }

    // CGWindow 字典里的数字可能桥接成 Int，也可能桥接成 NSNumber。
    private func integerValue(for key: CFString, in dictionary: [String: Any]) -> Int? {
        if let value = dictionary[key as String] as? Int {
            return value
        }

        return (dictionary[key as String] as? NSNumber)?.intValue
    }

    // 读取 Double 类型字段，例如窗口透明度。
    private func doubleValue(for key: CFString, in dictionary: [String: Any]) -> Double? {
        if let value = dictionary[key as String] as? Double {
            return value
        }

        return (dictionary[key as String] as? NSNumber)?.doubleValue
    }

    // 读取 CGWindow bounds 字典，并转成 CGRect。
    private func boundsValue(for key: CFString, in dictionary: [String: Any]) -> CGRect? {
        guard let boundsDictionary = dictionary[key as String] as? NSDictionary else {
            return nil
        }

        return CGRect(dictionaryRepresentation: boundsDictionary)
    }
}
