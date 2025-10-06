import { FlutterEmbeddingView } from 'flutter-rn-embedding';
import React from 'react';
import type { ViewStyle } from 'react-native';

interface Props {
    style?: ViewStyle;
}

const FlutterApp = (props: Props) => {
    return <FlutterEmbeddingView style={props.style} {...props} />;
};

export {
    FlutterApp
};
