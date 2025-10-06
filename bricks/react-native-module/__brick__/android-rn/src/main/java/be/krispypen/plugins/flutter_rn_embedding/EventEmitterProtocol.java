package be.krispypen.plugins.flutter_rn_embedding;

import androidx.annotation.NonNull;

import java.util.Map;

public interface EventEmitterProtocol {

  void invokeHandover(@NonNull String eventName, @NonNull Map<String, Object> data);

}
