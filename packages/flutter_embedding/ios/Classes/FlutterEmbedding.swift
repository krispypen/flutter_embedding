//
//  FlutterEmbedding.swift
//  flutter_embedding
//

import Foundation
import UIKit

public final class FlutterEmbedding {
    
    public static let shared = FlutterEmbedding()
    public static let flutterEvent: String = "EventFlutter";
    public static let allEvents: Dictionary<String, String> = {
        var allEvents: Dictionary<String, String> = [:]
        Handover.allCases.forEach { handover in
            allEvents[handover.rawValue] = handover.rawValue
        }
        return allEvents
    }()

    private static let CHANNEL_NAME = "flutter_embedding/embedding"
    private static let ENGINE_ID = "flutter_embedding_engine";
    
    private var flutterEngine: FlutterEngine?
    private var channel: FlutterMethodChannel?
    
    private var handoverResponder: HandoverResponderProtocol?
    
    internal func createChannel(with registrar: FlutterPluginRegistrar) -> FlutterMethodChannel {
        self.channel = FlutterMethodChannel(name: FlutterEmbedding.CHANNEL_NAME, binaryMessenger: registrar.messenger())
        
        return self.channel!
    }
    
    public func startEngine(
        forEnv env: String,
        forLanguage language: String,
        forThemeMode themeMode: String,
        with handoverResponder: HandoverResponderProtocol,
        completion: ((_ success: Bool?, _ error: FlutterEmbeddingError?) -> ())?
    ) {
        return self.startEngine(forEnv: env, forLanguage: language, forThemeMode: themeMode, with: handoverResponder, libraryURI: nil, completion: completion)
    }
    
    public func startEngine(
        forEnv environment: String,
        forLanguage language: String,
        forThemeMode themeMode: String,
        with handoverResponder: HandoverResponderProtocol,
        libraryURI: String?,
        completion: ((_ success: Bool?, _ error: FlutterEmbeddingError?) -> ())?
    ) {
        if (self.flutterEngine != nil) {
            completion?(true, nil)
            return;
        }
        
        
        self.handoverResponder = handoverResponder;
        self.flutterEngine = FlutterEngine(name: FlutterEmbedding.ENGINE_ID)
        
        let runEngine = {
            let runResult = self.flutterEngine!.run(withEntrypoint: "main", libraryURI: libraryURI, initialRoute: "/", entrypointArgs: ["{\"environment\":\"\(environment)\",\"language\":\"\(language)\",\"themeMode\":\"\(themeMode)\"}"])
            
            if let generatedPluginRegistrantClass = (NSClassFromString("GeneratedPluginRegistrant") as Any) as? NSObjectProtocol {
                let registerWitSelector = NSSelectorFromString("registerWithRegistry:")
                
                if generatedPluginRegistrantClass.responds(to: registerWitSelector) {
                    generatedPluginRegistrantClass.perform(registerWitSelector, with: self.flutterEngine)
                }
            }
            
            if runResult {
                completion?(true, nil)
            } else {
                completion?(false, FlutterEmbeddingError.genericError(code: "FLUTTER_ENGINE_RUN_FAILED", message: "Failed to run Flutter engine"))
            }
        }
        
        if Thread.isMainThread {
            runEngine()
        } else {
            DispatchQueue.main.async {
                runEngine()
            }
        }
    }
    
    public func stopEngine() {
        let destroyEngine = {
            self.flutterEngine?.destroyContext()
            self.flutterEngine = nil
            self.handoverResponder = nil
            self.channel = nil
        }
        
        if Thread.isMainThread {
            destroyEngine()
        } else {
            DispatchQueue.main.async {
                destroyEngine()
            }
        }
    }
    
    public func getEngine() -> FlutterEngine? {
        return self.flutterEngine
    }
    
    internal func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, Any?> else {
            result(FlutterEmbeddingError.illegalArguments(message: "Invalid arguments").toFlutterError());
            return;
        }
        
        switch (call.method) {
            case Handover.exit.rawValue:
                self.handoverResponder?.exit()
                result(nil)
                break;
            
            default: self.handoverResponder?.invokeHandover(
                    withName: call.method,
                    data: args
                ) { response, error in
                    if let error = error {
                        self.handleError(error: error, result: result)
                    } else {
                        result(response!)
                    }
                }
        }
    }
    
    // TODO handle errors for completion? https://www.hackingwithswift.com/articles/161/how-to-use-result-in-swift
    public func invokeHandover(
        withName name: String,
        data: Dictionary<String, Any?>,
        completion: ((_ response: Any?, _ error: FlutterEmbeddingError?) -> ())?
    ) {
        NSLog("Sending Data \(data) to \(self.channel != nil)")
        
        // Check channel in stead of flutterEngine, because embedding Flutter doesn't create a FlutterEngine
        if (self.channel != nil) {
            self.channel?.invokeMethod(name, arguments: data) { result in
                if let flutterError = result as? FlutterError {
                    completion?(nil, FlutterEmbeddingError.flutterError(error: flutterError))
                } else {
                    completion?(result, nil)
                }
            }
        } else {
            NSLog("No flutter engine running")
            completion?(nil, FlutterEmbeddingError.noFlutterEngine)
        }
    }
    
    public func changeLanguage(
        language: String,
        completion: ((_ success: Bool?, _ error: FlutterEmbeddingError?) -> ())?
    ) {
        self.invokeHandover(withName: "change_language", data: [
            "language": language,
        ]) { result, error in
            completion?(result as? Bool ?? false, error)
        }
    }

    public func changeThemeMode(
        themeMode: String,
        completion: ((_ success: Bool?, _ error: FlutterEmbeddingError?) -> ())?
    ) {
        self.invokeHandover(withName: "change_theme_mode", data: [
            "theme_mode": themeMode,
        ]) { result, error in
            completion?(result as? Bool ?? false, error)
        }
    }
    
    public func getViewController() throws -> FlutterViewController {
        guard let flutterEngine = self.flutterEngine else {
            throw FlutterEmbeddingError.noFlutterEngine
        }
        
        if flutterEngine.viewController != nil {
            return flutterEngine.viewController!
        }
        
        let vc = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
        
        return vc;
    }
    
    private func handleError(error: Error, result: @escaping FlutterResult) {
        if let flutterError = error as? FlutterEmbeddingError {
            result(flutterError.toFlutterError())
        } else {
            result(FlutterEmbeddingError.swiftError(error: error).toFlutterError())
        }
    }
    
}

public enum FlutterEmbeddingError: Error {
    case noFlutterEngine
    case illegalArguments(message: String)
    case swiftError(error: Error)
    case flutterError(error: FlutterError)
    case genericError(code: String, message: String)
    
    public func toFlutterError () -> FlutterError {
        switch self {
        case .noFlutterEngine:
          return FlutterError(
            code: "NO_FLUTTER_ENGINE",
            message: "No Flutter error",
            details: nil
          )
        case .illegalArguments(let message):
          return FlutterError(
            code: "ILLEGAL_ARGUMENTS",
            message: message,
            details: nil
          )
        case .swiftError(let error):
          return FlutterError(
            code: "SWIFT_ERROR",
            message: error.localizedDescription,
            details: nil
          )
        case .flutterError(let error):
            return error
        case .genericError(let code, let message):
            return FlutterError(
              code: code,
              message: message,
              details: nil
          )
      }
    }
}

extension FlutterEmbeddingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noFlutterEngine:
            return NSLocalizedString("No Flutter error.", comment: "NO_FLUTTER_ENGINE")
        case .illegalArguments(let message):
            return NSLocalizedString(message, comment: "ILLEGAL_ARGUMENTS")
        case .swiftError(let error):
            return error.localizedDescription
        case .flutterError(let error):
            return NSLocalizedString(error.message ?? error.description, comment: "FLUTTER_ERROR")
        case .genericError(let code, let message):
            return NSLocalizedString(message, comment: code)
      }
    }
}
