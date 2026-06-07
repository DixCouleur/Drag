//
//  AppDelegate.m
//  YunMove
//
//  Created by Yun on 2023/4/18.
//

#import "AppDelegate.h"
#import "AccessibilityPermissionGuide.h"
#import "AXWindowController.h"
#import "ModifierMonitor.h"
#import "StatusMenuController.h"

@interface AppDelegate ()

@property StatusMenuController *statusMenuController;
@property AccessibilityPermissionGuide *permissionGuide;
@property AXWindowController *windowController;
@property ModifierMonitor *modifierMonitor;

@end

@implementation AppDelegate

- (void)enableAccessibilityFeatures {
    [self.statusMenuController updatePermissionStatus:YES];
    [self.modifierMonitor start];
}

- (void)checkAccessibilityPermissionFromMenu:(id)sender {
    if([self.permissionGuide isTrustedWithPrompt:NO]) {
        [self enableAccessibilityFeatures];
        return;
    }

    [self.statusMenuController updatePermissionStatus:NO];
    [self showAccessibilityPermissionGuide];
}

- (void)showAccessibilityPermissionGuide {
    __weak AppDelegate *weakSelf = self;
    [self.permissionGuide showWithOpenSettingsHandler: ^{
        AppDelegate *strongSelf = weakSelf;
        [strongSelf.permissionGuide openSettings];
    } quitHandler: ^{
        AppDelegate *strongSelf = weakSelf;
        [strongSelf exit];
    }];
}

// 应用启动完成时的处理
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.permissionGuide = [AccessibilityPermissionGuide new];
    self.windowController = [AXWindowController new];
    self.modifierMonitor = [[ModifierMonitor alloc] initWithWindowController:self.windowController];
    self.statusMenuController = [StatusMenuController new];

    __weak AppDelegate *weakSelf = self;
    self.statusMenuController.openSettingsHandler = ^{
        AppDelegate *strongSelf = weakSelf;
        [strongSelf.permissionGuide openSettings];
    };
    self.statusMenuController.checkPermissionHandler = ^{
        AppDelegate *strongSelf = weakSelf;
        [strongSelf checkAccessibilityPermissionFromMenu:nil];
    };
    self.statusMenuController.quitHandler = ^{
        AppDelegate *strongSelf = weakSelf;
        [strongSelf exit];
    };

    [self.statusMenuController show];

    if([self.permissionGuide isTrustedWithPrompt:YES]) {
        [self enableAccessibilityFeatures];
    } else {
        [self.statusMenuController updatePermissionStatus:NO];
        [self showAccessibilityPermissionGuide];
    }
}

// 支持安全可恢复状态
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

// 退出应用
- (void)exit {
    [self.modifierMonitor stop];
    [self.windowController reset];
    [self.statusMenuController cancelTracking];
    [NSApp terminate:nil];
}

- (void)dealloc {
    [self.modifierMonitor stop];
    [self.windowController reset];
}

@end
