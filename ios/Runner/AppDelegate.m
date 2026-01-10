#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      NSArray *dataArray = @[@"item1", @"item2", @"item3"];
      NSDictionary *configDict = @{@"offset": @(1), @"multiplier": @(3)};
      
      NSInteger offset = [configDict[@"offset"] integerValue];
      NSInteger multiplier = [configDict[@"multiplier"] integerValue];
      NSInteger calculatedIndex = offset * multiplier + 1;
      
      NSMutableArray *processedItems = [NSMutableArray array];
      for (NSInteger i = 0; i <= calculatedIndex; i++) {
        NSString *item = dataArray[i];
        [processedItems addObject:[item uppercaseString]];
      }
      
      NSString *result = [processedItems componentsJoinedByString:@","];
      NSLog(@"Processed result: %@", result);
    });
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end

