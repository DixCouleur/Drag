#import "utils.h"

CGPoint
MousePosition(void) {
    CGEventRef event = CGEventCreate(NULL);
    if (event == NULL) {
        return CGPointZero;
    }

    CGPoint position = CGEventGetLocation(event);
    CFRelease(event);
    return position;
}

NS_INLINE void
getRole(AXUIElementRef element, CFStringRef *role) {
    AXError error = AXUIElementCopyAttributeValue(element, kAXRoleAttribute, (void *)role);
    if (error != kAXErrorSuccess) {
        NSLog(@"Failed to get role: %d", error);
        *role = nil;
    }
}

AXUIElementRef CopyWindowForElement(AXUIElementRef element) {
    if (element == NULL) {
        return NULL;
    }

    AXUIElementRef window = (AXUIElementRef)CFRetain(element);
    CFStringRef role = nil;
    while(window != nil) {
        getRole(window, &role);
        if(role == nil) {
            CFRelease(window);
            return nil;
        }

        if(CFStringCompare(role, kAXWindowRole, 0) == kCFCompareEqualTo) {
            CFRelease(role);
            return window;
        }

        CFRelease(role);
        AXUIElementRef parent = nil;
        AXError error = AXUIElementCopyAttributeValue(window, kAXParentAttribute, (void*)&parent);
        CFRelease(window);
        if (error != kAXErrorSuccess) {
            NSLog(@"Failed to get parent element: %d", error);
            return nil;
        }
        window = parent;
    }

    return window;
}

bool
CopyElementAtPosition(AXUIElementRef systemWideElement, CGPoint position, AXUIElementRef *element) {
    AXError error = AXUIElementCopyElementAtPosition(systemWideElement, position.x, position.y, element);
    if (error != kAXErrorSuccess) {
        NSLog(@"Failed to get element at position: %d", error);
        return false;
    }
    return true;
}
