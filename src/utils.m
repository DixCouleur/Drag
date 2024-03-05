#import "appkit/NSEvent.h"
#import "appkit/NSWindow.h"

void
getRole(AXUIElementRef element, CFStringRef *role) {
    AXUIElementCopyAttributeValue(element, kAXRoleAttribute, (void *)role);
}

AXUIElementRef
getWindow(AXUIElementRef element) {
    AXUIElementRef window = element;
    CFStringRef role = nil;
    while(window != nil) {
        getRole(window, &role);
        if(role == nil) {
            return nil;
        }
        
        if(CFStringCompare(role, kAXWindowRole, 0) == kCFCompareEqualTo) {
            return window;
        }

        AXUIElementCopyAttributeValue(window, kAXParentAttribute, (void*)&window);
    }

    return window;
}

bool
elementAtPosition(AXUIElementRef systemWideElement, CGPoint position, AXUIElementRef *element) {
    return AXUIElementCopyElementAtPosition(systemWideElement, position.x, position.y, element) == kAXErrorSuccess;
}

