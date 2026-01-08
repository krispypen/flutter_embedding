package be.krispypen.plugins.flutter_rn_embedding;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import be.krispypen.plugins.flutter_embedding.CompletionHandler;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class CompletableEventEmitterDecorator {

  static final String UUID_KEY = "_completable_event_uuid";
  static final String REQUEST_KEY = "_completable_event_request";
  static final String RESPONSE_KEY = "_completable_event_response";

  private final EventEmitterProtocol eventEmitter;
  private final Map<String, CompletionHandler<Object>> completers;

  CompletableEventEmitterDecorator(@NonNull EventEmitterProtocol eventEmitter) {
    this.eventEmitter = eventEmitter;
    completers = new HashMap();
  }

  // Can this work with generics?
  void invokeHandover(@NonNull String eventName, @Nullable Object data, @Nullable CompletionHandler<Object> completion) {
    final Map<String, Object> enveloppeData = new HashMap<String, Object>();
    enveloppeData.put("name", eventName);
    enveloppeData.put(CompletableEventEmitterDecorator.REQUEST_KEY, data);

    if (completion != null) {
      String uuid;
      do {
        uuid = UUID.randomUUID().toString();
      } while (completers.containsKey(uuid));

      completers.put(uuid, completion);

      enveloppeData.put(CompletableEventEmitterDecorator.UUID_KEY, uuid);
    }

    eventEmitter.invokeHandover("invokeHandover", enveloppeData);
  }

  void completeEvent(@NonNull String eventName, @NonNull Map data) {
    final String uuid = (String) data.get(CompletableEventEmitterDecorator.UUID_KEY);
    final Object response = data.get(CompletableEventEmitterDecorator.RESPONSE_KEY);

    Log.d("CompletableEventEmitterDecorator", "Complete event " + eventName + " with data " + data);
    if (uuid != null) {
       Log.d("CompletableEventEmitterDecorator", "Complete event uuid is not null");
      final CompletionHandler completer = completers.get(uuid);
      if (completer != null) {
        Log.d("CompletableEventEmitterDecorator", "Complete event completer is not null");
        completer.onSuccess(response);
        completers.remove(uuid);
      }
    }
  }

}
