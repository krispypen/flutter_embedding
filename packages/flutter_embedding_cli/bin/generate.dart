import 'dart:io';

import 'package:args/args.dart';
import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';

import 'src/generate_pod_spec.dart';
import 'src/generate_pod_structure.dart';
import 'src/generate_zip.dart';
import 'src/run_command.dart';

void main(List<String> arguments) async {
  // 1. Maak een ArgParser
  final parser = ArgParser()
    ..addCommand('ios', ArgParser()..addFlag('example', abbr: 'e', help: 'Generate example app'))
    ..addCommand('android', ArgParser()..addFlag('example', abbr: 'e', help: 'Generate example app'))
    ..addCommand('react-native', ArgParser()..addFlag('example', abbr: 'e', help: 'Generate example app'))
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  try {
    // 2. Parse de argumenten
    final ArgResults results = parser.parse(arguments);

    // 3. Behandel de 'help' vlag
    if (results['help']) {
      print('Usage: flutter_embedding_cli [options] <command> <arguments>');
      print(parser.usage);
      exit(0);
    }

    switch (results.command?.name) {
      case 'ios':
        final flutterIosBundleIdentifier = _getFlutterIosBundleIdentifier();
        print('Generating iOS module for bundle identifier: ${flutterIosBundleIdentifier}');
        // execute fvm flutter build ios-framework --cocoapods --output=build/ios/sdk
        await runCommand('fvm', ['flutter', 'build', 'ios-framework', '--cocoapods', '--output=build/ios/sdk']);

        await generateZip(Directory('build/ios/sdk'));
        await generatePodSpecs(Directory('build/ios/sdk'));
        await generatePodHelper(Directory('.'), Directory('build/ios/sdk'), 'https://krispypen.be');
        if (results.command?.flag('example') == true) {
          print('Generating iOS example app');
          final brick = Brick.path('/opt/gitrepos/meetup_demo_add-to-app/bricks/ios-example');
          final generator = await MasonGenerator.fromBrick(brick);
          final path = Directory.current.path + '/build/ios-example';
          final target = DirectoryGeneratorTarget(Directory(path));
          await generator.generate(target, vars: <String, dynamic>{
            'module_path': '/opt/gitrepos/meetup_demo_add-to-app/flutter_module',
            'iosBundleIdentifier': flutterIosBundleIdentifier
          });
          await runCommand('cp', ['-r', 'build/ios/sdk', '${path}/Flutter/']);
          print('Example app generated in: ${path}');
        }

        break;
      case 'android':
        // read flutter.androidPackage from pubspec.yaml
        final flutterAndroidPackage = _getFlutterAndroidPackage();
        print('Generating Android module for package: ${flutterAndroidPackage}');
        await runCommand('fvm', ['flutter', 'build', 'aar']);
        if (results.command?.flag('example') == true) {
          print('Generating Android example app');
          final brick = Brick.path('/opt/gitrepos/meetup_demo_add-to-app/bricks/android-example');

          final generator = await MasonGenerator.fromBrick(brick);
          final path = Directory.current.path + '/build/android-example';
          final target = DirectoryGeneratorTarget(Directory(path));

          await generator.generate(target, vars: <String, dynamic>{
            'module_path': '/opt/gitrepos/meetup_demo_add-to-app/flutter_module',
            'androidPackage': flutterAndroidPackage
          });
          print('Example app generated in: ${path}');
        }
        break;
      case 'react-native':
        print('Generating React Native module');
        final flutterRnEmbeddingPath = Directory.current.path + '/build/flutter-rn-embedding';
        final brick = Brick.path('/opt/gitrepos/meetup_demo_add-to-app/bricks/react-native-module');

        final generator = await MasonGenerator.fromBrick(brick);
        final path = Directory.current.path + '/build/flutter-rn-embedding';
        final target = DirectoryGeneratorTarget(Directory(path));

        await generator.generate(target, vars: <String, dynamic>{});
        print('React Native module generated in: ${path}');
        await runCommand('fvm', ['flutter', 'build', 'aar']);
        // copy all content of build/host/outputs/repo to flutterRnEmbeddingPath/android/Flutter including subdirectories
        final flutterDir = Directory('${flutterRnEmbeddingPath}/android/Flutter');
        if (flutterDir.existsSync()) {
          Directory('${flutterRnEmbeddingPath}/android/Flutter').deleteSync(recursive: true);
        }
        Directory('${flutterRnEmbeddingPath}/android/Flutter').createSync(recursive: true);
        await runCommand('cp', ['-r', 'build/host/outputs/repo', '${flutterRnEmbeddingPath}/android-rn/Flutter/']);
        await runCommand('fvm',
            ['flutter', 'build', 'ios-framework', '--cocoapods', '--output=${flutterRnEmbeddingPath}/ios-rn/Flutter']);

        await generateZip(Directory('${flutterRnEmbeddingPath}/ios-rn/Flutter'));
        await generatePodSpecs(Directory('${flutterRnEmbeddingPath}/ios-rn/Flutter'));
        await generatePodHelper(
            Directory('.'), Directory('${flutterRnEmbeddingPath}/ios-rn/Flutter'), 'https://krispypen.be');
        // cp Flutter/Release/Flutter.podspec to Flutter/Flutter.podspec
        File('${flutterRnEmbeddingPath}/ios-rn/Flutter/Release/Flutter.podspec')
            .copySync('${flutterRnEmbeddingPath}/ios-rn/Flutter/Flutter.podspec');
        // run: npm install
        // npm run ci
        // npm pack .
        await runCommand('npm', ['install'], directory: flutterRnEmbeddingPath);
        await runCommand('npm', ['run', 'ci'], directory: flutterRnEmbeddingPath);
        await runCommand('npm', ['pack', '.'], directory: flutterRnEmbeddingPath);
        if (results.command?.flag('example') == true) {
          print('Generating React Native example app');
          final brick = Brick.path('/opt/gitrepos/meetup_demo_add-to-app/bricks/react-native-example');

          final generator = await MasonGenerator.fromBrick(brick);
          final path = Directory.current.path + '/build/react-native-example';
          final target = DirectoryGeneratorTarget(Directory(path));

          await generator.generate(target, vars: <String, dynamic>{
            'flutterRnEmbeddingPath': flutterRnEmbeddingPath,
          });
          // run chmod 755 android/gradlew
          await runCommand('chmod', ['755', 'android/gradlew'], directory: path);
          print('Example app generated in: ${path}');
        }
        break;
      default:
        print('Invalid command');
        break;
    }

    // 4. Gebruik de geparste opties
    //final String naam = results['naam'];
    //print('Hallo, $naam! Dit is jouw Dart console command.');

    // 5. Behandel de positionele argumenten
    if (results.rest.isNotEmpty) {
      print('Ongedefinieerde positionele argumenten: ${results.rest}');
    }
  } on FormatException catch (e, stackTrace) {
    stderr.writeln(e.message);
    stderr.writeln('Stack trace: $stackTrace');
    stderr.writeln(parser.usage);
    exit(1);
  } catch (e, stackTrace) {
    stderr.writeln('Een fout is opgetreden: $e');
    stderr.writeln('Stack trace: $stackTrace');
    exit(2);
  }
}

String _getFlutterAndroidPackage() {
  final pubspec = File('pubspec.yaml');
  final flutterAndroidPackage = loadYaml(pubspec.readAsStringSync())['flutter']['module']['androidPackage'];
  if (flutterAndroidPackage == null) {
    print('flutter.androidPackage is not set in pubspec.yaml');
    exit(1);
  }
  return flutterAndroidPackage;
}

String _getFlutterIosBundleIdentifier() {
  final pubspec = File('pubspec.yaml');
  final flutterIosBundleIdentifier = loadYaml(pubspec.readAsStringSync())['flutter']['module']['iosBundleIdentifier'];
  if (flutterIosBundleIdentifier == null) {
    print('flutter.iosBundleIdentifier is not set in pubspec.yaml');
    exit(1);
  }
  return flutterIosBundleIdentifier;
}
