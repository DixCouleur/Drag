//
//  AppDelegate.m
//  YunMove
//
//  Created by Yun on 2023/4/18.
//

#import "AppDelegate.h"
#import "appkit/NSEvent.h"
#import <QuartzCore/QuartzCore.h>

#import "utils.h"


@interface AppDelegate ()

@property NSStatusItem *statusItem;

@property bool moveEnabled;
@property bool resizeEnabled;

@property CGSize winSize;
@property CGPoint winPosition;
@property AXValueRef axPosition;
@property AXValueRef axSize;
@property CGPoint mousePosition;
@property AXUIElementRef targetElement;
@property AXUIElementRef targetWindow;

@property NSTimer *mouseTimer;

@end

@implementation AppDelegate

- (void)initStatusBar {
    NSStatusItem *statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    statusItem.button.title = @"☁️";
    statusItem.menu = [NSMenu new];
    [statusItem.menu addItemWithTitle:@"Move: ⌃ + ⌘ + 鼠标移动" action:nil keyEquivalent:@""];
    [statusItem.menu addItemWithTitle:@"Resize: ⌃ + ⌥ + 鼠标移动" action:nil keyEquivalent:@""];
    [statusItem.menu addItemWithTitle:@"Quit" action:@selector(exit) keyEquivalent:@""];
    self.statusItem = statusItem;
}

- (void)startMouseObserver {
    self.mouseTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 / 144.0
                           repeats: YES
                             block: ^(NSTimer *timer) {
        // bool enabled = self.moveEnabled || self.resizeEnabled;
        
        if(self.targetWindow == nil) {
            return;
        }

        CGPoint newMousePosition = MousePosition();
        CGPoint moveOffset = CGPointSub(newMousePosition, self.mousePosition);
        // 如何鼠标没有移动
        if(CGPointEqualToPoint(self.mousePosition, newMousePosition)) {
            // 就直接返回
            return;
        }

        // 如果是 move 操作
        if(self.moveEnabled) {
            CGPoint cgWinPosition = CGPointAdd(self.winPosition, moveOffset);
            AXValueRef newWinPosition = AXValueCreate(kAXValueTypeCGPoint, &cgWinPosition);
            AXUIElementSetAttributeValue(self.targetWindow, kAXPositionAttribute, newWinPosition);
        }

        // 如果是 resize 操作
        if(self.resizeEnabled) {
            CGSize cgWinSize = CGSizeAdd(self.winSize, moveOffset);
            AXValueRef newWinSize = AXValueCreate(kAXValueTypeCGSize, &cgWinSize);
            AXUIElementSetAttributeValue(self.targetWindow, kAXSizeAttribute, newWinSize);
        }

    }];
}

- (void)stopMouseObserver {
    if(self.mouseTimer != nil) {
        [self.mouseTimer invalidate];
        self.mouseTimer = nil;
    }
}

- (void)startFlagsObserver {
    const AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();

    [NSEvent addGlobalMonitorForEventsMatchingMask: NSEventMaskFlagsChanged
                                           handler: ^(NSEvent *event) {

        NSEventModifierFlags flags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;

        self.moveEnabled = flags == (NSEventModifierFlagControl | NSEventModifierFlagCommand);
        self.resizeEnabled = flags == (NSEventModifierFlagControl | NSEventModifierFlagOption);

        // 如果都没有启用
        if(!self.moveEnabled && !self.resizeEnabled) {
            // 关掉鼠标移动的监听 目的是为了省资源
            [self stopMouseObserver];
            return;
        }

        // 获取当前鼠标的位置
        self.mousePosition = MousePosition();
        // 如果获取不到应用
        if(!elementAtPosition(systemWideElement, self.mousePosition, &(self->_targetElement))) {
            // 就直接返回
            return;
        }

        // 开启鼠标移动监听
        [self startMouseObserver];

        // 获取 window
        self.targetWindow = getWindow(self.targetElement);
        if(self.targetWindow != nil) {
            // 保存 window 当前的位置
            AXUIElementCopyAttributeValue(self.targetWindow, kAXPositionAttribute, (void *)&self->_axPosition);
            AXValueGetValue(self.axPosition, kAXValueTypeCGPoint, (void *)&self->_winPosition);
        
            // 保存 window 当前的大小
            AXUIElementCopyAttributeValue(self.targetWindow, kAXSizeAttribute, (void *)&self->_axSize);
            AXValueGetValue(self.axSize, kAXValueCGSizeType, (void *)&self->_winSize);
        }
    }];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self initStatusBar];
    [self startFlagsObserver];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (void)exit {
    [NSApp terminate:nil];
}

@end
