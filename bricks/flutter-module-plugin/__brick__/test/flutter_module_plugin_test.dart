import 'package:flutter_test/flutter_test.dart';
import 'package:{{moduleName}}/{{moduleName}}.dart';
import 'package:{{moduleName}}/{{moduleName}}_platform_interface.dart';
import 'package:{{moduleName}}/{{moduleName}}_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterModulePluginPlatform with MockPlatformInterfaceMixin implements FlutterModulePluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterModulePluginPlatform initialPlatform = FlutterModulePluginPlatform.instance;

  test('$MethodChannelFlutterModulePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterModulePlugin>());
  });

  test('getPlatformVersion', () async {
    FlutterModulePlugin flutterModulePlugin = FlutterModulePlugin();
    MockFlutterModulePluginPlatform fakePlatform = MockFlutterModulePluginPlatform();
    FlutterModulePluginPlatform.instance = fakePlatform;

    expect(await flutterModulePlugin.getPlatformVersion(), '42');
  });
}
