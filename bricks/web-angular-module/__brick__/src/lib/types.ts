import type { ServiceType } from '@protobuf-ts/runtime-rpc';
import type { MyRpcTransport } from './flutter-embedding.service';
{{#handoversToHostServices}}
import { {{type}} } from './handovers/{{snake_name}}';
import { I{{type}} } from './handovers/{{snake_name}}.server';
{{/handoversToHostServices}}
{{#handoversToFlutterServices}}
import { {{type}}Client } from './handovers/{{snake_name}}.client';
{{/handoversToFlutterServices}}
import { StartParams } from './handovers/handovers_to_flutter_service';
export interface FlutterEmbeddingApp {
    addView: (options: { hostElement: HTMLElement | null }) => number;
    removeView: (viewId: number) => void;
}

export interface FlutterEmbeddingState {
    setStartConfig: (startConfig: string) => void;
    onInvokeHandover: (callback: (method: string, args: unknown) => string) => void;
    onInvokeHandoverGRPC: (callback: (serviceName: string, method: string, data: Uint8Array) => Promise<Uint8Array | null>) => void;
    invokeHandover: (method: string, args: string) => void;
    invokeHandoverMap: (serviceName: string, method: string, data: Uint8Array) => Promise<Uint8Array>;
}

export interface HandoverServiceTuple {
    service: ServiceType;
    instance: object;
}
export interface FlutterEmbeddingViewInputs {
    className?: string;
    onInvokeHandover: (method: string, args: unknown) => string;
    startParams: StartParams;
    {{#handoversToHostServices}}
    {{name}}: I{{type}};
    {{/handoversToHostServices}}
    initState: (state: FlutterEmbeddingState, {{#handoversToFlutterServices}}{{name}}: {{type}}Client,{{/handoversToFlutterServices}}) => void;
}

