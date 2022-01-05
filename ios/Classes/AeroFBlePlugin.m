#import "AeroFBlePlugin.h"
#if __has_include(<aero_f_ble/aero_f_ble-Swift.h>)
#import <aero_f_ble/aero_f_ble-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "aero_f_ble-Swift.h"
#endif

@implementation AeroFBlePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftAeroPlugin registerWithRegistrar:registrar];
}
@end
