package {{exampleAndroidPackageName}}

import android.content.res.Configuration
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ScrollView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.isVisible
import com.google.android.material.snackbar.Snackbar
import com.google.android.material.tabs.TabLayout
import {{flutterEmbeddingPackageName}}.{{flutterEmbeddingName}}

class MainActivity : AppCompatActivity() {

    private lateinit var communicationView: CommunicationView
    private lateinit var startEngineButton: Button
    private lateinit var stopEngineButton: Button
    private lateinit var startScreenButton: Button
    private lateinit var startViewButton: Button
    internal lateinit var removeViewButton: Button
    private lateinit var tabLayout: TabLayout
    private lateinit var settingsPanel: ScrollView
    private lateinit var flutterContainer: FrameLayout

    // State keys for saving instance state
    companion object {
        private const val KEY_ENGINE_RUNNING = "engine_running"
        private const val KEY_FLUTTER_VIEW_VISIBLE = "flutter_view_visible"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        setupViews()
        setupButtons()
        setupResponsiveLayout()
        
        // Restore state if available
        savedInstanceState?.let {
            restoreState(it)
        }
    }
    
    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        // Save the UI state
        outState.putBoolean(KEY_ENGINE_RUNNING, stopEngineButton.visibility == View.VISIBLE)
        outState.putBoolean(KEY_FLUTTER_VIEW_VISIBLE, removeViewButton.visibility == View.VISIBLE)
    }
    
    private fun restoreState(savedInstanceState: Bundle) {
        val engineRunning = savedInstanceState.getBoolean(KEY_ENGINE_RUNNING, false)
        val flutterViewVisible = savedInstanceState.getBoolean(KEY_FLUTTER_VIEW_VISIBLE, false)
        
        if (engineRunning) {
            // Engine was running before configuration change
            startEngineButton.visibility = View.GONE
            stopEngineButton.visibility = View.VISIBLE
            startScreenButton.visibility = View.VISIBLE
            startViewButton.visibility = if (flutterViewVisible) View.GONE else View.VISIBLE
            removeViewButton.visibility = if (flutterViewVisible) View.VISIBLE else View.GONE
            communicationView.setEngineRunning(true)
        } else {
            // Engine was not running
            startEngineButton.visibility = View.VISIBLE
            stopEngineButton.visibility = View.GONE
            startScreenButton.visibility = View.GONE
            startViewButton.visibility = View.GONE
            removeViewButton.visibility = View.GONE
            communicationView.setEngineRunning(false)
        }
    }

    private fun setupViews() {
        communicationView = findViewById(R.id.communication_view)
        communicationView.setMainActivity(this)
        startEngineButton = findViewById(R.id.start_engine_button)
        stopEngineButton = findViewById(R.id.stop_engine_button)
        startScreenButton = findViewById(R.id.start_screen_button)
        startViewButton = findViewById(R.id.start_view_button)
        removeViewButton = findViewById(R.id.remove_view_button)
        tabLayout = findViewById(R.id.tab_layout)
        settingsPanel = findViewById(R.id.settings_panel)
        flutterContainer = findViewById(R.id.flutter_container)
    }

    private fun setupResponsiveLayout() {
        updateLayoutForScreenSize()
    }
    
    private fun updateLayoutForScreenSize() {
        val widthDp = resources.configuration.screenWidthDp
        val density = resources.displayMetrics.density
        
        if (widthDp >= 600) {
            // Large screen (>= 600dp): show side-by-side, hide tabs
            tabLayout.visibility = View.GONE
            settingsPanel.visibility = View.VISIBLE
            flutterContainer.visibility = View.VISIBLE
            
            // Set settingsPanel to max 400dp width, flutterContainer takes remaining space via XML weight
            val maxWidthPx = (400 * density).toInt()
            val settingsParams = settingsPanel.layoutParams as android.widget.LinearLayout.LayoutParams
            settingsParams.width = maxWidthPx
            settingsParams.weight = 0f
            settingsPanel.layoutParams = settingsParams
        } else {
            // Small screen: show tabs, toggle between views
            tabLayout.visibility = View.VISIBLE
            
            // Reset settingsPanel to use weight (full width when visible)
            val settingsParams = settingsPanel.layoutParams as android.widget.LinearLayout.LayoutParams
            settingsParams.width = 0
            settingsParams.weight = 1f
            settingsPanel.layoutParams = settingsParams
            
            // Clear existing tabs to avoid duplicates when reconfiguring
            tabLayout.removeAllTabs()
            tabLayout.addTab(tabLayout.newTab().setText("Settings"))
            tabLayout.addTab(tabLayout.newTab().setText("Flutter"))
            
            // Clear existing listeners
            tabLayout.clearOnTabSelectedListeners()
            
            // Initially show settings
            settingsPanel.visibility = View.VISIBLE
            flutterContainer.visibility = View.GONE
            
            tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
                override fun onTabSelected(tab: TabLayout.Tab?) {
                    when (tab?.position) {
                        0 -> {
                            // Settings tab
                            settingsPanel.visibility = View.VISIBLE
                            flutterContainer.visibility = View.GONE
                        }
                        1 -> {
                            // Flutter tab
                            settingsPanel.visibility = View.GONE
                            flutterContainer.visibility = View.VISIBLE
                        }
                    }
                }
                
                override fun onTabUnselected(tab: TabLayout.Tab?) {}
                override fun onTabReselected(tab: TabLayout.Tab?) {}
            })
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // Handle orientation changes or screen size changes without recreating the activity
        updateLayoutForScreenSize()
    }

    private fun setupButtons() {
        startEngineButton.setOnClickListener { view ->
            startEngine(view)
        }

        startScreenButton.setOnClickListener { view ->
            startScreen(view)
        }

        startViewButton.setOnClickListener { view ->
            startFlutterInView(view)
        }

        stopEngineButton.setOnClickListener { view ->
            stopEngine(view)
        }

        removeViewButton.setOnClickListener { view ->
            removeFlutterView(view)
        }
    }

    private fun startEngine(view: View) {
        communicationView.startEngine { success, error ->
            runOnUiThread {
                if (success) {
                    // Hide "Start Flutter Engine" button and show "Stop Flutter Engine" button
                    startEngineButton.visibility = View.GONE
                    stopEngineButton.visibility = View.VISIBLE
                    // Show start screen and start view buttons (engine is now running)
                    startScreenButton.visibility = View.VISIBLE
                    startViewButton.visibility = View.VISIBLE
                    // Show update buttons in communication view
                    communicationView.setEngineRunning(true)

                    Log.d("MainActivity", "Successfully started engine")
                    Snackbar.make(
                        view,
                        "Flutter engine started successfully",
                        Snackbar.LENGTH_SHORT
                    ).show()
                } else {
                    Log.e("MainActivity", "Error when starting engine: $error")
                    Snackbar.make(
                        view,
                        error?.message ?: "Something went wrong",
                        Snackbar.LENGTH_SHORT
                    ).show()
                }
            }
        }
    }

    private fun startScreen(view: View) {
        try {
            {{flutterEmbeddingName}}.instance().startScreen(this)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error when starting screen: $e")
            Toast.makeText(this, "Error starting Flutter screen: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun startFlutterInView(view: View) {
        try {
            val containerId = R.id.flutter_container
            val flutterFragment = {{flutterEmbeddingName}}.instance().getOrCreateFragment(this, containerId)

            if (flutterFragment != null) {
                // Hide "Open Flutter in View" button and show "Remove Flutter View" button
                startViewButton.visibility = View.GONE
                removeViewButton.visibility = View.VISIBLE

                Snackbar.make(
                    view,
                    "Flutter app loaded in view",
                    Snackbar.LENGTH_SHORT
                ).show()
                Log.d("MainActivity", "Flutter fragment added to view")
            } else {
                Snackbar.make(
                    view,
                    "Failed to create Flutter fragment",
                    Snackbar.LENGTH_SHORT
                ).show()
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error when starting Flutter in view: $e")
            Toast.makeText(this, "Error starting Flutter in view: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun removeFlutterView(view: View) {
        try {
            {{flutterEmbeddingName}}.instance().clearFragment(this)

            // Show "Open Flutter in View" button and hide "Remove Flutter View" button
            startViewButton.visibility = View.VISIBLE
            removeViewButton.visibility = View.GONE

            Snackbar.make(
                view,
                "Flutter view removed",
                Snackbar.LENGTH_SHORT
            ).show()
            Log.d("MainActivity", "Flutter fragment removed from view")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error when removing Flutter view: $e")
            Toast.makeText(this, "Error removing Flutter view: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun stopEngine(view: View) {
        {{flutterEmbeddingName}}.instance().stopEngine()

        // Show "Start Flutter Engine" button and hide "Stop Flutter Engine" button
        startEngineButton.visibility = View.VISIBLE
        stopEngineButton.visibility = View.GONE
        // Hide start screen and start view buttons (engine is not running)
        startScreenButton.visibility = View.GONE
        startViewButton.visibility = View.GONE
        // Hide update buttons in communication view
        communicationView.setEngineRunning(false)

        Snackbar.make(
            view,
            "Flutter engine stopped",
            Snackbar.LENGTH_SHORT
        ).show()
    }

    internal fun handleFlutterExit() {
        // Check if Flutter is embedded in the view (removeViewButton is visible)
        if (removeViewButton.isVisible) {
            // Flutter is embedded, remove it from the container
            removeFlutterView(removeViewButton)
        }
    }
}
