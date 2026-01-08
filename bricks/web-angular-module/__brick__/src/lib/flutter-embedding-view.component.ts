import { CommonModule } from '@angular/common';
import { Component, ElementRef, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { FlutterEmbeddingService, MyRpcTransport } from './flutter-embedding.service';
{{#handoversToFlutterServices}}
import { {{type}}Client } from './handovers/{{snake_name}}.client';
{{/handoversToFlutterServices}}
{{#handoversToHostServices}}
import { {{type}} } from './handovers/{{snake_name}}';
import type { I{{type}} } from './handovers/{{snake_name}}.server';
{{/handoversToHostServices}}
import { StartParams } from './handovers/handovers_to_flutter_service';
import { FlutterEmbeddingState, HandoverServiceTuple } from './types';

@Component({
    selector: 'flutter-embedding-view',
    standalone: true,
    imports: [CommonModule],
    template: `
        <div #hostElement [class]="className" [style]="divStyle">
            <div [style]="loadingStyle">
                Loading...
            </div>
        </div>
    `,
    styles: [`
        :host {
            display: block;
            height: 100%;
            width: 100%;
        }
        .loading-container {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100%;
        }
    `]
})
export class FlutterEmbeddingViewComponent implements OnInit, OnDestroy {
    @ViewChild('hostElement', { static: true }) hostElement!: ElementRef<HTMLDivElement>;
    @Input() className?: string;
    @Input() onInvokeHandover!: (method: string, args: unknown) => string;
    @Input() startParams!: StartParams;
    {{#handoversToHostServices}}
    @Input() {{name}}!: I{{type}};
    {{/handoversToHostServices}}
    @Input() initState!: (flutterEmbeddingState: FlutterEmbeddingState, {{#handoversToFlutterServices}}{{name}}: {{type}}Client,{{/handoversToFlutterServices}}) => void;

    flutterState: FlutterEmbeddingState | null = null;
    viewId: number | null = null;
    eventListener?: (event: Event) => void;

    divStyle: { [key: string]: string } = {
        height: '100%',
        width: '100%',
    };

    loadingStyle: { [key: string]: string } = {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100%'
    };

    constructor(private flutterEmbeddingService: FlutterEmbeddingService) { }

    async ngOnInit() {
        const flutterApp = await this.flutterEmbeddingService.startEngine();
        const target = this.hostElement.nativeElement;

        this.viewId = flutterApp.addView({ hostElement: target });

        this.eventListener = (event: Event) => {
            const state = (event as CustomEvent).detail as FlutterEmbeddingState;
            this.onFlutterAppLoaded(state);
        };

        target.addEventListener('flutter-initialized', this.eventListener, {
            once: true,
        });
    }

    ngOnDestroy() {
        const target = this.hostElement.nativeElement;
        if (this.eventListener) {
            target.removeEventListener('flutter-initialized', this.eventListener);
        }
        const flutterApp = this.flutterEmbeddingService.getFlutterApp();
        if (flutterApp && this.viewId !== null) {
            flutterApp.removeView(this.viewId);
        }
    }

    private onFlutterAppLoaded(state: FlutterEmbeddingState) {
        this.flutterState = state;
        this.flutterState.setStartConfig("{\"startParams\":[" + Array.from(StartParams.toBinary(this.startParams)) + "]}");
        state.onInvokeHandover((method: string, args: unknown) => {
            return this.onInvokeHandover(method, args);
        });
        var handoverServices: HandoverServiceTuple[] = [{{#handoversToHostServices}}{ service: {{type}}, instance: this.{{name}} },{{/handoversToHostServices}}];
        state.onInvokeHandoverGRPC(async (_serviceName: string, method: string, data: Uint8Array): Promise<Uint8Array | null> => {
            for (const { service, instance } of handoverServices) {
                for (const serviceMethod of service.methods) {
                    if (serviceMethod.name == method) {
                        const request = serviceMethod.I.fromBinary(data);
                        // eslint-disable-next-line @typescript-eslint/no-explicit-any
                        const methodFn = (instance as Record<string, unknown>)[serviceMethod.localName] as ((req: unknown, options?: unknown) => PromiseLike<any>);
                        // eslint-disable-next-line @typescript-eslint/no-explicit-any
                        const response = await methodFn(request, null).then((response: any) => {
                            return serviceMethod.O.toBinary(response);
                        });
                        return response;
                    }
                }
            }
            return null;
        });
        const rpcTransport = new MyRpcTransport(state);
        this.initState(state, {{#handoversToFlutterServices}} new {{type}}Client(rpcTransport),{{/handoversToFlutterServices}});
    }
}

