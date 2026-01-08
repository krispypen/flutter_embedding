import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '{{moduleName}}_method_channel.dart';

abstract class FlutterModulePluginPlatform extends PlatformInterface {
  /// Constructs a FlutterModulePluginPlatform.
  FlutterModulePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterModulePluginPlatform _instance = MethodChannelFlutterModulePlugin();

  /// The default instance of [FlutterModulePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterModulePlugin].
  static FlutterModulePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterModulePluginPlatform] when
  /// they register themselves.
  static set instance(FlutterModulePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
