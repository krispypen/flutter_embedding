// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_embedding/flutter_embedding_shared.dart';
import 'package:flutter_module/embedding/handovers/handovers_to_flutter_service.pb.dart';
import 'package:flutter_module/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/protobuf.dart';

void main() {
  test('test', () async {
    final args = {
      'method': 'changeThemeMode',
      'request': [8, 1],
    };
    final service = HandoversToFlutterService(StartParams());
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
    print('bytes: $bytes');
  });
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
