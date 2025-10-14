# Flutter Embedding Plugin

A Flutter plugin that enables seamless embedding of Flutter modules into native iOS and Android applications with bidirectional communication capabilities. This can also be used to embed Flutter modules into React Native applications.

## flutter_embedding_cli

[flutter_embedding_cli](https://pub.dev/packages/flutter_embedding_cli) is not required but recommended to generate the module and example applications.

## Screenshot

![Screenshot](https://raw.githubusercontent.com/krispypen/flutter_embedding/main/assets/demo.gif)

## Features

- **Bidirectional Communication**: Send data between Flutter and native code in both directions (called handover events)
- **Switch theme mode**: Sent at startup and can be changed at runtime, supports light/dark/system
- **Switch language**: Sent at startup and can be changed at runtime, supports any language
- **Pass environment at startup**: Sent as a String at startup
- **React Native Compatibility**: Includes workarounds for React Native layout issues
- **Fragment/ViewController Management**: Easy integration with native UI components

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_embedding: ^0.0.1-beta.2
```

Then run:

```bash
fvm flutter pub get
```

## Usage

### Flutter Side

#### 1. Initialize the Embedding Controller

```dart
import 'package:flutter_embedding/flutter_embedding.dart';

void main(List<String> args) {
  // Initialize the embedding controller with configuration
  final embeddingController = EmbeddingController.fromArgs(args);
  
  runApp(MyApp(embeddingController: embeddingController));
}
```

#### 2. Listen to Native Events

```dart
class MyApp extends StatelessWidget {
  final EmbeddingController embeddingController;
  
  const MyApp({Key? key, required this.embeddingController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: embeddingController.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          themeMode: themeMode,
          home: MyHomePage(embeddingController: embeddingController),
        );
      },
    );
  }
}
```

#### 3. Handle Custom Handover Events

```dart
// Add handlers for custom events from native side
embeddingController.addHandoverHandler('resetCounter', (args, _) async {
  // Handle the reset counter event
  print('Counter reset with value: ${args['counter']}');
  return true;
});

embeddingController.addHandoverHandler('updateUserData', (args, _) async {
  // Handle user data update
  final userData = args['userData'] as Map<String, dynamic>;
  // Update your app state
  return true;
});
```

#### 4. Send Events to Native Side

```dart
// Send data to native side
await embeddingController.invokeHandover('userAction', arguments: {
  'action': 'buttonPressed',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});

// Exit back to native app
embeddingController.exit();
```

#### 5. React Native Compatibility

If you have issues with platform widgets (like WebView, MapView, etc.) in React Native which show without width and height, wrap them with the provided wrapper to ensure the React Native LayoutManager can properly layout them. The widget itself will only do something on Android.

```dart
import 'package:flutter_embedding/rn_native_component_wrapper.dart';

Widget build(BuildContext context) {
  return RnNativeComponentWrapper(
    child: YourFlutterWidget(),
  );
}
```

### Native Side

#### Android

```java
import be.krispypen.plugins.flutter_embedding.FlutterEmbedding;
import be.krispypen.plugins.flutter_embedding.HandoverResponderInterface;

public class MainActivity extends FragmentActivity implements HandoverResponderInterface {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Start the Flutter engine
        FlutterEmbedding.instance().startEngine(
            this,
            "PROD",           // environment
            "en",             // language
            "system",         // theme mode
            this,             // handover responder
            (success, error) -> {
                if (success) {
                    // Engine started successfully
                    showFlutterFragment();
                } else {
                    // Handle error
                    Log.e("FlutterEmbedding", "Failed to start engine", error);
                }
            }
        );
    }
    
    private void showFlutterFragment() {
        // Get or create the Flutter fragment
        FlutterEmbeddingFlutterFragment fragment = FlutterEmbedding.instance()
            .getOrCreateFragment(this, R.id.flutter_container);
    }
    
    // Implement HandoverResponderInterface
    @Override
    public void exit() {
        // Handle exit from Flutter
        finish();
    }
    
    @Override
    public void invokeHandover(String method, Map<String, Object> data, 
                              CompletionHandler<Object> completion) {
        // Handle custom events from Flutter
        switch (method) {
            case "userAction":
                // Handle user action
                completion.onSuccess("Action processed");
                break;
            default:
                completion.onFailure(new Exception("Unknown method: " + method));
        }
    }
}
```

#### iOS

```swift
import flutter_embedding

class ViewController: UIViewController, HandoverResponderProtocol {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start the Flutter engine
        FlutterEmbedding.shared.startEngine(
            forEnv: "PROD",
            forLanguage: "en", 
            forThemeMode: "system",
            with: self
        ) { success, error in
            if success == true {
                // Engine started successfully
                self.showFlutterView()
            } else {
                // Handle error
                print("Failed to start Flutter engine: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func showFlutterView() {
        do {
            let flutterViewController = try FlutterEmbedding.shared.getViewController()
            addChild(flutterViewController)
            view.addSubview(flutterViewController.view)
            flutterViewController.view.frame = view.bounds
            flutterViewController.didMove(toParent: self)
        } catch {
            print("Failed to get Flutter view controller: \(error)")
        }
    }
    
    // Implement HandoverResponderProtocol
    func exit() {
        // Handle exit from Flutter
        dismiss(animated: true)
    }
    
    func invokeHandover(withName name: String, data: [String : Any?], 
                       completion: @escaping (Any?, FlutterEmbeddingError?) -> Void) {
        // Handle custom events from Flutter
        switch name {
        case "userAction":
            // Handle user action
            completion("Action processed", nil)
        default:
            completion(nil, FlutterEmbeddingError.genericError(
                code: "UNKNOWN_METHOD", 
                message: "Unknown method: \(name)"
            ))
        }
    }
}
```

## Configuration

### Environment Support

You can pass the environment name when initializing the engine.

### Theme Modes

You can pass the theme mode when initializing the engine but it will also be dynamic and can be changed from the native side. Supported theme modes:
- `light` - Light theme
- `dark` - Dark theme
- `system` - Follow system theme

### Language Support

The plugin supports dynamic language switching. Pass the language code (e.g., "en", "nl", "fr") when initializing the engine.

## Flutter API Reference

### EmbeddingController

The main controller class for managing Flutter embedding functionality.

#### Methods

- `EmbeddingController.fromArgs(List<String> args)` - Create controller from command line arguments
- `addHandoverHandler(String method, Handler handler)` - Add handler for native events
- `invokeHandover(String method, {Map<String, dynamic> arguments})` - Send event to native side
- `exit()` - Exit back to native application

#### Properties

- `environment` - Current environment (String)
- `themeMode` - Current theme mode (ValueNotifier<ThemeMode>)
- `language` - Current language (ValueNotifier<String>)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
