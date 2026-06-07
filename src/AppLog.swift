//
//  AppLog.swift
//  YunMove
//

import OSLog

enum AppLog {
    static let app = Logger(subsystem: "me.yun.YunDrag", category: "App")
    static let accessibility = Logger(subsystem: "me.yun.YunDrag", category: "Accessibility")
}
