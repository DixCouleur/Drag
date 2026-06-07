//
//  utils.h
//  YunMove
//
//  Created by Yun on 2023/4/18.
//

#ifndef utils_h
#define utils_h

#import <ApplicationServices/ApplicationServices.h>
#import <CoreGraphics/CoreGraphics.h>
#import <stdbool.h>

#define CGPointAdd(a,b) CGPointMake(a.x + b.x, a.y + b.y)
#define CGPointSub(a,b) CGPointMake(a.x - b.x, a.y - b.y)

#define CGSizeAdd(size,point) CGSizeMake(size.width + point.x, size.height + point.y)

CGPoint
MousePosition(void);


AXUIElementRef
CopyWindowForElement(AXUIElementRef element);

bool
CopyElementAtPosition(AXUIElementRef systemWideElement, CGPoint position, AXUIElementRef *element);


#endif /* utils_h */
