//
//  AXWindowController.m
//  YunMove
//

#import "AXWindowController.h"
#import "utils.h"

@interface AXWindowController ()

@property AXUIElementRef systemWideElement;
@property AXUIElementRef targetWindow;
@property CGSize winSize;
@property CGPoint winPosition;

@end

@implementation AXWindowController

- (BOOL)hasTargetWindow {
    return _targetWindow != nil;
}

- (BOOL)prepareSystemWideElement {
    if(_systemWideElement != nil) {
        return YES;
    }

    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    if(systemWideElement == nil) {
        NSLog(@"Failed to create system-wide element");
        return NO;
    }

    _systemWideElement = systemWideElement;
    return YES;
}

- (BOOL)captureWindowAtMousePosition:(CGPoint)mousePosition {
    if(![self prepareSystemWideElement]) {
        return NO;
    }

    AXUIElementRef targetElement = nil;
    if(!CopyElementAtPosition(_systemWideElement, mousePosition, &targetElement)) {
        [self clearTargetWindow];
        return NO;
    }

    AXUIElementRef targetWindow = CopyWindowForElement(targetElement);
    CFRelease(targetElement);
    if(targetWindow == nil) {
        [self clearTargetWindow];
        return NO;
    }

    [self setOwnedTargetWindow:targetWindow];

    AXValueRef positionValue = nil;
    AXError error = AXUIElementCopyAttributeValue(_targetWindow, kAXPositionAttribute, (void *)&positionValue);
    if(error == kAXErrorSuccess) {
        AXValueGetValue(positionValue, kAXValueTypeCGPoint, (void *)&_winPosition);
        CFRelease(positionValue);
    }

    AXValueRef sizeValue = nil;
    error = AXUIElementCopyAttributeValue(_targetWindow, kAXSizeAttribute, (void *)&sizeValue);
    if(error == kAXErrorSuccess) {
        AXValueGetValue(sizeValue, kAXValueCGSizeType, (void *)&_winSize);
        CFRelease(sizeValue);
    }

    return YES;
}

- (void)moveWindowByOffset:(CGPoint)offset {
    if(_targetWindow == nil) {
        return;
    }

    self.winPosition = CGPointAdd(self.winPosition, offset);
    [self updateWindowPosition:self.winPosition];
}

- (void)resizeWindowByOffset:(CGPoint)offset {
    if(_targetWindow == nil) {
        return;
    }

    self.winSize = CGSizeAdd(self.winSize, offset);
    [self updateWindowSize:self.winSize];
}

- (void)clearTargetWindow {
    [self setOwnedTargetWindow:nil];
}

- (void)reset {
    [self clearTargetWindow];
    if(_systemWideElement != nil) {
        CFRelease(_systemWideElement);
        _systemWideElement = nil;
    }
}

- (void)setOwnedTargetWindow:(AXUIElementRef)targetWindow {
    if(_targetWindow == targetWindow) {
        if(targetWindow != nil) {
            CFRelease(targetWindow);
        }
        return;
    }

    if(_targetWindow != nil) {
        CFRelease(_targetWindow);
    }
    _targetWindow = targetWindow;
}

- (void)updateWindowPosition:(CGPoint)newPosition {
    AXValueRef newWinPosition = AXValueCreate(kAXValueTypeCGPoint, &newPosition);
    if(newWinPosition) {
        AXError error = AXUIElementSetAttributeValue(_targetWindow, kAXPositionAttribute, newWinPosition);
        if(error != kAXErrorSuccess) {
            NSLog(@"Failed to set window position: %d", error);
        }
        CFRelease(newWinPosition);
    }
}

- (void)updateWindowSize:(CGSize)newSize {
    AXValueRef newWinSize = AXValueCreate(kAXValueTypeCGSize, &newSize);
    if(newWinSize) {
        AXError error = AXUIElementSetAttributeValue(_targetWindow, kAXSizeAttribute, newWinSize);
        if(error != kAXErrorSuccess) {
            NSLog(@"Failed to set window size: %d", error);
        }
        CFRelease(newWinSize);
    }
}

- (void)dealloc {
    [self reset];
}

@end
