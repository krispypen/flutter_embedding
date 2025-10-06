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
  invokeHandover: (eventName: string, data: {}) => void;
  changeLanguage: (language: string) => Promise<boolean>;
  changeThemeMode: (themeMode: string) => Promise<boolean>;
};

const nativeFlutterEmbeddingModule: NativeFlutterEmbeddingModuleType =
  NativeModules.FlutterEmbeddingModule;
const eventEmitter = new NativeEventEmitter(nativeFlutterEmbeddingModule);
let currentHandoverResponder: HandoverResponderInterface;

function addListener(
  eventName: string,
  listener: (request?: any, uuid?: string) => void,
) {
  eventEmitter.addListener(eventName, async (data: any) => {
    let uuid: string = data['COMPLETABLE_EVENT_UUID_KEY'];
    let request: any = data['COMPLETABLE_EVENT_REQUEST_KEY'];

    listener(
      request,
      uuid != null && typeof uuid === 'string' ? uuid : undefined
    );
  });
}

addListener('exit', async () => {
  currentHandoverResponder.exit?.();
});

addListener('invokeHandover', async (request?: any, uuid?: string) => {
  if (uuid != null) {
    await currentHandoverResponder.invokeHandover?.(request.name, request.data, (response: any, error: any) => {
      if (error) {
        nativeFlutterEmbeddingModule.invokeHandover(uuid, error);
      }
      nativeFlutterEmbeddingModule.respondToEvent(uuid, response);
    });

  } else {
    console.debug(`Invalid ${'invokeHandover'} event`);
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


const invokeHandover = (eventName: string, data: {}) =>
  nativeFlutterEmbeddingModule.invokeHandover(eventName, data);

const respondToEvent = (eventName: string, data: { [key: string]: any }) =>
  nativeFlutterEmbeddingModule.respondToEvent(eventName, data);

export const FlutterEmbeddingModule = {
  startEngine,
  stopEngine,
  changeLanguage,
  changeThemeMode,
  invokeHandover,
  respondToEvent,
};
