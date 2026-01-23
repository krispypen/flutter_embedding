//{{=<% %>=}}
import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import type { ServerCallContext } from '@protobuf-ts/runtime-rpc';
import type {
  IHandoversToHostService,
} from 'counter-embedding-angular';
import {
  ChangeLanguageRequest,
  ChangeThemeModeRequest,
  ExitRequest,
  ExitResponse,
  GetHostInfoRequest,
  GetHostInfoResponse,
  GetIncrementRequest,
  GetIncrementResponse,
  HandoversToFlutterServiceClient,
  Language,
  StartParams,
  ThemeMode
} from 'counter-embedding-angular';

const ENVIRONMENTS = ['MOCK', 'TST'];

@Component({
  selector: 'app-communication-view',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
  ],
  template: `
    <div style="display: flex; flex-direction: column; gap: 16px; padding: 16px;">
      <h2>Communication Settings</h2>

      <!-- Environment Selection -->
      <mat-form-field style="width: 100%;">
        <mat-label>Select Environment:</mat-label>
        <mat-select [(ngModel)]="currentEnvironment" [disabled]="hasViews">
          <mat-option *ngFor="let env of environments" [value]="env">{{ env }}</mat-option>
        </mat-select>
      </mat-form-field>

      <!-- Increment -->
      <mat-form-field style="width: 100%;">
        <mat-label>Increment</mat-label>
        <input matInput type="number" [(ngModel)]="currentIncrement" placeholder="Enter increment value">
      </mat-form-field>

      <!-- Theme Mode -->
      <mat-form-field style="width: 100%;">
        <mat-label>Select Theme Mode:</mat-label>
        <mat-select [(ngModel)]="currentThemeMode">
          <mat-option [value]="ThemeMode.LIGHT">light</mat-option>
          <mat-option [value]="ThemeMode.DARK">dark</mat-option>
          <mat-option [value]="ThemeMode.SYSTEM">system</mat-option>
        </mat-select>
      </mat-form-field>

      <button *ngIf="hasViews" mat-raised-button color="primary" (click)="handleChangeThemeMode()" style="width: 100%;">
        changeThemeMode
      </button>

      <!-- Language -->
      <mat-form-field style="width: 100%;">
        <mat-label>Select Language:</mat-label>
        <mat-select [(ngModel)]="currentLanguage">
          <mat-option [value]="Language.EN">en</mat-option>
          <mat-option [value]="Language.FR">fr</mat-option>
          <mat-option [value]="Language.NL">nl</mat-option>
        </mat-select>
      </mat-form-field>

      <button *ngIf="hasViews" mat-raised-button color="primary" (click)="handleChangeLanguage()" style="width: 100%;">
        changeLanguage
      </button>

    </div>
  `,
  styles: []
})
export class CommunicationViewComponent {
  // Internal state
  currentEnvironment: string = 'MOCK';
  currentLanguage: Language = Language.EN;
  currentThemeMode: ThemeMode = ThemeMode.SYSTEM;
  currentIncrement: number = 1;

  // Inputs from parent
  @Input() hasViews: boolean = false;
  @Input() handoversToFlutterServiceClients: HandoversToFlutterServiceClient[] = [];
  @Input() onRemoveView?: (viewId: number) => void;

  // Expose enums and constants to template
  Language = Language;
  ThemeMode = ThemeMode;
  environments = ENVIRONMENTS;

  async handleChangeLanguage() {
    const request = ChangeLanguageRequest.create({ language: this.currentLanguage });
    for (const client of this.handoversToFlutterServiceClients) {
      try {
        await client.changeLanguage(request);
        console.log('Language changed successfully');
      } catch (error) {
        console.error('Error changing language:', error);
      }
    }
  }

  async handleChangeThemeMode() {
    const request = ChangeThemeModeRequest.create({ themeMode: this.currentThemeMode });
    for (const client of this.handoversToFlutterServiceClients) {
      try {
        await client.changeThemeMode(request);
        console.log('Theme mode changed successfully');
      } catch (error) {
        console.error('Error changing theme mode:', error);
      }
    }
  }

  createStartParams(): StartParams {
    return {
      language: this.currentLanguage,
      themeMode: this.currentThemeMode,
      environment: this.currentEnvironment
    };
  }

  createHandoversToHostService(viewId: number): IHandoversToHostService {
    const onRemoveView = this.onRemoveView;
    const self = this;

    return new class implements IHandoversToHostService {
      getHostInfo(_request: GetHostInfoRequest, _context: ServerCallContext): Promise<GetHostInfoResponse> {
        return Promise.resolve(GetHostInfoResponse.create({ framework: 'Web Angular' }));
      }

      getIncrement(_request: GetIncrementRequest, _context: ServerCallContext): Promise<GetIncrementResponse> {
        return Promise.resolve(GetIncrementResponse.create({ increment: self.currentIncrement }));
      }

      exit(request: ExitRequest, _context: ServerCallContext): Promise<ExitResponse> {
        const counter = request.counter || 0;
        console.log('Flutter app requested exit with counter:', counter);

        // Show popup with counter value
        alert(`Flutter Exit\n\nCounter: ${counter}`);

        if (onRemoveView) {
          onRemoveView(viewId);
        }
        return Promise.resolve(ExitResponse.create({ success: true }));
      }
    }();
  }
}
