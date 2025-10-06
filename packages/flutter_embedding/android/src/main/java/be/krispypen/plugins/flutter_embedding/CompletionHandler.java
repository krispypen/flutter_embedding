package be.krispypen.plugins.flutter_embedding;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

public interface CompletionHandler<T> {
    void onSuccess(@Nullable T data);

    void onFailure(@NonNull Exception e);
}
