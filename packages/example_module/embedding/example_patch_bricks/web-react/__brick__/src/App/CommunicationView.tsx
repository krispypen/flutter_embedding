import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import FormControl from '@mui/material/FormControl'
import MenuItem from '@mui/material/MenuItem'
import Select, { SelectChangeEvent } from '@mui/material/Select'
import TextField from '@mui/material/TextField'
import Typography from '@mui/material/Typography'
import type { ServerCallContext } from '@protobuf-ts/runtime-rpc'
import type {
  IHandoversToHostService,
} from 'counter-embedding-react'
import {
  ChangeLanguageRequest,
  ChangeThemeModeRequest,
  ExitRequest,
  ExitResponse,
  GetHostInfoRequest,
  GetHostInfoResponse,
  GetIncrementRequest,
  GetIncrementResponse,
  HandoversToFlutterServiceClient,
  Language,
  StartParams,
  ThemeMode
} from 'counter-embedding-react'
import React from 'react'

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
  const [currentIncrement, setCurrentIncrement] = React.useState<number>(1)

  // Refs to access current state in callbacks
  const incrementRef = React.useRef<number>(1)

  React.useEffect(() => {
    incrementRef.current = currentIncrement
  }, [currentIncrement])

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

  const createStartParams = React.useCallback((): StartParams => {
    return {
      language: currentLanguage,
      themeMode: currentThemeMode,
      environment: currentEnvironment
    }
  }, [currentLanguage, currentThemeMode, currentEnvironment])

  const createHandoversToHostService = React.useCallback((viewId: number): IHandoversToHostService => {
    class HandoversToHostService implements IHandoversToHostService {
      getHostInfo(_request: GetHostInfoRequest, _context: ServerCallContext): Promise<GetHostInfoResponse> {
        return Promise.resolve(GetHostInfoResponse.create({ framework: 'Web React' }))
      }

      getIncrement(_request: GetIncrementRequest, _context: ServerCallContext): Promise<GetIncrementResponse> {
        return Promise.resolve(GetIncrementResponse.create({ increment: incrementRef.current }))
      }

      exit(request: ExitRequest, _context: ServerCallContext): Promise<ExitResponse> {
        const counter = request.counter || 0
        console.log('Flutter app requested exit with counter:', counter)

        // Show popup with counter value
        alert(`Flutter Exit\n\nCounter: ${counter}`)

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
      <Typography variant="h6">Communication Settings</Typography>

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

      {/* Increment */}
      <TextField
        label="Increment"
        placeholder="Enter increment value"
        value={currentIncrement}
        onChange={(e) => setCurrentIncrement(parseInt(e.target.value) || 1)}
        type="number"
        size="small"
        fullWidth
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

    </Box>
  )
}

export default CommunicationView
