package be.krispypen.plugins.flutter_embedding;

import android.content.Context;
import android.os.Bundle;
import android.view.View;

import androidx.activity.OnBackPressedCallback;
import androidx.annotation.NonNull;
import androidx.fragment.app.FragmentActivity;

import java.lang.ref.WeakReference;

import io.flutter.embedding.android.FlutterFragment;

public class FlutterEmbeddingFlutterFragment extends FlutterFragment {

    public final OnBackPressedCallback onBackPressedCallback =
            new OnBackPressedCallback(true) {
                @Override
                public void handleOnBackPressed() {
                    if (FlutterEmbeddingFlutterFragment.this.isVisible()) {
                        onBackPressed();
                    } else {
                        popSystemNavigator();
                    }
                }
            };

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);

        requireActivity().getOnBackPressedDispatcher().addCallback(this, onBackPressedCallback);
    }

    /**
     * {@inheritDoc}
     *
     * <p>Avoid overriding this method when using {@code
     * shouldAutomaticallyHandleOnBackPressed(true)}. If you do, you must always {@code return
     * super.popSystemNavigator()} rather than {@code return false}. Otherwise the navigation behavior
     * will recurse infinitely between this method and {@link #onBackPressed()}, breaking navigation.
     */
    @Override
    public boolean popSystemNavigator() {
        FragmentActivity activity = getActivity();
        if (activity != null) {
            // Unless we disable the callback, the dispatcher call will trigger it. This will then
            // trigger the fragment's onBackPressed() implementation, which will call through to the
            // dart side and likely call back through to this method, creating an infinite call loop.
            onBackPressedCallback.setEnabled(false);
            this.handleSystemBackPressed(activity);
            onBackPressedCallback.setEnabled(true);

            return true;
        }

        return false;
    }

    public static WeakReference<View> lastview;

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        lastview = new WeakReference<>(view);
    }

    public void handleSystemBackPressed(@NonNull FragmentActivity activity) {
        activity.getOnBackPressedDispatcher().onBackPressed();
    }

    // TODO: can we use these to see if the fragment is still visible?

    @Override
    public void onDetach() {
        super.onDetach();
    }

    @Override
    public void onStart() {
        super.onStart();
    }

    @Override
    public void onPause() {
        super.onPause();
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    @Override
    public void onStop() {
        super.onStop();
    }

    @Override
    public void onDestroy() {
         if (lastview != null) {
            lastview.clear();
        }
        super.onDestroy();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
    }
}
