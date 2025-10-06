package be.krispypen.plugins.flutter_embedding.util.parser;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;

public class JsonParserUtil {

    static public <T>  @Nullable T getOptional(Map<String,Object> map, String key) {
        final @Nullable Object value = map.get(key);
        if (value == null) {
            return null;
        }
        return (T) value;
    }

    static public Map<String, Object> getMap(Map<String,Object> map, String key){
        final @Nullable Object value = map.get(key);
        if (value instanceof Map) {
            return (Map<String, Object>) value;
        }
        return new HashMap<>();
    }

    static public <T> @NonNull T get(Map<String,Object> map, String key, T defaultValue) {
        final @Nullable T result = getOptional(map, key);
        if (result == null) return defaultValue;
        return result;
    }
}
