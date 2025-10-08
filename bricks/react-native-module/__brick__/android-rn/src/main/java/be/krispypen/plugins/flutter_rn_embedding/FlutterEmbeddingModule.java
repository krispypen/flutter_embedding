package be.krispypen.plugins.flutter_rn_embedding;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.ReactActivity;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import be.krispypen.plugins.flutter_embedding.CompletionHandler;
import be.krispypen.plugins.flutter_embedding.FlutterEmbedding;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class FlutterEmbeddingModule extends ReactContextBaseJavaModule implements EventEmitterProtocol {

  private final ReactApplicationContext reactContext;
  private final ReactNativeHandoverResponder handoverResponder;
  private final FlutterEmbeddingViewManager viewManager;

  public static final String REACT_CLASS = "FlutterEmbeddingModule";

  public FlutterEmbeddingModule(ReactApplicationContext reactContext, FlutterEmbeddingViewManager viewManager) {
    super(reactContext);
    this.reactContext = reactContext;
    this.handoverResponder = new ReactNativeHandoverResponder(this);
    this.viewManager = viewManager;
  }

  @NonNull
  @Override
  public String getName() {
    return REACT_CLASS;
  }

  @ReactMethod
  public void startEngine(@NonNull String environment, @NonNull String language, @NonNull String themeMode, Promise promise) {
    FlutterEmbedding.instance().startEngine(reactContext, environment, language, themeMode, handoverResponder, "package:flutter_module/main.dart", new CompletionHandler<Boolean>() {

      @Override
      public void onSuccess(Boolean unused) {
        promise.resolve(null);
      }

      @Override
      public void onFailure(Exception e) {
        promise.reject(e);
      }
    });
  }

  @ReactMethod
  public void stopEngine() {
    try {
      // clear fragment first, else this will throw an issue
      FlutterEmbedding.instance().clearFragment((ReactActivity) reactContext.getCurrentActivity());
    } catch (Exception e) {
      Log.e("FlutterEmbeddingModule", "Failed to clear fragment. (Because this was just a precaution we continue)", e);
    }
    viewManager.reset();
    FlutterEmbedding.instance().stopEngine();
  }

  @ReactMethod
  public void changeLanguage(@NonNull String language, Promise promise) {
    FlutterEmbedding.instance().changeLanguage(language, new CompletionHandler<Boolean>() {

      @Override
      public void onSuccess(Boolean result) {
        promise.resolve(result);
      }

      @Override
      public void onFailure(Exception e) {
        promise.reject(e);
      }
    });
  }

  @ReactMethod
  public void changeThemeMode(@NonNull String themeMode, Promise promise) {
    FlutterEmbedding.instance().changeThemeMode(themeMode, new CompletionHandler<Boolean>() {
      @Override
      public void onSuccess(Boolean result) { promise.resolve(result);}

      @Override
      public void onFailure(Exception e) { promise.reject(e);}
    });
  }

  @ReactMethod
  public void invokeHandoverReturn(@NonNull String name, ReadableMap data, Promise promise) {
    final Map<String, Object> newMap = convertReadableMapToMap(data);
    FlutterEmbedding.instance().invokeHandover(name, newMap, new CompletionHandler<Object>() {
      @Override
      public void onSuccess(Object result) { promise.resolve(result);}

      @Override
      public void onFailure(Exception e) { promise.reject(e);}
    });
  }

  @Override
  public void invokeHandover(@NonNull String eventName, @NonNull Map<String, Object> data) {
    final WritableMap arguments = convertToWritableMap(data);
    Log.d(REACT_CLASS, "Send Event " + eventName + " with data " + arguments.toString());
    reactContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
      .emit(eventName, arguments);
  }

  @ReactMethod
  void respondToEvent(String eventName, ReadableMap data) {
    Log.d(REACT_CLASS, "Received response for event " + eventName + " with data " + data);
    this.handoverResponder.handleResponse(eventName, data);
  }

  @Override
  public Map<String, Object> getConstants() {
    final LinkedHashMap constants = new LinkedHashMap();
    constants.putAll(FlutterEmbedding.ALL_EVENTS);
    constants.put("COMPLETABLE_EVENT_UUID_KEY", CompletableEventEmitterDecorator.UUID_KEY);
    constants.put("COMPLETABLE_EVENT_REQUEST_KEY", CompletableEventEmitterDecorator.REQUEST_KEY);
    constants.put("COMPLETABLE_EVENT_RESPONSE_KEY", CompletableEventEmitterDecorator.RESPONSE_KEY);
    return constants;
  }

  private Map<String, Object> convertReadableMapToMap(@NonNull ReadableMap data) {
    Map<String, Object> result = new LinkedHashMap<>();
    
    com.facebook.react.bridge.ReadableMapKeySetIterator iterator = data.keySetIterator();
    while (iterator.hasNextKey()) {
      String key = iterator.nextKey();
      switch (data.getType(key)) {
        case Null:
          result.put(key, null);
          break;
        case Boolean:
          result.put(key, data.getBoolean(key));
          break;
        case Number:
          result.put(key, data.getDouble(key));
          break;
        case String:
          result.put(key, data.getString(key));
          break;
        case Map:
          result.put(key, convertReadableMapToMap(data.getMap(key)));
          break;
        case Array:
          result.put(key, convertReadableArrayToList(data.getArray(key)));
          break;
      }
    }
    
    return result;
  }

  private List<Object> convertReadableArrayToList(@NonNull com.facebook.react.bridge.ReadableArray data) {
    List<Object> result = new ArrayList<>();
    
    for (int i = 0; i < data.size(); i++) {
      switch (data.getType(i)) {
        case Null:
          result.add(null);
          break;
        case Boolean:
          result.add(data.getBoolean(i));
          break;
        case Number:
          result.add(data.getDouble(i));
          break;
        case String:
          result.add(data.getString(i));
          break;
        case Map:
          result.add(convertReadableMapToMap(data.getMap(i)));
          break;
        case Array:
          result.add(convertReadableArrayToList(data.getArray(i)));
          break;
      }
    }
    
    return result;
  }

  private WritableArray convertToWritableArray(@NonNull List<Object> data) {
    WritableArray result = Arguments.createArray();

    for (Object value : data) {
      if (value == null) {
        result.pushNull();
      } else if (value instanceof String) {
        result.pushString((String) value);
      } else if (value instanceof Integer) {
        result.pushInt((Integer) value);
      } else if (value instanceof Boolean) {
        result.pushBoolean((Boolean) value);
      } else if (value instanceof Double) {
        result.pushDouble((Double) value);
      } else if (value instanceof Map) {
        result.pushMap(convertToWritableMap((Map) value));
      } else if (value instanceof List) {
        result.pushArray(convertToWritableArray((List) value));
      }
    }

    return result;
  }

  private WritableMap convertToWritableMap(@NonNull Map<String, Object> data) {
    WritableMap result = Arguments.createMap();
    for (Map.Entry<String, Object> pair : data.entrySet()) {
      if (pair.getValue() == null) {
        result.putNull(pair.getKey());
      } else if (pair.getValue() instanceof String) {
        result.putString(pair.getKey(), (String) pair.getValue());
      } else if (pair.getValue() instanceof Integer) {
        result.putInt(pair.getKey(), (Integer) pair.getValue());
      } else if (pair.getValue() instanceof Boolean) {
        result.putBoolean(pair.getKey(), (Boolean) pair.getValue());
      } else if (pair.getValue() instanceof Double) {
        result.putDouble(pair.getKey(), (Double) pair.getValue());
      } else if (pair.getValue() instanceof Map) {
        result.putMap(pair.getKey(), convertToWritableMap((Map) pair.getValue()));
      } else if (pair.getValue() instanceof List) {
        result.putArray(pair.getKey(), convertToWritableArray((List) pair.getValue()));
      }
    }
    return result;
  }

}
