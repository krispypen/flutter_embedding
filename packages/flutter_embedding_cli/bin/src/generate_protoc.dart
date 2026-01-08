import 'dart:io';

import 'package:yaml/yaml.dart';

import 'run_command.dart';

final flutterEmbeddingConfig = loadYaml(File('pubspec.yaml').readAsStringSync())['flutter_embedding'];

Future<String> getStartParamsMessage() async {
  final startParamsMessage = flutterEmbeddingConfig['handovers']['start_params'];
  return startParamsMessage;
}

Future<List<Map<String, String>>> getHandoversToHostServices() async {
  // handoversToHostProtoPaths is a list of proto files
  final handoversToHostProtoPaths = flutterEmbeddingConfig['handovers']['to_host'];

  return await getServicesFromProto(handoversToHostProtoPaths);
}

Future<List<Map<String, String>>> getHandoversToFlutterServices() async {
  final handoversToFlutterProtoPaths = flutterEmbeddingConfig['handovers']['to_flutter'];

  return await getServicesFromProto(handoversToFlutterProtoPaths);
}

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

Future<void> updateDartHandoverServices(bool verbose, String outputPath) async {
  // update proto services
  //protoc --dart_out=grpc:lib/protos protos/host_service.proto protos/embedding_service.proto --java_out=androidtest/ --kotlin_out=androidtestkotlin/ --swift_out=swift/ --grpc-swift-2_out=swift/ --doc_out=markdown,output:./protodocs/ --js_out=import_style=commonjs,binary:jstest/ --grpc-web_out=import_style=commonjs+dts,mode=grpcweb:jstest --proto_path protos
  // read pubspec.yaml and get embedding.host_handover_proto_paths and embedding.embedding_handover_proto_paths
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

Future<void> updateJavaHandoverServices(bool verbose, String outputPath) async {
  // update proto services
  //protoc --java_out=androidtest/ --kotlin_out=androidtestkotlin/ --swift_out=swift/ --grpc-swift-2_out=swift/ --doc_out=markdown,output:./protodocs/ --js_out=import_style=commonjs,binary:jstest/ --grpc-web_out=import_style=commonjs+dts,mode=grpcweb:jstest --proto_path protos
  // read pubspec.yaml and get embedding.host_handover_proto_paths and embedding.embedding_handover_proto_paths
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

Future<void> updateSwiftHandoverServices(bool verbose, String outputPath) async {
  // update proto services
  //protoc --swift_out=swift/ --grpc-swift-2_out=swift/ --doc_out=markdown,output:./protodocs/ --proto_path protos
  // read pubspec.yaml and get embedding.host_handover_proto_paths and embedding.embedding_handover_proto_paths
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

Future<void> updateReactNativeHandoverServices(bool verbose, String outputPath) async {
  // update proto services
  //protoc --dart_out=grpc:lib/protos protos/host_service.proto protos/embedding_service.proto --java_out=androidtest/ --kotlin_out=androidtestkotlin/ --swift_out=swift/ --grpc-swift-2_out=swift/ --doc_out=markdown,output:./protodocs/ --js_out=import_style=commonjs,binary:jstest/ --grpc-web_out=import_style=commonjs+dts,mode=grpcweb:jstest --proto_path protos
  // read pubspec.yaml and get embedding.host_handover_proto_paths and embedding.embedding_handover_proto_paths
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

Future<void> updateGrpcWebHandoverServices(bool verbose, String outputPath) async {
  // update proto services
  //protoc --js_out=jstest/  --proto_path protos
  //protoc --js_out=jstest/  --ts_opt=server_grpc1 --proto_path protos
  // read pubspec.yaml and get embedding.host_handover_proto_paths and embedding.embedding_handover_proto_paths
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
