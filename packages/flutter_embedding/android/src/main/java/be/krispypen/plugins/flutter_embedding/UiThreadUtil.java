package be.krispypen.plugins.flutter_embedding;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.Nullable;

// Helper utility from React Native
class UiThreadUtil {

    @Nullable
    private static Handler sMainHandler;

    /**
     * @return {@code true} if the current thread is the UI thread.
     */
    public static boolean isOnUiThread() {
        return Looper.getMainLooper().getThread() == Thread.currentThread();
    }

    /**
     * Runs the given {@code Runnable} on the UI thread.
     */
    public static void runOnUiThread(Runnable runnable) {
        runOnUiThread(runnable, 0);
    }

    /**
     * Runs the given {@code Runnable} on the UI thread with the specified delay.
     */
    public static void runOnUiThread(Runnable runnable, long delayInMs) {
        synchronized (UiThreadUtil.class) {
            if (sMainHandler == null) {
                sMainHandler = new Handler(Looper.getMainLooper());
            }
        }
        sMainHandler.postDelayed(runnable, delayInMs);
    }
}
