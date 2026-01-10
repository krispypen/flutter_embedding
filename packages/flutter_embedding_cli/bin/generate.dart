import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';

import 'src/generate_pod_spec.dart';
import 'src/generate_pod_structure.dart';
import 'src/generate_protoc.dart';
import 'src/generate_zip.dart';
import 'src/run_command.dart';

/// Exception thrown when configuration is invalid or missing.
class ConfigurationException implements Exception {
  final String message;
  const ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand(
        'ios',
        ArgParser()
          ..addFlag('example', abbr: 'e', help: 'Generate example app')
          ..addFlag('verbose', abbr: 'v', help: 'Verbose output'))
    ..addCommand(
        'android',
        ArgParser()
          ..addFlag('example', abbr: 'e', help: 'Generate example app')
          ..addFlag('verbose', abbr: 'v', help: 'Verbose output'))
    ..addCommand(
        'react-native',
        ArgParser()
          ..addFlag('example', abbr: 'e', help: 'Generate example app')
          ..addFlag('verbose', abbr: 'v', help: 'Verbose output'))
    ..addCommand(
        'web-react',
        ArgParser()
          ..addFlag('example', abbr: 'e', help: 'Generate example react web app')
          ..addFlag('verbose', abbr: 'v', help: 'Verbose output'))
    ..addCommand(
        'web-angular',
        ArgParser()
          ..addFlag('example', abbr: 'e', help: 'Generate example angular web app')
          ..addFlag('verbose', abbr: 'v', help: 'Verbose output'))
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  try {
    final ArgResults results = parser.parse(arguments);
    final verbose = results.command?.flag('verbose') ?? false;

    if (results['help']) {
      print('Usage: flutter_embedding_cli [options] <command> <arguments>');
      print(parser.usage);
      exit(0);
    }

    final localBricksPath = Directory('${Directory.current.path}/../../bricks');

    final flutterModuleVersion = getFlutterModuleVersion();

    final exampleIosPatchBrickPath = getExampleIosPatchBrickPath();
    final exampleAndroidPatchBrickPath = getExampleAndroidPatchBrickPath();
    final exampleReactNativePatchBrickPath = getExampleReactNativePatchBrickPath();
    final exampleWebReactPatchBrickPath = getExampleWebReactPatchBrickPath();
    final exampleWebAngularPatchBrickPath = getExampleWebAngularPatchBrickPath();

    final moduleName = _getModuleName();
    final webAngularPackageName = _getWebAngularPackageName();
    final webReactPackageName = _getWebReactPackageName();
    final reactNativePackageName = _getReactNativePackageName();

    final bool localBricks = localBricksPath.existsSync();
    final brickVars = <String, dynamic>{
      'flutterModuleVersion': flutterModuleVersion,
      'startParamsMessage': await getStartParamsMessage(),
      'handoversToHostServices': await getHandoversToHostServices(),
      'handoversToFlutterServices': await getHandoversToFlutterServices(),
      'androidPackage': _getFlutterAndroidPackage(),
      'iosBundleIdentifier': _getFlutterIosBundleIdentifier(),
      'flutterBaseModuleName': _getFlutterBaseModuleName(),
      'flutterEmbeddingName': _getFlutterEmbeddingName(),
      'moduleName': moduleName,
      'exampleAndroidPackageName': getExampleAndroidPackageName(),
      'exampleAndroidPackageNameFolder': getExampleAndroidPackageName()?.replaceAll('.', '/'),
      'exampleAndroidAppName': getExampleAndroidAppName(),
      'exampleIosBundleIdentifier': getExampleIosBundleIdentifier(),
      'exampleIosDisplayName': getExampleIosDisplayName(),
      'webAngularPackageName': webAngularPackageName,
      'webReactPackageName': webReactPackageName,
      'reactNativePackageName': reactNativePackageName,
      'flutterEmbeddingPackageName': _getFlutterEmbeddingPackageName(),
      'flutterEmbeddingPackageNameFolder': _getFlutterEmbeddingPackageName().replaceAll('.', '/'),
    };

    {
      final brick = localBricks
          ? Brick.path(('${localBricksPath.path}/flutter-module-plugin'))
          : Brick.git(
              GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/flutter-module-plugin'));
      final generator = await MasonGenerator.fromBrick(brick);
      final path = '${Directory.current.path}/embedding/$moduleName';
      final target = DirectoryGeneratorTarget(Directory(path));
      await generator.generate(target, vars: brickVars);
      print('Generated Flutter module plugin $moduleName in: $path');

      await updateDartHandoverServices(verbose, 'embedding/$moduleName/lib/handovers');
      await runCommand('fvm', ['flutter', 'pub', 'add', '$moduleName:{path: embedding/$moduleName}'], verbose);
    }
    switch (results.command?.name) {
      case 'ios':
        print('Generating iOS module for bundle identifier: ${brickVars['iosBundleIdentifier']}');
        // execute fvm flutter build ios-framework --cocoapods --output=build/ios/sdk
        await updateSwiftHandoverServices(verbose, 'embedding/$moduleName/ios/Classes/');
        await runCommand(
            'fvm', ['flutter', 'build', 'ios-framework', '--cocoapods', '--output=embedding/ios/sdk'], verbose);

        await generateZip(Directory('embedding/ios/sdk'), verbose);
        await generatePodSpecs(Directory('embedding/ios/sdk'));
        await generatePodHelper(Directory('.'), Directory('embedding/ios/sdk'), 'https://krispypen.be');
        print('iOS module generated in: ${Directory.current.path}/embedding/ios/sdk');
        final iosExamplePath = '${Directory.current.path}/embedding/ios/example';
        if (results.command?.flag('example') == true) {
          print('Generating iOS example app');
          final brick = localBricks
              ? Brick.path(('${localBricksPath.path}/ios-example'))
              : Brick.git(GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/ios-example'));
          final generator = await MasonGenerator.fromBrick(brick);

          final target = DirectoryGeneratorTarget(Directory(iosExamplePath));
          await generator.generate(target, vars: brickVars);

          if (exampleIosPatchBrickPath != null) {
            print('Applying iOS example patch brick: $exampleIosPatchBrickPath');
            final exampleIosPatchBrick = Brick.path(exampleIosPatchBrickPath);
            final exampleIosPatchGenerator = await MasonGenerator.fromBrick(exampleIosPatchBrick);
            final exampleIosPatchTarget = DirectoryGeneratorTarget(Directory(iosExamplePath));
            await exampleIosPatchGenerator.generate(exampleIosPatchTarget, vars: brickVars);
          }
          // now replace the bundle identifier 'com.example.FlutterEmbeddingExample' in the Xcode project  $iosExamplePath/FlutterEmbeddingExample.xcodeproj by just find replace
          final xcodeProject = File('$iosExamplePath/FlutterEmbeddingExample.xcodeproj/project.pbxproj');
          final xcodeProjectContent = xcodeProject.readAsStringSync();
          final newXcodeProjectContent = xcodeProjectContent
              .replaceAll('com.example.FlutterEmbeddingExample', brickVars['exampleIosBundleIdentifier'])
              .replaceAll('Flutter Embedding Example', brickVars['exampleIosDisplayName']);
          xcodeProject.writeAsStringSync(newXcodeProjectContent);
        }
        if (Directory(iosExamplePath).existsSync()) {
          await runCommand('cp', ['-r', 'embedding/ios/sdk', '$iosExamplePath/Flutter/'], verbose);
          print(
              'Example app sdk in: $iosExamplePath, you can now run (cd embedding/ios/example && pod install && open FlutterEmbeddingExample.xcworkspace) in this directory to install the example app');
        }

        break;
      case 'android':
        print('Generating Android module ${brickVars['androidPackage']}');
        await updateJavaHandoverServices(verbose, 'embedding/$moduleName/android/src/main/java/');
        final androidSdkPath = 'embedding/android/sdk';
        Directory('$androidSdkPath/host/outputs/repo').createSync(recursive: true);
        await runCommand(
            'fvm', ['flutter', 'build', 'aar', '--output=${Directory.current.path}/$androidSdkPath'], verbose);
        final androidExamplePath = '${Directory.current.path}/embedding/android/example';
        if (results.command?.flag('example') == true) {
          print('Generating Android example ${brickVars['exampleAndroidPackageName']}');
          final brick = localBricks
              ? Brick.path(('${localBricksPath.path}/android-example'))
              : Brick.git(
                  GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/android-example'));
          final generator = await MasonGenerator.fromBrick(brick);

          final target = DirectoryGeneratorTarget(Directory(androidExamplePath));

          await generator.generate(target, vars: brickVars);

          if (exampleAndroidPatchBrickPath != null) {
            print('Applying Android example patch brick: $exampleAndroidPatchBrickPath');
            final exampleAndroidPatchBrick = Brick.path(exampleAndroidPatchBrickPath);
            final exampleAndroidPatchGenerator = await MasonGenerator.fromBrick(exampleAndroidPatchBrick);
            final exampleAndroidPatchTarget = DirectoryGeneratorTarget(Directory(androidExamplePath));
            await exampleAndroidPatchGenerator.generate(exampleAndroidPatchTarget, vars: brickVars);
          }
          // fix permissions for gradlew, permissions are lost after generating a brick
          await runCommand('chmod', ['u+x', '$androidExamplePath/gradlew'], verbose);
        }
        if (Directory(androidExamplePath).existsSync()) {
          await runCommand('cp', ['-r', 'embedding/android/sdk', '$androidExamplePath/Flutter/'], verbose);
          print(
              'Example app sdk in: $androidExamplePath, you can now run (cd embedding/android/example && ./gradlew build) in this directory to build the example app');
        }
        break;
      case 'react-native':
        print('Generating React Native module');
        final flutterRnEmbeddingPath = '${Directory.current.path}/embedding/react-native/module';
        brickVars['flutterRnEmbeddingPath'] = flutterRnEmbeddingPath;
        final brick = localBricks
            ? Brick.path(('${localBricksPath.path}/react-native-module'))
            : Brick.git(
                GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/react-native-module'));

        final generator = await MasonGenerator.fromBrick(brick);
        final target = DirectoryGeneratorTarget(Directory(flutterRnEmbeddingPath));

        await generator.generate(target, vars: brickVars);
        await updateReactNativeHandoverServices(verbose, '$flutterRnEmbeddingPath/src/handovers');

        await runCommand('fvm', ['flutter', 'build', 'aar'], verbose);

        final flutterDir = Directory('$flutterRnEmbeddingPath/android/Flutter');
        if (flutterDir.existsSync()) {
          Directory('$flutterRnEmbeddingPath/android/Flutter').deleteSync(recursive: true);
        }
        Directory('$flutterRnEmbeddingPath/android/Flutter').createSync(recursive: true);
        await runCommand(
            'cp', ['-r', 'build/host/outputs/repo', '$flutterRnEmbeddingPath/android-rn/Flutter/'], verbose);
        await runCommand(
            'fvm',
            ['flutter', 'build', 'ios-framework', '--cocoapods', '--output=$flutterRnEmbeddingPath/ios-rn/Flutter'],
            verbose);

        await generateZip(Directory('$flutterRnEmbeddingPath/ios-rn/Flutter'), verbose);
        await generatePodSpecs(Directory('$flutterRnEmbeddingPath/ios-rn/Flutter'));
        await generatePodHelper(
            Directory('.'), Directory('$flutterRnEmbeddingPath/ios-rn/Flutter'), 'https://krispypen.be');

        File('$flutterRnEmbeddingPath/ios-rn/Flutter/Release/Flutter.podspec')
            .copySync('$flutterRnEmbeddingPath/ios-rn/Flutter/Flutter.podspec');

        await runCommand('npm', ['install'], directory: flutterRnEmbeddingPath, verbose);
        await runCommand('npm', ['run', 'ci'], directory: flutterRnEmbeddingPath, verbose);
        await runCommand('npm', ['pack', '.'], directory: flutterRnEmbeddingPath, verbose);
        print('React Native module generated in: $flutterRnEmbeddingPath');
        print('React Native module package: $flutterRnEmbeddingPath/$reactNativePackageName-$flutterModuleVersion.tgz');
        final flutterRnEmbeddingExamplePath = '${Directory.current.path}/embedding/react-native/example';
        if (results.command?.flag('example') == true) {
          print('Generating React Native example app');
          final brick = localBricks
              ? Brick.path(('${localBricksPath.path}/react-native-example'))
              : Brick.git(
                  GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/react-native-example'));

          final generator = await MasonGenerator.fromBrick(brick);
          final target = DirectoryGeneratorTarget(Directory(flutterRnEmbeddingExamplePath));

          await generator.generate(target, vars: brickVars);
          if (exampleReactNativePatchBrickPath != null) {
            print('Applying React Native example patch brick: $exampleReactNativePatchBrickPath');
            final exampleReactNativePatchBrick = Brick.path(exampleReactNativePatchBrickPath);
            final exampleReactNativePatchGenerator = await MasonGenerator.fromBrick(exampleReactNativePatchBrick);
            final exampleReactNativePatchTarget = DirectoryGeneratorTarget(Directory(flutterRnEmbeddingExamplePath));
            await exampleReactNativePatchGenerator.generate(exampleReactNativePatchTarget, vars: brickVars);
          }
          // fix permissions for gradlew, permissions are lost after generating a brick
          await runCommand('chmod', ['u+x', '$flutterRnEmbeddingExamplePath/android/gradlew'], verbose);
        }
        if (Directory(flutterRnEmbeddingExamplePath).existsSync()) {
          await runCommand(
              'npm',
              ['install', '$reactNativePackageName@file:../module/$reactNativePackageName-$flutterModuleVersion.tgz'],
              directory: flutterRnEmbeddingExamplePath,
              verbose);
          print('Example app sdk in: $flutterRnEmbeddingExamplePath');
        }
        break;
      case 'web-react':
        print('Generating Web React module');
        final flutterREmbeddingPath = '${Directory.current.path}/embedding/web-react/module';
        final brick = localBricks
            ? Brick.path(('${localBricksPath.path}/web-react-module'))
            : Brick.git(GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/web-react-module'));

        final generator = await MasonGenerator.fromBrick(brick);
        final target = DirectoryGeneratorTarget(Directory(flutterREmbeddingPath));

        await generator.generate(target, vars: brickVars);

        await updateGrpcWebHandoverServices(verbose, '$flutterREmbeddingPath/src/handovers');

        await runCommand(
            'fvm',
            [
              'flutter',
              'build',
              'web',
              '--source-maps',
              '--profile',
              '--base-href',
              '/flutter/',
              '--output=$flutterREmbeddingPath/public/flutter/'
            ],
            verbose);
        await runCommand('npm', ['install'], directory: flutterREmbeddingPath, verbose);
        await runCommand('npm', ['run', 'ci'], directory: flutterREmbeddingPath, verbose);
        await runCommand('npm', ['run', 'build'], directory: flutterREmbeddingPath, verbose);
        await runCommand('npm', ['pack', '.'], directory: flutterREmbeddingPath, verbose);
        print('Web React module generated in: $flutterREmbeddingPath');
        print('Web React module package: $flutterREmbeddingPath/$webReactPackageName-$flutterModuleVersion.tgz');
        final flutterReactEmbeddingExamplePath = '${Directory.current.path}/embedding/web-react/example';
        if (results.command?.flag('example') == true) {
          print('Generating Web React example app');
          final brick = localBricks
              ? Brick.path(('${localBricksPath.path}/web-react-example'))
              : Brick.git(
                  GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/web-react-example'));
          final generator = await MasonGenerator.fromBrick(brick);
          final target = DirectoryGeneratorTarget(Directory(flutterReactEmbeddingExamplePath));
          await generator.generate(target, vars: brickVars);
          if (exampleWebReactPatchBrickPath != null) {
            print('Applying Web React example patch brick: $exampleWebReactPatchBrickPath');
            final exampleWebReactPatchBrick = Brick.path(exampleWebReactPatchBrickPath);
            final exampleWebReactPatchGenerator = await MasonGenerator.fromBrick(exampleWebReactPatchBrick);
            final exampleWebReactPatchTarget = DirectoryGeneratorTarget(Directory(flutterReactEmbeddingExamplePath));
            await exampleWebReactPatchGenerator.generate(exampleWebReactPatchTarget, vars: brickVars);
          }
        }
        if (Directory(flutterReactEmbeddingExamplePath).existsSync()) {
          await runCommand(
              'npm',
              ['install', '$webReactPackageName@file:../module/$webReactPackageName-$flutterModuleVersion.tgz'],
              directory: flutterReactEmbeddingExamplePath,
              verbose);
          print(
              'Example app sdk in: $flutterReactEmbeddingExamplePath, you can now run (cd embedding/web-react/example && npm install && npm start) in this directory to start the example app');
        }
        break;
      case 'web-angular':
        print('Generating Web Angular module');
        final flutterAngularEmbeddingPath = '${Directory.current.path}/embedding/web-angular/module';
        final brick = localBricks
            ? Brick.path(('${localBricksPath.path}/web-angular-module'))
            : Brick.git(
                GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/web-angular-module'));

        final generator = await MasonGenerator.fromBrick(brick);
        final target = DirectoryGeneratorTarget(Directory(flutterAngularEmbeddingPath));

        await generator.generate(target, vars: brickVars);

        await updateGrpcWebHandoverServices(verbose, '$flutterAngularEmbeddingPath/src/lib/handovers');

        await runCommand(
            'fvm',
            [
              'flutter',
              'build',
              'web',
              '--source-maps',
              '--profile',
              '--base-href',
              '/flutter/',
              '--output=$flutterAngularEmbeddingPath/public/flutter/'
            ],
            verbose);
        await runCommand('npm', ['install'], directory: flutterAngularEmbeddingPath, verbose);
        await runCommand('npm', ['run', 'build'], directory: flutterAngularEmbeddingPath, verbose);
        await runCommand('npm', ['pack', '.'], directory: flutterAngularEmbeddingPath, verbose);
        print(
            'Web Angular module package: $flutterAngularEmbeddingPath/$webAngularPackageName-$flutterModuleVersion.tgz');
        final flutterAngularEmbeddingExamplePath = '${Directory.current.path}/embedding/web-angular/example';
        if (results.command?.flag('example') == true) {
          print('Generating Web Angular example app');
          final brick = localBricks
              ? Brick.path(('${localBricksPath.path}/web-angular-example'))
              : Brick.git(
                  GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/web-angular-example'));
          final generator = await MasonGenerator.fromBrick(brick);
          final target = DirectoryGeneratorTarget(Directory(flutterAngularEmbeddingExamplePath));
          await generator.generate(target, vars: brickVars);
          if (exampleWebAngularPatchBrickPath != null) {
            print('Applying Web Angular example patch brick: $exampleWebAngularPatchBrickPath');
            final exampleWebAngularPatchBrick = Brick.path(exampleWebAngularPatchBrickPath);
            final exampleWebAngularPatchGenerator = await MasonGenerator.fromBrick(exampleWebAngularPatchBrick);
            final exampleWebAngularPatchTarget =
                DirectoryGeneratorTarget(Directory(flutterAngularEmbeddingExamplePath));
            await exampleWebAngularPatchGenerator.generate(exampleWebAngularPatchTarget, vars: brickVars);
          }
        }
        if (Directory(flutterAngularEmbeddingExamplePath).existsSync()) {
          await runCommand(
              'npm',
              ['install', '$webAngularPackageName@file:../module/$webAngularPackageName-$flutterModuleVersion.tgz'],
              directory: flutterAngularEmbeddingExamplePath,
              verbose);
          print(
              'Example app sdk in: $flutterAngularEmbeddingExamplePath, you can now run (cd embedding/web-angular/example && npm install && npm start) in this directory to start the example app');
        }

        break;
      default:
        print('Invalid command');
        break;
    }
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln(parser.usage);
    exit(64); // EX_USAGE
  } on ConfigurationException catch (e) {
    stderr.writeln(e.toString());
    exit(78); // EX_CONFIG
  } on CommandException catch (e) {
    stderr.writeln(e.toString());
    stderr.writeln('Tip: Run with --verbose flag for more details.');
    exit(e.exitCode);
  } catch (e, stackTrace) {
    stderr.writeln('An unexpected error occurred: $e');
    stderr.writeln('Stack trace: $stackTrace');
    exit(1);
  }
}

String? getExampleIosPatchBrickPath() {
  final exampleIosPatchBrickPath = flutterEmbeddingConfig?['ios']?['example']?['brick_patch'];
  return exampleIosPatchBrickPath?.toString();
}

String? getExampleAndroidPatchBrickPath() {
  final exampleAndroidPatchBrickPath = flutterEmbeddingConfig?['android']?['example']?['brick_patch'];
  return exampleAndroidPatchBrickPath?.toString();
}

String? getExampleAndroidPackageName() {
  final exampleAndroidPackageName = flutterEmbeddingConfig?['android']?['example']?['package_name'];
  return exampleAndroidPackageName?.toString() ?? '${_getFlutterEmbeddingPackageName()}.example';
}

String? getExampleAndroidAppName() {
  final exampleAndroidAppName = flutterEmbeddingConfig?['android']?['example']?['app_name'];
  return exampleAndroidAppName?.toString() ?? 'Flutter Embedding Example';
}

String? getExampleIosBundleIdentifier() {
  final exampleIosBundleIdentifier = flutterEmbeddingConfig?['ios']?['example']?['bundle_identifier'];
  return exampleIosBundleIdentifier?.toString() ?? '${_getFlutterEmbeddingPackageName()}.example';
}

String? getExampleIosDisplayName() {
  final exampleIosDisplayName = flutterEmbeddingConfig?['ios']?['example']?['display_name'];
  return exampleIosDisplayName?.toString() ?? 'Flutter Embedding Example';
}

String? getExampleReactNativePatchBrickPath() {
  final exampleReactNativePatchBrickPath = flutterEmbeddingConfig?['react_native']?['example']?['brick_patch'];
  return exampleReactNativePatchBrickPath?.toString();
}

String? getExampleWebReactPatchBrickPath() {
  final exampleWebReactPatchBrickPath = flutterEmbeddingConfig?['web_react']?['example']?['brick_patch'];
  return exampleWebReactPatchBrickPath?.toString();
}

String? getExampleWebAngularPatchBrickPath() {
  final exampleWebAngularPatchBrickPath = flutterEmbeddingConfig?['web_angular']?['example']?['brick_patch'];
  return exampleWebAngularPatchBrickPath?.toString();
}

String getFlutterModuleVersion() {
  final pubspec = File('pubspec.yaml');
  final flutterModuleVersion = loadYaml(pubspec.readAsStringSync())['version'];
  return flutterModuleVersion.toString();
}

String _getFlutterBaseModuleName() {
  final pubspec = File('pubspec.yaml');
  final flutterModuleName = loadYaml(pubspec.readAsStringSync())['name'];
  if (flutterModuleName == null) {
    throw const ConfigurationException(
      'The "name" field is not set in pubspec.yaml. '
      'Please ensure your pubspec.yaml contains a valid package name.',
    );
  }
  return flutterModuleName;
}

String _getModuleName() {
  final moduleName = flutterEmbeddingConfig?['module_name'];
  if (moduleName != null && !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(moduleName)) {
    throw ConfigurationException(
      'The "flutter_embedding.module_name" value "$moduleName" is not a valid Dart package name. '
      'Package names must start with a lowercase letter and contain only lowercase letters, numbers, and underscores.',
    );
  }
  return moduleName ?? '${_getFlutterBaseModuleName()}_module';
}

String _getWebAngularPackageName() {
  final webAngularPackageName = flutterEmbeddingConfig?['web_angular']?['package_name'];
  if (webAngularPackageName == null) {
    return '${_getModuleName().replaceAll('_', '-')}-angular';
  }
  return webAngularPackageName;
}

String _getWebReactPackageName() {
  final webReactPackageName = flutterEmbeddingConfig?['web_react']?['package_name'];
  if (webReactPackageName == null) {
    return '${_getModuleName().replaceAll('_', '-')}-react';
  }
  return webReactPackageName;
}

String _getReactNativePackageName() {
  final reactNativePackageName = flutterEmbeddingConfig?['react_native']?['package_name'];
  if (reactNativePackageName == null) {
    return '${_getModuleName().replaceAll('_', '-')}-react-native';
  }
  return reactNativePackageName;
}

String _getFlutterEmbeddingName() {
  final flutterEmbeddingName = flutterEmbeddingConfig?['name'];
  if (flutterEmbeddingName == null) {
    throw const ConfigurationException(
      'The "flutter_embedding.name" field is not set in pubspec.yaml. '
      'Please add a "flutter_embedding" section with a "name" field.',
    );
  }
  return flutterEmbeddingName;
}

String _getFlutterEmbeddingPackageName() {
  final flutterEmbeddingPackageName = flutterEmbeddingConfig?['package_name'];
  if (flutterEmbeddingPackageName == null) {
    throw const ConfigurationException(
      'The "flutter_embedding.package_name" field is not set in pubspec.yaml. '
      'Please add a "package_name" field under the "flutter_embedding" section.',
    );
  }
  return flutterEmbeddingPackageName;
}

String _getFlutterAndroidPackage() {
  final pubspec = File('pubspec.yaml');
  final yaml = loadYaml(pubspec.readAsStringSync());
  final flutterAndroidPackage = yaml['flutter']?['module']?['androidPackage'];
  if (flutterAndroidPackage == null) {
    throw const ConfigurationException(
      'The "flutter.module.androidPackage" field is not set in pubspec.yaml. '
      'Please ensure your Flutter module configuration includes an androidPackage.',
    );
  }
  return flutterAndroidPackage;
}

String _getFlutterIosBundleIdentifier() {
  final pubspec = File('pubspec.yaml');
  final yaml = loadYaml(pubspec.readAsStringSync());
  final flutterIosBundleIdentifier = yaml['flutter']?['module']?['iosBundleIdentifier'];
  if (flutterIosBundleIdentifier == null) {
    throw const ConfigurationException(
      'The "flutter.module.iosBundleIdentifier" field is not set in pubspec.yaml. '
      'Please ensure your Flutter module configuration includes an iosBundleIdentifier.',
    );
  }
  return flutterIosBundleIdentifier;
}
