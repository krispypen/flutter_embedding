import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FlutterEmbeddingViewComponent } from './src/flutter-embedding-view.component';
import { FlutterEmbeddingApp, FlutterEmbeddingState, MyRpcTransport } from './src';
import { FlutterEmbeddingService } from './src/flutter-embedding.service';

// Example usage of the Flutter Angular Embedding Module
@Component({
    selector: 'app-example',
    standalone: true,
    imports: [CommonModule, FlutterEmbeddingViewComponent],
    template: `
        <div style="padding: 20px;">
            <h1>Flutter Angular Embedding Example</h1>

            <div style="margin-bottom: 20px;">
                <button
                    (click)="toggleFlutter()"
                    style="margin-right: 10px;"
                >
                    {{ showFlutter ? 'Hide' : 'Show' }} Flutter View
                </button>

                <select
                    [value]="language"
                    (change)="onLanguageChange($event)"
                    style="margin-right: 10px;"
                >
                    <option value="en">English</option>
                    <option value="es">Spanish</option>
                    <option value="fr">French</option>
                </select>

                <select
                    [value]="themeMode"
                    (change)="onThemeModeChange($event)"
                >
                    <option value="light">Light</option>
                    <option value="dark">Dark</option>
                </select>
            </div>

            <div *ngIf="showFlutter" style="height: 600px;">
                <flutter-embedding-view
                    [onInvokeHandover]="handleInvokeHandover"
                    [handoverServices]="[]"
                    [initState]="handleInitState"
                    className="example-flutter-view"
                ></flutter-embedding-view>
            </div>
        </div>
    `
})
export class ExampleComponent {
    showFlutter = false;
    language = 'en';
    themeMode = 'light';

    constructor(private flutterEmbeddingService: FlutterEmbeddingService) {}

    toggleFlutter() {
        this.showFlutter = !this.showFlutter;
    }

    onLanguageChange(event: Event) {
        this.language = (event.target as HTMLSelectElement).value;
    }

    onThemeModeChange(event: Event) {
        this.themeMode = (event.target as HTMLSelectElement).value;
    }

    handleInvokeHandover = (method: string, args: unknown): string => {
        console.log('Invoke handover:', method, args);
        return '';
    }

    handleInitState = (state: FlutterEmbeddingState, rpcTransport: MyRpcTransport) => {
        console.log('Flutter state initialized', state, rpcTransport);
        // You can use the state to change language, theme, etc.
        if (this.language) {
            state.changeLanguage(this.language);
        }
        if (this.themeMode) {
            state.changeThemeMode(this.themeMode);
        }
    }
}

