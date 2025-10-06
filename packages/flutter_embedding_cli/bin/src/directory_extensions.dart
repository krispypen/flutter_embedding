import 'dart:io';

import 'package:path/path.dart';

import 'link_extensions.dart';

extension DirectoryExtensions on Directory {
  void deleteSyncIfExist({bool recursive = false}) {
    if (existsSync()) {
      deleteSync(recursive: recursive);
    }
  }

  void moveSync(String newPath, {bool followLinks = true}) {
    copySync(newPath, followLinks: followLinks);
    deleteSync(recursive: true);
  }

  void copySync(String newPath, {bool followLinks = true}) {
    final normalizedPath = normalize(path);
    final normalizedNewPath = normalize(newPath);
    final destinationDirectory = Directory(normalizedNewPath);
    final list = listSync(recursive: true, followLinks: followLinks);
    if (!destinationDirectory.existsSync()) {
      destinationDirectory.createSync(recursive: true);
    }
    for (final entity in list) {
      var entityPath = entity.uri.path.replaceFirst(normalizedPath, '');
      if (entityPath.startsWith('/')) {
        entityPath = entityPath.replaceFirst('/', '');
      }

      final newEntityPath = join(normalizedNewPath, entityPath);
      if (entity is File) {
        entity.copySync(newEntityPath);
      } else if (entity is Directory) {
        final newDirectory = Directory(newEntityPath);
        newDirectory.createSync(recursive: true);
      } else if (entity is Link) {
        entity.copySync(newEntityPath);
      } else {
        throw Exception('Unknown entity type: ${entity.runtimeType} ($entityPath)');
      }
    }
  }
}
