# Flutter Embedding CLI

A command-line tool for generating modules that allow embedding Flutter into native iOS, Android, or React Native (more to come later) applications. 

## Overview

This CLI tool helps developers create the necessary modules and example applications for integrating Flutter modules into existing native mobile applications. At the moment it supports three platforms: iOS, Android, and React Native.

## Installation

1. Navigate to the `flutter_embedding_cli` directory
2. Install dependencies:
   ```bash
   dart pub get
   ```

## Usage

The CLI provides a single command with multiple subcommands:

```bash
dart run flutter_embedding_cli:generate [options] <command> [arguments]
```

### Global Options

- `--help`, `-h`: Show help information and usage

### Commands

#### iOS Module Generation

Generate iOS Flutter module and optionally create an example app:

```bash
dart run flutter_embedding_cli:generate ios [--example]
```

**Options:**
- `--example`, `-e`: Generate an example iOS app alongside the module

**What it does:**
1. Builds the Flutter iOS framework with CocoaPods support
2. Generates a ZIP file of the iOS SDK
3. Creates Podspec files for CocoaPods integration
4. Generates a Pod helper file
5. If `--example` is specified, creates a complete example iOS app

**Requirements:**
- You need to run this in a flutter module project. (The `pubspec.yaml` must contain `flutter.module.iosBundleIdentifier` configuration)

#### Android Module Generation

Generate Android Flutter module and optionally create an example app:

```bash
dart run flutter_embedding_cli:generate android [--example]
```

**Options:**
- `--example`, `-e`: Generate an example Android app alongside the module

**What it does:**
1. Builds the Flutter Android Archive (AAR)
2. If `--example` is specified, creates a complete example Android app

**Requirements:**
- You need to run this in a flutter module project. (The `pubspec.yaml` must contain `flutter.module.androidPackage` configuration)

#### React Native Module Generation

Generate React Native Flutter module and optionally create an example app:

```bash
dart run flutter_embedding_cli:generate react-native [--example]
```

**Options:**
- `--example`, `-e`: Generate an example React Native app alongside the module

**What it does:**
1. Generates the React Native module structure
2. Builds both Android AAR and iOS framework
3. Copies Flutter artifacts to the appropriate platform directories
4. Generates ZIP files and Podspecs for iOS
5. Runs npm install, ci, and pack commands (packaging the module)
6. If `--example` is specified, creates a complete example React Native app

## Configuration

### pubspec.yaml Requirements

Your Flutter module's `pubspec.yaml` must include the following configuration:

```yaml
flutter:
  module:
    androidPackage: com.yourcompany.yourapp
    iosBundleIdentifier: com.yourcompany.yourapp
```

## Output Structure

### iOS
- `build/ios/sdk/` - iOS framework and CocoaPods files
- `build/ios-example/` - Example iOS app (if `--example` flag used)

### Android
- `build/host/outputs/repo/` - Android AAR files
- `build/android-example/` - Example Android app (if `--example` flag used)

### React Native
- `build/flutter-rn-embedding/` - React Native module
- `build/react-native-example/` - Example React Native app (if `--example` flag used)

## Examples

### Generate iOS module only
```bash
dart run flutter_embedding_cli:generate ios
```

### Generate Android module with example app
```bash
dart run flutter_embedding_cli:generate android --example
```

### Generate React Native module with example app
```bash
dart run flutter_embedding_cli:generate react-native --example
```

### Show help
```bash
dart run flutter_embedding_cli:generate --help
```

## License

MIT License
