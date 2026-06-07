//
//  ModifierMonitor.h
//  YunMove
//

#import <Foundation/Foundation.h>

@class AXWindowController;

@interface ModifierMonitor : NSObject

- (instancetype)initWithWindowController:(AXWindowController *)windowController;
- (void)start;
- (void)stop;

@end
