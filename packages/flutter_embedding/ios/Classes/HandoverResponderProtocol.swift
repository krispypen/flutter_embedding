//
//  HandoverResponderProtocol.swift
//  flutter_embedding
//

import Foundation

/**
 * IMPORTANT: keep this in sync:
 * - with the Flutter version: handover_service.dart
 * - with the Android version: /HandoverResponderInterface.java
 * - with the React-native version: HandoverResponderInterface.ts
 **/
public protocol HandoverResponderProtocol {

    
    /**
     * This will be used to invoke a handover event to the native app.
     *
     * @param name
     * @param data
     * @param completion
     */
    func invokeHandover(
        withName name: String,
        data: Dictionary<String, Any?>,
        completion: ((_ response: Any?, _ error: FlutterEmbeddingError?) -> ())?
    )
}

public extension HandoverResponderProtocol {
  func provideAnonymousAccessToken(_ completion: @escaping ((_ accessToken: String?, _ error: Error?) -> ())) {
    completion(nil, FlutterEmbeddingError.genericError(
        code: "NOT_IMPLEMENTED",
        message: "This method of the protocol was not implemented on your class."
    ));
  }
}
