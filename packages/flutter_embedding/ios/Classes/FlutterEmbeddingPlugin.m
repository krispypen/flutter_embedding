#import "FlutterEmbeddingPlugin.h"
#if __has_include(<flutter_embedding/flutter_embedding-Swift.h>)
#import <flutter_embedding/flutter_embedding-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_embedding-Swift.h"
#endif

@implementation FlutterEmbeddingPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterEmbeddingPlugin registerWithRegistrar:registrar];
}
@end
