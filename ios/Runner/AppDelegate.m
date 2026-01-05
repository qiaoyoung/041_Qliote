#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    NSArray *arr = @[@"user", @"launch"];
    NSLog(@"Value: %@", arr[2]);
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end

