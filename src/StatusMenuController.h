//
//  StatusMenuController.h
//  YunMove
//

#import <Cocoa/Cocoa.h>

typedef void (^StatusMenuAction)(void);

@interface StatusMenuController : NSObject

@property (nonatomic, copy) StatusMenuAction openSettingsHandler;
@property (nonatomic, copy) StatusMenuAction checkPermissionHandler;
@property (nonatomic, copy) StatusMenuAction quitHandler;

- (void)show;
- (void)updatePermissionStatus:(BOOL)accessibilityEnabled;
- (void)cancelTracking;

@end
