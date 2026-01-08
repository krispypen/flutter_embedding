package be.krispypen.plugins.flutter_embedding;

import android.content.Context;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentActivity;
import androidx.fragment.app.FragmentManager;

import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

import io.flutter.FlutterInjector;
import android.util.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class FlutterEmbedding implements MethodChannel.MethodCallHandler {

    public static final Map<String, String> ALL_EVENTS;

    static {
        Map<String, String> allEvents = new LinkedHashMap<String, String>();
        for (Handover handover : Handover.values()) {
            allEvents.put(handover.getEventName(), handover.getEventName());
        }
        ALL_EVENTS = allEvents;
    }

    // Start allowed environments
    public static final String[] ALLOWED_ENVIRONMENTS = {"DEV", "TST", "UAT", "PILOT", "PROD", "DEMO", "MOCK"};
    // End allowed environments

    private static final String CHANNEL_NAME = "flutter_embedding/embedding";
    private static final String TAG_FLUTTER_FRAGMENT = "flutter_embedding_fragment";
    private static final String ENGINE_ID = "flutter_embedding_engine";
    private static final String TAG = "FlutterEmbedding";

    private static class LazyHolder {
        static final FlutterEmbedding INSTANCE = new FlutterEmbedding();
    }

    private FlutterEngine flutterEngine;
    private HandoverResponderInterface handoverResponder;

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    private FlutterEmbedding() {
    }

    public static FlutterEmbedding instance() {
        return LazyHolder.INSTANCE;
    }

    MethodChannel createChannel(@NonNull FlutterPlugin.FlutterPluginBinding flutterPluginBinding) {
        assert (channel == null);
        this.channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), FlutterEmbedding.CHANNEL_NAME);
        channel.setMethodCallHandler(this);

        return this.channel;
    }

    void detachChannel() {
        channel.setMethodCallHandler(null);
    }

    public void startEngine(@NonNull Context context, @NonNull String startConfig, @NonNull HandoverResponderInterface handoverResponder) {
        this.startEngine(context, startConfig, handoverResponder, null);
    }

    public void startEngine(@NonNull Context context, @NonNull String startConfig, @NonNull HandoverResponderInterface handoverResponder, @Nullable CompletionHandler<Boolean> completion) {
        this.startEngine(context, startConfig, handoverResponder, null, completion);
    }

    public void startEngine(@NonNull Context context, @NonNull String startConfig, @NonNull HandoverResponderInterface handoverResponder, @Nullable String libraryURI, @Nullable CompletionHandler<Boolean> completion) {
        if (this.flutterEngine != null) {
            if (completion != null) {
                completion.onSuccess(true);
            }
            return;
        }

        Runner engineRunner = () -> {
            this.handoverResponder = handoverResponder;
            this.flutterEngine = new FlutterEngine(context);

            FlutterLoader flutterLoader = FlutterInjector.instance().flutterLoader();

            if (!flutterLoader.initialized()) {
                completion.onFailure(new Exception("DartEntrypoints can only be created once a FlutterEngine is created."));
                throw new AssertionError(
                        "DartEntrypoints can only be created once a FlutterEngine is created.");
            }
            

            if (!this.flutterEngine.getDartExecutor().isExecutingDart()) {
                this.flutterEngine.getDartExecutor().executeDartEntrypoint(
                        //DartExecutor.DartEntrypoint.createDefault()
                        (libraryURI == null) ?
                                new DartExecutor.DartEntrypoint(flutterLoader.findAppBundlePath(), "main") :
                                new DartExecutor.DartEntrypoint(flutterLoader.findAppBundlePath(), libraryURI, "main"),
                                Arrays.asList(startConfig)
                );
            }

            // Cache the pre-warmed FlutterEngine to be used later by FlutterFragment.
            FlutterEngineCache
                    .getInstance()
                    .put(FlutterEmbedding.ENGINE_ID, this.flutterEngine);

            if (completion != null) {
                completion.onSuccess(true);
            }
        };

        if (UiThreadUtil.isOnUiThread()) {
            engineRunner.run();
        } else {
            UiThreadUtil.runOnUiThread(engineRunner::run);
        }
    }

    public void startScreen(Context context){
        context.startActivity(FlutterActivity
                .withCachedEngine(FlutterEmbedding.ENGINE_ID)
                .build(context));
    }

    public void stopEngine() {
        try {
            Runner destroyEngine = () -> {
                FlutterEngine engine = getEngine();
                if (engine != null) {
                    engine.destroy();
                    FlutterEngineCache.getInstance().remove(FlutterEmbedding.ENGINE_ID);
                }

                this.flutterEngine = null;
                this.handoverResponder = null;
                this.channel = null;
            };

            if (UiThreadUtil.isOnUiThread()) {
                destroyEngine.run();
            } else {
                UiThreadUtil.runOnUiThread(destroyEngine::run);
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to stop engine", e);
        }
    }

    /**
     * Gets the FlutterEngine in use.
     *
     * @return the FlutterEngine
     */
    public FlutterEngine getEngine() {
        return FlutterEngineCache.getInstance().get(FlutterEmbedding.ENGINE_ID);
    }

    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        Log.d(TAG, "received MethodCall from " + CHANNEL_NAME + " " + call.method + " with " + call.arguments);

        final Map<String, Object> params = (call.arguments instanceof Map) ? (Map<String, Object>) call.arguments : null;

        if (call.method.equals("internalRequestLayout")) {
            // a bug in react native requires the layout to be done manually https://github.com/facebook/react-native/issues/17968
            View view = FlutterEmbeddingFlutterFragment.lastview != null ? FlutterEmbeddingFlutterFragment.lastview.get() : null;
            if (view == null || !(view instanceof FrameLayout)) {
                Log.d(TAG, "internalRequestLayout lastview is null or not a FrameLayout");
                result.success(null);
                return;
            }
            FrameLayout fl = (FrameLayout) view;
            fl.measure(View.MeasureSpec.makeMeasureSpec(fl.getWidth(), View.MeasureSpec.EXACTLY),
                    View.MeasureSpec.makeMeasureSpec(fl.getHeight(), View.MeasureSpec.EXACTLY));
            fl.layout(fl.getLeft(), fl.getTop(), fl.getRight(), fl.getBottom());
            Log.d(TAG, "internalRequestLayout left: " + fl.getLeft() + " top: " + fl.getTop() + " right: " + fl.getRight() + " bottom: " + fl.getBottom() + " width: " + fl.getWidth() + " height: " + fl.getHeight() + " childCount: " + fl.getChildCount() + " fl: " + fl.toString());
            for (int i = 0; i < fl.getChildCount(); i++) {
                View child = fl.getChildAt(i);
                Log.d(TAG, "internalRequestLayout child: left:" + child.getLeft() + " top: " + child.getTop() + " right: " + child.getRight() + " bottom: " + child.getBottom() + " width: " + child.getWidth() + " height: " + child.getHeight() + " child: " + child.toString());
            }
            fl.requestLayout();
        } else {
            handoverResponder.invokeHandover(
                    call.method,
                    params,
                    new CompletionHandler<Object>() {
                        @Override
                        public void onSuccess(@Nullable Object data) {
                            Log.d(TAG, "onSuccess " + data);
                            result.success(data);
                        }

                        @Override
                        public void onFailure(@NonNull Exception e) {
                            Log.e(TAG, "onFailure " + e.getMessage());
                            result.error(e.getMessage(), null, e.getStackTrace());
                        }
                    });          
            return;
        }
    }

    // TODO should data be nonNull?
    public void invokeHandover(@NonNull String eventName, @NonNull Map<String, Object> data, @Nullable CompletionHandler<Object> completion) {
        // Check channel in stead of flutterEngine, because embedding Flutter doesn't create a FlutterEngine
        if (this.channel != null) {
            Runner invokeHandover = () -> {
                try {
                    this.channel.invokeMethod(eventName, data, new MethodChannel.Result() {
                        @Override
                        public void success(@Nullable Object result) {
                            Log.d(TAG, "Posting externalData to FlutterEmbedding success");

                            if (completion != null) {
                                completion.onSuccess(result);
                            }
                        }

                        @Override
                        public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
                            Log.e(TAG, "Posting externalData to FlutterEmbedding failed with " + errorMessage);

                            if (completion != null) {
                                // TODO custom error to provide everything
                                completion.onFailure(new Exception(errorMessage));
                            }
                        }

                        @Override
                        public void notImplemented() {
                            Log.e(TAG, "Posting externalData to FlutterEmbedding failed with notImplemented");
                            // TODO custom error to provide everything
                            if (completion != null) {
                                completion.onFailure(new Exception("Not implemented"));
                            }
                        }
                    });
                } catch (Exception e) {
                    completion.onFailure(new Exception("Sending event failed " + e.getMessage()));
                }
            };

            if (UiThreadUtil.isOnUiThread()) {
                invokeHandover.run();
            } else {
                UiThreadUtil.runOnUiThread(invokeHandover::run);
            }
        } else {
            completion.onFailure(new Exception("No Flutter engine running."));
        }
    }

    public void changeLanguage(@NonNull String language, @Nullable CompletionHandler<Boolean> completion) {
        final Map<String, Object> params = new HashMap<>();
        params.put("language", language);

        this.invokeHandover("change_language", params, new CompletionHandler<Object>() {
            @Override
            public void onSuccess(Object data) {
                completion.onSuccess(data instanceof Boolean ? (Boolean) data : false);
            }

            @Override
            public void onFailure(Exception e) {
                completion.onFailure(e);
            }
        });
    }

    public void changeThemeMode(@NonNull String themeMode, @Nullable CompletionHandler<Boolean> completion) {
        final Map<String, Object> params = new HashMap<>();
        params.put("theme_mode", themeMode);

        this.invokeHandover("change_theme_mode", params, new CompletionHandler<Object>() {
            @Override
            public void onSuccess(Object data) {
                completion.onSuccess(data instanceof Boolean ? (Boolean) data : false);
            }
            @Override
            public void onFailure(Exception e) {
                completion.onFailure(e);
            }
        });
    }

    public FlutterEmbeddingFlutterFragment getFragment(@NonNull FragmentActivity activity) {
        FragmentManager fragmentManager = activity.getSupportFragmentManager();

        return (FlutterEmbeddingFlutterFragment) fragmentManager.findFragmentByTag(FlutterEmbedding.TAG_FLUTTER_FRAGMENT);
    }


    public FlutterEmbeddingFlutterFragment getOrCreateFragment(@NonNull FragmentActivity activity) {
        return getOrCreateFragment(activity, (Integer) null);
    }

    public FlutterEmbeddingFlutterFragment getOrCreateFragment(@NonNull FragmentActivity activity, Integer containerViewId) {
        return getOrCreateFragment(activity, FlutterEmbeddingFlutterFragment.class, containerViewId);
    }

    public FlutterEmbeddingFlutterFragment getOrCreateFragment(@NonNull FragmentActivity activity, @NonNull Class<? extends FlutterEmbeddingFlutterFragment> subclass) {
        return getOrCreateFragment(activity, subclass, null);
    }

    public FlutterEmbeddingFlutterFragment getOrCreateFragment(@NonNull FragmentActivity activity, @NonNull Class<? extends FlutterEmbeddingFlutterFragment> subclass, Integer containerViewId) {
        FragmentManager fragmentManager = activity.getSupportFragmentManager();

        // Attempt to find an existing FlutterFragment,
        // in case this is not the first time that onCreate() was run.

        // Declare a local variable to reference the FlutterFragment so that you
        // can forward calls to it later.
        FlutterEmbeddingFlutterFragment flutterFragment = getFragment(activity);

        // Create and attach a FlutterFragment if one does not exist.
        if (flutterFragment == null) {
            flutterFragment = new FlutterFragment.CachedEngineFragmentBuilder(subclass, FlutterEmbedding.ENGINE_ID)
                    .shouldAutomaticallyHandleOnBackPressed(false)
                    .build();

            fragmentManager
                    .beginTransaction()
                    .add(
                            containerViewId != null ? containerViewId : 0,
                            flutterFragment,
                            TAG_FLUTTER_FRAGMENT
                    )
                    .commit();
        }

        // Execute the commit immediately or can use commitNow() instead
        fragmentManager.executePendingTransactions();

        return flutterFragment;
    }

    public boolean hasFragment(@NonNull FragmentActivity activity) {
        // activity.getOnBackPressedDispatcher().addCallback();

        // Attempt to find an existing FlutterFragment,
        // in case this is not the first time that onCreate() was run.

        // Declare a local variable to reference the FlutterFragment so that you
        // can forward calls to it later.
        FlutterFragment flutterFragment = getFragment(activity);

        return flutterFragment != null;
    }

    public void clearFragment(@NonNull FragmentActivity activity) {
        FragmentManager fragmentManager = activity.getSupportFragmentManager();

        FlutterFragment flutterFragment = getFragment(activity);
        if (flutterFragment != null) {
            Runner clearFragment = () -> {
                fragmentManager.beginTransaction().remove(flutterFragment).commitNow();
            };

            if (UiThreadUtil.isOnUiThread()) {
                clearFragment.run();
            } else {
                UiThreadUtil.runOnUiThread(clearFragment::run);
            }
        }
    }

}
