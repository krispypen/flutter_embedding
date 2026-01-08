# Flutter React Embedding Module

A React module for embedding Flutter web applications with TypeScript support.

## Installation

```bash
npm install {{webReactPackageName}}
```

## Peer Dependencies

This module requires the following peer dependencies:

```bash
npm install react react-dom @mui/material @emotion/react @emotion/styled
```

## Usage

### Basic Usage

```tsx
import React, { useState } from 'react';
import { FlutterView } from '{{webReactPackageName}}';

function App() {
  const [showFlutter, setShowFlutter] = useState(false);
  const [language, setLanguage] = useState('en');
  const [themeMode, setThemeMode] = useState('light');

  // Initialize your Flutter app
  const flutterApp = {
    addView: (options: { hostElement: HTMLElement | null }) => {
      // Your Flutter app initialization logic
      return 1; // Return view ID
    },
    removeView: (viewId: number) => {
      // Your Flutter app cleanup logic
    }
  };

  return (
    <div>
      <button onClick={() => setShowFlutter(!showFlutter)}>
        Toggle Flutter View
      </button>
      
      {showFlutter && (
        <FlutterView
          flutterApp={flutterApp}
          removeView={() => setShowFlutter(false)}
          currentLanguage={language}
          currentThemeMode={themeMode}
          className="my-flutter-view"
        />
      )}
    </div>
  );
}
```

### Advanced Usage with Custom Styling

```tsx
import React from 'react';
import { FlutterView, ViewWrapper } from '{{webReactPackageName}}';

function CustomFlutterApp() {
  const flutterApp = {
    // Your Flutter app instance
  };

  return (
    <div>
      <FlutterView
        flutterApp={flutterApp}
        removeView={() => console.log('Flutter view removed')}
        currentLanguage="en"
        currentThemeMode="dark"
        className="custom-flutter-container"
      />
      
      {/* Or use ViewWrapper separately for custom styling */}
      <ViewWrapper 
        className="my-custom-wrapper"
        removeView={() => console.log('View removed')}
      >
        <div>Your custom content here</div>
      </ViewWrapper>
    </div>
  );
}
```

## API Reference

### FlutterView Props

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `flutterApp` | `FlutterApp` | Yes | The Flutter app instance with addView and removeView methods |
| `removeView` | `() => void` | Yes | Callback function called when the view should be removed |
| `currentLanguage` | `string` | Yes | Current language code (e.g., 'en', 'es', 'fr') |
| `currentThemeMode` | `string` | Yes | Current theme mode ('light' or 'dark') |
| `className` | `string` | No | Optional CSS class name for styling |

### ViewWrapper Props

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `children` | `React.ReactNode` | Yes | Child components to render inside the wrapper |
| `removeView` | `() => void` | Yes | Callback function called when the view should be removed |
| `className` | `string` | No | Optional CSS class name for styling |

### Types

```tsx
interface FlutterApp {
  addView: (options: { hostElement: HTMLElement | null }) => number;
  removeView: (viewId: number) => void;
}

interface FlutterState {
  onExit: (callback: () => void) => void;
  onInvokeHandover: (callback: (method: string, args: any) => string) => void;
  changeLanguage: (language: string) => void;
  changeThemeMode: (themeMode: string) => void;
  invokeHandover: (method: string, args: string) => void;
}
```

## Features

- ✅ TypeScript support with full type definitions
- ✅ Material-UI integration for consistent styling
- ✅ Language and theme mode switching
- ✅ Handover communication between React and Flutter
- ✅ Responsive design with customizable styling
- ✅ Loading state with progress indicator
- ✅ Clean component lifecycle management

## Development

To build the module:

```bash
npm run build
```

## License

ISC
