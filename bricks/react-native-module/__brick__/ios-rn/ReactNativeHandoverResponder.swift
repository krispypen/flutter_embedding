//
//  ReactNativeHandoverResponder.swift
//  FlutterEmbeddingRNModule
//
//  Created by Kris Pypen
//

import Foundation
import Flutter
import flutter_embedding

class ReactNativeHandoverResponder: HandoverResponderProtocol {

    final let eventEmitter: CompletableEventEmitterDecorator

    init(eventEmitter: EventEmitterProtocol) {
        self.eventEmitter = CompletableEventEmitterDecorator(for: eventEmitter)
    }

    func handleResponse(forEvent eventName: String, data: Dictionary<String, Any>) {
        self.eventEmitter.completeEvent(
            withName: eventName,
            data: data
        );
    }

    func exit() {
        eventEmitter.invokeHandover(
            withName: Handover.exit.rawValue,
            data: nil,
            completion: nil
        )
    }

    func invokeHandover(withName name: String, data: Dictionary<String, Any?>, completion: ((Any?, flutter_embedding.FlutterEmbeddingError?) -> ())?) {
        eventEmitter.invokeHandover(
            withName: name,
            data: data,
            completion: { result in
                completion?(result, nil)
            }
        )
    }

}
