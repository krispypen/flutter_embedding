import Flutter
import UIKit

public class SwiftFlutterEmbeddingPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterEmbedding.shared.createChannel(with: registrar)
        
        registrar.addMethodCallDelegate(SwiftFlutterEmbeddingPlugin(), channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        FlutterEmbedding.shared.handle(call, result: result)
    }
}
