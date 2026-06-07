//
//  AccessibilityPermissionGuide.h
//  YunMove
//

#import <Cocoa/Cocoa.h>

typedef void (^AccessibilityPermissionAction)(void);

@interface AccessibilityPermissionGuide : NSObject

- (BOOL)isTrustedWithPrompt:(BOOL)prompt;
- (void)openSettings;
- (void)showWithOpenSettingsHandler:(AccessibilityPermissionAction)openSettingsHandler
                         quitHandler:(AccessibilityPermissionAction)quitHandler;

@end
