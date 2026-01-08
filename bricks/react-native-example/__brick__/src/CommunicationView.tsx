import { ServerCallContext } from '@protobuf-ts/runtime-rpc';
import React from 'react';
import {
    Alert,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    View,
} from 'react-native';
import { Dropdown } from 'react-native-element-dropdown';
import {
    ChangeLanguageRequest,
    ChangeThemeModeRequest,
    FlutterEmbeddingModule,
    HandleNotificationRequest,
    HandoversToFlutterServiceClient,
    IHandoversToHostService,
    InvestSuiteNotificationData,
    Language,
    OnExitRequest,
    OnExitResponse,
    ProvideAccessTokenRequest,
    ProvideAccessTokenResponse,
    ProvideAnonymousAccessTokenRequest,
    ProvideAnonymousAccessTokenResponse,
    ReceiveAnalyticsEventRequest,
    ReceiveAnalyticsEventResponse,
    ReceiveDebugLogRequest,
    ReceiveDebugLogResponse,
    ReceiveErrorRequest,
    ReceiveErrorResponse,
    ResetRequest,
    StartAddMoneyRequest,
    StartAddMoneyResponse,
    StartAuthorizationRequest,
    StartAuthorizationResponse,
    StartFaqRequest,
    StartFaqResponse,
    StartFundPortfolioRequest,
    StartFundPortfolioResponse,
    StartOnboardingRequest,
    StartOnboardingResponse,
    StartParams,
    StartTransactionSigningRequest,
    StartTransactionSigningResponse,
    ThemeMode,
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
    const [accessToken, setAccessToken] = React.useState<string>('');
    const [isEngineStarted, setIsEngineStarted] = React.useState<boolean>(false);
    const [handoversToFlutterServiceClient, setHandoversToFlutterServiceClient] = React.useState<HandoversToFlutterServiceClient | null>(null);

    // Refs to access current state in callbacks
    const accessTokenRef = React.useRef<string>('');

    React.useEffect(() => {
        accessTokenRef.current = accessToken;
    }, [accessToken]);

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
            provideAccessToken(_request: ProvideAccessTokenRequest, _context: ServerCallContext): Promise<ProvideAccessTokenResponse> {
                console.log('provideAccessToken called');
                return Promise.resolve(ProvideAccessTokenResponse.create({ accessToken: accessTokenRef.current }));
            },
            provideAnonymousAccessToken(_request: ProvideAnonymousAccessTokenRequest, _context: ServerCallContext): Promise<ProvideAnonymousAccessTokenResponse> {
                console.log('provideAnonymousAccessToken called');
                return Promise.resolve(ProvideAnonymousAccessTokenResponse.create({ anonymousAccessToken: '' }));
            },
            receiveAnalyticsEvent(request: ReceiveAnalyticsEventRequest, _context: ServerCallContext): Promise<ReceiveAnalyticsEventResponse> {
                console.log('receiveAnalyticsEvent:', request.name, request.parameters);
                return Promise.resolve(ReceiveAnalyticsEventResponse.create({}));
            },
            receiveDebugLog(request: ReceiveDebugLogRequest, _context: ServerCallContext): Promise<ReceiveDebugLogResponse> {
                console.log('receiveDebugLog:', request.level, request.message);
                return Promise.resolve(ReceiveDebugLogResponse.create({}));
            },
            receiveError(request: ReceiveErrorRequest, _context: ServerCallContext): Promise<ReceiveErrorResponse> {
                console.error('receiveError:', request.errorCode, request.data);
                return Promise.resolve(ReceiveErrorResponse.create({}));
            },
            onExit(_request: OnExitRequest, _context: ServerCallContext): Promise<OnExitResponse> {
                console.log('onExit called');
                onFlutterExit();
                return Promise.resolve(OnExitResponse.create({}));
            },
            startFaq(request: StartFaqRequest, _context: ServerCallContext): Promise<StartFaqResponse> {
                console.log('startFaq:', request.module);
                Alert.alert('startFaq called', request.module !== undefined ? `for module: ${request.module}` : '');
                return Promise.resolve(StartFaqResponse.create({}));
            },
            startOnboarding(_request: StartOnboardingRequest, _context: ServerCallContext): Promise<StartOnboardingResponse> {
                console.log('startOnboarding called');
                Alert.alert('startOnboarding called');
                return Promise.resolve(StartOnboardingResponse.create({ success: true }));
            },
            startFundPortfolio(request: StartFundPortfolioRequest, _context: ServerCallContext): Promise<StartFundPortfolioResponse> {
                console.log('startFundPortfolio:', request.portfolioData);
                Alert.alert('startFundPortfolio called');
                return Promise.resolve(StartFundPortfolioResponse.create({ success: true }));
            },
            startAddMoney(request: StartAddMoneyRequest, _context: ServerCallContext): Promise<StartAddMoneyResponse> {
                console.log('startAddMoney:', request.portfolioData);
                Alert.alert('startAddMoney called');
                return Promise.resolve(StartAddMoneyResponse.create({ success: true }));
            },
            startAuthorization(_request: StartAuthorizationRequest, _context: ServerCallContext): Promise<StartAuthorizationResponse> {
                console.log('startAuthorization called');
                Alert.alert('startAuthorization called');
                return Promise.resolve(StartAuthorizationResponse.create({ success: true }));
            },
            startTransactionSigning(request: StartTransactionSigningRequest, _context: ServerCallContext): Promise<StartTransactionSigningResponse> {
                console.log('startTransactionSigning:', request.portfolioId, request.amount, request.type);
                Alert.alert('startTransactionSigning called');
                return Promise.resolve(StartTransactionSigningResponse.create({ success: true }));
            },
            bottomBarItemPressed(request: BottomBarItemPressedRequest, _context: ServerCallContext): Promise<BottomBarItemPressedResponse> {
                console.log('bottomBarItemPressed:', request.url);
                Alert.alert('Bottom Bar Item Pressed', request.url);
                return Promise.resolve(BottomBarItemPressedResponse.create({}));
            },
        };
    }, [onFlutterExit]);

    const createStartParams = React.useCallback((): StartParams => {
        const params = StartParams.create({
            language: currentLanguage,
            themeMode: currentThemeMode,
            environment: currentEnvironment,
        });
        if (bottomBarConfiguration) {
            params.bottomBarConfiguration = bottomBarConfiguration;
        }
        return params;
    }, [currentLanguage, currentThemeMode, currentEnvironment, bottomBarConfiguration]);

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

    const handleNotification = async () => {
        if (!handoversToFlutterServiceClient) {
            Alert.alert('Error', 'Flutter service client not available');
            return;
        }
        try {
            const notificationData = InvestSuiteNotificationData.create({
                id: 'demo-notification-123',
                title: 'Demo Notification',
                body: 'This is a demo notification body',
                type: 'CASH_DEPOSIT_EXECUTED',
                module: 'SELF',
                createdAt: BigInt(Date.now()),
                data: { portfolio_id: 'DEMO' },
            });

            const request = HandleNotificationRequest.create({
                notificationData,
            });

            await handoversToFlutterServiceClient.handleNotification(request);
            console.log('Handle notification called successfully');
        } catch (error) {
            Alert.alert('Error', 'Failed to handle notification: ' + error);
        }
    };

    const reset = async (clearData: boolean) => {
        if (!handoversToFlutterServiceClient) {
            Alert.alert('Error', 'Flutter service client not available');
            return;
        }
        try {
            const request = ResetRequest.create({ clearData });
            await handoversToFlutterServiceClient.reset(request);
            console.log(`Reset called with clearData=${clearData}`);
        } catch (error) {
            Alert.alert('Error', 'Failed to reset: ' + error);
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

            {/* Access Token */}
            <View style={styles.section}>
                <Text style={styles.sectionTitle}>Access Token:</Text>
                <TextInput
                    style={[styles.input, isEngineStarted && styles.inputDisabled]}
                    placeholder="Paste access token here"
                    value={accessToken}
                    onChangeText={setAccessToken}
                    editable={!isEngineStarted}
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

