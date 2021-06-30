#import "Twins3AlbumPlugin.h"
#if __has_include(<twins3_album/twins3_album-Swift.h>)
#import <twins3_album/twins3_album-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "twins3_album-Swift.h"
#endif

@implementation Twins3AlbumPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTwins3AlbumPlugin registerWithRegistrar:registrar];
}
@end
