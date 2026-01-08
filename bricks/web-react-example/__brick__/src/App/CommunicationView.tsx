//{{=<% %>=}}
import type {
  BottomBarItemPressedRequest,
  BottomBarItemPressedResponse,
  IHandoversToHostService,
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
  StartTransactionSigningRequest,
  StartTransactionSigningResponse
} from '<% webReactPackageName %>'
import {
  BottomBarConfiguration,
  BottomBarItemPressedResponse as BottomBarItemPressedResponseType,
  ChangeLanguageRequest,
  ChangeThemeModeRequest,
  ExitRequest,
  ExitResponse,
  GetAccessTokenRequest,
  GetAccessTokenResponse,
  GetHostInfoRequest,
  GetHostInfoResponse,
  HandleNotificationRequest,
  HandoversToFlutterServiceClient,
  InvestSuiteNotificationData,
  Language,
  OnExitResponse as OnExitResponseType,
  ProvideAccessTokenResponse as ProvideAccessTokenResponseType,
  ProvideAnonymousAccessTokenResponse as ProvideAnonymousAccessTokenResponseType,
  ReceiveAnalyticsEventResponse as ReceiveAnalyticsEventResponseType,
  ReceiveDebugLogResponse as ReceiveDebugLogResponseType,
  ReceiveErrorResponse as ReceiveErrorResponseType,
  ResetRequest,
  StartAddMoneyResponse as StartAddMoneyResponseType,
  StartAuthorizationResponse as StartAuthorizationResponseType,
  StartFaqResponse as StartFaqResponseType,
  StartFundPortfolioResponse as StartFundPortfolioResponseType,
  StartOnboardingResponse as StartOnboardingResponseType,
  StartParams,
  StartTransactionSigningResponse as StartTransactionSigningResponseType,
  ThemeMode
} from '<% webReactPackageName %>'
import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import FormControl from '@mui/material/FormControl'
import MenuItem from '@mui/material/MenuItem'
import Select, { SelectChangeEvent } from '@mui/material/Select'
import TextField from '@mui/material/TextField'
import Typography from '@mui/material/Typography'
import type { ServerCallContext } from '@protobuf-ts/runtime-rpc'
import React from 'react'
import BottomBarConfigurationView from './BottomBarConfigurationView'

interface CommunicationViewProps {
  hasViews: boolean
  handoversToFlutterServiceClients: HandoversToFlutterServiceClient[]
  onRemoveView?: (viewId: number) => void
  methodsRef?: React.MutableRefObject<CommunicationViewMethods | null>
}

export interface CommunicationViewMethods {
  createStartParams: () => StartParams
  createHandoversToHostService: (viewId: number) => IHandoversToHostService
}

const environments = ['MOCK', 'TST']

function CommunicationView({
  hasViews,
  handoversToFlutterServiceClients,
  onRemoveView,
  methodsRef
}: CommunicationViewProps) {
  // Internal state
  const [currentEnvironment, setCurrentEnvironment] = React.useState<string>('MOCK')
  const [currentLanguage, setCurrentLanguage] = React.useState<Language>(Language.EN)
  const [currentThemeMode, setCurrentThemeMode] = React.useState<ThemeMode>(ThemeMode.SYSTEM)
  const [accessToken, setAccessToken] = React.useState<string>('')
  const [bottomBarEnabled, setBottomBarEnabled] = React.useState<boolean>(false)
  const [bottomBarConfiguration, setBottomBarConfiguration] = React.useState<BottomBarConfiguration | undefined>(undefined)

  // Refs to access current state in callbacks
  const accessTokenRef = React.useRef<string>(accessToken)

  React.useEffect(() => {
    accessTokenRef.current = accessToken
  }, [accessToken])

  const handleEnvironmentChange = (event: SelectChangeEvent) => {
    setCurrentEnvironment(event.target.value)
  }

  const handleLanguageChange = (event: SelectChangeEvent<Language>) => {
    const newLanguage = event.target.value as Language
    setCurrentLanguage(newLanguage)
  }

  const handleThemeModeChange = (event: SelectChangeEvent<ThemeMode>) => {
    const newThemeMode = event.target.value as ThemeMode
    setCurrentThemeMode(newThemeMode)
  }

  const handleChangeLanguage = async () => {
    const request = ChangeLanguageRequest.create({ language: currentLanguage })
    for (const client of handoversToFlutterServiceClients) {
      try {
        await client.changeLanguage(request)
        console.log('Language changed successfully')
      } catch (error) {
        console.error('Error changing language:', error)
      }
    }
  }

  const handleChangeThemeMode = async () => {
    const request = ChangeThemeModeRequest.create({ themeMode: currentThemeMode })
    for (const client of handoversToFlutterServiceClients) {
      try {
        await client.changeThemeMode(request)
        console.log('Theme mode changed successfully')
      } catch (error) {
        console.error('Error changing theme mode:', error)
      }
    }
  }

  const handleNotification = async () => {
    const notificationData = InvestSuiteNotificationData.create({
      id: 'demo-notification-123',
      title: 'Demo Notification',
      body: 'This is a demo notification body',
      type: 'CASH_DEPOSIT_EXECUTED',
      module: 'SELF',
      createdAt: BigInt(Date.now()),
      data: { portfolio_id: 'DEMO' }
    })

    const request = HandleNotificationRequest.create({
      notificationData: notificationData
    })

    for (const client of handoversToFlutterServiceClients) {
      try {
        await client.handleNotification(request)
        console.log('Handle notification called successfully')
      } catch (error) {
        console.error('Error handling notification:', error)
      }
    }
  }

  const handleReset = async (clearData: boolean) => {
    const request = ResetRequest.create({ clearData })

    for (const client of handoversToFlutterServiceClients) {
      try {
        await client.reset(request)
        console.log(`Reset called with clearData=${clearData}`)
      } catch (error) {
        console.error('Error resetting:', error)
      }
    }
  }

  const createStartParams = React.useCallback((): StartParams => {
    const params: StartParams = {
      language: currentLanguage,
      themeMode: currentThemeMode,
      environment: currentEnvironment
    }
    if (bottomBarConfiguration) {
      params.bottomBarConfiguration = bottomBarConfiguration
    }
    return params
  }, [currentLanguage, currentThemeMode, currentEnvironment, bottomBarConfiguration])

  const createHandoversToHostService = React.useCallback((viewId: number): IHandoversToHostService => {
    class HandoversToHostService implements IHandoversToHostService {
      provideAccessToken(_request: ProvideAccessTokenRequest, _context: ServerCallContext): Promise<ProvideAccessTokenResponse> {
        console.log('provideAccessToken called')
        return Promise.resolve(ProvideAccessTokenResponseType.create({ accessToken: accessTokenRef.current }))
      }

      provideAnonymousAccessToken(_request: ProvideAnonymousAccessTokenRequest, _context: ServerCallContext): Promise<ProvideAnonymousAccessTokenResponse> {
        console.log('provideAnonymousAccessToken called')
        return Promise.resolve(ProvideAnonymousAccessTokenResponseType.create({ anonymousAccessToken: '' }))
      }

      receiveAnalyticsEvent(request: ReceiveAnalyticsEventRequest, _context: ServerCallContext): Promise<ReceiveAnalyticsEventResponse> {
        console.log('receiveAnalyticsEvent:', request.name, request.parameters)
        return Promise.resolve(ReceiveAnalyticsEventResponseType.create({}))
      }

      receiveDebugLog(request: ReceiveDebugLogRequest, _context: ServerCallContext): Promise<ReceiveDebugLogResponse> {
        console.log('receiveDebugLog:', request.level, request.message)
        return Promise.resolve(ReceiveDebugLogResponseType.create({}))
      }

      receiveError(request: ReceiveErrorRequest, _context: ServerCallContext): Promise<ReceiveErrorResponse> {
        console.error('receiveError:', request.errorCode, request.data)
        return Promise.resolve(ReceiveErrorResponseType.create({}))
      }

      onExit(_request: OnExitRequest, _context: ServerCallContext): Promise<OnExitResponse> {
        console.log('onExit called')
        if (onRemoveView) {
          onRemoveView(viewId)
        }
        return Promise.resolve(OnExitResponseType.create({}))
      }

      startFaq(request: StartFaqRequest, _context: ServerCallContext): Promise<StartFaqResponse> {
        console.log('startFaq:', request.module)
        alert('startFaq called' + (request.module !== undefined ? ` for module: ${request.module}` : ''))
        return Promise.resolve(StartFaqResponseType.create({}))
      }

      startOnboarding(_request: StartOnboardingRequest, _context: ServerCallContext): Promise<StartOnboardingResponse> {
        console.log('startOnboarding called')
        alert('startOnboarding called')
        return Promise.resolve(StartOnboardingResponseType.create({ success: true }))
      }

      startFundPortfolio(request: StartFundPortfolioRequest, _context: ServerCallContext): Promise<StartFundPortfolioResponse> {
        console.log('startFundPortfolio:', request.portfolioData)
        alert('startFundPortfolio called')
        return Promise.resolve(StartFundPortfolioResponseType.create({ success: true }))
      }

      startAddMoney(request: StartAddMoneyRequest, _context: ServerCallContext): Promise<StartAddMoneyResponse> {
        console.log('startAddMoney:', request.portfolioData)
        alert('startAddMoney called')
        return Promise.resolve(StartAddMoneyResponseType.create({ success: true }))
      }

      startAuthorization(_request: StartAuthorizationRequest, _context: ServerCallContext): Promise<StartAuthorizationResponse> {
        console.log('startAuthorization called')
        alert('startAuthorization called')
        return Promise.resolve(StartAuthorizationResponseType.create({ success: true }))
      }

      startTransactionSigning(request: StartTransactionSigningRequest, _context: ServerCallContext): Promise<StartTransactionSigningResponse> {
        console.log('startTransactionSigning:', request.portfolioId, request.amount, request.type)
        alert('startTransactionSigning called')
        return Promise.resolve(StartTransactionSigningResponseType.create({ success: true }))
      }

      bottomBarItemPressed(request: BottomBarItemPressedRequest, _context: ServerCallContext): Promise<BottomBarItemPressedResponse> {
        console.log('bottomBarItemPressed:', request.url)
        alert('Bottom bar item pressed with URL: ' + request.url)
        return Promise.resolve(BottomBarItemPressedResponseType.create({ success: true }))
      }

      getHostInfo(_request: GetHostInfoRequest, _context: ServerCallContext): Promise<GetHostInfoResponse> {
        return Promise.resolve(GetHostInfoResponse.create({ framework: 'Web React' }))
      }

      getAccessToken(_request: GetAccessTokenRequest, _context: ServerCallContext): Promise<GetAccessTokenResponse> {
        return Promise.resolve(GetAccessTokenResponse.create({ accessToken: accessTokenRef.current }))
      }

      exit(request: ExitRequest, _context: ServerCallContext): Promise<ExitResponse> {
        console.log('Exit requested to host:', request.reason)
        if (onRemoveView) {
          onRemoveView(viewId)
        }
        return Promise.resolve(ExitResponse.create({ success: true }))
      }
    }

    return new HandoversToHostService()
  }, [onRemoveView])

  // Expose methods via methodsRef
  React.useEffect(() => {
    if (methodsRef) {
      methodsRef.current = {
        createStartParams,
        createHandoversToHostService
      }
    }
  }, [createStartParams, createHandoversToHostService, methodsRef])

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, p: 2 }}>
      <Typography variant="h6">Handovers:</Typography>

      {/* Environment Selection */}
      <FormControl fullWidth size="small">
        <Typography variant="body2">Select Environment:</Typography>
        <Select
          value={currentEnvironment}
          onChange={handleEnvironmentChange}
          disabled={hasViews}
        >
          {environments.map((env) => (
            <MenuItem key={env} value={env}>{env}</MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* Access Token */}
      <TextField
        label="Access Token"
        placeholder="Paste access token here"
        value={accessToken}
        onChange={(e) => setAccessToken(e.target.value)}
        size="small"
        fullWidth
        multiline
        rows={2}
      />

      {/* Theme Mode */}
      <FormControl fullWidth size="small">
        <Typography variant="body2">Select Theme Mode:</Typography>
        <Select
          value={currentThemeMode}
          onChange={handleThemeModeChange}
        >
          <MenuItem value={ThemeMode.LIGHT}>light</MenuItem>
          <MenuItem value={ThemeMode.DARK}>dark</MenuItem>
          <MenuItem value={ThemeMode.SYSTEM}>system</MenuItem>
        </Select>
      </FormControl>

      {hasViews && (
        <Button
          variant="contained"
          onClick={handleChangeThemeMode}
          fullWidth
        >
          changeThemeMode
        </Button>
      )}

      {/* Language */}
      <FormControl fullWidth size="small">
        <Typography variant="body2">Select Language:</Typography>
        <Select
          value={currentLanguage}
          onChange={handleLanguageChange}
        >
          <MenuItem value={Language.EN}>en</MenuItem>
          <MenuItem value={Language.FR}>fr</MenuItem>
          <MenuItem value={Language.NL}>nl</MenuItem>
        </Select>
      </FormControl>

      {hasViews && (
        <Button
          variant="contained"
          onClick={handleChangeLanguage}
          fullWidth
        >
          changeLanguage
        </Button>
      )}

      {/* Handle Notification Button */}
      {hasViews && (
        <Button
          variant="contained"
          onClick={handleNotification}
          fullWidth
        >
          handleNotification (CASH_DEPOSIT_EXECUTED)
        </Button>
      )}

      {/* Reset Buttons */}
      {hasViews && (
        <>
          <Button
            variant="contained"
            onClick={() => handleReset(false)}
            fullWidth
          >
            reset
          </Button>
          <Button
            variant="contained"
            onClick={() => handleReset(true)}
            fullWidth
            color="warning"
          >
            reset & clearData
          </Button>
        </>
      )}

      {/* Bottom Bar Configuration */}
      <BottomBarConfigurationView
        enabled={bottomBarEnabled}
        onEnabledChange={setBottomBarEnabled}
        onConfigurationChange={setBottomBarConfiguration}
        hasViews={hasViews}
      />
    </Box>
  )
}

export default CommunicationView

