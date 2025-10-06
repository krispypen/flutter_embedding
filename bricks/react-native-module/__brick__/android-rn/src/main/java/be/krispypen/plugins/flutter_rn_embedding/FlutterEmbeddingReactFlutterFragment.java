package be.krispypen.plugins.flutter_rn_embedding;

import androidx.annotation.NonNull;
import androidx.fragment.app.FragmentActivity;

import com.facebook.react.ReactApplication;
import com.facebook.react.ReactNativeHost;
import be.krispypen.plugins.flutter_embedding.FlutterEmbeddingFlutterFragment;

public class FlutterEmbeddingReactFlutterFragment extends FlutterEmbeddingFlutterFragment {

  @Override
  public void handleSystemBackPressed(@NonNull FragmentActivity activity) {
    final ReactNativeHost reactNativeHost = ((ReactApplication) activity.getApplication()).getReactNativeHost();
    if (reactNativeHost.hasInstance()) {
      reactNativeHost.getReactInstanceManager().onBackPressed();
    }
  }

}
