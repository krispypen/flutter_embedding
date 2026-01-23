import { ServerCallContext } from '@protobuf-ts/runtime-rpc';
import React from 'react';
import {
    Alert,
    StyleSheet,
    Text,
    TouchableOpacity,
    View,
} from 'react-native';
import { Dropdown } from 'react-native-element-dropdown';
import {
    ChangeLanguageRequest,
    ChangeThemeModeRequest,
    ExitRequest,
    ExitResponse,
    FlutterEmbeddingModule,
    GetHostInfoRequest,
    GetHostInfoResponse,
    GetIncrementRequest,
    GetIncrementResponse,
    HandoversToFlutterServiceClient,
    IHandoversToHostService,
    Language,
    StartParams,
    ThemeMode
} from '{{reactNativePackageName}}';

interface CommunicationViewProps {
    onFlutterExit: () => void;
    onEngineStateChange: (isStarted: boolean) => void;
    onHandoversToFlutterServiceClientChange: (client: HandoversToFlutterServiceClient | null) => void;
}

const CommunicationView = React.forwardRef<{ startEngine: (callback: (success: boolean, error?: Error) => void) => void }, CommunicationViewProps>(({
    onFlutterExit,
    onEngineStateChange,
    onHandoversToFlutterServiceClientChange,
}, ref) => {
    // State
    const [currentEnvironment, setCurrentEnvironment] = React.useState<string>('MOCK');
    const [currentLanguage, setCurrentLanguage] = React.useState<Language>(Language.EN);
    const [currentThemeMode, setCurrentThemeMode] = React.useState<ThemeMode>(ThemeMode.SYSTEM);
    const [currentIncrement, setCurrentIncrement] = React.useState<number>(1);
    const [isEngineStarted, setIsEngineStarted] = React.useState<boolean>(false);
    const [handoversToFlutterServiceClient, setHandoversToFlutterServiceClient] = React.useState<HandoversToFlutterServiceClient | null>(null);

    // Refs to access current state in callbacks
    const incrementRef = React.useRef<number>(1);

    React.useEffect(() => {
        incrementRef.current = currentIncrement;
    }, [currentIncrement]);

    React.useEffect(() => {
        onEngineStateChange(isEngineStarted);
    }, [isEngineStarted, onEngineStateChange]);

    React.useEffect(() => {
        onHandoversToFlutterServiceClientChange(handoversToFlutterServiceClient);
    }, [handoversToFlutterServiceClient, onHandoversToFlutterServiceClientChange]);

    const environments = React.useMemo(() => [
        { label: 'MOCK', value: 'MOCK' },
        { label: 'TST', value: 'TST' },
    ], []);

    const increments = React.useMemo(() => [
        { label: '1', value: 1 },
        { label: '2', value: 2 },
        { label: '3', value: 3 },
        { label: '4', value: 4 },
        { label: '5', value: 5 },
    ], []);

    const languages = React.useMemo(() => [
        { label: 'en', value: Language.EN },
        { label: 'fr', value: Language.FR },
        { label: 'nl', value: Language.NL },
    ], []);

    const themeModes = React.useMemo(() => [
        { label: 'light', value: ThemeMode.LIGHT },
        { label: 'dark', value: ThemeMode.DARK },
        { label: 'system', value: ThemeMode.SYSTEM },
    ], []);

    // Create HandoversToHostService
    const createHandoversToHostService = React.useCallback((): IHandoversToHostService => {
        return {
            getHostInfo(_request: GetHostInfoRequest, _context: ServerCallContext): Promise<GetHostInfoResponse> {
                return Promise.resolve(GetHostInfoResponse.create({ framework: 'React Native' }));
            },
            getIncrement(_request: GetIncrementRequest, _context: ServerCallContext): Promise<GetIncrementResponse> {
                return Promise.resolve(GetIncrementResponse.create({ increment: incrementRef.current }));
            },
            exit(request: ExitRequest, _context: ServerCallContext): Promise<ExitResponse> {
                const counter = request.counter || 0;
                console.log('Flutter app requested exit with counter:', counter);

                // Show popup with counter value
                Alert.alert(
                    'Flutter Exit',
                    `Counter: ${counter}`,
                    [
                        {
                            text: 'OK',
                            onPress: () => onFlutterExit()
                        }
                    ],
                    { cancelable: false }
                );

                onFlutterExit();

                return Promise.resolve(ExitResponse.create({ success: true }));
            },
        };
    }, [onFlutterExit]);

    const createStartParams = React.useCallback((): StartParams => {
        return StartParams.create({
            language: currentLanguage,
            themeMode: currentThemeMode,
            environment: currentEnvironment,
        });
    }, [currentLanguage, currentThemeMode, currentEnvironment]);

    const startEngine = React.useCallback(async (callback: (success: boolean, error?: Error) => void) => {
        try {
            await FlutterEmbeddingModule.startEngine({
                startParams: createStartParams(),
                handoversToHostService: createHandoversToHostService(),
            });

            setIsEngineStarted(true);

            // Get the handovers to flutter service client
            const client = FlutterEmbeddingModule.handoversToFlutterServiceClient();
            setHandoversToFlutterServiceClient(client);

            callback(true);
        } catch (error) {
            callback(false, error as Error);
        }
    }, [createStartParams, createHandoversToHostService]);

    // Expose startEngine via ref
    React.useImperativeHandle(ref, () => ({
        startEngine,
    }), [startEngine]);

    const changeLanguage = async () => {
        if (!handoversToFlutterServiceClient) {
            Alert.alert('Error', 'Flutter service client not available');
            return;
        }
        try {
            const request = ChangeLanguageRequest.create({ language: currentLanguage });
            await handoversToFlutterServiceClient.changeLanguage(request);
            console.log('Language changed successfully');
        } catch (error) {
            Alert.alert('Error', 'Failed to change language: ' + error);
        }
    };

    const changeThemeMode = async () => {
        if (!handoversToFlutterServiceClient) {
            Alert.alert('Error', 'Flutter service client not available');
            return;
        }
        try {
            const request = ChangeThemeModeRequest.create({ themeMode: currentThemeMode });
            await handoversToFlutterServiceClient.changeThemeMode(request);
            console.log('Theme mode changed successfully');
        } catch (error) {
            Alert.alert('Error', 'Failed to change theme mode: ' + error);
        }
    };

    return (
        <View style={styles.container}>
            {/* Environment */}
            <View style={styles.section}>
                <Text style={styles.sectionTitle}>Select Environment:</Text>
                <Dropdown
                    data={environments}
                    labelField="label"
                    valueField="value"
                    value={currentEnvironment}
                    onChange={item => setCurrentEnvironment(item.value)}
                    style={styles.dropdown}
                    disable={isEngineStarted}
                />
            </View>

            {/* Increment */}
            <View style={styles.section}>
                <Text style={styles.sectionTitle}>Select Increment:</Text>
                <Dropdown
                    data={increments}
                    labelField="label"
                    valueField="value"
                    value={currentIncrement}
                    onChange={item => setCurrentIncrement(item.value)}
                    style={styles.dropdown}
                />
            </View>

            {/* Theme Mode */}
            <View style={styles.section}>
                <Text style={styles.sectionTitle}>Select Theme Mode:</Text>
                <Dropdown
                    data={themeModes}
                    labelField="label"
                    valueField="value"
                    value={currentThemeMode}
                    onChange={item => setCurrentThemeMode(item.value)}
                    style={styles.dropdown}
                />
                {isEngineStarted && (
                    <TouchableOpacity style={styles.button} onPress={changeThemeMode}>
                        <Text style={styles.buttonText}>changeThemeMode</Text>
                    </TouchableOpacity>
                )}
            </View>

            {/* Language */}
            <View style={styles.section}>
                <Text style={styles.sectionTitle}>Select Language:</Text>
                <Dropdown
                    data={languages}
                    labelField="label"
                    valueField="value"
                    value={currentLanguage}
                    onChange={item => setCurrentLanguage(item.value)}
                    style={styles.dropdown}
                />
                {isEngineStarted && (
                    <TouchableOpacity style={styles.button} onPress={changeLanguage}>
                        <Text style={styles.buttonText}>changeLanguage</Text>
                    </TouchableOpacity>
                )}
            </View>


        </View>
    );
});

CommunicationView.displayName = 'CommunicationView';

const styles = StyleSheet.create({
    container: {
        flex: 1,
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
    dropdown: {
        backgroundColor: '#f0f0f0',
        borderRadius: 8,
        padding: 12,
        marginBottom: 8,
    },
    input: {
        backgroundColor: '#f0f0f0',
        borderRadius: 8,
        padding: 12,
        fontSize: 14,
    },
    inputDisabled: {
        opacity: 0.5,
    },
});

export default CommunicationView;

