//
//  AppDelegate.m
//  YunMove
//
//  Created by Yun on 2023/4/18.
//

#import "AppDelegate.h"
#import "AppKit/NSEvent.h"

#import "utils.h"


@interface AppDelegate ()

// 系统级可访问性元素，用于获取全局鼠标位置下的元素
@property AXUIElementRef systemWideElement;

// 控制窗口移动和调整大小的标志
@property BOOL moveEnabled;
@property BOOL resizeEnabled;

// 状态栏图标和菜单
@property NSStatusItem *statusItem;
@property id flagsMonitor;
// 窗口大小和位置
@property CGSize winSize;
@property CGPoint winPosition;
// 鼠标位置
@property CGPoint mousePosition;
// 当前目标窗口。通过 setOwnedTargetWindow: 接管 Copy 返回的引用。
@property AXUIElementRef targetWindow;
// 鼠标位置观察定时器
@property NSTimer *mouseTimer;

@end

@implementation AppDelegate

- (void)setOwnedTargetWindow:(AXUIElementRef)targetWindow {
    if (_targetWindow == targetWindow) {
        if (targetWindow != nil) {
            CFRelease(targetWindow);
        }
        return;
    }

    if (_targetWindow != nil) {
        CFRelease(_targetWindow);
    }
    _targetWindow = targetWindow;
}

- (void)clearTargetWindow {
    [self setOwnedTargetWindow:nil];
}

// 初始化状态栏图标和菜单
- (void)initStatusBar {
    // 创建状态栏图标
    NSStatusItem *statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    statusItem.button.title = @"☁️";
    statusItem.menu = [NSMenu new];
    
    // 添加菜单项
    [statusItem.menu addItemWithTitle:@"Move: ⌃ + ⌘ + 鼠标移动" action:nil keyEquivalent:@""];
    [statusItem.menu addItemWithTitle:@"Resize: ⌃ + ⌥ + 鼠标移动" action:nil keyEquivalent:@""];
    [statusItem.menu addItemWithTitle:@"Quit" action:@selector(exit) keyEquivalent:@"q"];
    self.statusItem = statusItem;
}

// 更新窗口位置
- (void)updateWindowPosition:(CGPoint)newPosition {
    // 创建新的位置值
    AXValueRef newWinPosition = AXValueCreate(kAXValueTypeCGPoint, &newPosition);
    if (newWinPosition) {
        // 设置窗口位置
        AXError error = AXUIElementSetAttributeValue(self.targetWindow, kAXPositionAttribute, newWinPosition);
        if (error != kAXErrorSuccess) {
            NSLog(@"Failed to set window position: %d", error);
        }
        CFRelease(newWinPosition);
    }
}

// 更新窗口大小
- (void)updateWindowSize:(CGSize)newSize {
    // 创建新的大小值
    AXValueRef newWinSize = AXValueCreate(kAXValueTypeCGSize, &newSize);
    if (newWinSize) {
        // 设置窗口大小
        AXError error = AXUIElementSetAttributeValue(self.targetWindow, kAXSizeAttribute, newWinSize);
        if (error != kAXErrorSuccess) {
            NSLog(@"Failed to set window size: %d", error);
        }
        CFRelease(newWinSize);
    }
}

// 开始监听鼠标移动
- (void)startMouseObserver {
    if(self.mouseTimer != nil) {
        return;
    }

    __weak AppDelegate *weakSelf = self;
    // 创建定时器，每秒144次检查鼠标位置
    self.mouseTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 / 144.0
                           repeats: YES
                             block: ^(NSTimer *timer) {
        AppDelegate *strongSelf = weakSelf;
        if(strongSelf == nil) {
            [timer invalidate];
            return;
        }

        // 如果没有目标窗口，直接返回
        if(strongSelf.targetWindow == nil) {
            return;
        }

        // 获取新的鼠标位置并计算偏移量
        CGPoint newMousePosition = MousePosition();
        CGPoint moveOffset = CGPointSub(newMousePosition, strongSelf.mousePosition);
        
        // 如果鼠标位置没有变化，直接返回
        if(CGPointEqualToPoint(strongSelf.mousePosition, newMousePosition)) {
            return;
        }

        // 如果启用了移动功能，更新窗口位置
        if(strongSelf.moveEnabled) {
            strongSelf.winPosition = CGPointAdd(strongSelf.winPosition, moveOffset);
            [strongSelf updateWindowPosition:strongSelf.winPosition];
        }

        // 如果启用了调整大小功能，更新窗口大小
        if(strongSelf.resizeEnabled) {
            strongSelf.winSize = CGSizeAdd(strongSelf.winSize, moveOffset);
            [strongSelf updateWindowSize:strongSelf.winSize];
        }

        // 更新当前鼠标位置
        strongSelf.mousePosition = newMousePosition;
    }];
}

// 停止监听鼠标移动
- (void)stopMouseObserver {
    if(self.mouseTimer != nil) {
        [self.mouseTimer invalidate];
        self.mouseTimer = nil;
    }
}

- (void)stopFlagsObserver {
    if(self.flagsMonitor != nil) {
        [NSEvent removeMonitor:self.flagsMonitor];
        self.flagsMonitor = nil;
    }
}


// 开始监听修饰键（Control、Command、Option）的状态
- (void)startFlagsObserver {
    // 创建系统级可访问性元素
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    if (!systemWideElement) {
        NSLog(@"Failed to create system-wide element");
        return;
    }
    if (_systemWideElement != nil) {
        CFRelease(_systemWideElement);
    }
    _systemWideElement = systemWideElement;

    __weak AppDelegate *weakSelf = self;
    // 添加全局修饰键状态监听器
    self.flagsMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask: NSEventMaskFlagsChanged
                                                                handler: ^(NSEvent *event) {
        AppDelegate *strongSelf = weakSelf;
        if(strongSelf == nil) {
            return;
        }

        // 获取修饰键状态
        NSEventModifierFlags flags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
        // 检查是否按下 Control + Command（移动模式）
        strongSelf.moveEnabled = flags == (NSEventModifierFlagControl | NSEventModifierFlagCommand);
        // 检查是否按下 Control + Option（调整大小模式）
        strongSelf.resizeEnabled = flags == (NSEventModifierFlagControl | NSEventModifierFlagOption);

        // 如果两个模式都未启用，停止监听并清理资源
        if(!strongSelf.moveEnabled && !strongSelf.resizeEnabled) {
            [strongSelf stopMouseObserver];
            [strongSelf clearTargetWindow];
            return;
        }

        // 获取当前鼠标位置下的元素
        strongSelf.mousePosition = MousePosition();
        AXUIElementRef targetElement = nil;
        if(!CopyElementAtPosition(strongSelf->_systemWideElement, strongSelf.mousePosition, &targetElement)) {
            [strongSelf stopMouseObserver];
            [strongSelf clearTargetWindow];
            return;
        }

        // 获取目标窗口
        AXUIElementRef targetWindow = CopyWindowForElement(targetElement);
        CFRelease(targetElement);

        if(targetWindow != nil) {
            [strongSelf setOwnedTargetWindow:targetWindow];

            // 获取窗口当前位置和大小
            AXValueRef positionValue;
            AXValueRef sizeValue;
            
            AXError error = AXUIElementCopyAttributeValue(strongSelf.targetWindow, kAXPositionAttribute, (void *)&positionValue);
            if (error == kAXErrorSuccess) {
                AXValueGetValue(positionValue, kAXValueTypeCGPoint, (void *)&strongSelf->_winPosition);
                CFRelease(positionValue);
            }

            error = AXUIElementCopyAttributeValue(strongSelf.targetWindow, kAXSizeAttribute, (void *)&sizeValue);
            if (error == kAXErrorSuccess) {
                AXValueGetValue(sizeValue, kAXValueCGSizeType, (void *)&strongSelf->_winSize);
                CFRelease(sizeValue);
            }
            
            // 开始监听鼠标移动
            [strongSelf startMouseObserver];
        } else {
            [strongSelf stopMouseObserver];
            [strongSelf clearTargetWindow];
        }
    }];
}

// 应用启动完成时的处理
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 检查辅助功能权限
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    
    // 如果没有权限，显示提示并退出
    if (!accessibilityEnabled) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"需要辅助功能权限"];
        [alert setInformativeText:@"请在系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能中允许此应用。"];
        [alert addButtonWithTitle:@"确定"];
        [alert runModal];
        [NSApp terminate:nil];
        return;
    }
    
    // 初始化状态栏和开始监听修饰键
    [self initStatusBar];
    [self startFlagsObserver];
}

// 支持安全可恢复状态
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

// 退出应用
- (void)exit {
    [self stopMouseObserver];
    [self stopFlagsObserver];
    [self clearTargetWindow];
    if(_systemWideElement != nil) {
        CFRelease(_systemWideElement);
        _systemWideElement = nil;
    }
    [self.statusItem.menu cancelTracking];
    [NSApp terminate:nil];
}

- (void)dealloc {
    [self stopMouseObserver];
    [self stopFlagsObserver];
    [self clearTargetWindow];
    if(_systemWideElement != nil) {
        CFRelease(_systemWideElement);
        _systemWideElement = nil;
    }
}

@end
