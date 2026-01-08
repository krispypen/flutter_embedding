//{{=<% %>=}}
import {
  FlutterEmbeddingState,
  FlutterEmbeddingViewComponent,
  HandoversToFlutterServiceClient
} from '<% webAngularPackageName %>';
import { BreakpointObserver } from '@angular/cdk/layout';
import { CommonModule } from '@angular/common';
import { Component, ViewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatTabsModule } from '@angular/material/tabs';
import { CommunicationViewComponent } from './app.communicationview.component';

interface View {
  id: number;
  state: FlutterEmbeddingState | null;
  handoversToFlutterServiceClient: HandoversToFlutterServiceClient | null;
}

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatButtonModule,
    MatTabsModule,
    FlutterEmbeddingViewComponent,
    CommunicationViewComponent
  ],
  template: `
    <div style="display: flex; flex-direction: column; height: 100vh; overflow: hidden;">
      <ng-container *ngIf="isLargeScreen; else smallScreenLayout">
        <!-- Large screen: Side-by-side layout -->
        <div style="display: flex; flex: 1; overflow: hidden;">
          <!-- Settings Panel -->
          <div style="width: 400px; flex-shrink: 0; overflow: auto; border-right: 1px solid #e0e0e0;">
            <div style="height: 100%; overflow: auto; padding: 16px;">
              <h1><% flutterEmbeddingName %> Demo</h1>
              
              <button mat-raised-button color="primary" (click)="addView()" style="width: 100%; margin-bottom: 16px;">
                Add Flutter view
              </button>

              <app-communication-view
                #communicationView
                [hasViews]="hasViews"
                [handoversToFlutterServiceClients]="handoversToFlutterServiceClients"
                [onRemoveView]="removeView.bind(this)"
              ></app-communication-view>
            </div>
          </div>

          <!-- Flutter Container -->
          <div style="flex: 1; overflow: hidden;">
            <div style="height: 100%; display: flex; flex-direction: column; background-color: #f0f0f0; overflow: hidden;">
              <div *ngIf="views.length === 0" style="display: flex; align-items: center; justify-content: center; height: 100%; color: #666;">
                <h2>Flutter container area</h2>
              </div>
              
              <div *ngFor="let view of views" style="flex: 1; display: flex; flex-direction: column; position: relative; min-height: 300px; width: 100%;">
                <div style="position: absolute; top: 8px; right: 8px; z-index: 10;">
                  <button mat-raised-button color="warn" (click)="removeView(view.id)">
                    Remove View {{ view.id }}
                  </button>
                </div>
                
                <flutter-embedding-view
                  className="flutter-embedding-view"
                  [onInvokeHandover]="handleInvokeHandover"
                  [startParams]="communicationView.createStartParams()"
                  [handoversToHostService]="communicationView.createHandoversToHostService(view.id)"
                  [initState]="handleInitState(view)"
                ></flutter-embedding-view>
              </div>
            </div>
          </div>
        </div>
      </ng-container>

      <!-- Small screen: Tabbed layout -->
      <ng-template #smallScreenLayout>
        <div style="display: flex; flex-direction: column; height: 100vh; overflow: hidden; width: 100%;">
          <mat-tab-group [(selectedIndex)]="selectedTabIndex" style="flex: 1;">
            <mat-tab label="Settings">
              <div style="height: 100%; overflow: auto; padding: 16px;">
                <h1><% flutterEmbeddingName %> Demo</h1>
                
                <button mat-raised-button color="primary" (click)="addView()" style="width: 100%; margin-bottom: 16px;">
                  Add Flutter view
                </button>

                <app-communication-view
                  #communicationView
                  [hasViews]="hasViews"
                  [handoversToFlutterServiceClients]="handoversToFlutterServiceClients"
                  [onRemoveView]="removeView.bind(this)"
                ></app-communication-view>
              </div>
            </mat-tab>
            
            <mat-tab label="Flutter">
              <div style="height: 100%; display: flex; flex-direction: column; background-color: #f0f0f0; overflow: hidden;">
                <div *ngIf="views.length === 0" style="display: flex; align-items: center; justify-content: center; height: 100%; color: #666;">
                  <h2>Flutter container area</h2>
                </div>
                
                <div *ngFor="let view of views" style="flex: 1; display: flex; flex-direction: column; position: relative; min-height: 300px; width: 100%;">
                  <div style="position: absolute; top: 8px; right: 8px; z-index: 10;">
                    <button mat-raised-button color="warn" (click)="removeView(view.id)">
                      Remove View {{ view.id }}
                    </button>
                  </div>
                  
                  <flutter-embedding-view
                    className="flutter-embedding-view"
                    [onInvokeHandover]="handleInvokeHandover"
                    [startParams]="communicationView.createStartParams()"
                    [handoversToHostService]="communicationView.createHandoversToHostService(view.id)"
                    [initState]="handleInitState(view)"
                  ></flutter-embedding-view>
                </div>
              </div>
            </mat-tab>
          </mat-tab-group>
        </div>
      </ng-template>
    </div>
  `,
  styles: [`
    :host {
      height: 100vh;
      display: block;
    }
  `]
})
export class AppComponent {
  @ViewChild('communicationView') communicationView!: CommunicationViewComponent;

  views: View[] = [];
  selectedTabIndex: number = 0;
  isLargeScreen: boolean = false;

  // Derived state
  get hasViews(): boolean {
    return this.views.length > 0;
  }

  get handoversToFlutterServiceClients(): HandoversToFlutterServiceClient[] {
    return this.views
      .map(v => v.handoversToFlutterServiceClient)
      .filter((client): client is HandoversToFlutterServiceClient => client !== null);
  }

  constructor(private breakpointObserver: BreakpointObserver) {
    this.breakpointObserver.observe(['(min-width: 600px)']).subscribe((result: { matches: boolean }) => {
      this.isLargeScreen = result.matches;
    });
  }

  addView() {
    const newId = this.views.length > 0
      ? (this.views[this.views.length - 1]?.id ?? 0) + 1
      : 1;
    this.views = [
      ...this.views,
      {
        id: newId,
        state: null,
        handoversToFlutterServiceClient: null
      }
    ];
  }

  removeView(id: number) {
    this.views = this.views.filter(v => v.id !== id);
  }

  handleInvokeHandover = (method: string, args: unknown): string => {
    alert('Invoke handover: ' + method + ' ' + JSON.stringify(args));
    return 'Hello back to Flutter';
  }

  handleInitState = (view: View) => {
    return (state: FlutterEmbeddingState, handoversToFlutterServiceClient: HandoversToFlutterServiceClient) => {
      view.state = state;
      view.handoversToFlutterServiceClient = handoversToFlutterServiceClient;
    };
  }
}
