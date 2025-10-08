import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef Handler = Future<Object?> Function(Map<String, dynamic> arguments);

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
    Map<String, dynamic> arguments = const {},
    bool withPerformanceTracing = false,
  }) async {
    try {
      final response = await _platform.invokeMethod<T>(method, arguments);
      return response;
    } catch (e, stackTrace) {
      log('Handover $method failed $e $stackTrace');

      rethrow;
    }
  }
}

class EmbeddingController {
  String environment = 'DEV';
  ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  ValueNotifier<String> language = ValueNotifier('en');
  EmbeddingChannel embeddingChannel = EmbeddingChannel.instance;

  EmbeddingController.fromArgs(List<String> args) {
    if (args.isNotEmpty) {
      final config = jsonDecode(args.first);
      environment = config['environment'] as String;
      final themeName = config['themeMode'] as String;
      themeMode.value = ThemeMode.values.byName(themeName);
      final languageName = config['language'] as String;
      language.value = languageName;
    }
    embeddingChannel.on('change_theme_mode', (args) async {
      themeMode.value = ThemeMode.values.byName(args['theme_mode'] as String);
      return true;
    });
    embeddingChannel.on('change_language', (args) async {
      language.value = args['language'] as String;
      return true;
    });
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
    return embeddingChannel.invoke(method, arguments: arguments);
  }

  // This is used to go back to the native side.
  void exit() {
    invokeHandover('exit');
  }
}
