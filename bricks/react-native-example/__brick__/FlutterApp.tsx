import type { ViewStyle } from 'react-native';
import { FlutterEmbeddingView } from '{{reactNativePackageName}}';

interface Props {
    style?: ViewStyle;
}

const FlutterApp = (props: Props) => {
    return <FlutterEmbeddingView style={props.style} {...props} />;
};

export {
    FlutterApp
};
