//
//  main.swift
//  YunMove
//

import AppKit

// AppKit 应用入口：手动创建应用和代理，避免菜单栏应用启动流程不明确。
let app = NSApplication.shared

// 这里必须强引用 AppDelegate，否则代理可能被释放，菜单栏和快捷键监听就不会工作。
let appDelegate = AppDelegate()

app.delegate = appDelegate

// 显式完成启动后再进入事件循环，确保 applicationDidFinishLaunching 会执行。
app.finishLaunching()
app.run()
