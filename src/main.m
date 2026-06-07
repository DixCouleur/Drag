#import "AppDelegate.h"

int
main(int argc, const char * argv[]) {
    NSApplication *app = [NSApplication sharedApplication];
    
    AppDelegate *delegate = [AppDelegate new];
    app.delegate = delegate;
    
    return NSApplicationMain(argc, argv);
}
