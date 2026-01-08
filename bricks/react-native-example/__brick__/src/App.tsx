//{{=<% %>=}}

/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * Generated with the TypeScript template
 * https://github.com/react-native-community/react-native-template-typescript
 *
 * @format
 */

import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator, StackScreenProps } from '@react-navigation/stack';
import { FlutterEmbeddingModule, HandoversToFlutterServiceClient } from '<% reactNativePackageName %>';
import React from 'react';
import {
  Alert,
  Dimensions,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';
import CommunicationView from './CommunicationView';
import { FlutterApp } from '../FlutterApp';

const RESPONSIVE_BREAKPOINT = 600;

type RootStackParamList = {
  Home: undefined;
  Flutter: undefined;
};

const Stack = createStackNavigator<RootStackParamList>();

const App = () => {
  return (
    <SafeAreaProvider>
      <NavigationContainer>
        <Stack.Navigator>
          <Stack.Screen name="Home" component={HomeScreen} options={{ headerShown: false }} />
          <Stack.Screen name="Flutter" component={FlutterScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </SafeAreaProvider>
  );
};

const HomeScreen = ({ navigation }: StackScreenProps<RootStackParamList, 'Home'>) => {
  // Responsive layout: >= 600 is side-by-side, < 600 is tabs
  const [isLargeScreen, setIsLargeScreen] = React.useState<boolean>(false);
  const [selectedTab, setSelectedTab] = React.useState<number>(0); // 0 = Settings, 1 = Flutter

  // Safe area insets
  const insets = useSafeAreaInsets();

  // State
  const [isEngineStarted, setIsEngineStarted] = React.useState<boolean>(false);
  const [isFlutterInView, setIsFlutterInView] = React.useState<boolean>(false);
  const [handoversToFlutterServiceClient, setHandoversToFlutterServiceClient] = React.useState<HandoversToFlutterServiceClient | null>(null);

  // Refs
  const communicationViewRef = React.useRef<{ startEngine: (callback: (success: boolean, error?: Error) => void) => void }>(null);
  const isFlutterInViewRef = React.useRef<boolean>(false);

  // Keep ref in sync with state
  React.useEffect(() => {
    isFlutterInViewRef.current = isFlutterInView;
  }, [isFlutterInView]);

  React.useEffect(() => {
    const updateLayout = () => {
      const { width } = Dimensions.get('window');
      setIsLargeScreen(width >= RESPONSIVE_BREAKPOINT);
    };

    updateLayout();
    const subscription = Dimensions.addEventListener('change', updateLayout);

    return () => {
      subscription?.remove();
    };
  }, []);

  const handleFlutterExit = React.useCallback(() => {
    if (isFlutterInViewRef.current) {
      setIsFlutterInView(false);
    }
  }, []);

  const startEngine = () => {
    if (!communicationViewRef.current) {
      Alert.alert('Error', 'Communication view not ready');
      return;
    }

    communicationViewRef.current.startEngine((success, error) => {
      if (success) {
        Alert.alert('Engine started', 'The Flutter engine started successfully');
      } else {
        Alert.alert('Error', 'Something went wrong when starting the engine: ' + (error?.message || 'Unknown error'));
      }
    });
  };

  const stopEngine = () => {
    FlutterEmbeddingModule.stopEngine();
    setIsFlutterInView(false);
  };

  const startScreen = () => {
    if (!isEngineStarted) {
      Alert.alert('Error', 'Please start the Flutter engine first');
      return;
    }
    navigation.navigate('Flutter');
  };

  const startFlutterInView = () => {
    if (!isEngineStarted) {
      Alert.alert('Error', 'Please start the Flutter engine first');
      return;
    }
    setIsFlutterInView(true);
  };

  // Settings Panel Content
  const SettingsPanel = (
    <ScrollView
      style={styles.settingsContainer}
      contentContainerStyle={[styles.settingsContent, { paddingBottom: insets.bottom + 16 }]}
    >
      <Text style={styles.title}><% flutterEmbeddingName %> Demo</Text>

      {/* Engine Controls */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Flutter Engine Controls</Text>
        {!isEngineStarted ? (
          <TouchableOpacity style={styles.button} onPress={startEngine}>
            <Text style={styles.buttonText}>startEngine</Text>
          </TouchableOpacity>
        ) : (
          <TouchableOpacity style={styles.button} onPress={stopEngine}>
            <Text style={styles.buttonText}>stopEngine</Text>
          </TouchableOpacity>
        )}
      </View>

      {/* Flutter App Controls */}
      {isEngineStarted && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Flutter App</Text>

          <TouchableOpacity style={styles.button} onPress={startScreen}>
            <Text style={styles.buttonText}>startScreen</Text>
          </TouchableOpacity>

          {!isFlutterInView ? (
            <TouchableOpacity style={styles.button} onPress={startFlutterInView}>
              <Text style={styles.buttonText}>startFlutterInView</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity style={styles.button} onPress={setIsFlutterInView.bind(null, false)}>
              <Text style={styles.buttonText}>removeFlutterView</Text>
            </TouchableOpacity>
          )}
        </View>
      )}

      {/* Communication View */}
      <CommunicationView
        ref={communicationViewRef}
        onFlutterExit={handleFlutterExit}
        onEngineStateChange={setIsEngineStarted}
        onHandoversToFlutterServiceClientChange={setHandoversToFlutterServiceClient}
      />
    </ScrollView>
  );

  // Flutter Container Content
  const FlutterContainer = (
    <View style={styles.flutterContainer}>
      {isFlutterInView ? (
        <FlutterApp style={styles.flutterApp} />
      ) : (
        <Text style={styles.containerText}>Flutter container area</Text>
      )}
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle={'dark-content'} />

      {isLargeScreen ? (
        // Large screen: Side-by-side layout
        <View style={styles.sideBySideContainer}>
          <View style={styles.settingsSide}>
            {SettingsPanel}
          </View>
          <View style={styles.flutterSide}>
            {FlutterContainer}
          </View>
        </View>
      ) : (
        // Small screen: Tabbed layout
        <View style={styles.tabbedContainer}>
          {/* Tab Buttons */}
          <View style={styles.tabBar}>
            <TouchableOpacity
              style={[styles.tabButton, selectedTab === 0 && styles.tabButtonActive]}
              onPress={() => setSelectedTab(0)}
            >
              <Text style={[styles.tabButtonText, selectedTab === 0 && styles.tabButtonTextActive]}>
                Settings
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.tabButton, selectedTab === 1 && styles.tabButtonActive]}
              onPress={() => setSelectedTab(1)}
            >
              <Text style={[styles.tabButtonText, selectedTab === 1 && styles.tabButtonTextActive]}>
                Flutter
              </Text>
            </TouchableOpacity>
          </View>

          {/* Tab Content */}
          <View style={styles.tabContent}>
            <View style={[styles.tabPanel, selectedTab !== 0 && styles.tabPanelHidden]}>
              {SettingsPanel}
            </View>
            <View style={[styles.tabPanel, selectedTab !== 1 && styles.tabPanelHidden]}>
              {FlutterContainer}
            </View>
          </View>
        </View>
      )}
    </SafeAreaView>
  );
};

const FlutterScreen = () => {
  return (
    <FlutterApp
      style={{
        flex: 1,
      }}
    />
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ffffff',
  },
  sideBySideContainer: {
    flex: 1,
    flexDirection: 'row',
  },
  settingsSide: {
    width: 400,
    borderRightWidth: 1,
    borderRightColor: '#e0e0e0',
  },
  flutterSide: {
    flex: 1,
  },
  tabbedContainer: {
    flex: 1,
    flexDirection: 'column',
  },
  tabBar: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
    backgroundColor: '#ffffff',
  },
  tabButton: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  tabButtonActive: {
    borderBottomColor: '#007AFF',
  },
  tabButtonText: {
    fontSize: 16,
    color: '#666666',
  },
  tabButtonTextActive: {
    color: '#007AFF',
    fontWeight: '600',
  },
  tabContent: {
    flex: 1,
  },
  tabPanel: {
    flex: 1,
  },
  tabPanelHidden: {
    display: 'none',
  },
  settingsContainer: {
    flex: 1,
  },
  settingsContent: {
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#000000',
    marginBottom: 16,
    textAlign: 'center',
  },
  section: {
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#000000',
    marginBottom: 8,
  },
  button: {
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    marginVertical: 4,
    alignItems: 'center',
  },
  buttonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '500',
  },
  flutterContainer: {
    flex: 1,
    backgroundColor: '#f0f0f0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  flutterApp: {
    flex: 1,
    width: '100%',
  },
  containerText: {
    fontSize: 16,
    color: '#666666',
    textAlign: 'center',
  },
});

export default App;

