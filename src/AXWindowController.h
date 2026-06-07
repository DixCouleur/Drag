//
//  AXWindowController.h
//  YunMove
//

#import <ApplicationServices/ApplicationServices.h>
#import <CoreGraphics/CoreGraphics.h>

@interface AXWindowController : NSObject

@property (nonatomic, readonly) BOOL hasTargetWindow;

- (BOOL)prepareSystemWideElement;
- (BOOL)captureWindowAtMousePosition:(CGPoint)mousePosition;
- (void)moveWindowByOffset:(CGPoint)offset;
- (void)resizeWindowByOffset:(CGPoint)offset;
- (void)clearTargetWindow;
- (void)reset;

@end
