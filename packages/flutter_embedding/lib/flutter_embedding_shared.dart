import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:grpc/src/shared/io_bits/io_bits.dart';

class DummyServiceCall extends ServiceCall {
  @override
  Map<String, String>? get clientMetadata => null;
  @override
  Map<String, String>? get headers => null;
  @override
  Map<String, String>? get trailers => null;
  @override
  DateTime? get deadline => null;

  @override
  // TODO: implement clientCertificate
  X509Certificate? get clientCertificate => throw UnimplementedError();

  @override
  // TODO: implement isCanceled
  bool get isCanceled => throw UnimplementedError();

  @override
  // TODO: implement isTimedOut
  bool get isTimedOut => throw UnimplementedError();

  @override
  // TODO: implement remoteAddress
  InternetAddress? get remoteAddress => throw UnimplementedError();

  @override
  void sendHeaders() {
    // TODO: implement sendHeaders
  }

  @override
  void sendTrailers({int? status, String? message}) {
    // TODO: implement sendTrailers
  }
}

class MyClientCall<Q, R> extends ClientCall<Q, R> {
  final StreamController<R> _responseController = StreamController<R>.broadcast();

  MyClientCall(super.method, super.requests, super.options) : super();

  @override
  Stream<R> get response => _responseController.stream;

  setResponse(R data) {
    _responseController.add(data);
    _responseController.close();
  }
}
