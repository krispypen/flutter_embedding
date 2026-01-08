import {
  Platform,
  requireNativeComponent,
  UIManager,
  ViewStyle,
} from 'react-native';

const LINKING_ERROR =
  "The package '{{reactNativePackageName}}' doesn't seem to be linked. Make sure: \n\n" +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

export type FlutterEmbeddingProps = {
  style?: ViewStyle;
};

const ComponentName = 'FlutterEmbeddingView';

export const FlutterEmbeddingView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<FlutterEmbeddingProps>(ComponentName)
    : () => {
      throw new Error(LINKING_ERROR);
    };
