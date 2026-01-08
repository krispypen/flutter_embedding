//
//  EmbeddingChannelGRPCProxy.swift
//  Proxy implementation that routes all gRPC calls through embeddingchannel
//

import Foundation
import Flutter

/// FlutterEmbeddingGRPCCore Transport that proxies all calls through the embeddingchannel
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct EmbeddingChannelGRPCTransport: FlutterEmbeddingGRPCCore.ClientTransport {
    private let embeddingChannel: EmbeddingChannel
    
    public init(embeddingChannel: EmbeddingChannel) {
        self.embeddingChannel = embeddingChannel
    }
    
    public func connect(lazy: Bool, using configuration: FlutterEmbeddingGRPCCore.ClientTransportConfiguration) -> EmbeddingChannelGRPCStream {
        return EmbeddingChannelGRPCStream(embeddingChannel: embeddingChannel)
    }
}

/// Stream implementation that routes calls through embeddingchannel
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct EmbeddingChannelGRPCStream: FlutterEmbeddingGRPCCore.ClientTransportStream {
    private let embeddingChannel: EmbeddingChannel
    
    init(embeddingChannel: EmbeddingChannel) {
        self.embeddingChannel = embeddingChannel
    }
    
    public func execute(
        _ request: FlutterEmbeddingGRPCCore.ClientRequest<Data>,
        method: FlutterEmbeddingGRPCCore.MethodDescriptor,
        options: FlutterEmbeddingGRPCCore.CallOptions
    ) async throws -> FlutterEmbeddingGRPCCore.ClientResponse<Data> {
        // Extract service name and method name from method descriptor
        // Format is typically "/serviceName/methodName" or "serviceName/methodName"
        let fullMethodName = method.fullyQualifiedMethod
        let trimmedMethodName = fullMethodName.hasPrefix("/") ? String(fullMethodName.dropFirst()) : fullMethodName
        let components = trimmedMethodName.split(separator: "/")
        guard components.count >= 2 else {
            throw NSError(domain: "EmbeddingChannelGRPC", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid method name: \(fullMethodName)"])
        }
        let serviceName = String(components[0])
        let methodName = String(components[1])
        
        // Request message is already Data (serialized)
        let requestData = request.message
        let intArray = requestData.map { Int8(bitPattern: $0) }

        NSLog("intArray: \(intArray)")
        
        // Prepare data dictionary to send through embeddingchannel
        let data: Dictionary<String, Any?> = [
            "method": methodName,
            "data": intArray
        ]

        print("execute Data: \(data)")
        
        // Call embeddingchannel and wait for response
        return try await withCheckedThrowingContinuation { continuation in
            embeddingChannel.invokeHandover(withName: serviceName, data: data) { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Handle response - could be Data, FlutterStandardTypedData, or [UInt8]
                let responseData: Data?
                if let data = response as? Data {
                    responseData = data
                } else if let typedData = response as? FlutterStandardTypedData {
                    responseData = typedData.data
                } else if let byteArray = response as? [UInt8] {
                    responseData = Data(byteArray)
                } else if let intArray = response as? [Int8] {
                    responseData = Data(intArray.map { UInt8(bitPattern: $0) })
                } else {
                    continuation.resume(throwing: NSError(domain: "EmbeddingChannelGRPC", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format: \(type(of: response))"]))
                    return
                }
                
                guard let responseData = responseData else {
                    continuation.resume(throwing: NSError(domain: "EmbeddingChannelGRPC", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to extract response data"]))
                    return
                }
                
                // Return response as Data (will be deserialized by the GRPCClient)
                let clientResponse = FlutterEmbeddingGRPCCore.ClientResponse<Data>(
                    message: responseData,
                    metadata: [:],
                    trailingMetadata: [:]
                )
                continuation.resume(returning: clientResponse)
            }
        }
    }
}

/// Protocol for embeddingchannel access
public protocol EmbeddingChannel: AnyObject {
    func invokeHandover(
        withName name: String,
        data: Dictionary<String, Any?>,
        completion: ((_ response: Any?, _ error: Error?) -> ())?
    )
}

