import type { ClientStreamingCall, DuplexStreamingCall, MethodInfo, RpcOptions, RpcTransport, ServerStreamingCall, ServiceType, UnaryCall } from '@protobuf-ts/runtime-rpc';
import {
  EventSubscriptionVendor,
  NativeEventEmitter,
  NativeModules,
} from 'react-native';
import 'text-encoding';
import { StartParams } from './handovers/handovers_to_flutter_service';
{{#handoversToFlutterServices}}
import { {{type}}Client } from './handovers/{{snake_name}}.client';
{{/handoversToFlutterServices}}
{{#handoversToHostServices}}
import { {{type}} } from './handovers/{{snake_name}}';
{{/handoversToHostServices}}
{{#handoversToHostServices}}
import { I{{type}} } from './handovers/{{snake_name}}.server';
{{/handoversToHostServices}}
import type {
  HandoverResponderInterface,
} from './interfaces/index';

export class MyRpcTransport implements RpcTransport {
  nativeFlutterEmbeddingModule: NativeFlutterEmbeddingModuleType;
  constructor() {
    this.nativeFlutterEmbeddingModule = NativeModules.FlutterEmbeddingModule;
  }
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  mergeOptions(_options?: Partial<RpcOptions>): RpcOptions {
    return {};
  }
  unary<I extends object, O extends object>(method: MethodInfo<I, O>, input: I, options: RpcOptions): UnaryCall<I, O> {
    console.log('unary call: ', method.service.typeName);
    let data = Array.from(method.I.toBinary(input));
    this.nativeFlutterEmbeddingModule.invokeHandoverReturn(method.service.typeName, { 'name': method.service.typeName, 'method': method.name, 'request': data });
    const emptyResponse = method.O.create();
    const promise = Promise.resolve(emptyResponse);
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const headersMetadata = (options?.meta?.headers ?? {}) as any;

    const finishedUnaryCall = {
      method,
      request: input,
      requestHeaders: headersMetadata,
      headers: headersMetadata,
      response: emptyResponse,
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
  clientStreaming<I extends object, O extends object>(_method: MethodInfo<I, O>, _options: RpcOptions): ClientStreamingCall<I, O> {
    throw new Error('Method not implemented.')
  }
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  duplex<I extends object, O extends object>(_method: MethodInfo<I, O>, _options: RpcOptions): DuplexStreamingCall<I, O> {
    throw new Error('Method not implemented.')
  }
}

type NativeFlutterEmbeddingModuleType = EventSubscriptionVendor & {
  startEngine: (startConfig: string) => Promise<void>;
  stopEngine: () => void;
  respondToEvent: (eventName: string, data: { [key: string]: any }) => void;
  invokeHandover: (eventName: string, data: { [key: string]: any }) => void;
  invokeHandoverReturn: (eventName: string, data: { [key: string]: any }) => void;
};

const nativeFlutterEmbeddingModule: NativeFlutterEmbeddingModuleType =
  NativeModules.FlutterEmbeddingModule;
const eventEmitter = new NativeEventEmitter(nativeFlutterEmbeddingModule);
let currentHandoverResponder: HandoverResponderInterface;


eventEmitter.addListener("invokeHandover", async (data: any) => {
  let name: string = data['name'];
  if (name == "exit") {
    currentHandoverResponder.exit?.();
  } else if (name != '') {
    currentHandoverResponder.invokeHandover?.(name, data["_completable_event_request"], (response: any, _error: any) => {
      if (response != null) {
        response["_completable_event_uuid"] = data["_completable_event_uuid"];
        respondToEvent(name, response);
      }
    });
  }
});

eventEmitter.addListener("exit", async (_data: any) => {
  currentHandoverResponder.exit?.();
});

export interface HandoverServiceTuple {
  service: ServiceType;
  instance: object;
}

export interface FlutterStartEngineParams {
  startParams: StartParams;
  {{#handoversToHostServices}}{{name}}: I{{type}};{{/handoversToHostServices}}
}
const startEngine = ({
  startParams,
  {{#handoversToHostServices}}{{name}},
  {{/handoversToHostServices}}
}: FlutterStartEngineParams): Promise<void> => {
  var handoverServices: HandoverServiceTuple[] = [];
  {{#handoversToHostServices}}
  handoverServices.push({ service: {{type}}, instance: {{name}} });
  {{/handoversToHostServices}}
  currentHandoverResponder = {
    invokeHandover: async (name: string, data: any, completion: (response: any, error: any) => void) => {
      const dataObj = data as { [key: string]: any };
      var serviceName = name
      var serviceMethodName = dataObj["method"] as string
      var serviceData = dataObj["data"] as Uint8Array;
      var uuid = dataObj["_completable_event_uuid"] as string;

      for (const { service, instance } of handoverServices) {
        if (service.typeName == serviceName) {
          for (const serviceMethod of service.methods) {
            if (serviceMethod.name == serviceMethodName) {
              const messageType = serviceMethod.I;
              const uintarray = Uint8Array.from(serviceData);
              const request = messageType.fromBinary(uintarray);
              const methodFn = (instance as Record<string, unknown>)[serviceMethod.localName] as ((req: unknown, options?: unknown) => PromiseLike<any>);
              // eslint-disable-next-line @typescript-eslint/no-explicit-any
              const response = await methodFn(request, null).then((response: any) => {
                return Array.from(serviceMethod.O.toBinary(response));
              });
              completion({ "_completable_event_uuid": uuid, "_completable_event_response": response }, null);

              return;
            }
          }
        }
      }
    }
  };

  const startConfig = "{\"startParams\":[" + Array.from(StartParams.toBinary(startParams)) + "]}"

  return nativeFlutterEmbeddingModule.startEngine(startConfig).then(async () => {
    const extraActions: any[] = [];

    for (let action of extraActions) {
      await action();
    }
  });
};
const stopEngine = () => nativeFlutterEmbeddingModule.stopEngine();

{{#handoversToFlutterServices}}
const {{name}}Client = () => {
  return new {{type}}Client(new MyRpcTransport());
}{{/handoversToFlutterServices}}

const invokeHandover = (eventName: string, data: {}) => {
  nativeFlutterEmbeddingModule.invokeHandoverReturn(eventName, data);
}

const invokeHandoverReturn = (eventName: string, data: { [key: string]: any }) => {
  nativeFlutterEmbeddingModule.invokeHandoverReturn(eventName, data);
}

const respondToEvent = (eventName: string, data: { [key: string]: any }) =>
  nativeFlutterEmbeddingModule.respondToEvent(eventName, data);

export const FlutterEmbeddingModule = {
  startEngine,
  stopEngine,
  invokeHandover,
  invokeHandoverReturn,
  respondToEvent,
  {{#handoversToFlutterServices}}
  {{name}}Client,
  {{/handoversToFlutterServices}}
};
