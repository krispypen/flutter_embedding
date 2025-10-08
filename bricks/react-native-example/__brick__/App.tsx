{{=<% %>=}}



/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * Generated with the TypeScript template
 * https://github.com/react-native-community/react-native-template-typescript
 *
 * @format
 */

import React from 'react';
import {
  Alert,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View
} from 'react-native';

import { NavigationContainer, useFocusEffect } from '@react-navigation/native';
import {
  FlutterEmbeddingModule,
} from 'flutter-rn-embedding';

import { createStackNavigator, StackScreenProps } from '@react-navigation/stack';
import { Dropdown } from 'react-native-element-dropdown';
import { ExampleHandoverResponder } from './ExampleHandoverResponder';
import { FlutterApp } from './FlutterApp';

type RootStackParamList = {
  Home: undefined;
  Flutter: undefined;
};

const Stack = createStackNavigator<RootStackParamList>();

const App = () => {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Flutter" component={FlutterScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

let handoverResponder: ExampleHandoverResponder;

const HomeScreen = ({
  navigation,
}: StackScreenProps<RootStackParamList, 'Home'>) => {
  const [currentEnvironment, setCurrentEnvironment] = React.useState<string>('DEV');
  const [currentLanguage, setCurrentLanguage] = React.useState<string>('en');
  const [currentThemeMode, setCurrentThemeMode] = React.useState<string>('system');
  const [isEngineStarted, setIsEngineStarted] = React.useState<boolean>(false);
  const [isFlutterInView, setIsFlutterInView] = React.useState<boolean>(false);

  // Use ref to access current state value in callbacks
  const isFlutterInViewRef = React.useRef<boolean>(false);

  // Update ref when state changes
  React.useEffect(() => {
    isFlutterInViewRef.current = isFlutterInView;
  }, [isFlutterInView]);

  // Sync isFlutterInView state with navigation
  useFocusEffect(
    React.useCallback(() => {
      // When HomeScreen is focused, Flutter is not in view
      setIsFlutterInView(false);
    }, [])
  );

  const languages = React.useMemo(() => [
    { value: 'en' },
    { value: 'nl' },
    { value: 'fr' },
  ], []);

  const themeModes = React.useMemo(() => [
    { value: 'light' },
    { value: 'dark' },
    { value: 'system' },
  ], []);

  const openApp = () => {
    setIsFlutterInView(true);
    navigation.navigate('Flutter');
  };

  const startEngine = async () => {
    handoverResponder = new ExampleHandoverResponder({
      exit: () => {
        if (isFlutterInViewRef.current) {
          removeFlutterView();
        } else {
          navigation.navigate('Home');
        }
      },
      invokeHandover: (name: string, data: any, completion: (response: any, error: any) => void) => {
        console.log("invokeHandover in app.tsx " + data);
        // show alert
        Alert.alert('Invoke handover', data);
        completion(null, null);
      },
    });

    try {
      await FlutterEmbeddingModule.startEngine({
        environment: currentEnvironment,
        handoverResponder: handoverResponder,
        language: currentLanguage,
        themeMode: currentThemeMode,
      });
      setIsEngineStarted(true);

      Alert.alert('Engine started', 'The Flutter engine is started successfully', [
        { text: 'OK', onPress: () => console.log('OK Pressed') },
      ]);
    } catch (error) {
      Alert.alert('Error', 'Something went wrong when starting the engine' + error, [
        { text: 'OK' },
      ]);
    }
  };

  const stopEngine = () => {
    FlutterEmbeddingModule.stopEngine();
    setIsEngineStarted(false);
    setIsFlutterInView(false);
  };

  const startFlutterInView = () => {
    if (!isEngineStarted) {
      Alert.alert('Error', 'Please start the Flutter engine first', [
        { text: 'OK' },
      ]);
      return;
    }
    setIsFlutterInView(true);
  };

  const removeFlutterView = () => {
    setIsFlutterInView(false);
  };

  const changeLanguage = async () => {
    let response = await FlutterEmbeddingModule.changeLanguage({ language: currentLanguage });

    Alert.alert(
      'Change language',
      response === true
        ? 'Successfully changed language'
        : 'Something went wrong (when changing language)',
      [{ text: 'OK' }]
    );
  };

  const changeThemeMode = async () => {
    setCurrentThemeMode(currentThemeMode);
    let response = await FlutterEmbeddingModule.changeThemeMode({ themeMode: currentThemeMode });

    Alert.alert(
      'Change theme mode',
      response === true
        ? 'Successfully changed theme mode'
        : 'Something went wrong (when changing theme mode)',
      [{ text: 'OK' }]
    );
  };

  const showHandoverAlert = () => {
    FlutterEmbeddingModule.invokeHandover('handoverDemo', { data: 'Hello from React Native' });
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle={'dark-content'} />
      <ScrollView contentInsetAdjustmentBehavior="automatic">
        <View style={styles.content}>
          {/* Title */}
          <Text style={styles.title}>Flutter Embedding Demo</Text>

          {/* Engine Controls */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Flutter Engine Controls</Text>

            {!isEngineStarted ? (
              <TouchableOpacity style={styles.button} onPress={startEngine}>
                <Text style={styles.buttonText}>Start Flutter Engine</Text>
              </TouchableOpacity>
            ) : (
              <TouchableOpacity style={styles.button} onPress={stopEngine}>
                <Text style={styles.buttonText}>Stop Flutter Engine</Text>
              </TouchableOpacity>
            )}
          </View>

          {/* Flutter App Controls */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Flutter App</Text>

            <TouchableOpacity style={styles.button} onPress={openApp}>
              <Text style={styles.buttonText}>Open in new screen</Text>
            </TouchableOpacity>

            {!isFlutterInView ? (
              <TouchableOpacity style={styles.button} onPress={startFlutterInView}>
                <Text style={styles.buttonText}>Open in view</Text>
              </TouchableOpacity>
            ) : (
              <TouchableOpacity style={styles.button} onPress={removeFlutterView}>
                <Text style={styles.buttonText}>Remove Flutter View</Text>
              </TouchableOpacity>
            )}
          </View>

          {/* Theme Mode */}
          <View style={styles.section}>
            <View style={styles.themeRow}>
              <Text style={styles.sectionTitle}>Theme Mode:</Text>
              <Dropdown
                data={themeModes}
                maxHeight={300}
                labelField="value"
                valueField="value"
                value={currentThemeMode}
                onChange={item => {
                  setCurrentThemeMode(item.value);
                }}
                style={styles.dropdownRow}
              />
            </View>
            {isEngineStarted && (
              <TouchableOpacity style={styles.button} onPress={changeThemeMode}>
                <Text style={styles.buttonText}>Update Theme Mode</Text>
              </TouchableOpacity>
            )}
          </View>

          {/* Language Section */}
          <View style={styles.section}>
            <View style={styles.languageRow}>
              <Text style={styles.sectionTitle}>Language</Text>
              <Dropdown
                data={languages}
                maxHeight={300}
                labelField="value"
                valueField="value"
                value={currentLanguage}
                onChange={item => {
                  setCurrentLanguage(item.value);
                }}
                style={styles.dropdownRow}
              />
            </View>
            {isEngineStarted && (
              <TouchableOpacity style={styles.button} onPress={changeLanguage}>
                <Text style={styles.buttonText}>Update Language</Text>
              </TouchableOpacity>
            )}
          </View>

          {/* Handover Controls */}
          {isEngineStarted && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Handover Controls</Text>

              <TouchableOpacity style={styles.button} onPress={showHandoverAlert}>
                <Text style={styles.buttonText}>Invoke handover</Text>
              </TouchableOpacity>
            </View>
          )}

          {/* Flutter Container */}
          <View style={styles.flutterContainer}>
            {isFlutterInView ? (
              <FlutterApp style={styles.flutterApp} />
            ) : (
              <Text style={styles.containerText}>Flutter container area</Text>
            )}
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const FlutterScreen = () => {
  // This would need access to the parent state, but since it's in a different component,
  // we'll handle this differently by updating the state when navigating
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
  content: {
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
    marginBottom: 2,
  },
  infoText: {
    fontSize: 14,
    color: '#666666',
    marginBottom: 12,
  },
  button: {
    backgroundColor: '#007AFF',
    paddingVertical: 4,
    paddingHorizontal: 16,
    marginVertical: 2,
    alignItems: 'center',
  },
  buttonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '500',
  },
  dropdown: {
    marginVertical: 8,
  },
  themeRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginBottom: 8,
    paddingTop: 8,
  },
  languageRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginBottom: 8,
    paddingTop: 8,
  },
  dropdownRow: {
    flex: 1,
    marginLeft: 16,
    marginTop: 0,
  },
  flutterContainer: {
    backgroundColor: '#f0f0f0',
    minHeight: 300,
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

<%={{ }}=%>