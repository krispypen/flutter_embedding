
import Box from '@mui/material/Box';
import CircularProgress from '@mui/material/CircularProgress';
import type { ClientStreamingCall, DuplexStreamingCall, MethodInfo, RpcOptions, RpcTransport, ServerStreamingCall, UnaryCall } from "@protobuf-ts/runtime-rpc";
import React, { memo, useEffect, useRef } from 'react';
import { FlutterEmbeddingState, FlutterEmbeddingViewProps, HandoverServiceTuple } from './types';
{{#handoversToFlutterServices}}
import { {{type}}Client } from './handovers/{{snake_name}}.client';
{{/handoversToFlutterServices}}
{{#handoversToHostServices}}
import { {{type}} } from './handovers/{{snake_name}}';
{{/handoversToHostServices}}
import { StartParams } from './handovers/handovers_to_flutter_service';

export class MyRpcTransport implements RpcTransport {
    state: FlutterEmbeddingState;
    constructor(state: FlutterEmbeddingState) {
        this.state = state;
    }
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    mergeOptions(_options?: Partial<RpcOptions>): RpcOptions {
        return {};
    }
    unary<I extends object, O extends object>(method: MethodInfo<I, O>, input: I): UnaryCall<I, O> {
        console.log('unary call: ', method.service.typeName);

        const promise = this.state.invokeHandoverMap(method.service.typeName, method.name, method.I.toBinary(input)).then((result) => {
            const response = method.O.fromBinary(result);
            return response as O;
        });
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const headersMetadata = ({}) as any;

        const finishedUnaryCall = {
            method,
            request: input,
            requestHeaders: headersMetadata,
            headers: headersMetadata,
            response: promise,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            status: { code: 'OK' } as any,
            trailers: {},
        };

        return {
            method,
            request: input,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            requestHeaders: headersMetadata as any,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            headers: Promise.resolve(headersMetadata),
            response: promise,
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            status: promise.then(() => ({ code: 'OK' } as any)),
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            trailers: promise.then(() => ({})),
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            then: (onfulfilled?: any, onrejected?: any) => promise.then(() => finishedUnaryCall).then(onfulfilled, onrejected),
            // Add promiseFinished method to satisfy UnaryCall type
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            promiseFinished: async () => finishedUnaryCall as any,
        } as unknown as UnaryCall<I, O>;
    }
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    serverStreaming<I extends object, O extends object>(_method: MethodInfo<I, O>, _input: I, _options: RpcOptions): ServerStreamingCall<I, O> {
        throw new Error('Method not implemented.')
    }
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    clientStreaming<I extends object, O extends object>(method: MethodInfo<I, O>, options: RpcOptions): ClientStreamingCall<I, O> {
        throw new Error('Method not implemented.')
    }
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    duplex<I extends object, O extends object>(method: MethodInfo<I, O>, options: RpcOptions): DuplexStreamingCall<I, O> {
        throw new Error('Method not implemented.')
    }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
declare let _flutter: any; // flutter.js is loaded in index.html
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let flutterApp: any | null = null;

export async function startEngine() {
    if (_flutter === undefined) {
        throw new Error('Flutter is not initialized, make sure to add <script src="%PUBLIC_URL%/flutter/flutter.js" defer></script> to your index.html file');
    }
    if (flutterApp) return flutterApp;
    // with webassembly
    /*const engineInitializer = await new Promise<any>((resolve) => {
      _flutter.buildConfig = { "builds": [{ "compileTarget": "dart2wasm", "renderer": "skwasm", "mainWasmPath": window.location.origin + "/flutter/main.dart.wasm", "jsSupportRuntimePath": window.location.origin + "/flutter/main.dart.mjs" }, { "compileTarget": "dart2js", "renderer": "canvaskit", "mainJsPath": window.location.origin + "/flutter/main.dart.js" }] };
      _flutter.loader.load({
        onEntrypointLoaded: resolve,
      })
    })*/
    // without assembly:
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const engineInitializer = await new Promise<any>((resolve) => {
        _flutter.loader.loadEntrypoint({
            entrypointUrl: window.location.origin + '/flutter/main.dart.js',
            onEntrypointLoaded: resolve,
        })
    })
    const appRunner = await engineInitializer?.initializeEngine({
        assetBase: window.location.origin + '/flutter/',
        multiViewEnabled: true,
    })

    flutterApp = await appRunner.runApp();
}

export const FlutterEmbedding = {
    startEngine,
}

const divStyle: React.CSSProperties = {
    height: '100%',
    width: '100%',
};

export const FlutterEmbeddingView: React.FC<FlutterEmbeddingViewProps> = memo(({
    className,
    onInvokeHandover,
    initState,
    startParams,
    {{#handoversToHostServices}}
    {{name}},
    {{/handoversToHostServices}}
}) => {
    const flutterState = useRef<FlutterEmbeddingState | null>(null);
    const ref = useRef<HTMLDivElement>(null);
    const handoverServices: HandoverServiceTuple[] = [{{#handoversToHostServices}}{ service: {{type}}, instance: {{name}} },{{/handoversToHostServices}}];

    const onFlutterAppLoaded = (state: FlutterEmbeddingState) => {
        flutterState.current = state;
        state.setStartConfig("{\"startParams\":[" + Array.from(StartParams.toBinary(startParams)) + "]}");
        state.onInvokeHandover((method: string, args: unknown) => {
            return onInvokeHandover(method, args);
        });
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
        initState(state, {{#handoversToFlutterServices}}new {{type}}Client(rpcTransport),{{/handoversToFlutterServices}});
    };
    //{{=<% %>=}}
    useEffect(() => {
        const target = ref.current;
        if (!target) return;

        const viewId: number = flutterApp.addView({ hostElement: target });

        const eventListener = (event: Event) => {
            const state = (event as CustomEvent).detail as FlutterEmbeddingState;
            onFlutterAppLoaded(state);
        };

        target.addEventListener('flutter-initialized', eventListener, {
            once: true,
        });

        return () => {
            target.removeEventListener('flutter-initialized', eventListener);
            flutterApp.removeView(viewId);
        };
    }, []);

    return (
        <Box ref={ref} style={divStyle} className={className}>
            <Box sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                height: '100%'
            }}>
                <CircularProgress />
            </Box>
        </Box>
    );
});