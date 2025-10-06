import Foundation
import UIKit
import AVFoundation
import flutter_embedding


@objc(FlutterEmbeddingModule)
class FlutterEmbeddingModule: NSObject, EventEmitterProtocol {
    
    private final var handoverResponder: ReactNativeHandoverResponder?
    
    override init() {
        super.init()
        
        self.handoverResponder = ReactNativeHandoverResponder(eventEmitter: self)
    }
    

    @objc func startEngine(_ env: String, language: String, themeMode: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        FlutterEmbedding.shared.startEngine(forEnv: env, forLanguage: language, forThemeMode: themeMode, with: handoverResponder!, libraryURI: "package:flutter_module/main.dart") { result, error in
            if let flutterError = error?.toFlutterError() {
                reject(flutterError.code, flutterError.message ?? flutterError.description, error)
            } else {
                resolve(nil)
            }
        }
    }
    
    @objc func stopEngine() {
        FlutterEmbedding.shared.stopEngine()
    }
    
    
    @objc func changeLanguage(_ language: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        FlutterEmbedding.shared.changeLanguage(language: language) { result, error in
            if let flutterError = error?.toFlutterError() {
                reject(flutterError.code, flutterError.message ?? flutterError.description, error)
            } else {
                resolve(result)
            }
        }
    }

    @objc func changeThemeMode(_ themeMode: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        FlutterEmbedding.shared.changeThemeMode(themeMode: themeMode) { result, error in
            if let flutterError = error?.toFlutterError() {
                reject(flutterError.code, flutterError.message ?? flutterError.description, error)
            } else {
                resolve(result)
            }
        }
    }
    
    
    @objc func invokeHandover(withName name: String, data: Dictionary<String, Any>, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        FlutterEmbedding.shared.invokeHandover(withName: name, data: data) { result, error in
            if let flutterError = error?.toFlutterError() {
                reject(flutterError.code, flutterError.message ?? flutterError.description, error)
            } else {
                resolve(result)
            }
        }
    }
    
    @objc func respondToEvent(_ eventName: String, data: Dictionary<String, Any>) {
        self.handoverResponder?.handleResponse(forEvent: eventName, data: data)
    }
    
}
