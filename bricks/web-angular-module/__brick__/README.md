# Flutter Angular Embedding Module

An Angular module for embedding Flutter web applications with TypeScript support.

## Installation

```bash
npm install {{webAngularPackageName}}
```

## Peer Dependencies

This module requires the following peer dependencies:

```bash
npm install @angular/core @angular/common @protobuf-ts/runtime-rpc
```

## Usage

### Basic Usage

```typescript
import { Component } from '@angular/core';
import { FlutterEmbeddingViewComponent } from '{{webAngularPackageName}}';
import { FlutterEmbeddingState, MyRpcTransport } from '{{webAngularPackageName}}';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [FlutterEmbeddingViewComponent],
  template: `
    <flutter-embedding-view
      [onInvokeHandover]="handleInvokeHandover"
      [handoverServices]="[]"
      [initState]="handleInitState"
      className="my-flutter-view"
    ></flutter-embedding-view>
  `
})
export class AppComponent {
  handleInvokeHandover = (method: string, args: unknown): string => {
    console.log('Invoke handover:', method, args);
    return '';
  }

  handleInitState = (state: FlutterEmbeddingState, rpcTransport: MyRpcTransport) => {
    console.log('Flutter state initialized', state);
    state.changeLanguage('en');
    state.changeThemeMode('light');
  }
}
```

### Using with FlutterEmbeddingModule

```typescript
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FlutterEmbeddingModule } from '{{webAngularPackageName}}';

@NgModule({
  imports: [
    BrowserModule,
    FlutterEmbeddingModule
  ],
  // ...
})
export class AppModule { }
```

### Using the Service Directly

```typescript
import { Component, OnInit } from '@angular/core';
import { FlutterEmbeddingService } from '{{webAngularPackageName}}';

@Component({
  selector: 'app-root',
  template: '<div>Flutter App</div>'
})
export class AppComponent implements OnInit {
  constructor(private flutterService: FlutterEmbeddingService) {}

  async ngOnInit() {
    await this.flutterService.startEngine();
  }
}
```

## API Reference

### FlutterEmbeddingViewComponent

#### Inputs

| Input | Type | Required | Description |
|------|------|----------|-------------|
| `onInvokeHandover` | `(method: string, args: unknown) => string` | Yes | Callback function for handling handover invocations |
| `handoverServices` | `HandoverServiceTuple[]` | Yes | Array of handover service tuples |
| `initState` | `(state: FlutterEmbeddingState, rpcTransport: MyRpcTransport) => void` | Yes | Callback function called when Flutter state is initialized |
| `className` | `string` | No | Optional CSS class name for styling |

### FlutterEmbeddingService

#### Methods

- `startEngine(): Promise<any>` - Initializes and starts the Flutter engine
- `getFlutterApp(): any` - Returns the current Flutter app instance

### Types

```typescript
interface FlutterEmbeddingApp {
  addView: (options: { hostElement: HTMLElement | null }) => number;
  removeView: (viewId: number) => void;
}

interface FlutterEmbeddingState {
  onExit: (callback: () => void) => void;
  onInvokeHandover: (callback: (method: string, args: unknown) => string) => void;
  onInvokeHandoverGRPC: (callback: (serviceName: string, method: string, data: Uint8Array) => Promise<Uint8Array | null>) => void;
  changeLanguage: (language: string) => void;
  changeThemeMode: (themeMode: string) => void;
  invokeHandover: (method: string, args: string) => void;
  invokeHandoverMap: (serviceName: string, method: string, data: Uint8Array) => void;
}

interface HandoverServiceTuple {
  service: ServiceType;
  instance: object;
}
```

## Features

- ✅ TypeScript support with full type definitions
- ✅ Angular Material integration for consistent styling
- ✅ Language and theme mode switching
- ✅ Handover communication between Angular and Flutter
- ✅ Responsive design with customizable styling
- ✅ Loading state with progress spinner
- ✅ Clean component lifecycle management
- ✅ Standalone component support (Angular 14+)
- ✅ Injectable service for engine management

## Development

To build the module:

```bash
npm run build
```

## License

ISC

