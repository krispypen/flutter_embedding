import React, { useState } from 'react';
import { FlutterApp, FlutterView } from './src';

// Example usage of the Flutter React Embedding Module
function ExampleApp() {
    const [showFlutter, setShowFlutter] = useState(false);
    const [language, setLanguage] = useState('en');
    const [themeMode, setThemeMode] = useState('light');

    // Mock Flutter app instance
    const flutterApp: FlutterApp = {
        addView: (options: { hostElement: HTMLElement | null }) => {
            console.log('Adding Flutter view to element:', options.hostElement);
            // In a real implementation, this would initialize the Flutter app
            // and return a view ID
            return 1;
        },
        removeView: (viewId: number) => {
            console.log('Removing Flutter view:', viewId);
            // In a real implementation, this would clean up the Flutter view
        }
    };

    return (
        <div style={{ padding: '20px' }}>
            <h1>Flutter React Embedding Example</h1>

            <div style={{ marginBottom: '20px' }}>
                <button
                    onClick={() => setShowFlutter(!showFlutter)}
                    style={{ marginRight: '10px' }}
                >
                    {showFlutter ? 'Hide' : 'Show'} Flutter View
                </button>

                <select
                    value={language}
                    onChange={(e) => setLanguage(e.target.value)}
                    style={{ marginRight: '10px' }}
                >
                    <option value="en">English</option>
                    <option value="es">Spanish</option>
                    <option value="fr">French</option>
                </select>

                <select
                    value={themeMode}
                    onChange={(e) => setThemeMode(e.target.value)}
                >
                    <option value="light">Light</option>
                    <option value="dark">Dark</option>
                </select>
            </div>

            {showFlutter && (
                <FlutterView
                    flutterApp={flutterApp}
                    removeView={() => setShowFlutter(false)}
                    currentLanguage={language}
                    currentThemeMode={themeMode}
                    className="example-flutter-view"
                />
            )}
        </div>
    );
}

export default ExampleApp;
