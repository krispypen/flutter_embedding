import 'dart:io';

import 'package:path/path.dart';

import 'directory_extensions.dart';
import 'run_command.dart';

Future<void> generateZip(Directory buildDirectory) async {
  final envNames = ['Release', 'Debug'];

  for (final env in envNames) {
    final envDirectory = Directory(join(buildDirectory.path, env));
    if (!envDirectory.existsSync()) {
      throw Exception('Failed to find $env directory, make sure the app-in-app iOS build was successful.');
    }

    // Remove $env/Pods directory
    final podsDir = Directory(join(envDirectory.path, 'Pods'));
    if (podsDir.existsSync()) {
      podsDir.deleteSync(recursive: true);
    }

    // Create $env/Frameworks directory
    Directory(join(envDirectory.path, 'Frameworks')).createSync(recursive: true);

    // Move *.xcframework files to $env/Frameworks
    final xcframeworkFiles = envDirectory
        .listSync(followLinks: false)
        .where((entity) => entity.path.endsWith('.xcframework'))
        .whereType<Directory>();
    for (final file in xcframeworkFiles) {
      final folderName = basename(file.path);
      file.moveSync(join(envDirectory.path, 'Frameworks', folderName));
    }

    // Zip the Frameworks directory
    await runCommand('zip', ['-r', 'Frameworks.zip', 'Frameworks'], directory: envDirectory.path);

    // Remove Frameworks directory
    Directory(join(envDirectory.path, 'Frameworks')).deleteSync(recursive: true);
  }
}
