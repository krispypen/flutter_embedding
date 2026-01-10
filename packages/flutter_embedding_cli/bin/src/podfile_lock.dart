import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

/// Represents a parsed Podfile.lock file.
///
/// Provides access to pod versions and spec repository information.
class PodFileLock {
  final Map<String, String> pods;
  final SpecRepo specRepo;

  const PodFileLock._({
    required this.pods,
    required this.specRepo,
  });

  /// Parses the Podfile.lock from the given [directory].
  ///
  /// Looks for Podfile.lock in either .ios/ or ios/ subdirectory.
  /// Throws an [Exception] if the file is not found or both directories exist.
  factory PodFileLock.parse(Directory directory) {
    final podFileName = 'Podfile.lock';
    final iosPodFileLock = File(join(directory.path, '.ios', podFileName));
    final hiddenIosPodFileLock = File(join(directory.path, 'ios', podFileName));
    if (!iosPodFileLock.existsSync() && !hiddenIosPodFileLock.existsSync()) {
      throw Exception('Could not find $podFileName in `.ios` and `ios` folders. (Did you run pod install?)');
    }
    if (iosPodFileLock.existsSync() && hiddenIosPodFileLock.existsSync()) {
      throw Exception('.ios and ios folders both exist, this is not normal. Double check your project structure.');
    }
    final podFileLock = iosPodFileLock.existsSync() ? iosPodFileLock : hiddenIosPodFileLock;
    final podFileContents = podFileLock.readAsStringSync();
    final podData = loadYaml(podFileContents);
    return _parsePodData(podData);
  }

  static PodFileLock _parsePodData(YamlMap podData) {
    final pods = <String, String>{};
    for (final element in podData['PODS']) {
      String dependency;
      if (element is String) {
        dependency = element;
      } else if (element is YamlMap) {
        dependency = element.entries.first.key;
      } else {
        throw Exception('Failed to parse ${element.runtimeType} in Podfile.lock');
      }

      final results = RegExp(r'^([^/]*)\s+\((.*)\)$').firstMatch(dependency);
      if (results != null) {
        pods[results.group(1)!] = results.group(2)!;
      }
    }
    return PodFileLock._(
      pods: pods,
      specRepo: SpecRepo._(
        trunk: podData['SPEC REPOS'] == null
            ? <String>[]
            : (podData['SPEC REPOS']['trunk'] as YamlList).whereType<String>().toList(),
      ),
    );
  }

  /// Returns the version string for the given [podName].
  ///
  /// Throws an [Exception] if the pod is not found in the lock file.
  String getPodVersion(String podName) {
    if (pods.containsKey(podName)) {
      return pods[podName]!;
    }
    throw Exception('Could not find pod `$podName` in Podfile.lock');
  }
}

/// Represents the spec repositories section of a Podfile.lock.
class SpecRepo {
  final List<String> trunk;

  const SpecRepo._({
    required this.trunk,
  });
}
