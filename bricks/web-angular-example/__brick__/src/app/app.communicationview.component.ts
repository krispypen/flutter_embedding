//{{=<% %>=}}
import type {
  BottomBarItemPressedRequest,
  BottomBarItemPressedResponse,
  IHandoversToHostService,
  OnExitRequest,
  OnExitResponse,
  ProvideAccessTokenRequest,
  ProvideAccessTokenResponse,
  ProvideAnonymousAccessTokenRequest,
  ProvideAnonymousAccessTokenResponse,
  ReceiveAnalyticsEventRequest,
  ReceiveAnalyticsEventResponse,
  ReceiveDebugLogRequest,
  ReceiveDebugLogResponse,
  ReceiveErrorRequest,
  ReceiveErrorResponse,
  StartAddMoneyRequest,
  StartAddMoneyResponse,
  StartAuthorizationRequest,
  StartAuthorizationResponse,
  StartFaqRequest,
  StartFaqResponse,
  StartFundPortfolioRequest,
  StartFundPortfolioResponse,
  StartOnboardingRequest,
  StartOnboardingResponse,
  StartTransactionSigningRequest,
  StartTransactionSigningResponse
} from '<% webAngularPackageName %>';
import {
  BottomBarConfiguration,
  BottomBarItemPressedResponse as BottomBarItemPressedResponseType,
  ChangeLanguageRequest,
  ChangeThemeModeRequest,
  ExitRequest,
  ExitResponse,
  GetAccessTokenRequest,
  GetAccessTokenResponse,
  GetHostInfoRequest,
  GetHostInfoResponse,
  HandleNotificationRequest,
  HandoversToFlutterServiceClient,
  InvestSuiteNotificationData,
  Language,
  OnExitResponse as OnExitResponseType,
  ProvideAccessTokenResponse as ProvideAccessTokenResponseType,
  ProvideAnonymousAccessTokenResponse as ProvideAnonymousAccessTokenResponseType,
  ReceiveAnalyticsEventResponse as ReceiveAnalyticsEventResponseType,
  ReceiveDebugLogResponse as ReceiveDebugLogResponseType,
  ReceiveErrorResponse as ReceiveErrorResponseType,
  ResetRequest,
  StartAddMoneyResponse as StartAddMoneyResponseType,
  StartAuthorizationResponse as StartAuthorizationResponseType,
  StartFaqResponse as StartFaqResponseType,
  StartFundPortfolioResponse as StartFundPortfolioResponseType,
  StartOnboardingResponse as StartOnboardingResponseType,
  StartParams,
  StartTransactionSigningResponse as StartTransactionSigningResponseType,
  ThemeMode
} from '<% webAngularPackageName %>';
import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import type { ServerCallContext } from '@protobuf-ts/runtime-rpc';

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
    <div style="display: flex; flex-direction: column; gap: 16px;">
      <h2>Handovers:</h2>

      <!-- Environment Selection -->
      <mat-form-field style="width: 100%;">
        <mat-label>Select Environment:</mat-label>
        <mat-select [(ngModel)]="currentEnvironment" [disabled]="hasViews">
          <mat-option *ngFor="let env of environments" [value]="env">{{ env }}</mat-option>
        </mat-select>
      </mat-form-field>

      <!-- Access Token -->
      <mat-form-field style="width: 100%;">
        <mat-label>Access Token</mat-label>
        <textarea matInput [(ngModel)]="accessToken" placeholder="Paste access token here" rows="2"></textarea>
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

      <!-- Handle Notification Button -->
      <button *ngIf="hasViews" mat-raised-button color="primary" (click)="handleNotification()" style="width: 100%;">
        handleNotification (CASH_DEPOSIT_EXECUTED)
      </button>

      <!-- Reset Buttons -->
      <button *ngIf="hasViews" mat-raised-button color="primary" (click)="handleReset(false)" style="width: 100%;">
        reset
      </button>
      
      <button *ngIf="hasViews" mat-raised-button color="warn" (click)="handleReset(true)" style="width: 100%;">
        reset & clearData
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
  accessToken: string = '';
  bottomBarEnabled: boolean = false;
  bottomBarConfiguration?: BottomBarConfiguration;

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

  async handleNotification() {
    const notificationData = InvestSuiteNotificationData.create({
      id: 'demo-notification-123',
      title: 'Demo Notification',
      body: 'This is a demo notification body',
      type: 'CASH_DEPOSIT_EXECUTED',
      module: 'SELF',
      createdAt: BigInt(Date.now()),
      data: { portfolio_id: 'DEMO' }
    });

    const request = HandleNotificationRequest.create({
      notificationData: notificationData
    });

    for (const client of this.handoversToFlutterServiceClients) {
      try {
        await client.handleNotification(request);
        console.log('Handle notification called successfully');
      } catch (error) {
        console.error('Error handling notification:', error);
      }
    }
  }

  async handleReset(clearData: boolean) {
    const request = ResetRequest.create({ clearData });

    for (const client of this.handoversToFlutterServiceClients) {
      try {
        await client.reset(request);
        console.log(`Reset called with clearData=${clearData}`);
      } catch (error) {
        console.error('Error resetting:', error);
      }
    }
  }

  createStartParams(): StartParams {
    const params: StartParams = {
      language: this.currentLanguage,
      themeMode: this.currentThemeMode,
      environment: this.currentEnvironment
    };
    if (this.bottomBarConfiguration) {
      params.bottomBarConfiguration = this.bottomBarConfiguration;
    }
    return params;
  }

  createHandoversToHostService(viewId: number): IHandoversToHostService {
    const accessTokenRef = { value: this.accessToken };
    const onRemoveView = this.onRemoveView;

    return new class implements IHandoversToHostService {
      provideAccessToken(_request: ProvideAccessTokenRequest, _context: ServerCallContext): Promise<ProvideAccessTokenResponse> {
        console.log('provideAccessToken called');
        return Promise.resolve(ProvideAccessTokenResponseType.create({ accessToken: accessTokenRef.value }));
      }

      provideAnonymousAccessToken(_request: ProvideAnonymousAccessTokenRequest, _context: ServerCallContext): Promise<ProvideAnonymousAccessTokenResponse> {
        console.log('provideAnonymousAccessToken called');
        return Promise.resolve(ProvideAnonymousAccessTokenResponseType.create({ anonymousAccessToken: '' }));
      }

      receiveAnalyticsEvent(request: ReceiveAnalyticsEventRequest, _context: ServerCallContext): Promise<ReceiveAnalyticsEventResponse> {
        console.log('receiveAnalyticsEvent:', request.name, request.parameters);
        return Promise.resolve(ReceiveAnalyticsEventResponseType.create({}));
      }

      receiveDebugLog(request: ReceiveDebugLogRequest, _context: ServerCallContext): Promise<ReceiveDebugLogResponse> {
        console.log('receiveDebugLog:', request.level, request.message);
        return Promise.resolve(ReceiveDebugLogResponseType.create({}));
      }

      receiveError(request: ReceiveErrorRequest, _context: ServerCallContext): Promise<ReceiveErrorResponse> {
        console.error('receiveError:', request.errorCode, request.data);
        return Promise.resolve(ReceiveErrorResponseType.create({}));
      }

      onExit(_request: OnExitRequest, _context: ServerCallContext): Promise<OnExitResponse> {
        console.log('onExit called');
        if (onRemoveView) {
          onRemoveView(viewId);
        }
        return Promise.resolve(OnExitResponseType.create({}));
      }

      startFaq(request: StartFaqRequest, _context: ServerCallContext): Promise<StartFaqResponse> {
        console.log('startFaq:', request.module);
        alert('startFaq called' + (request.module !== undefined ? ` for module: ${request.module}` : ''));
        return Promise.resolve(StartFaqResponseType.create({}));
      }

      startOnboarding(_request: StartOnboardingRequest, _context: ServerCallContext): Promise<StartOnboardingResponse> {
        console.log('startOnboarding called');
        alert('startOnboarding called');
        return Promise.resolve(StartOnboardingResponseType.create({ success: true }));
      }

      startFundPortfolio(request: StartFundPortfolioRequest, _context: ServerCallContext): Promise<StartFundPortfolioResponse> {
        console.log('startFundPortfolio:', request.portfolioData);
        alert('startFundPortfolio called');
        return Promise.resolve(StartFundPortfolioResponseType.create({ success: true }));
      }

      startAddMoney(request: StartAddMoneyRequest, _context: ServerCallContext): Promise<StartAddMoneyResponse> {
        console.log('startAddMoney:', request.portfolioData);
        alert('startAddMoney called');
        return Promise.resolve(StartAddMoneyResponseType.create({ success: true }));
      }

      startAuthorization(_request: StartAuthorizationRequest, _context: ServerCallContext): Promise<StartAuthorizationResponse> {
        console.log('startAuthorization called');
        alert('startAuthorization called');
        return Promise.resolve(StartAuthorizationResponseType.create({ success: true }));
      }

      startTransactionSigning(request: StartTransactionSigningRequest, _context: ServerCallContext): Promise<StartTransactionSigningResponse> {
        console.log('startTransactionSigning:', request.portfolioId, request.amount, request.type);
        alert('startTransactionSigning called');
        return Promise.resolve(StartTransactionSigningResponseType.create({ success: true }));
      }

      bottomBarItemPressed(request: BottomBarItemPressedRequest, _context: ServerCallContext): Promise<BottomBarItemPressedResponse> {
        console.log('bottomBarItemPressed:', request.url);
        alert('Bottom bar item pressed with URL: ' + request.url);
        return Promise.resolve(BottomBarItemPressedResponseType.create({ success: true }));
      }

      getHostInfo(_request: GetHostInfoRequest, _context: ServerCallContext): Promise<GetHostInfoResponse> {
        return Promise.resolve(GetHostInfoResponse.create({ framework: 'Web Angular' }));
      }

      getAccessToken(_request: GetAccessTokenRequest, _context: ServerCallContext): Promise<GetAccessTokenResponse> {
        return Promise.resolve(GetAccessTokenResponse.create({ accessToken: accessTokenRef.value }));
      }

      exit(request: ExitRequest, _context: ServerCallContext): Promise<ExitResponse> {
        console.log('Exit requested to host:', request.reason);
        if (onRemoveView) {
          onRemoveView(viewId);
        }
        return Promise.resolve(ExitResponse.create({ success: true }));
      }
    }();
  }
}

