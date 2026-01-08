import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'podfile_lock.dart';

Future<void> generatePodHelper(
  Directory flutterModuleDirectory,
  Directory buildDirectory,
  String gitRepo,
) async {
  final envNames = ['Release', 'Debug'];

  final podFilelock = PodFileLock.parse(flutterModuleDirectory);

  final podhelperFile = File(join(buildDirectory.path, 'podhelper.rb'));
  if (podhelperFile.existsSync()) {
    podhelperFile.deleteSync();
  }

  for (final env in envNames) {
    final envPodsDirectory = Directory(join(buildDirectory.path, env, 'Pods'));
    if (!envPodsDirectory.existsSync()) {
      envPodsDirectory.createSync(recursive: true);
    }
  }

  final writeStream = podhelperFile.openWrite();
  writeStream.write('require \'json\'\n');
  writeStream.write('require \'addressable/uri\'\n\n');
  writeStream.write('def install_all_flutter_pods (options={})\n');
  writeStream.write('  prefix = options[:path] ||=  File.expand_path(__dir__)\n');

  writeStream.write('  pod "Flutter", :podspec => File.join(prefix, "Release", "Flutter.podspec")\n');

  // Filter out SwiftProtobuf from direct pod declarations since it's already a dependency
  // of FlutterEmbeddingModule and will be available transitively
  for (final podName in podFilelock.specRepo.trunk) {
    if (podName == 'SwiftProtobuf') {
      continue; // Skip SwiftProtobuf - it comes through FlutterEmbeddingModule dependencies
    }
    // writeStream.write('  pod "$podName", "${podFilelock.getPodVersion(podName)}"\n');
    for (final env in envNames) {
      final envPath = join(buildDirectory.path, env);
      final podFile = File(join(envPath, '$podName.xcframework'));
      if (podFile.existsSync()) {
        podFile.renameSync(join(envPath, 'Pods', '$podName.xcframework'));
        print('Successfully moved - $podName for $env!');
      }
    }
  }

  writeStream.write('\n');

  final pubspec = File(flutterModuleDirectory.path + '/pubspec.yaml');
  final pubspecData = loadYaml(pubspec.readAsStringSync());

  final moduleName = 'FlutterEmbeddingModule';

  for (final env in envNames) {
    writeStream.write('  pod \'$moduleName-$env\',\n');
    writeStream.write('    :configurations => options[:${env.toLowerCase()}_configs] || [\'$env\'],\n');
    writeStream.write('    :podspec => File.join(prefix, \'$env\', \'$moduleName.podspec\')\n');
  }

  writeStream.write('end\n\n');

  writeStream.write('def setModuleDependencies(s)\n');
  for (final env in envNames) {
    writeStream.write('  s.dependency "$moduleName-$env"\n');
  }
  writeStream.write('end\n\n');

  writeStream.write('def setCommonProps(s)\n');
  writeStream.write('  s.version       =\'${pubspecData['version']}\'\n');
  writeStream.write('  s.summary       = \'${pubspecData['description']}\'\n');
  if (pubspecData['homepage'] == null) {
    writeStream.write('  s.homepage      = \'$gitRepo#readme\'\n');
  } else {
    writeStream.write('  s.homepage      = \'${pubspecData['homepage']}\'\n');
  }
  writeStream.write('  s.license       = \'MIT\'\n');
  writeStream.write('  s.source        = { :git =>\'$gitRepo\', :tag => "${pubspecData['version']}" }\n');
  writeStream.write('  s.authors       = { \'Kris Pypen\' => \'kris.pypen@gmail.com\' }\n');
  writeStream.write('  s.platforms     = { :ios => "11.0" }\n');
  writeStream.write('  s.swift_version = \'5.0\'\n');
  writeStream.write('  s.requires_arc  = true\n');
  writeStream.write('end\n\n');

  writeStream.write('def generateFrameworksSpecProps(s, configuration)\n');
  writeStream.write('  setCommonProps(s)\n');
  writeStream.write(
      '  uri = Addressable::URI.parse(File.expand_path(File.join(configuration, "Frameworks.zip"), __dir__))\n\n');
  writeStream.write('  s.name = "$moduleName-#{configuration}"\n');
  writeStream.write('  s.source = { :http => "file://#{uri.normalize.to_s}", :type => "zip"}\n');
  writeStream.write('  s.xcconfig = { \'FRAMEWORK_SEARCH_PATHS\' => "\'\${PODS_ROOT}/#{s.name}\'"}\n');
  writeStream.write('  s.description  = <<-DESC\n');
  writeStream.write('                  App flutter module for ${pubspecData['name']}, #{configuration}\n');
  writeStream.write('                  DESC\n');
  writeStream.write('  s.source_files = "Frameworks/**/*.{swift,h,m}"\n');
  writeStream.write('  s.exclude_files = "Frameworks/**/*.xcframework/**/*.h"\n');
  writeStream.write('  s.vendored_frameworks = \'**/*.xcframework\'\n');
  writeStream.write('  s.preserve_paths = "**/*.xcframework"\n');
  writeStream.write(
      '  s.pod_target_xcconfig = { \'DEFINES_MODULE\' => \'YES\', \'EXCLUDED_ARCHS[sdk=iphonesimulator*]\' => \'i386\',\n');
  writeStream.write(
      '    \'OTHER_LDFLAGS\' => \'\$(inherited) -ObjC -framework Flutter -framework App -framework FlutterPluginRegistrant -framework flutter_embedding\'\n');
  writeStream.write('  }\n');
  writeStream.write('  s.static_framework = true\n\n');

  for (final podName in podFilelock.specRepo.trunk) {
    if (podName == 'SwiftProtobuf') {
      continue; // Skip SwiftProtobuf - it comes through FlutterEmbeddingModule dependencies
    }
    //writeStream.write('  s.dependency "$podName"\n');
  }

  writeStream.write('end\n\n');

  // When working with xcfilelists, CocoaPods sometimes just adds duplicate dependencies if you're working with
  // framework files. This is a workaround to make sure we remove duplicates since they lead to compilation errors.
  // Issue open here: https://github.com/CocoaPods/CocoaPods/issues/11737
  writeStream.write(
      '# When working with xcfilelists, CocoaPods sometimes just adds duplicate dependencies if you\'re working with\n');
  writeStream.write(
      '# framework files. This is a workaround to make sure we remove duplicates since they lead to compilation errors.\n');
  writeStream.write('# Issue open here: https://github.com/CocoaPods/CocoaPods/issues/11737\n');
  writeStream.write('def fllutter_embedding_sdk_post_integrate(target)\n');
  writeStream.write('  puts "Running SDK post integrate hook"\n');
  writeStream.write(
      '  IO.write(File.join(Dir.pwd,"Pods/Target Support Files/Pods-#{target}/Pods-#{target}-frameworks-Release-output-files.xcfilelist"),\n');
  writeStream.write(
      '  IO.readlines(File.join(Dir.pwd,"Pods/Target Support Files/Pods-#{target}/Pods-#{target}-frameworks-Release-output-files.xcfilelist"), chomp: true).uniq.join("\\n"))\n');
  writeStream.write(
      '  IO.write(File.join(Dir.pwd,"Pods/Target Support Files/Pods-#{target}/Pods-#{target}-frameworks-Debug-output-files.xcfilelist"),\n');
  writeStream.write(
      '  IO.readlines(File.join(Dir.pwd,"Pods/Target Support Files/Pods-#{target}/Pods-#{target}-frameworks-Debug-output-files.xcfilelist"), chomp: true).uniq.join("\\n"))\n');
  writeStream.write('end\n\n');

  writeStream.close();
}
