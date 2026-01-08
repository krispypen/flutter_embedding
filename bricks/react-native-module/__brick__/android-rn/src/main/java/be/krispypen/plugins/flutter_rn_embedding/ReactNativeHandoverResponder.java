package be.krispypen.plugins.flutter_rn_embedding;

import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ReadableMap;
import be.krispypen.plugins.flutter_embedding.CompletionHandler;
import be.krispypen.plugins.flutter_embedding.Handover;
import be.krispypen.plugins.flutter_embedding.HandoverResponderInterface;

import java.util.Map;

public class ReactNativeHandoverResponder implements HandoverResponderInterface {
  private static final String TAG = "RNHandoverResponder";

  final CompletableEventEmitterDecorator eventEmitter;

  ReactNativeHandoverResponder(@NonNull EventEmitterProtocol eventEmitter) {
    this.eventEmitter = new CompletableEventEmitterDecorator(eventEmitter);
  }

  void handleResponse(String eventName, ReadableMap data) {
    Log.d(ReactNativeHandoverResponder.TAG, "Handle response for event " + eventName + " with data " + data);
    Map<String, Object> map = FlutterEmbeddingModule.convertReadableMapToMap(data);
    Log.d(ReactNativeHandoverResponder.TAG, "Handle response for event " + eventName + " with hashmapdata " + map);
    this.eventEmitter.completeEvent(eventName, map);
  }

  @Override
  public void invokeHandover(@NonNull String name, @NonNull Map<String, Object> data, @NonNull CompletionHandler<Object> completion) {
    Log.d(ReactNativeHandoverResponder.TAG, "Start invokeHandover " + name + " with data " + data);
    eventEmitter.invokeHandover(name, data, completion);
  }

  
}
