import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_embedding/flutter_embedding.dart';
import 'package:flutter_embedding/flutter_embedding_shared.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:protobuf/protobuf.dart';
import 'package:web/web.dart';

void broadcastAppEvent(int viewId, String name, JSObject data) {
  final HTMLElement? root = ui_web.views.getHostElement(viewId) as HTMLElement?;
  assert(root != null, 'Flutter root element cannot be found!');

  final eventDetails = CustomEventInit(detail: data);
  eventDetails.bubbles = true;
  eventDetails.composed = true;

  root!.dispatchEvent(CustomEvent(name, eventDetails));
}

class EmbeddingController {
  // TODO make something abstract here to share with the IO version
  WebInteropStateManager? stateManager;
  Map<String, List<Handler>> handoverHandlers = {};

  Completer<Map<String, dynamic>> startConfig = Completer<Map<String, dynamic>>();
  EmbeddingController(List<String> args);

  static EmbeddingController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EmbeddingControllerInheritedWidget>()!.embeddingController;
  }

  Future<Map<String, dynamic>> getStartConfig() {
    return startConfig.future;
  }

  void init(WebInteropStateManager stateManager) {
    this.stateManager = stateManager;
  }

  void addHandoverHandler(String method, Handler handler) {
    print('adding a HandoverHandler: $method');
    final handlers = handoverHandlers[method];
    if (handlers != null) {
      handlers.add(handler);
    } else {
      handoverHandlers[method] = [handler];
    }
    /*return () {
      handoverHandlers[method]?.remove(handler);
    };*/
  }

  Future<Object?> invokeHandoverInternal(String method, {Map<String, dynamic> arguments = const {}}) {
    print('invokeHandoverInternal: $method $arguments');
    final handlers = handoverHandlers[method];
    if (handlers != null) {
      for (final handler in handlers) {
        return Future.value(handler(arguments));
      }
    }
    return Future.value(null);
  }

  Future<String?> invokeHandover(String method, {Map<String, dynamic> arguments = const {}}) {
    return stateManager?.invokeHandoverToExternal(method, arguments: arguments) ?? Future.value(null);
  }

  void addEmbeddingHandoverService(Service service) {
    addHandoverHandler(service.$name, (args) async {
      final serviceMethod = service.$lookupMethod(args['method'] as String);
      final request = serviceMethod?.requestDeserializer(args['request'] as List<int>);
      print('request: $request');
      final response = await serviceMethod?.handle(DummyServiceCall(), Stream.value(request), []).first;
      return response?.writeToBuffer();
    });
  }

  EmbeddingMethodClientChannel handoverChannel() {
    return EmbeddingMethodClientChannel(stateManager!);
  }
}

class EmbeddingMethodClientChannel extends ClientChannelBase {
  EmbeddingMethodClientChannel(this.stateManager) : super();
  final WebInteropStateManager stateManager;

  @override
  ClientCall<Q, R> createCall<Q, R>(ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options) {
    final call = MyClientCall<Q, R>(
      method,
      requests,
      options,
    );
    // do the call
    requests.first.then((request) {
      stateManager
          .invokeHandoverToExternalGRPC(
              method.path.split('/')[1], method.path.split('/')[2], (request as GeneratedMessage).writeToBuffer().toJS)
          .then((response) {
        final responseData = method.responseDeserializer(response!.toDart);
        call.setResponse(responseData);
      });
    });
    return call;
  }

  @override
  ClientConnection createConnection() {
    throw UnimplementedError();
  }
}

/// This is the bit of state that JS is able to see.
///
/// It contains getters/setters/operations and a mechanism to
/// subscribe to change notifications from an incoming [notifier].
@JSExport()
class WebInteropStateManager {
  WebInteropStateManager({
    required int viewId,
    required EmbeddingController interactionEmbeddingController,
  }) : _interactionEmbeddingController = interactionEmbeddingController;

  final EmbeddingController _interactionEmbeddingController;

  Future<String?> Function(String, Map<String, dynamic>)? _onInvokeHandover;
  JSPromise<JSUint8Array?> Function(String, String, JSUint8Array)? _onInvokeHandoverGRPC;

  void setStartConfig(String startConfig) {
    print('setStartConfig: $startConfig');
    _interactionEmbeddingController.startConfig.complete(jsonDecode(startConfig));
  }

  void onInvokeHandover(Future<String?> Function(String, Map<String, dynamic>) f) {
    _onInvokeHandover = f;
  }

  void onInvokeHandoverGRPC(JSPromise<JSUint8Array?> Function(String, String, JSUint8Array) f) {
    _onInvokeHandoverGRPC = f;
  }

  Future<String?> invokeHandover(String method, String arguments) async {
    return _interactionEmbeddingController.invokeHandoverInternal(method, arguments: jsonDecode(arguments))
        as Future<String?>;
  }

  JSPromise<JSAny?> invokeHandoverMap(String serviceName, String method, JSUint8Array data) {
    final response = _interactionEmbeddingController.invokeHandoverInternal(serviceName,
        arguments: {'request': data, 'method': method, 'serviceName': serviceName});
    // convert to JS
    return response.then((resp) => (resp as Uint8List).toJS).toJS;
  }

  Future<String?> invokeHandoverToExternal(String method, {Map<String, dynamic> arguments = const {}}) async {
    if (_onInvokeHandover == null) {
      return null;
    }
    final t = await _onInvokeHandover!(method, arguments);
    return t?.toString();
  }

  Future<JSUint8Array?> invokeHandoverToExternalGRPC(String serviceName, String method, JSUint8Array data) async {
    if (_onInvokeHandoverGRPC == null) {
      return null;
    }
    final t = await _onInvokeHandoverGRPC!(serviceName, method, data).toDart;
    return t;
  }
}

class EmbeddingWrapper extends StatefulWidget {
  final Widget child;
  final EmbeddingController embeddingController;
  const EmbeddingWrapper({super.key, required this.child, required this.embeddingController});
  @override
  State<EmbeddingWrapper> createState() => _EmbeddingWrapperState();
}

class _EmbeddingWrapperState extends State<EmbeddingWrapper> {
  late WebInteropStateManager _state;

  @override
  void initState() {
    if (kIsWeb || kIsWasm) {
      _state = WebInteropStateManager(
          viewId: View.of(context).viewId, interactionEmbeddingController: widget.embeddingController);
      widget.embeddingController.init(_state);
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (kIsWeb || kIsWasm) {
      final export = createJSInteropWrapper(_state);
      final int viewId = View.of(context).viewId;

      // Emit this through the root object of the flutter app :)
      broadcastAppEvent(viewId, 'flutter-initialized', export);
    }
    super.didChangeDependencies();
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
