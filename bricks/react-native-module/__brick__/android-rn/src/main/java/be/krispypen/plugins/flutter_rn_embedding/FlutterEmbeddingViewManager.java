package be.krispypen.plugins.flutter_rn_embedding;

import android.graphics.Color;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.facebook.react.ReactActivity;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import be.krispypen.plugins.flutter_embedding.FlutterEmbedding;

import io.flutter.embedding.android.FlutterFragment;

public class FlutterEmbeddingViewManager extends SimpleViewManager<View> {
  private FrameLayout layout;

  public static final String REACT_CLASS = "FlutterEmbeddingView";
  ReactApplicationContext mCallerContext;

  public FlutterEmbeddingViewManager(ReactApplicationContext reactContext) {
    mCallerContext = reactContext;
  }

  void reset() {
    this.layout = null;
  }

  @Override
  @NonNull
  public String getName() {
    return REACT_CLASS;
  }

  @Override
  @NonNull
  public FrameLayout createViewInstance(@NonNull ThemedReactContext context) {
    if (layout != null) {
      return layout;
    }

    layout = new FrameLayout(context);

    final ReactActivity activity = (ReactActivity) mCallerContext.getCurrentActivity();

    // Get a reference to the Activity's FragmentManager to add a new
    // FlutterFragment, or find an existing one.
    assert activity != null;
    final FlutterFragment flutterFragment = FlutterEmbedding.instance().getOrCreateFragment(activity, FlutterEmbeddingReactFlutterFragment.class);

    // This step is needed to in order for ReactNative to render your view
    layout.addView(flutterFragment.getView(), FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);

    return layout;
  }

  @ReactProp(name = "color")
  public void setColor(View view, String color) {
    view.setBackgroundColor(Color.parseColor(color));
  }
}
