import 'dart:io';

import 'package:path/path.dart';

/// Generates CocoaPods podspec files for Release and Debug configurations.
///
/// Creates podspec files in [buildDirectory]/Release and [buildDirectory]/Debug
/// that reference the shared podhelper.rb file.
Future<void> generatePodSpecs(Directory buildDirectory) async {
  final envNames = ['Release', 'Debug'];
  final moduleName = 'FlutterEmbeddingModule';

  for (final env in envNames) {
    final podspecFile = File(join(buildDirectory.path, env, '$moduleName.podspec'));
    if (podspecFile.existsSync()) {
      podspecFile.deleteSync();
    }

    final writeStream = podspecFile.openWrite();
    writeStream.write('require \'./../podhelper\'\n\n');

    writeStream.write('Pod::Spec.new do |s|\n');
    writeStream.write('  generateFrameworksSpecProps(s, "$env")\n');
    writeStream.write('end\n');

    await writeStream.close();
  }
}
