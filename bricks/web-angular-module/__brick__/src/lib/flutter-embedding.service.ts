//{{=<% %>=}}
import { Injectable } from '@angular/core';
import type { ClientStreamingCall, DuplexStreamingCall, MethodInfo, RpcOptions, RpcTransport, ServerStreamingCall, UnaryCall } from "@protobuf-ts/runtime-rpc";
import { FlutterEmbeddingState } from './types';

export class MyRpcTransport implements RpcTransport {
    state: FlutterEmbeddingState;
    constructor(state: FlutterEmbeddingState) {
        this.state = state;
    }
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    mergeOptions(_options?: Partial<RpcOptions>): RpcOptions {
        return {};
    }
    unary<I extends object, O extends object>(method: MethodInfo<I, O>, input: I, options: RpcOptions): UnaryCall<I, O> {
        console.log('unary call: ', method.service.typeName);

        const promise = new Promise<O>(async (resolve, reject) => {
            this.state.invokeHandoverMap(method.service.typeName, method.name, method.I.toBinary(input)).then((result) => {
                const response = method.O.fromBinary(result);
                resolve(response as O);
            }).catch((error) => {
                reject(error);
            });
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

@Injectable({
    providedIn: 'root'
})
export class FlutterEmbeddingService {
    async startEngine(): Promise<any> {
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
        return flutterApp;
    }

    getFlutterApp(): any {
        return flutterApp;
    }
}

export const FlutterEmbedding = {
    startEngine: async () => {
        const service = new FlutterEmbeddingService();
        return service.startEngine();
    }
}

