//
//  CompletableEventHandler.swift
//  FlutterEmbeddingRNModule
//
//  Created by Kris Pypen.
//

import Foundation


class CompletableEventEmitterDecorator {
    
    internal static let UUID_KEY: String = "_completable_event_uuid"
    internal static let REQUEST_KEY: String = "_completable_event_request"
    internal static let RESPONSE_KEY: String = "_completable_event_response"
    
    final private let eventEmitter: EventEmitterProtocol
    final private var completers: Dictionary<String, ((Any?) -> ())> = [:]
    
    init(for eventEmitter: EventEmitterProtocol) {
        self.eventEmitter = eventEmitter
    }
    
    // Can this work with generics?
    func invokeHandover(withName name: String, data: Any?, completion: ((Any?)->())?) {
        var enveloppeData: Dictionary<String, Any> = [:]
        enveloppeData[CompletableEventEmitterDecorator.REQUEST_KEY] = data
        
        if (completion != nil) {
            let uuid = UUID().uuidString;
            
            completers[uuid] = completion
            
            enveloppeData[CompletableEventEmitterDecorator.UUID_KEY] = uuid
        }

        enveloppeData["name"] = name
        
        eventEmitter.sendEvent(withName: "invokeHandover", data: enveloppeData)
    }

    func completeEvent(withName name: String, data: Dictionary<String, Any?>) {
        if let uuid = data[CompletableEventEmitterDecorator.UUID_KEY] as? String, let completer: (Any?) -> () = completers[uuid] {
            completer(data[CompletableEventEmitterDecorator.RESPONSE_KEY] as Any?);
            completers.removeValue(forKey: uuid)
        }
    }
    
}

protocol EventEmitterProtocol {
    func sendEvent(withName name: String, data: Dictionary<String, Any?>)
}
