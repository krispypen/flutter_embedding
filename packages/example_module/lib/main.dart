import 'package:counter_embedding/counter_embedding.dart' hide ThemeMode;
import 'package:flutter/material.dart';
import 'package:flutter_embedding/flutter_embedding.dart';
import 'package:grpc/grpc.dart' hide ConnectionState;

void main(List<String> args) {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details); // Prints the standard, detailed Flutter error
  };

  runFlutterEmbeddingApp(MyApp(), () => FlutterModuleEmbeddingController(args));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  HandoversToFlutterService? handoversToFlutterService;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FlutterModuleEmbeddingController.of(context).getStartParams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (handoversToFlutterService == null) {
          handoversToFlutterService = HandoversToFlutterService(snapshot.data!);
          EmbeddingController.of(context).addEmbeddingHandoverService(handoversToFlutterService!);
        }
        return ValueListenableBuilder(
          valueListenable: handoversToFlutterService!.themeMode,
          builder: (context, themeMode, child) {
            return ValueListenableBuilder(
              valueListenable: handoversToFlutterService!.language,
              builder: (context, language, child) {
                return MaterialApp(
                  title: 'Flutter Demo',
                  theme: ThemeData(primarySwatch: Colors.blue),
                  darkTheme: ThemeData.dark(),
                  themeMode: themeMode,
                  home: MyHomePage(
                    title: 'Flutter Demo $language',
                    handoversToFlutterService: handoversToFlutterService!,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class HandoversToFlutterService extends HandoversToFlutterServiceBase {
  late ValueNotifier<Language> language;
  late ValueNotifier<ThemeMode> themeMode;
  List<Function()> resetCallbacks = [];

  HandoversToFlutterService(StartParams startParams) {
    language = ValueNotifier(startParams.language);
    themeMode = ValueNotifier(switch (startParams.themeMode.name) {
      'THEME_MODE_LIGHT' => ThemeMode.light,
      'THEME_MODE_DARK' => ThemeMode.dark,
      'THEME_MODE_SYSTEM' => ThemeMode.system,
      _ => throw Exception('Invalid theme mode: ${startParams.themeMode.name}'),
    });
  }
  @override
  Future<ChangeLanguageResponse> changeLanguage(ServiceCall call, ChangeLanguageRequest request) async {
    language.value = request.language;
    return ChangeLanguageResponse(success: true);
  }

  @override
  Future<ChangeThemeModeResponse> changeThemeMode(ServiceCall call, ChangeThemeModeRequest request) async {
    themeMode.value = switch (request.themeMode.name) {
      'THEME_MODE_LIGHT' => ThemeMode.light,
      'THEME_MODE_DARK' => ThemeMode.dark,
      'THEME_MODE_SYSTEM' => ThemeMode.system,
      _ => ThemeMode.system,
    };
    return ChangeThemeModeResponse(success: true);
  }

  @override
  Future<ResetResponse> reset(ServiceCall call, ResetRequest request) async {
    for (var callback in resetCallbacks) {
      callback();
    }
    return ResetResponse(success: true);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.handoversToFlutterService});

  final String title;
  final HandoversToFlutterService handoversToFlutterService;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Future<GetHostInfoResponse?>? _hostInfoFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final embeddingController = FlutterModuleEmbeddingController.of(context);
      widget.handoversToFlutterService.resetCallbacks.add(() {
        setState(() {
          _counter = 0;
        });
      });
      _hostInfoFuture = embeddingController.handoversToHostService.getHostInfo(GetHostInfoRequest());
    }
  }

  @override
  Widget build(BuildContext context) {
    final embeddingController = FlutterModuleEmbeddingController.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder(
              future: _hostInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return Text('I\'m a flutter app running inside a ${snapshot.data?.framework} app');
              },
            ),
            const Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
            ElevatedButton(
              onPressed: () async {
                final resp = await embeddingController.handoversToHostService.exit(ExitRequest(counter: _counter));
                print('Exit response: $resp');
              },
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resp = await embeddingController.handoversToHostService.getIncrement(GetIncrementRequest());
          setState(() {
            _counter += resp.increment;
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
