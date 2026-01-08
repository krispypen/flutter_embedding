import 'dart:convert';
import 'dart:io';

Future<void> runCommand(String command, List<String> arguments, bool verbose, {String directory = '.'}) async {
  if (verbose) {
    print('> Executing: $command ${arguments.join(' ')}');
  }

  final process =
      await Process.start(command, arguments, workingDirectory: directory, environment: Platform.environment);

  final StringBuffer output = StringBuffer();

  // Listen to stdout and print in real-time with proper UTF-8 decoding
  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (verbose) {
      print(line);
    } else {
      output.writeln(line);
    }
  });

  // Listen to stderr and print in real-time with proper UTF-8 decoding
  process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
    if (verbose) {
      stderr.writeln(line);
    } else {
      output.writeln(line);
    }
  });

  // Wait for the process to complete
  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    print('Process exited with code: $exitCode');
    print('Command: $command ${arguments.join(' ')}');
    print('Directory: $directory');
    if (!verbose) {
      print('To get more details, run with the --verbose flag');
      print(output.toString());
    }
    exit(exitCode);
  }
}
