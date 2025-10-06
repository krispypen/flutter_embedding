package be.krispypen.plugins.flutter_rn_embedding;

import com.facebook.react.ReactActivity;
import com.facebook.react.ReactActivityDelegate;
import be.krispypen.plugins.flutter_embedding.FlutterEmbedding;
import be.krispypen.plugins.flutter_embedding.FlutterEmbeddingFlutterFragment;

public class FlutterEmbeddingReactActivity extends ReactActivity {

  @Override
  protected ReactActivityDelegate createReactActivityDelegate() {
    return new FlutterEmbeddingReactActivityDelegate(this, this.getMainComponentName());
  }

  /**
   * This is the one called when React cannot handle back press anymore
   * Typically this is when the whole navigation stack is popped ... so we need to let
   * Android native handle the back press now.
   * <p>
   * In this case we need to disable the flutter fragment back press handler, because else that
   * will again send the event to React Native and then React Native will again invoke this default
   * back press handler. This will end in an infinite loop. From the moment "invokeDefaultOnBackPressed"
   * is triggered we can assume it was because of an event received from React Native because it cannot
   * pop anymore.
   */
  @Override
  public void invokeDefaultOnBackPressed() {
    // this is what FlutterFragment does by default for #popSystemNavigator
    // we will temporary disable the flutterFragment onBackPressedCallback to give the native back pressed
    // handler a chance to react.
    final FlutterEmbeddingFlutterFragment flutterFragment = FlutterEmbedding.instance().getFragment(this);
    if (flutterFragment != null) {
      flutterFragment.onBackPressedCallback.setEnabled(false);
    }

    getOnBackPressedDispatcher().onBackPressed();

    if (flutterFragment != null) {
      flutterFragment.onBackPressedCallback.setEnabled(true);
    }
  }

}
