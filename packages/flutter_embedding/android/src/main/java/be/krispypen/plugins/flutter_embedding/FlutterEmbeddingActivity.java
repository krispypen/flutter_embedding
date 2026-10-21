package be.krispypen.plugins.flutter_embedding;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.lang.ref.WeakReference;

import io.flutter.embedding.android.FlutterActivity;

/**
 * FlutterActivity launched by {@link FlutterEmbedding#startScreen}. It keeps a weak reference to the
 * running instance so {@link FlutterEmbedding#stopScreen()} can finish it (e.g. on the exit handover).
 */
public class FlutterEmbeddingActivity extends FlutterActivity {

    @Nullable
    private static WeakReference<FlutterEmbeddingActivity> current;

    @Nullable
    private Runner onDestroyed;

    /**
     * The running instance, or null when no screen is showing (or it is already being destroyed).
     */
    @Nullable
    static FlutterEmbeddingActivity current() {
        return current != null ? current.get() : null;
    }

    /**
     * Finishes this activity (if not already finishing) and runs {@code onDestroyed} once it is
     * destroyed, i.e. after its FlutterView has detached from the engine.
     */
    void finish(@NonNull Runner onDestroyed) {
        this.onDestroyed = onDestroyed;
        if (!isFinishing()) {
            finish();
        }
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        current = new WeakReference<>(this);
    }

    @Override
    protected void onDestroy() {
        if (current() == this) {
            current = null;
        }
        super.onDestroy();

        if (onDestroyed != null) {
            Runner runner = onDestroyed;
            onDestroyed = null;
            runner.run();
        }
    }
}
