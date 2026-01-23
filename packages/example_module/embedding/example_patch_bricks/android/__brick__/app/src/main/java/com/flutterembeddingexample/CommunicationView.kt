package com.flutterembeddingexample

import HandoversToFlutterServiceOuterClass
import HandoversToHostServiceOuterClass
import android.content.Context
import android.text.Editable
import android.text.TextWatcher
import android.util.AttributeSet
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.Spinner
import android.widget.TextView
import androidx.appcompat.widget.SwitchCompat
import be.krispypen.plugins.flutter_embedding.CompletionHandler
import {{flutterEmbeddingPackageName}}.{{flutterEmbeddingName}}
import io.grpc.stub.StreamObserver
import java.lang.ref.WeakReference

class CommunicationView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {

    private var currentThemeMode = HandoversToFlutterServiceOuterClass.ThemeMode.THEME_MODE_SYSTEM
    private var currentLanguage = HandoversToFlutterServiceOuterClass.Language.LANGUAGE_EN
    private var currentEnvironment = "MOCK"
    private var currentIncrement = 1
    
    
    // Weak reference to MainActivity
    private var mainActivityRef: WeakReference<MainActivity>? = null

    // UI Elements
    private lateinit var environmentSpinner: Spinner
    private lateinit var incrementEditText: EditText
    private lateinit var themeModeSpinner: Spinner
    private lateinit var changeThemeModeButton: Button
    private lateinit var languageSpinner: Spinner
    private lateinit var changeLanguageButton: Button
    

    private val environments = arrayOf("MOCK", "TST")

    init {
        LayoutInflater.from(context).inflate(R.layout.communication_view, this, true)
        setupViews()
        setupSpinners()
        setupButtons()
    }

    private fun setupViews() {
        environmentSpinner = findViewById(R.id.environment_spinner)
        incrementEditText = findViewById(R.id.increment_edit_text)
        themeModeSpinner = findViewById(R.id.theme_mode_spinner)
        changeThemeModeButton = findViewById(R.id.change_theme_mode_button)
        languageSpinner = findViewById(R.id.language_spinner)
        changeLanguageButton = findViewById(R.id.change_language_button)
        
        setupIncrementEditText()

        // Initially hide update buttons (engine not running yet)
        changeThemeModeButton.visibility = View.GONE
        changeLanguageButton.visibility = View.GONE
    }
    
    private fun setupIncrementEditText() {
        incrementEditText.setText(currentIncrement.toString())
        incrementEditText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val text = s?.toString() ?: ""
                currentIncrement = text.toIntOrNull() ?: 1
                Log.d("CommunicationView", "Increment changed to: $currentIncrement")
            }
        })
    }

    private fun setupSpinners() {
        setupEnvironmentSpinner()
        setupThemeModeSpinner()
        setupLanguageSpinner()
    }

    private fun setupEnvironmentSpinner() {
        val adapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, environments)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        environmentSpinner.adapter = adapter
        environmentSpinner.setSelection(0) // Select "MOCK" by default

        environmentSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                currentEnvironment = environments[position]
                Log.d("CommunicationView", "Environment changed to: $currentEnvironment")
            }

            override fun onNothingSelected(parent: AdapterView<*>?) {
                // Do nothing
            }
        }
    }

    private fun setupThemeModeSpinner() {
        val items = arrayOf(
            HandoversToFlutterServiceOuterClass.ThemeMode.THEME_MODE_LIGHT,
            HandoversToFlutterServiceOuterClass.ThemeMode.THEME_MODE_DARK,
            HandoversToFlutterServiceOuterClass.ThemeMode.THEME_MODE_SYSTEM
        )

        themeModeSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                currentThemeMode = items[position]
                Log.d("CommunicationView", "Theme mode changed to: $currentThemeMode")
            }

            override fun onNothingSelected(parent: AdapterView<*>?) {
                // Do nothing
            }
        }

        val adapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, items)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        themeModeSpinner.adapter = adapter
        themeModeSpinner.setSelection(2) // Select "system" by default
    }

    private fun setupLanguageSpinner() {
        val items = arrayOf(
            HandoversToFlutterServiceOuterClass.Language.LANGUAGE_EN,
            HandoversToFlutterServiceOuterClass.Language.LANGUAGE_FR,
            HandoversToFlutterServiceOuterClass.Language.LANGUAGE_NL
        )

        languageSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                currentLanguage = items[position]
                Log.d("CommunicationView", "Language changed to: $currentLanguage")
            }

            override fun onNothingSelected(parent: AdapterView<*>?) {
                // Do nothing
            }
        }

        val adapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, items)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        languageSpinner.adapter = adapter
        languageSpinner.setSelection(0) // Select "en" by default
    }

    private fun setupButtons() {
        changeThemeModeButton.setOnClickListener { changeThemeMode() }
        changeLanguageButton.setOnClickListener { changeLanguage() }
    }

    private fun changeThemeMode() {
        val request = HandoversToFlutterServiceOuterClass.ChangeThemeModeRequest.newBuilder()
            .setThemeMode(currentThemeMode)
            .build()
        {{flutterEmbeddingName}}.instance().handoversToFlutterService().changeThemeMode(request)
        Log.d("CommunicationView", "Theme mode changed successfully")
    }

    private fun changeLanguage() {
        val request = HandoversToFlutterServiceOuterClass.ChangeLanguageRequest.newBuilder()
            .setLanguage(currentLanguage)
            .build()
        {{flutterEmbeddingName}}.instance().handoversToFlutterService().changeLanguage(request)
        Log.d("CommunicationView", "Language changed successfully")
    }

    fun createStartParams(): HandoversToFlutterServiceOuterClass.StartParams {
        val builder = HandoversToFlutterServiceOuterClass.StartParams.newBuilder()
            .setEnvironment(currentEnvironment)
            .setLanguage(currentLanguage)
            .setThemeMode(currentThemeMode)

        return builder.build()
    }

    fun setEngineRunning(isRunning: Boolean) {
        changeThemeModeButton.visibility = if (isRunning) View.VISIBLE else View.GONE
        changeLanguageButton.visibility = if (isRunning) View.VISIBLE else View.GONE
    }
    
    fun setMainActivity(activity: MainActivity) {
        mainActivityRef = WeakReference(activity)
    }
    
    private fun createHandoversToHostService(): HandoversToHostServiceGrpc.HandoversToHostServiceImplBase {
        return object : HandoversToHostServiceGrpc.HandoversToHostServiceImplBase() {
            
            override fun getIncrement(
                request: HandoversToHostServiceOuterClass.GetIncrementRequest?,
                responseObserver: StreamObserver<HandoversToHostServiceOuterClass.GetIncrementResponse?>?
            ) {
                val response = HandoversToHostServiceOuterClass.GetIncrementResponse.newBuilder()
                    .setIncrement(currentIncrement)
                    .build()
                responseObserver?.onNext(response)
                responseObserver?.onCompleted()
            }
            
            override fun getHostInfo(
                request: HandoversToHostServiceOuterClass.GetHostInfoRequest?,
                responseObserver: StreamObserver<HandoversToHostServiceOuterClass.GetHostInfoResponse?>?
            ) {
                val response = HandoversToHostServiceOuterClass.GetHostInfoResponse.newBuilder()
                    .setFramework("Android")
                    .build()
                responseObserver?.onNext(response)
                responseObserver?.onCompleted()
            }
            
            override fun exit(
                request: HandoversToHostServiceOuterClass.ExitRequest?,
                responseObserver: StreamObserver<HandoversToHostServiceOuterClass.ExitResponse?>?
            ) {
                // Handle exit from Flutter app
                val counter = request?.counter ?: 0
                Log.d("CommunicationView", "Flutter app requested exit with counter: $counter")
                
                mainActivityRef?.get()?.let { activity ->
                    activity.runOnUiThread {
                        // Show popup with counter value
                        android.app.AlertDialog.Builder(activity)
                            .setTitle("Flutter Exit")
                            .setMessage("Counter: $counter")
                            .setPositiveButton("OK") { dialog, _ ->
                                dialog.dismiss()
                                activity.handleFlutterExit()
                            }
                            .setCancelable(false)
                            .show()
                    }
                }
                
                val response = HandoversToHostServiceOuterClass.ExitResponse.newBuilder()
                    .setSuccess(true)
                    .build()
                responseObserver?.onNext(response)
                responseObserver?.onCompleted()
            }
        }
    }
    
    fun startEngine(completion: (Boolean, Exception?) -> Unit) {
        val mainActivity = mainActivityRef?.get()
        if (mainActivity == null) {
            completion(false, Exception("MainActivity reference is null"))
            return
        }
        
        val startParams = createStartParams()
        val handoversToHostService = createHandoversToHostService()
        
        {{flutterEmbeddingName}}.instance().startEngine(
            mainActivity,
            startParams = startParams,
            handoversToHostService = handoversToHostService,
            object : CompletionHandler<Boolean> {
                override fun onSuccess(data: Boolean?) {
                    completion(true, null)
                }
                
                override fun onFailure(e: Exception) {
                    completion(false, e)
                }
            }
        )
    }
}

