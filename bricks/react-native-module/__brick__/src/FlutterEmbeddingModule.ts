import {
  EventSubscriptionVendor,
  NativeEventEmitter,
  NativeModules,
} from 'react-native';
import type {
  HandoverResponderInterface,
} from './interfaces/index';

type NativeFlutterEmbeddingModuleType = EventSubscriptionVendor & {
  startEngine: (env: string, language: string, themeMode: string) => Promise<void>;
  stopEngine: () => void;
  respondToEvent: (eventName: string, data: { [key: string]: any }) => void;
  invokeHandover: (eventName: string, data: { [key: string]: any }) => void;
  invokeHandoverReturn: (eventName: string, data: { [key: string]: any }) => void;
  changeLanguage: (language: string) => Promise<boolean>;
  changeThemeMode: (themeMode: string) => Promise<boolean>;
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
    currentHandoverResponder.invokeHandover?.(name, JSON.stringify(data["_completable_event_request"]), (response: any, _error: any) => {
      if (response != null) {
        respondToEvent(name, response);
      }
    });
  }
});

export interface FlutterStartEngineParams {
  handoverResponder: HandoverResponderInterface;
  environment: string;
  language: string;
  themeMode?: string;
}
const startEngine = ({
  environment,
  handoverResponder,
  language,
  themeMode,
}: FlutterStartEngineParams): Promise<void> => {
  currentHandoverResponder = handoverResponder;

  return nativeFlutterEmbeddingModule.startEngine(environment, language, themeMode ?? 'system').then(async () => {
    const extraActions: any[] = [];

    for (let action of extraActions) {
      await action();
    }
  });
};

const stopEngine = () => nativeFlutterEmbeddingModule.stopEngine();

const changeLanguage = ({ language }: { language: string }): Promise<boolean> =>
  nativeFlutterEmbeddingModule.changeLanguage(language);

const changeThemeMode = ({ themeMode }: { themeMode: string }): Promise<boolean> =>
  nativeFlutterEmbeddingModule.changeThemeMode(themeMode);


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
  changeLanguage,
  changeThemeMode,
  invokeHandover,
  invokeHandoverReturn,
  respondToEvent,
};
