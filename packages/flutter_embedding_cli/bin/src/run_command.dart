import 'dart:convert';
import 'dart:io';

Future<void> runCommand(String command, List<String> arguments, {String directory = '.'}) async {
  print('> Executing: $command ${arguments.join(' ')}');

  final process = await Process.start(command, arguments, workingDirectory: directory);

  // Listen to stdout and print in real-time with proper UTF-8 decoding
  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    print(line);
  });

  // Listen to stderr and print in real-time with proper UTF-8 decoding
  process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    stderr.writeln(line);
  });

  // Wait for the process to complete
  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    print('Process exited with code: $exitCode');
    exit(exitCode);
  }
}
