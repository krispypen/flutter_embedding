//{{=<% %>=}}
import { Inject, Injectable, InjectionToken, Optional } from '@angular/core';
import type { ClientStreamingCall, DuplexStreamingCall, MethodInfo, RpcOptions, RpcTransport, ServerStreamingCall, UnaryCall } from "@protobuf-ts/runtime-rpc";
import { FlutterEmbeddingState } from './types';

/**
 * Configuration options for the Flutter Embedding module.
 */
export interface FlutterEmbeddingConfig {
    /**
     * Base path where Flutter assets are located.
     * Defaults to using document.baseURI + 'flutter/' which respects the HTML <base href="..."> tag.
     * Examples:
     * - '/flutter/' for root deployment
     * - '/my-app/flutter/' for subdirectory deployment
     * - 'flutter/' to use relative path from document.baseURI
     */
    basePath?: string;
}

/**
 * Injection token for Flutter Embedding configuration.
 * Use this to provide custom configuration when importing the module.
 * 
 * @example
 * // In your app.module.ts or app.config.ts:
 * providers: [
 *   { provide: FLUTTER_EMBEDDING_CONFIG, useValue: { basePath: '/my-app/flutter/' } }
 * ]
 */
export const FLUTTER_EMBEDDING_CONFIG = new InjectionToken<FlutterEmbeddingConfig>('FLUTTER_EMBEDDING_CONFIG');

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

/**
 * Resolves the Flutter base path from configuration or defaults to document.baseURI + 'flutter/'.
 * This ensures Flutter assets are found correctly regardless of deployment path.
 */
function resolveFlutterBasePath(basePath?: string): string {
    if (basePath) {
        // Ensure path ends with /
        return basePath.endsWith('/') ? basePath : basePath + '/';
    }
    // Default: use document.baseURI which respects <base href="...">
    return new URL('flutter/', document.baseURI).href;
}

@Injectable({
    providedIn: 'root'
})
export class FlutterEmbeddingService {
    private basePath: string;

    constructor(@Optional() @Inject(FLUTTER_EMBEDDING_CONFIG) config?: FlutterEmbeddingConfig) {
        this.basePath = resolveFlutterBasePath(config?.basePath);
    }

    async startEngine(): Promise<any> {
        if (_flutter === undefined) {
            throw new Error('Flutter is not initialized, make sure to add <script src="flutter/flutter.js" defer></script> to your index.html file');
        }
        if (flutterApp) return flutterApp;
        // with webassembly
        /*const engineInitializer = await new Promise<any>((resolve) => {
          _flutter.buildConfig = { "builds": [{ "compileTarget": "dart2wasm", "renderer": "skwasm", "mainWasmPath": this.basePath + "main.dart.wasm", "jsSupportRuntimePath": this.basePath + "main.dart.mjs" }, { "compileTarget": "dart2js", "renderer": "canvaskit", "mainJsPath": this.basePath + "main.dart.js" }] };
          _flutter.loader.load({
            onEntrypointLoaded: resolve,
          })
        })*/
        // without assembly:
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const engineInitializer = await new Promise<any>((resolve) => {
            _flutter.loader.loadEntrypoint({
                entrypointUrl: this.basePath + 'main.dart.js',
                onEntrypointLoaded: resolve,
            })
        })
        const appRunner = await engineInitializer?.initializeEngine({
            assetBase: this.basePath,
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
    startEngine: async (config?: FlutterEmbeddingConfig) => {
        const basePath = resolveFlutterBasePath(config?.basePath);
        if (_flutter === undefined) {
            throw new Error('Flutter is not initialized, make sure to add <script src="flutter/flutter.js" defer></script> to your index.html file');
        }
        if (flutterApp) return flutterApp;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const engineInitializer = await new Promise<any>((resolve) => {
            _flutter.loader.loadEntrypoint({
                entrypointUrl: basePath + 'main.dart.js',
                onEntrypointLoaded: resolve,
            })
        })
        const appRunner = await engineInitializer?.initializeEngine({
            assetBase: basePath,
            multiViewEnabled: true,
        })
        flutterApp = await appRunner.runApp();
        return flutterApp;
    }
}

