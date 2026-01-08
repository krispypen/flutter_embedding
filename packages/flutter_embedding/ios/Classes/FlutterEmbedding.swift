//
//  FlutterEmbedding.swift
//  flutter_embedding
//

import Foundation
import UIKit
import Flutter

public final class FlutterEmbedding {
    
    public static let shared = FlutterEmbedding()
    public static let flutterEvent: String = "EventFlutter";
    public static let allEvents: Dictionary<String, String> = {
        var allEvents: Dictionary<String, String> = [:]
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
        startConfig: String,
        with handoverResponder: HandoverResponderProtocol,
        completion: ((_ success: Bool?, _ error: FlutterEmbeddingError?) -> ())?
    ) {
        return self.startEngine(startConfig: startConfig, with: handoverResponder, libraryURI: nil, completion: completion)
    }
    
    public func startEngine(
        startConfig: String,
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
            let runResult = self.flutterEngine!.run(withEntrypoint: "main", libraryURI: libraryURI, initialRoute: "/", entrypointArgs: [startConfig])
            
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
        // 1. Zorg ervoor dat de argumenten een Dictionary zijn
        guard var incomingMap = call.arguments as? [String: Any] else {
            // Stuur een fout terug als de argumenten niet het verwachte formaat hebben
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected Map not found.", details: nil))
            return
        }

        // convert FlutterStandardTypedData to Swift Data
        guard let typedData = incomingMap["data"] as? FlutterStandardTypedData else {
            // Stuur een fout terug als de 'data' sleutel ontbreekt of van een verkeerd type is
            result(FlutterError(code: "MISSING_DATA", message: "Data-element missing or not a FlutterStandardTypedData.", details: nil))
            return
        }

        // convert FlutterStandardTypedData to Swift Data
        // 'data' is NSData, that is automatically converted to Swift Data
        let swiftData: Data = typedData.data as Data

        // Optioneel: Voor een Array van UInt8
        let byteArray: [UInt8] = [UInt8](swiftData)

        // 4. Vervang de oude waarde in de Dictionary door de nieuwe Swift Data
        // Omdat we 'var incomingMap' hebben, kunnen we de waarde aanpassen.
        incomingMap["data"] = byteArray // swiftData 

        // De nieuwe map met native Swift Data (en de rest van de data)
        let processedMap: [String: Any] = incomingMap

        self.handoverResponder?.invokeHandover(
            withName: call.method,
            data: processedMap
        ) { response, error in
            if let error = error {
                self.handleError(error: error, result: result)
            } else {
                // Handle response which can be either Data or [NSNumber]
                let data: Data
                var typedData: FlutterStandardTypedData?
                
                if let responseData = response as? Data {
                    // Response is already Data, use it directly
                    data = responseData
                    typedData = FlutterStandardTypedData(bytes: data)
                } else if let nsNumberArray = response as? [NSNumber] {
                    // Convert NSNumber array to int array
                    let intArray: [Int] = nsNumberArray.map { nsNumber in
                        return nsNumber.intValue
                    }
                    // Convert the [Int] array to Data
                    data = intArray.withUnsafeBytes { Data($0) }
                    typedData = FlutterStandardTypedData(int64: data)
                } else {
                    print("Error: Response is neither Data nor an array of NSNumber. Response: \(String(describing: response))")
                    result(FlutterError(code: "INVALID_RESPONSE", message: "Response must be either Data or [NSNumber]", details: nil))
                    return
                }

                // Create a FlutterStandardTypedData (Int64Array is the most robust for [Int])
                // Note: Int64Array corresponds to Dart's List<int> (64-bit int).
                // Use .int32Array if you're sure the numbers fit in 32-bits.
                result(typedData!)
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
                    // convert data["request"] to [int]
            // convert data["request"] to Data
            var requestData: Data?
            var typedData: FlutterStandardTypedData?

            if let requestArray = data["request"] as? [Int] { // at this moment this is what we get from react native code
                NSLog("Request array: \(requestArray)")
                requestData = requestArray.withUnsafeBytes { Data($0) }
                typedData = FlutterStandardTypedData(int64: requestData!)
            } else if let requestDataDirect = data["request"] as? Data { // at this moment this is what we get from ios native code
                NSLog("Request data direct: \(requestDataDirect)")
                requestData = requestDataDirect
                typedData = FlutterStandardTypedData(bytes: requestData!)
            } /*else if let requestUInt8Array = data["request"] as? [UInt8] {
                requestData = Data(requestUInt8Array)
                typedData = FlutterStandardTypedData(int64: requestData!)
            }*/

            guard let requestData = requestData else {
                completion?(nil, FlutterEmbeddingError.genericError(code: "INVALID_REQUEST_DATA", message: "Request data is missing or invalid"))
                return
            }

            // clone data into new dictionary
            var newData: [String: Any?] = data.mapValues { $0 }
            newData["request"] = typedData
            newData["test"] = "test"
            
            // Ensure method channel calls are made on the main thread
            DispatchQueue.main.async {
                self.channel?.invokeMethod(name, arguments: newData) { result in
                    if let flutterError = result as? FlutterError {
                        completion?(nil, FlutterEmbeddingError.flutterError(error: flutterError))
                    } else {
                        // Handle result as either [Int] or FlutterStandardTypedData
                        if let typedData = result as? FlutterStandardTypedData { // at this moment this is what we get from ios native code
                            // Extract Data from FlutterStandardTypedData
                            let data = typedData.data as Data
                            completion?(data, nil)
                        } else if let resultArray = result as? [Int] { // at this moment this is what we get from react native code
                            // Convert [Int] to Data
                            let resultData = resultArray.withUnsafeBytes { Data($0) }
                            completion?(resultData, nil)
                        } else {
                            completion?(nil, FlutterEmbeddingError.genericError(code: "INVALID_RESULT", message: "Result \(String(describing: result)) is not a valid [Int] or FlutterStandardTypedData"))
                        }
                    }
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
