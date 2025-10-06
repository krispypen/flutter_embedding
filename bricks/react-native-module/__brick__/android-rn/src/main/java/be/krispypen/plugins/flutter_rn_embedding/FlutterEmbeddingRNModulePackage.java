package be.krispypen.plugins.flutter_rn_embedding;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.Arrays;
import java.util.List;

public class FlutterEmbeddingRNModulePackage implements ReactPackage {

  private FlutterEmbeddingModule module;
  private FlutterEmbeddingViewManager viewManager;

  private void initiatePackage(ReactApplicationContext reactContext) {
    if (viewManager == null && module == null) {
      this.viewManager = new FlutterEmbeddingViewManager(reactContext);
      this.module = new FlutterEmbeddingModule(reactContext, viewManager);
    }
  }

  @Override
  public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
    initiatePackage(reactContext);
    return Arrays.asList(module);
  }

  @Override
  public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
    initiatePackage(reactContext);
    return Arrays.asList(viewManager);
  }
}
