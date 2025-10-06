import 'dart:io';

import 'package:path/path.dart';

extension LinkExtensions on Link {
  void copySync(String newPath) {
    final targetPath = targetSync();
    final newLink = Link(newPath);
    if (isRelative(targetPath)) {
      final fullPath = join(parent.path, targetPath);
      final newTargetPath = relative(fullPath, from: newLink.parent.path);
      if (!File(fullPath).existsSync() && !Directory(fullPath).existsSync()) {
        print('Target path does not exist, `$newTargetPath` (We will continue, but something to check!)');
        return;
      }
      newLink.createSync(newTargetPath);
    } else {
      newLink.createSync(targetPath);
    }
  }

  void moveSync(String newPath) {
    copySync(newPath);
    deleteSync(recursive: true);
  }
}
