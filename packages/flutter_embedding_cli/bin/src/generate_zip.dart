import 'dart:io';

import 'package:path/path.dart';

import 'directory_extensions.dart';
import 'run_command.dart';

/// Creates zip archives of the xcframework files for Release and Debug configurations.
///
/// Moves all .xcframework directories into a Frameworks folder and creates a
/// Frameworks.zip archive in each configuration directory.
Future<void> generateZip(Directory buildDirectory, bool verbose) async {
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
    await runCommand('zip', ['-r', 'Frameworks.zip', 'Frameworks'], directory: envDirectory.path, verbose);

    // Remove Frameworks directory
    Directory(join(envDirectory.path, 'Frameworks')).deleteSync(recursive: true);
  }
}

/// Creates a zip archive of the generated module/sdk artifacts and example app.
///
/// Zips the [contents] paths (relative to [directory]) into [zipName] inside
/// [directory], skipping paths that don't exist. When [password] is provided
/// the archive is protected with it (classic `zip -P` encryption).
Future<void> generateSdkZip(
  Directory directory,
  String zipName,
  List<String> contents,
  List<String> exclusions,
  String? password,
  bool verbose,
) async {
  final existingContents = contents
      .where((content) => FileSystemEntity.typeSync(join(directory.path, content)) != FileSystemEntityType.notFound)
      .toList();
  if (existingContents.isEmpty) {
    print('Skipping $zipName: nothing to zip in ${directory.path}');
    return;
  }

  // delete any previous archive, otherwise zip updates it in place and stale entries survive
  final zipFile = File(join(directory.path, zipName));
  if (zipFile.existsSync()) {
    zipFile.deleteSync();
  }

  await runCommand(
      'zip',
      [
        if (password != null) ...['-P', password],
        '-r',
        zipName,
        ...existingContents,
        if (exclusions.isNotEmpty) ...['-x', ...exclusions],
      ],
      directory: directory.path,
      verbose);
  print('SDK zip generated: ${zipFile.path}');
}
