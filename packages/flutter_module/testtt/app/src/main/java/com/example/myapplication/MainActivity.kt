package com.example.myapplication

import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.Spinner
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.snackbar.Snackbar
import be.krispypen.plugins.flutter_embedding.FlutterEmbedding
import be.krispypen.plugins.flutter_embedding.CompletionHandler
import be.krispypen.plugins.flutter_embedding.HandoverResponderInterface
import be.krispypen.plugins.flutter_embedding.models.Messages

class MainActivity : AppCompatActivity() {
    
    private var currentThemeMode = "system"
    private var currentLanguage = "en"
    private var currentEnvironment = "DEV"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        setupThemeModeSpinner()
        setupButtons()
    }

    private fun setupThemeModeSpinner() {
        val items = arrayOf("light", "dark", "system")
        val spinner = findViewById<Spinner>(R.id.theme_mode_spinner)
        
        spinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(
                parent: AdapterView<*>?,
                view: View?,
                position: Int,
                id: Long
            ) {
                currentThemeMode = items[position]
                Log.d("MainActivity", "Theme mode changed to: $currentThemeMode")
            }

            override fun onNothingSelected(parent: AdapterView<*>?) {
                // Do nothing
            }
        }

        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, items)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        spinner.adapter = adapter
        spinner.setSelection(2) // Select "system" by default
    }


    private fun setupButtons() {
        findViewById<Button>(R.id.start_engine_button).setOnClickListener { view ->
            startEngine(view)
        }
        
        findViewById<Button>(R.id.start_screen_button).setOnClickListener { view ->
            startScreen(view)
        }
        
        findViewById<Button>(R.id.start_view_button).setOnClickListener { view ->
            startFlutterInView(view)
        }
        
        findViewById<Button>(R.id.stop_engine_button).setOnClickListener { view ->
            stopEngine(view)
        }
        
        findViewById<Button>(R.id.update_theme_button).setOnClickListener { view ->
            updateThemeMode(view)
        }
        
        findViewById<Button>(R.id.remove_view_button).setOnClickListener { view ->
            removeFlutterView(view)
        }
    }

    private fun startEngine(view: View) {
        val handoverResponder = ExampleHandoverResponder("dummy_token")
        FlutterEmbedding.instance().startEngine(
            this, 
            currentEnvironment, 
            currentLanguage, 
            currentThemeMode, 
            handoverResponder,
            object: CompletionHandler<Boolean> {
                override fun onSuccess(data: Boolean?) {
                    // Hide "Start Flutter Engine" button and show "Stop Flutter Engine" button
                    findViewById<Button>(R.id.start_engine_button).visibility = View.GONE
                    findViewById<Button>(R.id.stop_engine_button).visibility = View.VISIBLE
                    
                    Log.d("MainActivity", "Successfully started engine")
                    Snackbar.make(
                        view,
                        "Flutter engine started successfully",
                        Snackbar.LENGTH_SHORT
                    ).show()
                }

                override fun onFailure(e: Exception) {
                    Log.e("MainActivity", "Error when starting engine: $e")
                    Snackbar.make(
                        view,
                        e.message ?: "Something went wrong",
                        Snackbar.LENGTH_SHORT
                    ).show()
                }
            }
        )
    }

    private fun startScreen(view: View) {
        try {
            FlutterEmbedding.instance().startScreen(this)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error when starting screen: $e")
            Toast.makeText(this, "Error starting Flutter screen: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun startFlutterInView(view: View) {
        try {
            val containerId = R.id.flutter_container
            val flutterFragment = FlutterEmbedding.instance().getOrCreateFragment(this, containerId)
            
            if (flutterFragment != null) {
                // Hide "Open Flutter in View" button and show "Remove Flutter View" button
                findViewById<Button>(R.id.start_view_button).visibility = View.GONE
                findViewById<Button>(R.id.remove_view_button).visibility = View.VISIBLE
                
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
            FlutterEmbedding.instance().clearFragment(this)
            
            // Show "Open Flutter in View" button and hide "Remove Flutter View" button
            findViewById<Button>(R.id.start_view_button).visibility = View.VISIBLE
            findViewById<Button>(R.id.remove_view_button).visibility = View.GONE
            
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
        FlutterEmbedding.instance().stopEngine()
        
        // Show "Start Flutter Engine" button and hide "Stop Flutter Engine" button
        findViewById<Button>(R.id.start_engine_button).visibility = View.VISIBLE
        findViewById<Button>(R.id.stop_engine_button).visibility = View.GONE
        
        Snackbar.make(
            view,
            "Flutter engine stopped",
            Snackbar.LENGTH_SHORT
        ).show()
    }

    private fun updateThemeMode(view: View) {
        FlutterEmbedding.instance().changeThemeMode(
            currentThemeMode, 
            object: CompletionHandler<Boolean> {
                override fun onSuccess(data: Boolean?) {
                    Log.d("MainActivity", "Successfully changed theme mode")
                    Snackbar.make(
                        view,
                        "Theme mode updated to: $currentThemeMode",
                        Snackbar.LENGTH_SHORT
                    ).show()
                }

                override fun onFailure(e: Exception) {
                    Log.e("MainActivity", "Error when changing theme mode: $e")
                    Snackbar.make(
                        view,
                        e.message ?: "Something went wrong (when changing theme mode)",
                        Snackbar.LENGTH_SHORT
                    ).show()
                }
            }
        )
    }
}

class ExampleHandoverResponder(private val accessToken: String) : HandoverResponderInterface {
    override fun provideAccessToken(completion: CompletionHandler<String?>) {
        TODO("Not yet implemented")
    }

    override fun receiveAnalyticsEvent(request: Messages.FlutterAnalyticsEventRequest) {
        TODO("Not yet implemented")
    }

    override fun receiveDebugLog(request: Messages.FlutterDebugLogRequest) {
        TODO("Not yet implemented")
    }

    override fun receiveError(request: Messages.FlutterErrorRequest) {
        TODO("Not yet implemented")
    }

    override fun exit() {
        // Handle exit from Flutter app
        Log.d("ExampleHandoverResponder", "Flutter app requested exit")
    }

    override fun startFaq(request: Messages.FlutterFaqRequest) {
        TODO("Not yet implemented")
    }

    override fun startOnboarding(
        request: Messages.FlutterOnboardingRequest,
        completion: CompletionHandler<Messages.FlutterOnboardingResponse?>
    ) {
        TODO("Not yet implemented")
    }

    override fun startFundPortfolio(
        request: Messages.FlutterFundPortfolioRequest,
        completion: CompletionHandler<Messages.FlutterFundPortfolioResponse?>
    ) {
        TODO("Not yet implemented")
    }

    override fun startAddMoney(
        request: Messages.FlutterAddMoneyRequest,
        completion: CompletionHandler<Messages.FlutterAddMoneyResponse?>
    ) {
        TODO("Not yet implemented")
    }

    override fun startAuthorization(completion: CompletionHandler<Messages.FlutterAuthorizationResponse?>) {
        TODO("Not yet implemented")
    }

    override fun startTransactionSigning(
        request: Messages.FlutterStartTransactionSigningRequest,
        completion: CompletionHandler<Messages.FlutterStartTransactionSigningResponse?>
    ) {
        TODO("Not yet implemented")
    }
}
