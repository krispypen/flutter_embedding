import 'dart:convert';
import 'dart:io';

/// Whether to use fvm (Flutter Version Manager) when invoking flutter/dart/protoc.
///
/// When true, commands are invoked via `fvm` (e.g. `fvm flutter ...`,
/// `fvm exec protoc ...`). When false, the underlying tools are invoked directly.
bool useFVM = false;

/// Runs a `flutter` command, optionally prefixed with `fvm` when [useFVM] is true.
Future<void> runFlutterCommand(
  List<String> arguments,
  bool verbose, {
  String directory = '.',
}) async {
  await runCommand(
    useFVM ? 'fvm' : 'flutter',
    useFVM ? ['flutter', ...arguments] : arguments,
    verbose,
    directory: directory,
  );
}

/// Runs a `protoc` command, optionally prefixed with `fvm exec` when [useFVM] is true.
Future<void> runProtocCommand(
  List<String> arguments,
  bool verbose, {
  String directory = '.',
}) async {
  await runCommand(
    useFVM ? 'fvm' : 'protoc',
    useFVM ? ['exec', 'protoc', ...arguments] : arguments,
    verbose,
    directory: directory,
  );
}

/// Exception thrown when a command execution fails.
class CommandException implements Exception {
  /// The command that was executed.
  final String command;

  /// The arguments passed to the command.
  final List<String> arguments;

  /// The directory in which the command was executed.
  final String directory;

  /// The exit code of the command.
  final int exitCode;

  /// The output captured from the command (if not in verbose mode).
  final String output;

  CommandException({
    required this.command,
    required this.arguments,
    required this.directory,
    required this.exitCode,
    required this.output,
  });

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('CommandException: Process exited with code $exitCode')
      ..writeln('Command: $command ${arguments.join(' ')}')
      ..writeln('Directory: $directory');
    if (output.isNotEmpty) {
      buffer
        ..writeln('Output:')
        ..writeln(output);
    }
    return buffer.toString();
  }
}

/// Runs a command in a subprocess.
///
/// If [verbose] is true, the command output is streamed to stdout/stderr.
/// Otherwise, output is captured and included in the exception if the command fails.
///
/// Throws [CommandException] if the command exits with a non-zero exit code.
Future<void> runCommand(
  String command,
  List<String> arguments,
  bool verbose, {
  String directory = '.',
}) async {
  if (verbose) {
    print('> Executing: $command ${arguments.join(' ')}');
  }

  final process = await Process.start(
    command,
    arguments,
    workingDirectory: directory,
    environment: Platform.environment,
  );

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
    throw CommandException(
      command: command,
      arguments: arguments,
      directory: directory,
      exitCode: exitCode,
      output: output.toString(),
    );
  }
}
