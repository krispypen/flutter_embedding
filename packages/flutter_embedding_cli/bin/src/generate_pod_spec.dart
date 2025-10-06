import 'dart:io';

import 'package:path/path.dart';

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

    writeStream.close();
  }
}
