# Flutter Embedding

A comprehensive solution for embedding Flutter modules into native iOS, Android, and React Native applications with seamless bidirectional communication capabilities.

## Overview

This repository contains everything you need to integrate Flutter modules into existing native mobile applications. It provides a Flutter plugin, a CLI tool for generating platform-specific modules, and example applications for each supported platform.

## 🚀 Features

- **Cross-platform Support**: Works with iOS, Android, and React Native applications
- **Bidirectional Communication**: Send data between Flutter and native code in both directions
- **Theme Management**: Runtime dynamic theme switching (light/dark/system)
- **Language Support**: Runtime language switching capabilities
- **Environment Configuration**: Support for multiple environments
- **React Native Compatibility**: Includes workarounds for React Native layout issues
- **Easy Integration**: Simple setup with minimal configuration required

## 📦 Packages

This repository contains three main packages:

### 1. [flutter_embedding](./packages/flutter_embedding/)
The core Flutter plugin that provides the embedding functionality and communication bridge between Flutter and native code.

**Key Features:**
- Bidirectional communication with native apps
- Dynamic theme and language switching
- React Native layout compatibility
- Environment configuration support

### 2. [flutter_embedding_cli](./packages/flutter_embedding_cli/)
A command-line tool for generating platform-specific modules and example applications.

**Supported Platforms:**
- iOS (with CocoaPods support)
- Android (with AAR generation)
- React Native (with npm package generation)

### 3. [flutter_module](./packages/flutter_module/)
A demo Flutter module that showcases the embedding capabilities.

## 🏗️ Project Structure

```
flutter_embedding/
├── packages/
│   ├── flutter_embedding/          # Core Flutter plugin
│   ├── flutter_embedding_cli/      # CLI tool for module generation
│   └── flutter_module/             # Demo Flutter module
├── bricks/                         # Mason brick templates
│   ├── android-example/            # Android example template
│   ├── ios-example/                # iOS example template
│   ├── react-native-example/       # React Native example template
│   └── react-native-module/        # React Native module template
└── README.md                       # This file
```

## 📚 Documentation

- [Flutter Embedding Plugin Documentation](./packages/flutter_embedding/README.md)
- [CLI Tool Documentation](./packages/flutter_embedding_cli/README.md)
- [Flutter Module Documentation](./packages/flutter_module/README.md)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in this repository
- Check the documentation in each package directory
- Review the example applications for implementation details

---

**Made with ❤️ by [Krispypen](https://krispypen.be/)**
