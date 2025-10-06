package be.krispypen.plugins.flutter_rn_embedding;

import androidx.annotation.Nullable;

import com.facebook.react.ReactActivity;
import com.facebook.react.ReactActivityDelegate;

public class FlutterEmbeddingReactActivityDelegate extends ReactActivityDelegate {

  public FlutterEmbeddingReactActivityDelegate(ReactActivity activity, @Nullable String mainComponentName) {
    super(activity, mainComponentName);
  }

  @Override
  public boolean onBackPressed() {
    return false;
  }

}
