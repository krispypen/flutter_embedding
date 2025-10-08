package com.flutterembeddingexample

import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.Spinner
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.snackbar.Snackbar
import be.krispypen.plugins.flutter_embedding.FlutterEmbedding
import be.krispypen.plugins.flutter_embedding.CompletionHandler
import be.krispypen.plugins.flutter_embedding.HandoverResponderInterface
import androidx.core.view.isVisible

class MainActivity : AppCompatActivity() {
    
    private var currentThemeMode = "system"
    private var currentLanguage = "en"
    private var currentEnvironment = "DEV"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        setupThemeModeSpinner()
        setupLanguageSpinner()
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

    private fun setupLanguageSpinner() {
        val items = arrayOf("en", "fr", "nl")
        val spinner = findViewById<Spinner>(R.id.language_spinner)
        
        spinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(
                parent: AdapterView<*>?,
                view: View?,
                position: Int,
                id: Long
            ) {
                currentLanguage = items[position]
                Log.d("MainActivity", "Language changed to: $currentLanguage")
            }

            override fun onNothingSelected(parent: AdapterView<*>?) {
                // Do nothing
            }
        }

        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, items)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        spinner.adapter = adapter
        spinner.setSelection(0) // Select "en" by default
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

        findViewById<Button>(R.id.update_language_button).setOnClickListener { view ->
            updateLanguage(view)
        }

        findViewById<Button>(R.id.invoke_handover_button).setOnClickListener { view ->
            invokeHandover(view)
        }
    }

    private fun startEngine(view: View) {
        val handoverResponder = ExampleHandoverResponder(this)
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

    internal fun removeFlutterView(view: View) {
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

    private fun updateLanguage(view: View) {
        FlutterEmbedding.instance().changeLanguage(
            currentLanguage, 
            object: CompletionHandler<Boolean> {
                override fun onSuccess(data: Boolean?) {
                    Log.d("MainActivity", "Successfully changed language")
                    Snackbar.make(
                        view,
                        "Language updated to: $currentLanguage",
                        Snackbar.LENGTH_SHORT
                    ).show()
                }

                override fun onFailure(e: Exception) {
                    Log.e("MainActivity", "Error when changing language: $e")
                    Snackbar.make(
                        view,
                        e.message ?: "Something went wrong (when changing language)",
                        Snackbar.LENGTH_SHORT
                    ).show()
                }
            }
        )
    }

    private fun invokeHandover(view: View) {
        FlutterEmbedding.instance().invokeHandover("handoverDemo", mapOf("data" to "Hello from Android"), object: CompletionHandler<Any?> {
            override fun onSuccess(data: Any?) {
                Log.d("MainActivity", "Successfully invoked handover")
            }

            override fun onFailure(e: Exception) {
                Log.e("MainActivity", "Error when invoking handover: $e")
                Snackbar.make(
                    view,
                    e.message ?: "Something went wrong (when invoking handover)",
                    Snackbar.LENGTH_SHORT
                ).show()
            }
        })
    }
}

class ExampleHandoverResponder(
    private val mainActivity: MainActivity
) : HandoverResponderInterface {

    override fun exit() {
        // Handle exit from Flutter app
        Log.d("ExampleHandoverResponder", "Flutter app requested exit")
        
        // Check if Flutter is embedded in the view (removeViewButton is visible)
        val removeViewButton = mainActivity.findViewById<Button>(R.id.remove_view_button)
        if (removeViewButton.isVisible) {
            // Flutter is embedded, remove it from the container
            mainActivity.removeFlutterView(removeViewButton)
        }
    }

    override fun invokeHandover(
        name: String,
        data: MutableMap<String?, Any?>,
        completion: CompletionHandler<Any?>?
    ){
        // show alert
        AlertDialog.Builder(mainActivity)
            .setTitle("Handover received: $name")
            .setMessage("Data: $data")
            .setPositiveButton("OK") { _, _ ->
                completion?.onSuccess(null)
            }
            .show()
    }
}
