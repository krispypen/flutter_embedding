import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '{{moduleName}}_platform_interface.dart';

/// An implementation of [FlutterModulePluginPlatform] that uses method channels.
class MethodChannelFlutterModulePlugin extends FlutterModulePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('{{moduleName}}');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
