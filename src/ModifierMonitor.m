//
//  ModifierMonitor.m
//  YunMove
//

#import "ModifierMonitor.h"
#import "AXWindowController.h"
#import "utils.h"
#import <AppKit/NSEvent.h>

@interface ModifierMonitor ()

@property AXWindowController *windowController;
@property BOOL moveEnabled;
@property BOOL resizeEnabled;
@property CGPoint mousePosition;
@property NSTimer *mouseTimer;
@property id flagsMonitor;

@end

@implementation ModifierMonitor

- (instancetype)initWithWindowController:(AXWindowController *)windowController {
    self = [super init];
    if(self) {
        _windowController = windowController;
    }
    return self;
}

- (void)start {
    if(self.flagsMonitor != nil) {
        return;
    }

    if(![self.windowController prepareSystemWideElement]) {
        return;
    }

    __weak ModifierMonitor *weakSelf = self;
    self.flagsMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask: NSEventMaskFlagsChanged
                                                               handler: ^(NSEvent *event) {
        ModifierMonitor *strongSelf = weakSelf;
        if(strongSelf == nil) {
            return;
        }

        [strongSelf handleFlagsChanged:event];
    }];
}

- (void)stop {
    [self stopMouseObserver];
    [self.windowController clearTargetWindow];

    if(self.flagsMonitor != nil) {
        [NSEvent removeMonitor:self.flagsMonitor];
        self.flagsMonitor = nil;
    }
}

- (void)handleFlagsChanged:(NSEvent *)event {
    NSEventModifierFlags flags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
    self.moveEnabled = flags == (NSEventModifierFlagControl | NSEventModifierFlagCommand);
    self.resizeEnabled = flags == (NSEventModifierFlagControl | NSEventModifierFlagOption);

    if(!self.moveEnabled && !self.resizeEnabled) {
        [self stopMouseObserver];
        [self.windowController clearTargetWindow];
        return;
    }

    self.mousePosition = MousePosition();
    if(![self.windowController captureWindowAtMousePosition:self.mousePosition]) {
        [self stopMouseObserver];
        return;
    }

    [self startMouseObserver];
}

- (void)startMouseObserver {
    if(self.mouseTimer != nil) {
        return;
    }

    __weak ModifierMonitor *weakSelf = self;
    self.mouseTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 / 144.0
                                                      repeats: YES
                                                        block: ^(NSTimer *timer) {
        ModifierMonitor *strongSelf = weakSelf;
        if(strongSelf == nil) {
            [timer invalidate];
            return;
        }

        [strongSelf updateTargetWindowForCurrentMousePosition];
    }];
}

- (void)stopMouseObserver {
    if(self.mouseTimer != nil) {
        [self.mouseTimer invalidate];
        self.mouseTimer = nil;
    }
}

- (void)updateTargetWindowForCurrentMousePosition {
    if(!self.windowController.hasTargetWindow) {
        return;
    }

    CGPoint newMousePosition = MousePosition();
    CGPoint moveOffset = CGPointSub(newMousePosition, self.mousePosition);
    if(CGPointEqualToPoint(self.mousePosition, newMousePosition)) {
        return;
    }

    if(self.moveEnabled) {
        [self.windowController moveWindowByOffset:moveOffset];
    }

    if(self.resizeEnabled) {
        [self.windowController resizeWindowByOffset:moveOffset];
    }

    self.mousePosition = newMousePosition;
}

- (void)dealloc {
    [self stop];
}

@end
