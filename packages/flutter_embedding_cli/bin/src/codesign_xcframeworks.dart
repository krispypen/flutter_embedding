import 'dart:io';

import 'package:path/path.dart';

import 'run_command.dart';

/// Signs the xcframeworks directly inside [directory] with [identity].
///
/// App Store Connect rejects apps that embed a "commonly used third-party SDK"
/// (Flutter, connectivity_plus, share_plus, ...) from an unsigned xcframework
/// (ITMS-91065). `flutter build ios-framework` never signs the plugin
/// xcframeworks, and recombining slices with `xcodebuild -create-xcframework`
/// (see generateHybridXcframeworks) drops the signature Flutter.xcframework
/// ships with. Xcframeworks that are still signed (e.g. Flutter.xcframework in
/// the CocoaPods output) keep their original signature.
///
/// [identity] is anything `codesign --sign` accepts, e.g. a certificate name
/// like "Apple Distribution: Company (TEAMID)" or its SHA-1 hash.
Future<void> codesignXcframeworks(Directory directory, String identity, bool verbose) async {
  final xcframeworks = directory
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((entity) => entity.path.endsWith('.xcframework'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (xcframeworks.isEmpty) {
    throw Exception('No xcframeworks found in ${directory.path} to sign.');
  }

  for (final xcframework in xcframeworks) {
    final name = basename(xcframework.path);
    if (Directory(join(xcframework.path, '_CodeSignature')).existsSync()) {
      print('Keeping existing signature of $name');
      continue;
    }
    await runCommand('codesign', ['--timestamp', '--sign', identity, xcframework.path], verbose);
    print('Signed $name');
  }
}
