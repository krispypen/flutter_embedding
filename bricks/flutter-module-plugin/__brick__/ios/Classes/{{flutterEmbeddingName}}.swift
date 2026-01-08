//
//  FlutterEmbedding.swift
//  flutter_embedding
//

import Foundation
import UIKit
import SwiftProtobuf
import flutter_embedding

// Note: We still import GRPCCore for compatibility with generated code,
// but we use CustomGRPCCore for our own client implementations

public final class {{flutterEmbeddingName}} {
    
    public static let shared = {{flutterEmbeddingName}}()
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
        self.channel = FlutterMethodChannel(name: {{flutterEmbeddingName}}.CHANNEL_NAME, binaryMessenger: registrar.messenger())
        
        return self.channel!
    }
    
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    public func startEngine(
        startParams: {{startParamsMessage}},
        {{#handoversToHostServices}}
        {{name}}: {{type}}.SimpleServiceProtocol,
        {{/handoversToHostServices}}
        completion: ((_ success: Bool?, _ error: FlutterEmbeddingError?) -> ())?
    ) {
        guard let startParamsData = try? startParams.serializedData() else {
            completion?(false, FlutterEmbeddingError.illegalArguments(message: "Failed to serialize StartParams"))
            return
        }
        let startParamsIntArray = startParamsData.map { Int8(bitPattern: $0) }
        let arrayString = startParamsIntArray.map { String($0) }.joined(separator: ",")
        let startConfig = "{\"startParams\":[" + arrayString + "]}"
        // Create a handover responder that converts gRPC service calls to handover invocations
        let services: [any FlutterEmbeddingGRPCCore.RegistrableRPCService] = [{{#handoversToHostServices}}{{name}}, {{/handoversToHostServices}}]
        let handoverResponder = GRPCHandoverResponder(services: services)
        return FlutterEmbedding.shared.startEngine(startConfig: startConfig, with: handoverResponder, completion: completion)
    }
    
    
    public func stopEngine() {
        FlutterEmbedding.shared.stopEngine()
    }
    
    internal func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, Any?> else {
            result(FlutterEmbeddingError.illegalArguments(message: "Invalid arguments").toFlutterError());
            return;
        }
        
        switch (call.method) {
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
    
    public func invokeHandover(
        withName name: String,
        data: Dictionary<String, Any?>,
        completion: ((_ response: Any?, _ error: FlutterEmbeddingError?) -> ())?
    ) {
        NSLog("Sending Data \(data) in {{flutterEmbeddingName}}.invokeHandover with name \(name)")
        return FlutterEmbedding.shared.invokeHandover(withName: name, data: data, completion: completion)
    }
    
    public func getViewController() throws -> FlutterViewController {
        return try FlutterEmbedding.shared.getViewController()
    }
    
    private func handleError(error: Error, result: @escaping FlutterResult) {
        if let flutterError = error as? FlutterEmbeddingError {
            result(flutterError.toFlutterError())
        } else {
            result(FlutterEmbeddingError.swiftError(error: error).toFlutterError())
        }
    }
}

/// FlutterEmbeddingGRPCCore Transport that uses invokeHandover directly on {{flutterEmbeddingName}}
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct {{flutterEmbeddingName}}Transport: FlutterEmbeddingGRPCCore.ClientTransport {
    private let flutterModuleEmbedding: {{flutterEmbeddingName}}
    
    public init(flutterModuleEmbedding: {{flutterEmbeddingName}}) {
        self.flutterModuleEmbedding = flutterModuleEmbedding
    }
    
    public func connect(lazy: Bool, using configuration: FlutterEmbeddingGRPCCore.ClientTransportConfiguration) -> FlutterEmbeddingGRPCStream {
        return FlutterEmbeddingGRPCStream(flutterModuleEmbedding: flutterModuleEmbedding)
    }
}

/// Stream implementation that routes calls through {{flutterEmbeddingName}}.invokeHandover
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct FlutterEmbeddingGRPCStream: FlutterEmbeddingGRPCCore.ClientTransportStream {
    private let flutterModuleEmbedding: {{flutterEmbeddingName}}
    
    init(flutterModuleEmbedding: {{flutterEmbeddingName}}) {
        self.flutterModuleEmbedding = flutterModuleEmbedding
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
            throw NSError(domain: "FlutterEmbeddingGRPC", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid method name: \(fullMethodName)"])
        }
        let serviceName = String(components[0])
        let methodName = String(components[1])
        
        // Request message is already Data (serialized)
        let requestData = request.message
        
        // Prepare data dictionary matching Kotlin implementation format
        // ["request": requestBytes, "service": serviceName, "method": methodName]
        let data: Dictionary<String, Any?> = [
            "request": requestData,
            "service": serviceName,
            "method": methodName
        ]

        NSLog("Sending Data \(data) to {{flutterEmbeddingName}}.invokeHandover")
        
        // Call invokeHandover and wait for response
        return try await withCheckedThrowingContinuation { continuation in
            flutterModuleEmbedding.invokeHandover(withName: serviceName, data: data) { response, error in
                if let error = error {
                    // Convert FlutterEmbeddingError to NSError if needed
                    let nsError: Error
                    if let flutterError = error as? FlutterEmbeddingError {
                        nsError = NSError(domain: "FlutterEmbeddingGRPC", code: -2, userInfo: [NSLocalizedDescriptionKey: "Flutter embedding error: \(flutterError)"])
                    } else {
                        nsError = error
                    }
                    continuation.resume(throwing: nsError)
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
                } else if let byteList = response as? [Any] {
                    // Handle List<Byte> or List<Int> similar to Kotlin implementation
                    responseData = Data(byteList.compactMap { item in
                        if let byte = item as? UInt8 {
                            return byte
                        } else if let int = item as? Int {
                            return UInt8(int & 0xFF)
                        }
                        return nil
                    })
                } else {
                    continuation.resume(throwing: NSError(domain: "FlutterEmbeddingGRPC", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format: \(type(of: response))"]))
                    return
                }
                
                guard let responseData = responseData else {
                    continuation.resume(throwing: NSError(domain: "FlutterEmbeddingGRPC", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to extract response data"]))
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



extension {{flutterEmbeddingName}} {
    {{#handoversToFlutterServices}}
    @available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
    public func {{name}}() -> {{type}}.Client<{{flutterEmbeddingName}}Transport> {
        let transport = {{flutterEmbeddingName}}Transport(flutterModuleEmbedding: self)
        let client = FlutterEmbeddingGRPCCore.GRPCClient(transport: transport)
        return {{type}}.Client(wrapping: client)
    }
    {{/handoversToFlutterServices}}
}



@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
private class GRPCHandoverResponder: HandoverResponderProtocol {
    private var methodHandlers: [String: MethodHandler] = [:]
    
    private struct MethodHandler {
        let deserializer: any FlutterEmbeddingGRPCCore.MessageDeserializerProtocol
        let serializer: any FlutterEmbeddingGRPCCore.MessageSerializerProtocol
        let handler: (Any, FlutterEmbeddingGRPCCore.ServerContext) async throws -> Any
    }
    
    init(services: [any FlutterEmbeddingGRPCCore.RegistrableRPCService]) {
        // Create a router with a registration callback
        var router = FlutterEmbeddingGRPCCore.RPCRouter<FakeServerTransport>()
        
        // Set up callback to capture handlers
        router.setRegistrationCallback { [weak self] descriptor, deserializer, serializer, handler in
            guard let self = self else { return }
            let methodKey = descriptor.fullyQualifiedMethod
            let normalizedKey = methodKey.hasPrefix("/") ? String(methodKey.dropFirst()) : methodKey
            
            self.methodHandlers[normalizedKey] = MethodHandler(
                deserializer: deserializer,
                serializer: serializer,
                handler: handler
            )
        }
        
        // Register all services - this will populate methodHandlers via the callback
        for service in services {
            service.registerMethods(with: &router)
        }
    }
    
    func invokeHandover(
        withName name: String,
        data: Dictionary<String, Any?>,
        completion: ((_ response: Any?, _ error: FlutterEmbeddingError?) -> ())?
    ) {
        // data["method"] is always a String
        guard let methodName = data["method"] as? String else {
            completion?(nil, FlutterEmbeddingError.illegalArguments(message: "Missing 'method' in data"))
            return
        }
        
        // data["data"] is always a [UInt8] array
        guard let byteArray = data["data"] as? [UInt8] else {
            completion?(nil, FlutterEmbeddingError.illegalArguments(message: "Missing 'data' (UInt8 array) in data"))
            return
        }
        
        let requestData = Data(byteArray)
        
        // Build method key: serviceName/methodName (normalize to match router format)
        let methodKey = "\(name)/\(methodName)"
        
        guard let methodHandler = methodHandlers[methodKey] else {
            completion?(nil, FlutterEmbeddingError.genericError(code: "METHOD_NOT_FOUND", message: "Method \(methodKey) not found"))
            return
        }
        
        // Route the call
        Task {
            do {
                // Deserialize request
                let request = try await methodHandler.deserializer.deserialize(requestData)
                
                // Create server context with the method descriptor
                let methodDescriptor = FlutterEmbeddingGRPCCore.MethodDescriptor(fullyQualifiedMethod: methodKey)
                let context = FlutterEmbeddingGRPCCore.ServerContext(descriptor: methodDescriptor)
                
                // Call handler
                let response = try await methodHandler.handler(request, context)
                
                // Serialize response
                let responseData = try await methodHandler.serializer.serialize(response)
                
                completion?(responseData, nil)
            } catch {
                completion?(nil, FlutterEmbeddingError.swiftError(error: error))
            }
        }
    }
}




// Fake server transport for router (not actually used for transport)
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
private struct FakeServerTransport: FlutterEmbeddingGRPCCore.ServerTransport {
    typealias Bytes = Data
    
    func listen(
        streamHandler: @escaping @Sendable (
            _ stream: FlutterEmbeddingGRPCCore.RPCStream<
                FlutterEmbeddingGRPCCore.RPCAsyncSequence<FlutterEmbeddingGRPCCore.RPCRequestPart<Data>, any Error>,
                FlutterEmbeddingGRPCCore.RPCWriter<FlutterEmbeddingGRPCCore.RPCResponsePart<Data>>.Closable
            >,
            _ context: FlutterEmbeddingGRPCCore.ServerContext
        ) async -> Void
    ) async throws {
        // Not implemented - this transport is only used for type purposes
    }
    
    func beginGracefulShutdown() {
        // Not implemented
    }
}
