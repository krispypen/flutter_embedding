import 'dart:io';

import 'package:yaml/yaml.dart';

import 'run_command.dart';

/// The flutter_embedding configuration section from pubspec.yaml.
///
/// This is lazily loaded from the current directory's pubspec.yaml.
final flutterEmbeddingConfig = loadYaml(File('pubspec.yaml').readAsStringSync())['flutter_embedding'];

/// Returns the start params message type from the embedding configuration.
Future<String> getStartParamsMessage() async {
  final startParamsMessage = flutterEmbeddingConfig['handovers']['start_params'];
  return startParamsMessage;
}

/// Returns a list of service definitions for host-to-Flutter handover services.
///
/// Each service is represented as a map with keys: 'name', 'snake_name', 'path', and 'type'.
Future<List<Map<String, String>>> getHandoversToHostServices() async {
  final handoversToHostProtoPaths = flutterEmbeddingConfig['handovers']['to_host'];
  return await getServicesFromProto(handoversToHostProtoPaths);
}

/// Returns a list of service definitions for Flutter-to-host handover services.
///
/// Each service is represented as a map with keys: 'name', 'snake_name', 'path', and 'type'.
Future<List<Map<String, String>>> getHandoversToFlutterServices() async {
  final handoversToFlutterProtoPaths = flutterEmbeddingConfig['handovers']['to_flutter'];
  return await getServicesFromProto(handoversToFlutterProtoPaths);
}

/// Parses proto files to extract service definitions.
Future<List<Map<String, String>>> getServicesFromProto(YamlList protoPaths) async {
  // read all proto files in handoversToHostProtoPaths files  and search for all services
  final services = <Map<String, String>>[];
  final serviceRegex = RegExp(r'service\s+(\w+)\s*\{');

  for (final protoPath in protoPaths) {
    final protoFile = File('${Directory.current.path}/embedding/protos/$protoPath');
    final content = protoFile.readAsStringSync();
    final matches = serviceRegex.allMatches(content);

    for (final match in matches) {
      final serviceName = match.group(1);
      if (serviceName != null) {
        // first letter of name should be lowercase
        final firstLetter = serviceName.substring(0, 1).toLowerCase();
        final rest = serviceName.substring(1);
        final name = '$firstLetter$rest';
        final snakeName =
            name.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (Match match) => '_${match[0]}').toLowerCase();
        services.add({'name': name, 'snake_name': snakeName, 'path': protoPath, 'type': serviceName});
      }
    }
  }

  return services;
}

/// Generates Dart gRPC service stubs from proto definitions.
///
/// Output is written to [outputPath].
Future<void> updateDartHandoverServices(bool verbose, String outputPath) async {
  final handoversToHostProtoPaths = flutterEmbeddingConfig['handovers']['to_host'];
  final handoversToFlutterProtoPaths = flutterEmbeddingConfig['handovers']['to_flutter'];
  if (handoversToHostProtoPaths.isNotEmpty) {
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--dart_out=grpc:$outputPath',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToHostProtoPaths.join(',')
        ],
        verbose);
  }
  if (handoversToFlutterProtoPaths.isNotEmpty) {
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--dart_out=grpc:$outputPath',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToFlutterProtoPaths.join(',')
        ],
        verbose);
  }
}

/// Generates Java gRPC service stubs from proto definitions.
///
/// Output is written to [outputPath].
Future<void> updateJavaHandoverServices(bool verbose, String outputPath) async {
  final handoversToHostProtoPaths = flutterEmbeddingConfig['handovers']['to_host'];
  final handoversToFlutterProtoPaths = flutterEmbeddingConfig['handovers']['to_flutter'];
  if (handoversToHostProtoPaths.isNotEmpty) {
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--java_out=$outputPath',
          '--grpc-java_out=$outputPath',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToHostProtoPaths.join(',')
        ],
        verbose);
  }
  if (handoversToFlutterProtoPaths.isNotEmpty) {
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--java_out=$outputPath',
          '--grpc-java_out=grpc:$outputPath',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToFlutterProtoPaths.join(',')
        ],
        verbose);
  }
}

/// Generates Swift gRPC service stubs from proto definitions.
///
/// Output is written to [outputPath].
Future<void> updateSwiftHandoverServices(bool verbose, String outputPath) async {
  final handoversToHostProtoPaths = flutterEmbeddingConfig['handovers']['to_host'];
  final handoversToFlutterProtoPaths = flutterEmbeddingConfig['handovers']['to_flutter'];
  // available options see: https://github.com/grpc/grpc-swift-protobuf/blob/main/Sources/protoc-gen-grpc-swift-2/Options.swift
  if (handoversToHostProtoPaths.isNotEmpty) {
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--swift_out=$outputPath',
          '--swift_opt=Visibility=Public',
          '--grpc-swift-2_out=$outputPath',
          '--grpc-swift-2_opt=Client=false,Visibility=Public,GRPCProtobufModuleName=FlutterEmbeddingProtobuf,GRPCModuleName=FlutterEmbeddingGRPCCore',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToHostProtoPaths.join(',')
        ],
        verbose);
  }

  if (handoversToFlutterProtoPaths.isNotEmpty) {
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--swift_out=$outputPath',
          '--swift_opt=Visibility=Public',
          '--grpc-swift-2_out=$outputPath',
          '--grpc-swift-2_opt=Server=false,Visibility=Public,GRPCProtobufModuleName=FlutterEmbeddingProtobuf,GRPCModuleName=FlutterEmbeddingGRPCCore',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToFlutterProtoPaths.join(',')
        ],
        verbose);
  }

  // now we need to remove all the "import FlutterEmbeddingProtobuf" and "import FlutterEmbeddingGRPCCore" from the generated files
  final files = Directory(outputPath).listSync(recursive: true).where((file) => file.path.endsWith('.swift')).toList();
  for (final file in files) {
    final content = File(file.path).readAsStringSync();
    final newContent =
        content.replaceAll('import FlutterEmbeddingProtobuf', '').replaceAll('import FlutterEmbeddingGRPCCore', '');
    File(file.path).writeAsStringSync(newContent);
  }
}

/// Generates TypeScript service stubs for React Native from proto definitions.
///
/// Output is written to [outputPath].
Future<void> updateReactNativeHandoverServices(bool verbose, String outputPath) async {
  final handoversToHostProtoPaths = flutterEmbeddingConfig['handovers']['to_host'];
  final handoversToFlutterProtoPaths = flutterEmbeddingConfig['handovers']['to_flutter'];
  if (handoversToHostProtoPaths.isNotEmpty) {
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--ts_out=$outputPath',
          '--ts_opt=server_generic,client_none',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToHostProtoPaths.join(',')
        ],
        verbose);
  }
  if (handoversToFlutterProtoPaths.isNotEmpty) {
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--ts_out=$outputPath',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToFlutterProtoPaths.join(',')
        ],
        verbose);
  }
}

/// Generates TypeScript service stubs for gRPC-Web from proto definitions.
///
/// Output is written to [outputPath].
Future<void> updateGrpcWebHandoverServices(bool verbose, String outputPath) async {
  final handoversToHostProtoPaths = flutterEmbeddingConfig['handovers']['to_host'];
  final handoversToFlutterProtoPaths = flutterEmbeddingConfig['handovers']['to_flutter'];
  if (handoversToHostProtoPaths.isNotEmpty) {
    // create outputPath if needed
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--ts_out=$outputPath',
          '--ts_opt=server_generic,client_none',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToHostProtoPaths.join(',')
        ],
        verbose);
  }
  if (handoversToFlutterProtoPaths.isNotEmpty) {
    Directory(outputPath).createSync(recursive: true);
    await runCommand(
        'protoc',
        [
          '--ts_out=$outputPath',
          '--proto_path',
          '${Directory.current.path}/embedding/protos',
          handoversToFlutterProtoPaths.join(',')
        ],
        verbose);
  }
}
