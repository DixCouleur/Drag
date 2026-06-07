//
//  Geometry.swift
//  YunMove
//

import CoreGraphics

// 获取当前鼠标在屏幕坐标系中的位置。
func currentMousePosition() -> CGPoint {
    CGEvent(source: nil)?.location ?? .zero
}

// 让 CGPoint 可以直接做加法，便于累计窗口位置偏移。
func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

// 让 CGPoint 可以直接做减法，便于计算鼠标移动距离。
func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

// 用鼠标偏移量调整窗口尺寸。
func +(lhs: CGSize, rhs: CGPoint) -> CGSize {
    CGSize(width: lhs.width + rhs.x, height: lhs.height + rhs.y)
}
