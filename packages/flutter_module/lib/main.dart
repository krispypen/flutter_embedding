import 'package:flutter/material.dart';
import 'package:flutter_embedding/flutter_embedding.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  final embeddingController = EmbeddingController.fromArgs(args);

  runApp(MyApp(embeddingController));
}

class MyApp extends StatelessWidget {
  const MyApp(this.embeddingController, {super.key});

  final EmbeddingController embeddingController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: embeddingController.themeMode,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder(
          valueListenable: embeddingController.language,
          builder: (context, language, child) {
            return MaterialApp(
              title: 'Flutter Demo',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              darkTheme: ThemeData.dark(),
              themeMode: embeddingController.themeMode.value,
              home: MyHomePage(title: 'Flutter Demo Home Page $language', embeddingController: embeddingController),
            );
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.embeddingController});
  final EmbeddingController embeddingController;

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    widget.embeddingController.addHandoverHandler('handoverDemo', (args) async {
      // short alert
      showDialog(
        context: context,
        builder: (context) => AlertDialog(title: Text('Received handover'), content: Text('Data: $args')),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Youu have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
            ElevatedButton(
              onPressed: () => widget.embeddingController.invokeHandover(
                'handoverDemo',
                arguments: {'message': 'Hello from Flutter Module'},
              ),
              child: const Text('Say Hello'),
            ),
            ElevatedButton(onPressed: widget.embeddingController.exit, child: const Text('Exit')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
