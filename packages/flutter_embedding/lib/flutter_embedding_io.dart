import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_embedding/flutter_embedding.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:protobuf/protobuf.dart';

import 'flutter_embedding_shared.dart';

class EmbeddingController {
  EmbeddingChannel embeddingChannel = EmbeddingChannel.instance;

  Completer<Map<String, dynamic>> startConfig = Completer<Map<String, dynamic>>();

  EmbeddingController(List<String> args) {
    if (args.isNotEmpty) {
      startConfig.complete(jsonDecode(args.first));
    } else {
      startConfig.complete({});
    }
  }

  static EmbeddingController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EmbeddingControllerInheritedWidget>()!.embeddingController;
  }

  /// Add a handler for a handover event.
  ///
  /// This is used to handle handover events coming from the native side.
  ///
  /// Example:
  /// ```dart
  /// embeddingController.addHandoverHandler('resetCounter', (args, _) async {
  ///   return true;
  /// });
  /// ```
  void addHandoverHandler(String method, Handler handler) {
    embeddingChannel.on(method, handler);
  }

  /// Invoke a handover event.
  ///
  /// This is used to invoke handover events to the native side.
  ///
  /// Example:
  /// ```dart
  /// embeddingController.invokeHandover('resetCounter', arguments: {'counter': 0});
  /// ```

  Future<String?> invokeHandover(String method, {Map<String, dynamic> arguments = const {}}) {
    return embeddingChannel.invoke(method, data: arguments);
  }

  // This is used to go back to the native side.
  @Deprecated('Use handoversToHostService.exit() instead')
  void exit() {
    invokeHandover('exit');
  }

  void addEmbeddingHandoverService(Service service) {
    embeddingChannel.on(service.$name, (args) async {
      final serviceMethod = service.$lookupMethod(args['method'] as String);
      final request = serviceMethod!.requestDeserializer(args['request'] as List<int>);
      print('request: $request');
      print('request type: ${request.runtimeType}');
      // Create a properly typed stream using createRequestStream()
      // This preserves the generic type from ServiceMethod<Q, R>
      final sourceStream = Stream.value(request);
      final subscription = sourceStream.listen(null);
      final controller = serviceMethod.createRequestStream(subscription);
      controller.add(request);
      controller.close();

      // Call handle with the properly typed stream
      final response = await serviceMethod.handle(DummyServiceCall(), controller.stream, []).first;
      print('response: $response');
      final bytes = (response as GeneratedMessage).writeToBuffer();
      return bytes;
    });
  }

  EmbeddingMethodClientChannel handoverChannel() {
    return EmbeddingMethodClientChannel(embeddingChannel);
  }
}

class EmbeddingMethodClientChannel extends ClientChannelBase {
  EmbeddingMethodClientChannel(this.embeddingChannel) : super();
  final EmbeddingChannel embeddingChannel;

  @override
  ClientCall<Q, R> createCall<Q, R>(ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options) {
    final call = MyClientCall<Q, R>(
      method,
      requests,
      options,
    );
    // do the call
    final serviceName = method.path.split('/')[1];
    final methodName = method.path.split('/')[2];
    requests.first.then((request) {
      final requestData = (request as GeneratedMessage).writeToBuffer();
      embeddingChannel
          .invoke(serviceName, data: {'name': serviceName, 'method': methodName, 'data': requestData}).then((response) {
        try {
          final responseData = method.responseDeserializer(response!);
          call.setResponse(responseData);
        } catch (e, stackTrace) {
          debugPrint('error: $e');
          debugPrint('stackTrace: $stackTrace');
        }
      });
    });
    return call;
  }

  @override
  ClientConnection createConnection() {
    throw UnimplementedError();
  }
}

class EmbeddingChannelGrpcTransportStream extends GrpcTransportStream {
  EmbeddingChannelGrpcTransportStream();

  StreamController<GrpcMessage> _incomingMessages = StreamController<GrpcMessage>.broadcast();
  StreamController<List<int>> _outgoingMessages = StreamController<List<int>>.broadcast();

  add(GrpcMessage message) {
    _incomingMessages.add(message);
  }

  @override
  Stream<GrpcMessage> get incomingMessages => _incomingMessages.stream;

  @override
  StreamSink<List<int>> get outgoingMessages => _outgoingMessages.sink;

  @override
  Future<void> terminate() {
    _incomingMessages.close();
    _outgoingMessages.close();
    return Future.value();
  }
}

/*class EmbeddingChannelClientConnection extends ClientConnection {
  final EmbeddingChannel embeddingChannel;

  EmbeddingChannelClientConnection(this.embeddingChannel);

  @override
  String get authority => '';

  @override
  String get scheme => '';

  @override
  void dispatchCall(ClientCall call) {
    call.onConnectionReady(this);
  }

  @override
  GrpcTransportStream makeRequest(
    String path,
    Duration? timeout,
    Map<String, String> metadata,
    ErrorHandler onRequestFailure, {
    required CallOptions callOptions,
  }) {
    final resp = EmbeddingChannelGrpcTransportStream();
    embeddingChannel.invoke(path, data: metadata).then((response) {
      response.forEach((element) {
        resp.add(element);
      });
      resp.terminate();
    });
    return resp;
  }

  @override
  set onStateChanged(_) {}

  @override
  Future<void> shutdown() {
    // TODO: implement shutdown
    throw UnimplementedError();
  }

  @override
  Future<void> terminate() {
    // TODO: implement terminate
    throw UnimplementedError();
  }
}*/

class EmbeddingWrapper extends StatefulWidget {
  final Widget child;
  final EmbeddingController embeddingController;
  const EmbeddingWrapper({super.key, required this.child, required this.embeddingController});
  @override
  State<EmbeddingWrapper> createState() => _EmbeddingWrapperState();
}

class _EmbeddingWrapperState extends State<EmbeddingWrapper> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class EmbeddingControllerInheritedWidget extends InheritedWidget {
  final EmbeddingController embeddingController;
  const EmbeddingControllerInheritedWidget({super.key, required this.embeddingController, required super.child});

  @override
  bool updateShouldNotify(EmbeddingControllerInheritedWidget oldWidget) {
    return oldWidget.embeddingController != embeddingController;
  }
}
