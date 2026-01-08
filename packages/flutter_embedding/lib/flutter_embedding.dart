import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'flutter_embedding_io.dart' if (dart.library.js_interop) 'flutter_embedding_web.dart';

export 'flutter_embedding_io.dart' if (dart.library.js_interop) 'flutter_embedding_web.dart';

typedef Handler = Future<Object?> Function(Map<String, dynamic> arguments);
typedef HandlerBinary = Future<Object?> Function(List<int> arguments);

const String embeddingChannelName = 'flutter_embedding/embedding';

class EmbeddingChannel {
  static final EmbeddingChannel instance = EmbeddingChannel._();

  final _platform = const MethodChannel(embeddingChannelName);
  final _nativeMessageHandlers = <String, List<Handler>>{};

  EmbeddingChannel._() {
    _platform.setMethodCallHandler(nativeMethodCallHandler);
  }

  @visibleForTesting
  Future<dynamic> nativeMethodCallHandler(MethodCall methodCall) async {
    log(
      'Received WhiteLabelModule message: ${methodCall.method} ${methodCall.arguments} ${methodCall.arguments.runtimeType}',
    );

    final nativeMessageHandlers = _nativeMessageHandlers[methodCall.method];
    if (nativeMessageHandlers != null) {
      // Cast methodCall.arguments to Map<String, dynamic> if it's a Map
      final Map<String, dynamic> arguments =
          methodCall.arguments is Map ? Map<String, dynamic>.from(methodCall.arguments as Map) : <String, dynamic>{};

      for (final handler in nativeMessageHandlers) {
        final response = await handler(arguments);
        if (response != null) {
          return response;
        }
      }
    }
  }

  VoidCallback on(String method, Handler handler) {
    final nativeMessageHandlers = _nativeMessageHandlers[method] ?? <Handler>[];
    nativeMessageHandlers.add(handler);
    _nativeMessageHandlers[method] = nativeMessageHandlers;

    return () {
      final nativeMessageHandlers = _nativeMessageHandlers[method] ?? <Handler>[];
      nativeMessageHandlers.remove(handler);
    };
  }

  Future<T?> invoke<T>(
    String method, {
    Map<String, dynamic> data = const {},
    bool withPerformanceTracing = false,
  }) async {
    try {
      final response = await _platform.invokeMethod<T>(method, data);
      return response;
    } catch (e, stackTrace) {
      log('Handover $method failed $e $stackTrace');

      rethrow;
    }
  }
}

class MultiViewWebApp extends StatefulWidget {
  const MultiViewWebApp({super.key, required this.viewBuilder});

  final WidgetBuilder viewBuilder;

  @override
  State<MultiViewWebApp> createState() => _MultiViewWebAppState();
}

class _MultiViewWebAppState extends State<MultiViewWebApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateViews();
  }

  @override
  void didUpdateWidget(MultiViewWebApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Need to re-evaluate the viewBuilder callback for all views.
    _views.clear();
    _updateViews();
  }

  @override
  void didChangeMetrics() {
    _updateViews();
  }

  Map<Object, Widget> _views = <Object, Widget>{};

  void _updateViews() {
    final Map<Object, Widget> newViews = <Object, Widget>{};
    for (final FlutterView view in WidgetsBinding.instance.platformDispatcher.views) {
      final Widget viewWidget = _views[view.viewId] ?? _createViewWidget(view);
      newViews[view.viewId] = viewWidget;
    }
    setState(() {
      _views = newViews;
    });
  }

  Widget _createViewWidget(FlutterView view) {
    return View(
      view: view,
      child: Builder(
        builder: widget.viewBuilder,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewCollection(views: _views.values.toList(growable: false));
  }
}

void runFlutterEmbeddingApp(Widget app, EmbeddingController Function() getEmbeddingController) {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb || kIsWasm) {
    runWidget(
      MultiViewWebApp(viewBuilder: (BuildContext context) {
        final embeddingController = getEmbeddingController();
        return EmbeddingWrapper(
            embeddingController: embeddingController,
            child: EmbeddingControllerInheritedWidget(embeddingController: embeddingController, child: app));
      }),
    );
  } else {
    final embeddingController = getEmbeddingController();
    runApp(EmbeddingControllerInheritedWidget(embeddingController: embeddingController, child: app));
  }
}
