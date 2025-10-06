import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class PodFileLock {
  final Map<String, String> pods;
  final SpecRepo specRepo;

  const PodFileLock._({
    required this.pods,
    required this.specRepo,
  });

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

  String getPodVersion(podName) {
    if (pods.containsKey(podName)) {
      return pods[podName]!;
    }
    throw Exception('Could not find pod `$podName` in Podfile.lock');
  }
}

class SpecRepo {
  final List<String> trunk;

  const SpecRepo._({
    required this.trunk,
  });
}
