import Foundation
import UIKit
import AVFoundation
import flutter_embedding
import React


@objc(FlutterEmbeddingModule)
class FlutterEmbeddingModule: RCTEventEmitter, EventEmitterProtocol {
    
    private final var handoverResponder: ReactNativeHandoverResponder?
    
    override init() {
        super.init()
        
        self.handoverResponder = ReactNativeHandoverResponder(eventEmitter: self)
    }
    
    /// Base overide for RCTEventEmitter.
    ///
    /// - Returns: all supported events
    @objc open override func supportedEvents() -> [String]! {
        return Array(["exit", "invokeHandover"])
    }
    

    @objc func startEngine(_ env: String, language: String, themeMode: String, handoverResponder: ReactNativeHandoverResponder, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
        // Store the handoverResponder for later use
        self.handoverResponder = handoverResponder
        
        FlutterEmbedding.shared.startEngine(forEnv: env, forLanguage: language, forThemeMode: themeMode, with: handoverResponder, libraryURI: "package:flutter_module/main.dart") { result, error in
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
    
    func sendEvent(withName name: String, data: Dictionary<String, Any?>) {
        super.sendEvent(withName: name, body: data)
    }

    @objc func exit() {
       super.sendEvent(withName: "exit", body: nil)
    }
    
    @objc func invokeHandoverReturn(_ name: String, data: Dictionary<String, Any>) {
        FlutterEmbedding.shared.invokeHandover(withName: name, data: data, completion: nil);
    }
    
    @objc func respondToEvent(_ eventName: String, data: Dictionary<String, Any>) {
        self.handoverResponder?.handleResponse(forEvent: eventName, data: data)
    }
    
    @objc(requiresMainQueueSetup)
    override static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    @objc(constantsToExport)
    override func constantsToExport() -> [AnyHashable: Any]! {
        return FlutterEmbedding.allEvents.merging([
            "COMPLETABLE_EVENT_UUID_KEY": CompletableEventEmitterDecorator.UUID_KEY,
            "COMPLETABLE_EVENT_REQUEST_KEY": CompletableEventEmitterDecorator.REQUEST_KEY,
            "COMPLETABLE_EVENT_RESPONSE_KEY": CompletableEventEmitterDecorator.RESPONSE_KEY,
        ]) { $1 }
    }
    
}
