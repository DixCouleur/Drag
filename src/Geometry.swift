//
//  Geometry.swift
//  YunMove
//

import CoreGraphics

func currentMousePosition() -> CGPoint {
    CGEvent(source: nil)?.location ?? .zero
}

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func +(lhs: CGSize, rhs: CGPoint) -> CGSize {
    CGSize(width: lhs.width + rhs.x, height: lhs.height + rhs.y)
}
