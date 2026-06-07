//
//  AccessibilityPermissionGuide.m
//  YunMove
//

#import "AccessibilityPermissionGuide.h"

@implementation AccessibilityPermissionGuide

- (BOOL)isTrustedWithPrompt:(BOOL)prompt {
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @(prompt)};
    return AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

- (void)openSettings {
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
    if(![NSWorkspace.sharedWorkspace openURL:url]) {
        NSLog(@"Failed to open Accessibility settings");
    }
}

- (void)showWithOpenSettingsHandler:(AccessibilityPermissionAction)openSettingsHandler
                         quitHandler:(AccessibilityPermissionAction)quitHandler {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    [alert setMessageText:@"需要辅助功能权限"];
    [alert setInformativeText:@"YunDrag 需要辅助功能权限来读取鼠标下的窗口，并移动或调整窗口大小。请在系统设置 > 隐私与安全性 > 辅助功能中启用 YunDrag，然后回到菜单栏点击“检查权限”。"];
    [alert addButtonWithTitle:@"打开辅助功能设置"];
    [alert addButtonWithTitle:@"稍后"];
    [alert addButtonWithTitle:@"退出"];

    NSModalResponse response = [alert runModal];
    if(response == NSAlertFirstButtonReturn) {
        if(openSettingsHandler != nil) {
            openSettingsHandler();
        }
    } else if(response == NSAlertThirdButtonReturn) {
        if(quitHandler != nil) {
            quitHandler();
        }
    }
}

@end
