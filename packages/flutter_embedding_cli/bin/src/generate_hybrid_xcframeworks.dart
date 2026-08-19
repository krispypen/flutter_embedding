import 'dart:io';

import 'package:path/path.dart';

import 'run_command.dart';

/// Creates hybrid xcframeworks that combine the Release device slice with the
/// Debug simulator slice.
///
/// A single hybrid framework set runs AOT (release) on physical devices and
/// JIT (debug) on simulators, independent of the host app's build
/// configuration. This is what makes a single Swift Package Manager product
/// possible: SPM cannot select frameworks per build configuration the way the
/// CocoaPods podhelper does, but with hybrid frameworks the platform slice
/// (device vs simulator) makes that choice instead.
///
/// The simulator slice is always the Debug (JIT) build. A real AOT simulator
/// slice is not possible with the stock Flutter engine: the simulator slice of
/// the Release/Profile Flutter.xcframework is built as a JIT runtime — at
/// startup its embedder looks for flutter_assets/kernel_blob.bin and aborts on
/// AOT-only assets (verified on Flutter 3.41.5). See
/// https://github.com/flutter/flutter/issues/58886.
///
/// Reads the per-configuration output of `flutter build ios-framework` in
/// [buildDirectory] (expects `Release/*.xcframework` and `Debug/*.xcframework`,
/// so this must run before `generateZip` moves them into Frameworks.zip) and
/// writes the merged xcframeworks to [outputDirectory].
Future<void> generateHybridXcframeworks(Directory buildDirectory, Directory outputDirectory, bool verbose) async {
  final releaseDirectory = Directory(join(buildDirectory.path, 'Release'));
  final debugDirectory = Directory(join(buildDirectory.path, 'Debug'));
  for (final directory in [releaseDirectory, debugDirectory]) {
    if (!directory.existsSync()) {
      throw Exception(
          'Failed to find ${basename(directory.path)} directory, make sure the app-in-app iOS build was successful.');
    }
  }

  if (outputDirectory.existsSync()) {
    outputDirectory.deleteSync(recursive: true);
  }
  outputDirectory.createSync(recursive: true);

  final xcframeworks = releaseDirectory
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((entity) => entity.path.endsWith('.xcframework'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (xcframeworks.isEmpty) {
    throw Exception('No xcframeworks found in ${releaseDirectory.path}, '
        'make sure generateHybridXcframeworks runs before generateZip.');
  }

  for (final xcframework in xcframeworks) {
    final frameworkName = basenameWithoutExtension(xcframework.path);
    final deviceFramework = _findFrameworkSlice(xcframework, frameworkName, simulator: false);
    final simulatorFramework = _findFrameworkSlice(
      Directory(join(debugDirectory.path, '$frameworkName.xcframework')),
      frameworkName,
      simulator: true,
    );

    await runCommand(
        'xcodebuild',
        [
          '-create-xcframework',
          '-framework',
          deviceFramework.path,
          '-framework',
          simulatorFramework.path,
          '-output',
          join(outputDirectory.path, '$frameworkName.xcframework'),
        ],
        verbose);
    print('Created hybrid $frameworkName.xcframework (Release device + Debug simulator)');
  }
}

/// Finds the framework inside the device or simulator slice of [xcframework].
///
/// Slices are identified by their library identifier directory name
/// (e.g. `ios-arm64` vs `ios-arm64_x86_64-simulator`) rather than hardcoded
/// names, so this keeps working when the set of architectures changes.
Directory _findFrameworkSlice(Directory xcframework, String frameworkName, {required bool simulator}) {
  if (!xcframework.existsSync()) {
    throw Exception('Failed to find ${xcframework.path}.');
  }
  // only look at real slice directories (e.g. skip _CodeSignature in signed xcframeworks)
  final framework = xcframework
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((entity) => basename(entity.path).contains('simulator') == simulator)
      .map((entity) => Directory(join(entity.path, '$frameworkName.framework')))
      .where((framework) => framework.existsSync())
      .firstOrNull;
  if (framework == null) {
    throw Exception(
        'Failed to find a ${simulator ? 'simulator' : 'device'} slice with $frameworkName.framework in ${xcframework.path}.');
  }
  return framework;
}
