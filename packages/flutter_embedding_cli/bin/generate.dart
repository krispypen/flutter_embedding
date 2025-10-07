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
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  try {
    // 2. Parse de argumenten
    final ArgResults results = parser.parse(arguments);
    final verbose = results.command?.flag('verbose') ?? false;

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
        await runCommand(
            'fvm', ['flutter', 'build', 'ios-framework', '--cocoapods', '--output=build/ios/sdk'], verbose);

        await generateZip(Directory('build/ios/sdk'), verbose);
        await generatePodSpecs(Directory('build/ios/sdk'));
        await generatePodHelper(Directory('.'), Directory('build/ios/sdk'), 'https://krispypen.be');
        print('iOS module generated in: ${Directory.current.path}/build/ios/sdk');
        if (results.command?.flag('example') == true) {
          print('Generating iOS example app');
          final brick =
              Brick.git(GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/ios-example'));
          final generator = await MasonGenerator.fromBrick(brick);
          final path = Directory.current.path + '/build/ios-example';
          final target = DirectoryGeneratorTarget(Directory(path));
          await generator.generate(target, vars: <String, dynamic>{
            'module_path': '/opt/gitrepos/meetup_demo_add-to-app/flutter_module',
            'iosBundleIdentifier': flutterIosBundleIdentifier
          });
          await runCommand('cp', ['-r', 'build/ios/sdk', '${path}/Flutter/'], verbose);
          print('Example app generated in: ${path}');
        }

        break;
      case 'android':
        // read flutter.androidPackage from pubspec.yaml
        final flutterAndroidPackage = _getFlutterAndroidPackage();
        print('Generating Android module for package: ${flutterAndroidPackage}');
        await runCommand('fvm', ['flutter', 'build', 'aar'], verbose);
        if (results.command?.flag('example') == true) {
          print('Generating Android example app');
          final brick =
              Brick.git(GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/android-example'));

          final generator = await MasonGenerator.fromBrick(brick);
          final path = Directory.current.path + '/build/android-example';
          final target = DirectoryGeneratorTarget(Directory(path));

          await generator.generate(target, vars: <String, dynamic>{
            'module_path': '/opt/gitrepos/meetup_demo_add-to-app/flutter_module',
            'androidPackage': flutterAndroidPackage
          });
          await runCommand('cp', ['-r', 'build/host/outputs/repo', '${path}/Flutter/'], verbose);
          print('Example app generated in: ${path}');
        }
        break;
      case 'react-native':
        print('Generating React Native module');
        final flutterRnEmbeddingPath = Directory.current.path + '/build/flutter-rn-embedding';
        final brick = Brick.git(
            GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/react-native-module'));

        final generator = await MasonGenerator.fromBrick(brick);
        final target = DirectoryGeneratorTarget(Directory(flutterRnEmbeddingPath));

        await generator.generate(target, vars: <String, dynamic>{});

        await runCommand('fvm', ['flutter', 'build', 'aar'], verbose);

        final flutterDir = Directory('${flutterRnEmbeddingPath}/android/Flutter');
        if (flutterDir.existsSync()) {
          Directory('${flutterRnEmbeddingPath}/android/Flutter').deleteSync(recursive: true);
        }
        Directory('${flutterRnEmbeddingPath}/android/Flutter').createSync(recursive: true);
        await runCommand(
            'cp', ['-r', 'build/host/outputs/repo', '${flutterRnEmbeddingPath}/android-rn/Flutter/'], verbose);
        await runCommand(
            'fvm',
            ['flutter', 'build', 'ios-framework', '--cocoapods', '--output=${flutterRnEmbeddingPath}/ios-rn/Flutter'],
            verbose);

        await generateZip(Directory('${flutterRnEmbeddingPath}/ios-rn/Flutter'), verbose);
        await generatePodSpecs(Directory('${flutterRnEmbeddingPath}/ios-rn/Flutter'));
        await generatePodHelper(
            Directory('.'), Directory('${flutterRnEmbeddingPath}/ios-rn/Flutter'), 'https://krispypen.be');

        File('${flutterRnEmbeddingPath}/ios-rn/Flutter/Release/Flutter.podspec')
            .copySync('${flutterRnEmbeddingPath}/ios-rn/Flutter/Flutter.podspec');

        await runCommand('npm', ['install'], directory: flutterRnEmbeddingPath, verbose);
        await runCommand('npm', ['run', 'ci'], directory: flutterRnEmbeddingPath, verbose);
        await runCommand('npm', ['pack', '.'], directory: flutterRnEmbeddingPath, verbose);
        print('React Native module generated in: ${flutterRnEmbeddingPath}');
        print('React Native module package: ${flutterRnEmbeddingPath}/flutter-rn-embedding-1.0.0.tgz');
        if (results.command?.flag('example') == true) {
          print('Generating React Native example app');
          final brick = Brick.git(
              GitPath('https://github.com/krispypen/flutter_embedding.git', path: 'bricks/react-native-example'));

          final generator = await MasonGenerator.fromBrick(brick);
          final path = Directory.current.path + '/build/react-native-example';
          final target = DirectoryGeneratorTarget(Directory(path));

          await generator.generate(target, vars: <String, dynamic>{
            'flutterRnEmbeddingPath': flutterRnEmbeddingPath,
          });
          // run chmod 755 android/gradlew
          await runCommand('chmod', ['755', 'android/gradlew'], directory: path, verbose);
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
