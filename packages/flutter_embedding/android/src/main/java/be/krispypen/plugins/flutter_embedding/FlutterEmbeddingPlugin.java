package be.krispypen.plugins.flutter_embedding;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;

/**
 * FlutterEmbeddingPlugin
 */
public class FlutterEmbeddingPlugin implements FlutterPlugin {

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        MethodChannel channel = FlutterEmbedding.instance().createChannel(flutterPluginBinding);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        FlutterEmbedding.instance().detachChannel();
    }
}
