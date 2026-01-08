//{{=<% %>=}}
import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import CssBaseline from '@mui/material/CssBaseline'
import Tab from '@mui/material/Tab'
import Tabs from '@mui/material/Tabs'
import Typography from '@mui/material/Typography'
import useMediaQuery from '@mui/material/useMediaQuery'
import {
  FlutterEmbeddingState,
  FlutterEmbeddingView,
  HandoversToFlutterServiceClient,
  Language,
  ThemeMode
} from '<% webReactPackageName %>'
import React from 'react'
import CommunicationView, { CommunicationViewMethods } from './CommunicationView'

interface View {
  id: number
  state: FlutterEmbeddingState | null
  handoversToFlutterServiceClient: HandoversToFlutterServiceClient | null
}

function App() {
  // Responsive layout: >= 600 is side-by-side, < 600 is tabs
  const isLargeScreen = useMediaQuery('(min-width:600px)')
  const [selectedTab, setSelectedTab] = React.useState(0)

  // State
  const [views, setViews] = React.useState<View[]>([])

  // Ref to CommunicationView methods
  const communicationViewMethodsRef = React.useRef<CommunicationViewMethods | null>(null)

  // Derived state - engine is "running" when there are views
  const hasViews = views.length > 0

  const addView = () => {
    setViews((flutterViewKeys) => {
      return [
        ...flutterViewKeys,
        {
          id: (flutterViewKeys[flutterViewKeys.length - 1]?.id ?? 0) + 1,
          state: null,
          handoversToFlutterServiceClient: null
        }
      ]
    })
  }

  const removeView = (id: number) => {
    setViews((flutterViewKeys) => flutterViewKeys.filter(k => k.id !== id))
  }

  const handleTabChange = (_event: React.SyntheticEvent, newValue: number) => {
    setSelectedTab(newValue)
  }

  const handoversToFlutterServiceClients = views
    .map(v => v.handoversToFlutterServiceClient)
    .filter((client): client is HandoversToFlutterServiceClient => client !== null)

  // Settings Panel Content
  const SettingsPanel = (
    <Box sx={{
      height: '100%',
      overflow: 'auto',
      p: 2,
      borderRight: isLargeScreen ? '1px solid #e0e0e0' : 'none'
    }}>
      <Typography variant="h5" component="h2" gutterBottom>
        <% flutterEmbeddingName %> Demo
      </Typography>

      <Button
        fullWidth
        variant="contained"
        onClick={addView}
        sx={{ mb: 2 }}
      >
        Add Flutter view
      </Button>

      <CommunicationView
        hasViews={hasViews}
        handoversToFlutterServiceClients={handoversToFlutterServiceClients}
        onRemoveView={removeView}
        methodsRef={communicationViewMethodsRef}
      />
    </Box>
  )

  // Flutter Container Content
  const FlutterContainer = (
    <Box sx={{
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      backgroundColor: '#f0f0f0',
      overflow: 'hidden'
    }}>
      {views.length === 0 ? (
        <Box sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100%',
          color: '#666'
        }}>
          <Typography variant="h6">Flutter container area</Typography>
        </Box>
      ) : (
        views.map((view) => (
          <Box key={view.id} sx={{
            flex: 1,
            display: 'flex',
            flexDirection: 'column',
            position: 'relative',
            minHeight: '300px',
            width: '100%'
          }}>
            <Box sx={{
              position: 'absolute',
              top: 8,
              right: 8,
              zIndex: 10
            }}>
              <Button
                variant="contained"
                size="small"
                color="error"
                onClick={() => removeView(view.id)}
              >
                Remove View {view.id}
              </Button>
            </Box>
            <FlutterEmbeddingView
              key={view.id}
              className="flutter-embedding-view"
              onInvokeHandover={(method: string, args: unknown) => {
                alert('Invoke handover: ' + method + ' ' + JSON.stringify(args))
                return 'Hello back to Flutter'
              }}
              startParams={communicationViewMethodsRef.current?.createStartParams() ?? { language: Language.EN, themeMode: ThemeMode.SYSTEM, environment: 'MOCK' }}
              handoversToHostService={communicationViewMethodsRef.current!.createHandoversToHostService(view.id)}
              initState={(state: FlutterEmbeddingState, handoversToFlutterServiceClient: HandoversToFlutterServiceClient) => {
                setViews(prevViews => prevViews.map(v =>
                  v.id === view.id
                    ? { ...v, state, handoversToFlutterServiceClient }
                    : v
                ))
              }}
            />
          </Box>
        ))
      )}
    </Box>
  )

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100vh', overflow: 'hidden' }}>
      <CssBaseline />

      {isLargeScreen ? (
        // Large screen: Side-by-side layout
        <Box sx={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
          <Box sx={{ width: 400, flexShrink: 0, overflow: 'auto' }}>
            {SettingsPanel}
          </Box>
          <Box sx={{ flex: 1, overflow: 'hidden' }}>
            {FlutterContainer}
          </Box>
        </Box>
      ) : (
        // Small screen: Tabbed layout
        <Box sx={{ display: 'flex', flexDirection: 'column', height: '100vh', overflow: 'hidden', width: '100%' }}>
          <Tabs
            value={selectedTab}
            onChange={handleTabChange}
            variant="fullWidth"
            sx={{ borderBottom: 1, borderColor: 'divider' }}
          >
            <Tab label="Settings" />
            <Tab label="Flutter" />
          </Tabs>
          <Box sx={{ flex: 1, overflow: 'hidden' }}>
            {selectedTab === 0 ? (
              <Box sx={{ height: '100%', overflow: 'auto' }}>
                {SettingsPanel}
              </Box>
            ) : (
              FlutterContainer
            )}
          </Box>
        </Box>
      )}
    </Box>
  )
}

export default App
