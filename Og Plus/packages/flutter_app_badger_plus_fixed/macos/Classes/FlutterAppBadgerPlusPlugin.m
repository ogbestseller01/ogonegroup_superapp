#import "FlutterAppBadgerPlusPlugin.h"

@implementation FlutterAppBadgerPlusPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"g123k/flutter_app_badger_plus"
                                  binaryMessenger:[registrar messenger]];
  FlutterAppBadgerPlusPlugin *instance = [[FlutterAppBadgerPlusPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  NSLog(@"%@", call.method);
  if ([@"updateBadgeCount" isEqualToString:call.method]) {
    NSDictionary *args = call.arguments;
    NSNumber *count = [args objectForKey:@"count"];
    [NSApp dockTile].badgeLabel = [count stringValue];
    result(nil);
  } else if ([@"removeBadge" isEqualToString:call.method]) {
    [NSApp dockTile].badgeLabel = nil;
    result(nil);
  } else if ([@"isAppBadgeSupported" isEqualToString:call.method]) {
    result(@YES);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
