//
//  AppLog.swift
//  YunMove
//

import OSLog

// 统一管理日志分类，方便用 Console.app 或 log stream 过滤 YunDrag 日志。
enum AppLog {
    static let app = Logger(subsystem: "me.yun.YunDrag", category: "App")
    static let accessibility = Logger(subsystem: "me.yun.YunDrag", category: "Accessibility")
}
