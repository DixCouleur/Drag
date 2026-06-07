//
//  AXWindowController.swift
//  YunMove
//

import ApplicationServices
import CoreGraphics

@MainActor
final class AXWindowController {
    private var systemWideElement: AXUIElement?
    private var targetWindow: AXUIElement?
    private var windowSize = CGSize.zero
    private var windowPosition = CGPoint.zero

    var hasTargetWindow: Bool {
        targetWindow != nil
    }

    func prepareSystemWideElement() -> Bool {
        if systemWideElement != nil {
            return true
        }

        systemWideElement = AXUIElementCreateSystemWide()
        return true
    }

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

        guard elementError == .success, let targetElement else {
            if elementError != .success {
                AppLog.accessibility.debug("Failed to get element at position: \(elementError.rawValue, privacy: .public)")
            }
            clearTargetWindow()
            return false
        }

        guard let targetWindow = copyWindow(for: targetElement) else {
            clearTargetWindow()
            return false
        }

        self.targetWindow = targetWindow
        captureWindowFrame()
        return true
    }

    func moveWindow(by offset: CGPoint) {
        guard targetWindow != nil else {
            return
        }

        windowPosition = windowPosition + offset
        updateWindowPosition(windowPosition)
    }

    func resizeWindow(by offset: CGPoint) {
        guard targetWindow != nil else {
            return
        }

        windowSize = windowSize + offset
        updateWindowSize(windowSize)
    }

    func clearTargetWindow() {
        targetWindow = nil
    }

    func reset() {
        clearTargetWindow()
        systemWideElement = nil
    }

    private func copyWindow(for element: AXUIElement) -> AXUIElement? {
        if let window = copyWindowAttribute(from: element) {
            return window
        }

        return copyWindowByWalkingParents(from: element)
    }

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

    private func captureWindowFrame() {
        guard let targetWindow else {
            return
        }

        var positionValue: CFTypeRef?
        let positionError = AXUIElementCopyAttributeValue(targetWindow, kAXPositionAttribute as CFString, &positionValue)
        if positionError == .success, let positionValue = axValue(from: positionValue) {
            var position = CGPoint.zero
            if AXValueGetValue(positionValue, .cgPoint, &position) {
                windowPosition = position
            }
        }

        var sizeValue: CFTypeRef?
        let sizeError = AXUIElementCopyAttributeValue(targetWindow, kAXSizeAttribute as CFString, &sizeValue)
        if sizeError == .success, let sizeValue = axValue(from: sizeValue) {
            var size = CGSize.zero
            if AXValueGetValue(sizeValue, .cgSize, &size) {
                windowSize = size
            }
        }
    }

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

    private func axElement(from value: CFTypeRef?) -> AXUIElement? {
        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        return (value as! AXUIElement)
    }

    private func axValue(from value: CFTypeRef?) -> AXValue? {
        guard let value, CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        return (value as! AXValue)
    }
}
