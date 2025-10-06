import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_embedding/flutter_embedding.dart';

/// Wrap this widget around a native component to ensure it is properly laid out when it is rendered in React Native.
///
/// This is because React Native has a bug where it doesn't properly layout the component when it is rendered in a
/// Flutter app.
///
/// This is a workaround to ensure the component is properly laid out when it is rendered in React Native.
///
/// See https://github.com/facebook/react-native/issues/17968 for more details.
///
/// Example:
/// ```dart
/// RnNativeComponentWrapper(child: MyNativeComponent());
/// ```

class RnNativeComponentWrapper extends StatelessWidget {
  /// The native component to wrap.
  final Widget child;

  /// Creates a new [RnNativeComponentWrapper] widget.
  const RnNativeComponentWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (kIsWeb || kIsWasm || !Platform.isAndroid) {
        return child;
      }
      // a bug in react native requires the layout to be done manually https://github.com/facebook/react-native/issues/17968
      WidgetsBinding.instance.addPostFrameCallback((_) {
        const OptionalMethodChannel(embeddingChannelName).invokeMethod('internalRequestLayout');
        // wait 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          const OptionalMethodChannel(embeddingChannelName).invokeMethod('internalRequestLayout');
        });
      });

      return child;
    });
  }
}
