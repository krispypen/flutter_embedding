import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_embedding/flutter_embedding.dart';
{{#handoversToHostServices}}
export 'handovers/{{snake_name}}.pb.dart';
import 'handovers/{{snake_name}}.pbgrpc.dart';
{{/handoversToHostServices}}
{{#handoversToFlutterServices}}
export 'handovers/{{snake_name}}.pbgrpc.dart';
import 'handovers/{{snake_name}}.pbgrpc.dart';
{{/handoversToFlutterServices}}

export 'package:grpc/grpc.dart';

import '{{moduleName}}_platform_interface.dart';

class FlutterModulePlugin {
  Future<String?> getPlatformVersion() {
    return FlutterModulePluginPlatform.instance.getPlatformVersion();
  }
}

class FlutterModuleEmbeddingController extends EmbeddingController {
  Completer<{{startParamsMessage}}> startParams = Completer<{{startParamsMessage}}>();

  FlutterModuleEmbeddingController(super.args) {
    startConfig.future.then((startConfig) {
      if (startConfig['startParams'] != null) {
        print('startParams: ${startConfig['startParams']}');
        startParams.complete({{startParamsMessage}}.fromBuffer(List<int>.from(startConfig['startParams'])));
      }
    });
  }

  Future<{{startParamsMessage}}> get{{startParamsMessage}}() {
    return startParams.future;
  }

  {{#handoversToHostServices}}
  {{type}}Client get {{name}} => {{type}}Client(handoverChannel());
  {{/handoversToHostServices}}

  static FlutterModuleEmbeddingController of(BuildContext context) {
    return EmbeddingController.of(context) as FlutterModuleEmbeddingController;
  }
}


void runFlutterModuleEmbeddingApp(List<String> args, Future<Widget> Function(BuildContext context) builder) {
  runFlutterEmbeddingApp(
    Builder(
      builder: (context) {
        return FutureBuilder<Widget>(
          future: builder(context),
          builder: (context, snapshot) => snapshot.data ?? const SizedBox.shrink(),
        );
      },
    ),
    () => FlutterModuleEmbeddingController(args),
  );
}

