//
//  StatusMenuController.m
//  YunMove
//

#import "StatusMenuController.h"

@interface StatusMenuController ()

@property NSStatusItem *statusItem;
@property NSMenuItem *permissionStatusItem;

@end

@implementation StatusMenuController

- (void)show {
    if(self.statusItem != nil) {
        return;
    }

    NSStatusItem *statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    statusItem.button.title = @"☁️";

    NSMenu *menu = [NSMenu new];
    self.permissionStatusItem = [menu addItemWithTitle:@"权限: 检查中" action:nil keyEquivalent:@""];
    self.permissionStatusItem.enabled = NO;

    NSMenuItem *openSettingsItem = [menu addItemWithTitle:@"打开辅助功能设置" action:@selector(openSettings:) keyEquivalent:@""];
    openSettingsItem.target = self;

    NSMenuItem *checkPermissionItem = [menu addItemWithTitle:@"检查权限" action:@selector(checkPermission:) keyEquivalent:@""];
    checkPermissionItem.target = self;

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Move: ⌃ + ⌘ + 鼠标移动" action:nil keyEquivalent:@""];
    [menu addItemWithTitle:@"Resize: ⌃ + ⌥ + 鼠标移动" action:nil keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [menu addItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"q"];
    quitItem.target = self;

    statusItem.menu = menu;
    self.statusItem = statusItem;
}

- (void)updatePermissionStatus:(BOOL)accessibilityEnabled {
    self.permissionStatusItem.title = accessibilityEnabled ? @"权限: 已授权" : @"权限: 未授权";
}

- (void)cancelTracking {
    [self.statusItem.menu cancelTracking];
}

- (void)openSettings:(id)sender {
    if(self.openSettingsHandler != nil) {
        self.openSettingsHandler();
    }
}

- (void)checkPermission:(id)sender {
    if(self.checkPermissionHandler != nil) {
        self.checkPermissionHandler();
    }
}

- (void)quit:(id)sender {
    if(self.quitHandler != nil) {
        self.quitHandler();
    }
}

@end
