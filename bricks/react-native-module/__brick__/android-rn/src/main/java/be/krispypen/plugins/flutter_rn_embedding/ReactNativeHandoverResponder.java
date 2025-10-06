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
    this.eventEmitter.completeEvent(eventName, data.toHashMap());
  }

  @Override
  public void exit() {
    Log.d(ReactNativeHandoverResponder.TAG, "Start exit");
    eventEmitter.invokeHandover(Handover.exit.getEventName(), null, null);
  }

  @Override
  public void invokeHandover(@NonNull String name, @NonNull Map<String, Object> data, @NonNull CompletionHandler<Object> completion) {
    Log.d(ReactNativeHandoverResponder.TAG, "Start invokeHandover");
    eventEmitter.invokeHandover(name, data, completion);
  }

  
}
