//
//  CustomGRPCCore.swift
//  Custom GRPCCore implementation that proxies through embeddingchannel
//
//  This module provides a minimal, API-compatible subset of GRPCCore functionality.
//  Instead of direct network communication, all RPC calls are proxied through
//  the Flutter embedding channel, allowing Flutter to communicate with native code
//  using a familiar gRPC-like interface.
//

import Foundation
import SwiftProtobuf


/// Namespace for Protobuf serialization/deserialization utilities
///
/// Provides SwiftProtobuf-compatible serializer and deserializer implementations
/// for use with the custom GRPCCore implementation.
public enum FlutterEmbeddingProtobuf {

    /// Serializer for SwiftProtobuf messages
    public struct ProtobufSerializer<Message: SwiftProtobuf.Message>: FlutterEmbeddingGRPCCore.MessageSerializer {
        public init() {}
        
        public func serialize(_ message: Message) async throws -> Data {
            return try message.serializedData()
        }
    }

    /// Deserializer for SwiftProtobuf messages
    public struct ProtobufDeserializer<Message: SwiftProtobuf.Message>: FlutterEmbeddingGRPCCore.MessageDeserializer {
        public init() {}
        
        public func deserialize(_ data: Data) async throws -> Message {
            return try Message(serializedData: data)
        }
    }
    
}

/// Custom GRPCCore module - minimal interface definitions for proxying through embeddingchannel
///
/// This module provides the same interfaces as GRPCCore but all calls are proxied through
/// the embedding channel instead of direct network communication. It implements a subset
/// of GRPCCore's functionality sufficient for unary RPC calls.
public enum FlutterEmbeddingGRPCCore {
    
    // MARK: - Method Descriptor
    
    /// Method descriptor for identifying RPC methods
    public struct MethodDescriptor: Sendable, Hashable {
        public let fullyQualifiedMethod: String
        
        public init(fullyQualifiedMethod: String) {
            self.fullyQualifiedMethod = fullyQualifiedMethod
        }
        
        public init(service: ServiceDescriptor, method: String) {
            let serviceName = service.fullyQualifiedService
            self.fullyQualifiedMethod = "/\(serviceName)/\(method)"
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.fullyQualifiedMethod)
        }
        
        public static func == (lhs: MethodDescriptor, rhs: MethodDescriptor) -> Bool {
            return lhs.fullyQualifiedMethod == rhs.fullyQualifiedMethod
        }
    }
    
    // MARK: - Service Descriptor
    
    /// Service descriptor for identifying RPC services
    public struct ServiceDescriptor: Sendable {
        public let fullyQualifiedService: String
        
        public init(fullyQualifiedService: String) {
            self.fullyQualifiedService = fullyQualifiedService
        }
    }
    
    // MARK: - Client Request
    
    /// Client request wrapper
    public struct ClientRequest<Message: Sendable>: Sendable {
        public let message: Message
        public let metadata: Metadata
        
        public init(message: Message, metadata: Metadata = [:]) {
            self.message = message
            self.metadata = metadata
        }
    }
    
    // MARK: - Client Response
    
    /// Client response wrapper
    public struct ClientResponse<Message: Sendable>: Sendable {
        public let message: Message
        public let metadata: Metadata
        public let trailingMetadata: Metadata
        
        public init(message: Message, metadata: Metadata = [:], trailingMetadata: Metadata = [:]) {
            self.message = message
            self.metadata = metadata
            self.trailingMetadata = trailingMetadata
        }
    }
    
    // MARK: - Call Options
    
    /// Options for configuring RPC calls
    public struct CallOptions: Sendable {
        public static let defaults = CallOptions()
        
        public init() {}
    }
    
    // MARK: - Metadata
    
    /// Metadata dictionary type
    public typealias Metadata = [String: String]
    
    // MARK: - Client Transport
    
    /// Configuration for client transport
    public struct ClientTransportConfiguration: Sendable {
        public init() {}
    }
    
    /// Stream protocol for client transport
    /// The stream always works with Data (serialized messages)
    public protocol ClientTransportStream: Sendable {
        func execute(
            _ request: ClientRequest<Data>,
            method: MethodDescriptor,
            options: CallOptions
        ) async throws -> ClientResponse<Data>
    }
    
    /// Protocol for client transport implementations
    public protocol ClientTransport: Sendable {
        associatedtype Stream: ClientTransportStream
        
        func connect(lazy: Bool, using configuration: ClientTransportConfiguration) -> Stream
    }
    
    // MARK: - GRPC Client
    
    /// GRPC client that uses a transport to make RPC calls
    public struct GRPCClient<Transport: ClientTransport>: Sendable {
        private let transport: Transport
        private let stream: Transport.Stream
        
        public init(transport: Transport) {
            self.transport = transport
            self.stream = transport.connect(lazy: false, using: ClientTransportConfiguration())
        }
        
        /// Execute a unary RPC call
        public func unary<Request: Sendable, Response: Sendable, Result: Sendable>(
            request: ClientRequest<Request>,
            descriptor: MethodDescriptor,
            serializer: some MessageSerializer<Request>,
            deserializer: some MessageDeserializer<Response>,
            options: CallOptions,
            onResponse handleResponse: @Sendable @escaping (ClientResponse<Response>) async throws -> Result
        ) async throws -> Result {
            // Serialize request
            let requestData = try await serializer.serialize(request.message)
            
            // Create request with serialized data (as Data)
            let serializedRequest = ClientRequest<Data>(message: requestData, metadata: request.metadata)
            
            // Execute via transport stream (returns Data as message)
            let response = try await stream.execute(serializedRequest, method: descriptor, options: options)
            
            // Deserialize response from Data
            let responseMessage = try await deserializer.deserialize(response.message)
            
            // Create response wrapper
            let clientResponse = ClientResponse<Response>(
                message: responseMessage,
                metadata: response.metadata,
                trailingMetadata: response.trailingMetadata
            )
            
            // Handle response
            return try await handleResponse(clientResponse)
        }
    }
    
    // MARK: - Message Serializer
    
    /// Protocol for serializing messages
    public protocol MessageSerializer<Message>: Sendable {
        associatedtype Message: Sendable
        
        func serialize(_ message: Message) async throws -> Data
    }
    
    // MARK: - Message Deserializer
    
    /// Protocol for deserializing messages
    public protocol MessageDeserializer<Message>: Sendable {
        associatedtype Message: Sendable
        
        func deserialize(_ data: Data) async throws -> Message
    }
    
    // MARK: - Server Implementation
    
    // MARK: - Helper Types
    
    /// Protocol for contiguous bytes
    public protocol GRPCContiguousBytes: Sendable {
        func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
    }
    
    /// Async sequence wrapper for RPC messages
    public struct RPCAsyncSequence<Element: Sendable, Failure: Error>: AsyncSequence, Sendable {
        public typealias AsyncIterator = Iterator
        private let _makeAsyncIterator: @Sendable () -> AsyncIterator
        
        public init(_ makeAsyncIterator: @escaping @Sendable () -> AsyncIterator) {
            self._makeAsyncIterator = makeAsyncIterator
        }
        
        public func makeAsyncIterator() -> AsyncIterator {
            return _makeAsyncIterator()
        }
        
        public struct Iterator: AsyncIteratorProtocol {
            private let _next: @Sendable () async throws -> Element?
            
            @usableFromInline
            init(_ next: @escaping @Sendable () async throws -> Element?) {
                self._next = next
            }
            
            public func next() async throws -> Element? {
                return try await _next()
            }
        }
    }
    
    /// RPC stream wrapper
    public struct RPCStream<Inbound: AsyncSequence, Outbound: Sendable>: Sendable {
        public let inbound: Inbound
        public let outbound: Outbound
        
        public init(inbound: Inbound, outbound: Outbound) {
            self.inbound = inbound
            self.outbound = outbound
        }
    }
    
    /// RPC request part
    public enum RPCRequestPart<Bytes: GRPCContiguousBytes>: Sendable {
        case metadata(Metadata)
        case message(Bytes)
        case end
    }
    
    /// RPC response part
    public enum RPCResponsePart<Bytes: GRPCContiguousBytes>: Sendable {
        case metadata(Metadata)
        case message(Bytes)
        case end
    }
    
    /// RPC Writer protocol
    public protocol RPCWriterProtocol<Element>: Sendable {
        associatedtype Element: Sendable
        func write(_ element: Element) async throws
        func write(contentsOf elements: some Sequence<Element>) async throws
    }
    
    /// Closable RPC Writer protocol
    public protocol ClosableRPCWriterProtocol<Element>: RPCWriterProtocol {
        func finish() async
        func finish(throwing error: any Error) async
    }
    
    /// RPC Writer struct
    public struct RPCWriter<Element: Sendable>: Sendable, RPCWriterProtocol {
        private let writer: any RPCWriterProtocol<Element>
        
        public init(wrapping other: some RPCWriterProtocol<Element>) {
            self.writer = other
        }
        
        public func write(_ element: Element) async throws {
            try await self.writer.write(element)
        }
        
        public func write(contentsOf elements: some Sequence<Element>) async throws {
            try await self.writer.write(contentsOf: elements)
        }
        
        /// Closable wrapper
        public struct Closable: Sendable, ClosableRPCWriterProtocol {
            private let writer: any ClosableRPCWriterProtocol<Element>
            
            init(wrapping other: some ClosableRPCWriterProtocol<Element>) {
                self.writer = other
            }
            
            public func write(_ element: Element) async throws {
                try await self.writer.write(element)
            }
            
            public func write(contentsOf elements: some Sequence<Element>) async throws {
                try await self.writer.write(contentsOf: elements)
            }
            
            public func finish() async {
                await self.writer.finish()
            }
            
            public func finish(throwing error: any Error) async {
                await self.writer.finish(throwing: error)
            }
        }
    }
    
    /// Status code for RPC errors
    public struct Status: Sendable {
        public enum Code: Sendable, Equatable {
            case ok
            case cancelled
            case unknown
            case invalidArgument
            case deadlineExceeded
            case notFound
            case alreadyExists
            case permissionDenied
            case resourceExhausted
            case failedPrecondition
            case aborted
            case outOfRange
            case unimplemented
            case internalError
            case unavailable
            case dataLoss
            case unauthenticated
            
            public struct Wrapped: Sendable, Equatable {
                public let rawValue: UInt8
                init(rawValue: UInt8) {
                    self.rawValue = rawValue
                }
            }
            
            public var wrapped: Wrapped {
                switch self {
                case .ok: return Wrapped(rawValue: 0)
                case .cancelled: return Wrapped(rawValue: 1)
                case .unknown: return Wrapped(rawValue: 2)
                case .invalidArgument: return Wrapped(rawValue: 3)
                case .deadlineExceeded: return Wrapped(rawValue: 4)
                case .notFound: return Wrapped(rawValue: 5)
                case .alreadyExists: return Wrapped(rawValue: 6)
                case .permissionDenied: return Wrapped(rawValue: 7)
                case .resourceExhausted: return Wrapped(rawValue: 8)
                case .failedPrecondition: return Wrapped(rawValue: 9)
                case .aborted: return Wrapped(rawValue: 10)
                case .outOfRange: return Wrapped(rawValue: 11)
                case .unimplemented: return Wrapped(rawValue: 12)
                case .internalError: return Wrapped(rawValue: 13)
                case .unavailable: return Wrapped(rawValue: 14)
                case .dataLoss: return Wrapped(rawValue: 15)
                case .unauthenticated: return Wrapped(rawValue: 16)
                }
            }
        }
        
        public let code: Code
        public let message: String
        
        public init(code: Code, message: String = "") {
            self.code = code
            self.message = message
        }
    }
    
    /// RPC Cancellation Handle
    public struct RPCCancellationHandle: Sendable {
        public init() {}
    }
    
    // MARK: - Server Transport
    
    public protocol ServerTransport<Bytes>: Sendable {
        associatedtype Bytes: GRPCContiguousBytes & Sendable
        
        typealias Inbound = RPCAsyncSequence<RPCRequestPart<Bytes>, any Error>
        typealias Outbound = RPCWriter<RPCResponsePart<Bytes>>.Closable
        
        func listen(
            streamHandler: @escaping @Sendable (
                _ stream: RPCStream<Inbound, Outbound>,
                _ context: ServerContext
            ) async -> Void
        ) async throws
        
        func beginGracefulShutdown()
    }
    
    // MARK: - Server Context
    
    public struct ServerContext: Sendable {
        public protocol TransportSpecific: Sendable {}
        
        public var descriptor: MethodDescriptor
        public var remotePeer: String
        public var localPeer: String
        public var transportSpecific: (any TransportSpecific)?
        public var cancellation: RPCCancellationHandle
        
        public init(
            descriptor: MethodDescriptor,
            remotePeer: String = "in-process:0",
            localPeer: String = "in-process:0",
            cancellation: RPCCancellationHandle = RPCCancellationHandle()
        ) {
            self.descriptor = descriptor
            self.remotePeer = remotePeer
            self.localPeer = localPeer
            self.transportSpecific = nil
            self.cancellation = cancellation
        }
    }
    
    // MARK: - Server Request/Response
    
    public struct ServerRequest<Message: Sendable>: Sendable {
        public var metadata: Metadata
        public var message: Message
        
        public init(metadata: Metadata = [:], message: Message) {
            self.metadata = metadata
            self.message = message
        }
        
        public init(stream request: StreamingServerRequest<Message>) async throws {
            var iterator = request.messages.makeAsyncIterator()
            
            guard let message = try await iterator.next() else {
                throw RPCError(
                    code: .invalidArgument,
                    message: "ServerRequest requires exactly one message, but the stream was empty."
                )
            }
            
            guard try await iterator.next() == nil else {
                throw RPCError(
                    code: .invalidArgument,
                    message: "ServerRequest requires exactly one message, but received multiple messages."
                )
            }
            
            self = ServerRequest(metadata: request.metadata, message: message)
        }
    }
    
    public struct StreamingServerRequest<Message: Sendable>: Sendable {
        public var metadata: Metadata
        public var messages: RPCAsyncSequence<Message, any Error>
        
        public init(metadata: Metadata = [:], messages: RPCAsyncSequence<Message, any Error>) {
            self.metadata = metadata
            self.messages = messages
        }
    }
    
    public struct ServerResponse<Message: Sendable>: Sendable {
        public struct Contents: Sendable {
            public var metadata: Metadata
            public var message: Message
            public var trailingMetadata: Metadata
            
            public init(
                message: Message,
                metadata: Metadata = [:],
                trailingMetadata: Metadata = [:]
            ) {
                self.metadata = metadata
                self.message = message
                self.trailingMetadata = trailingMetadata
            }
        }
        
        public var accepted: Result<Contents, RPCError>
        
        public init(message: Message, metadata: Metadata = [:], trailingMetadata: Metadata = [:]) {
            let contents = Contents(
                message: message,
                metadata: metadata,
                trailingMetadata: trailingMetadata
            )
            self.accepted = .success(contents)
        }
        
        public init(accepted: Result<Contents, RPCError>) {
            self.accepted = accepted
        }
    }
    
    public struct StreamingServerResponse<Message: Sendable>: Sendable {
        public struct Contents: Sendable {
            public var metadata: Metadata
            public var producer: @Sendable (RPCWriter<Message>) async throws -> Metadata
            
            public init(
                metadata: Metadata = [:],
                producer: @escaping @Sendable (RPCWriter<Message>) async throws -> Metadata
            ) {
                self.metadata = metadata
                self.producer = producer
            }
        }
        
        public var accepted: Result<Contents, RPCError>
        
        public init(accepted: Result<Contents, RPCError>) {
            self.accepted = accepted
        }
        
        public init(single response: ServerResponse<Message>) {
            switch response.accepted {
            case .success(let contents):
                let contents = Contents(metadata: contents.metadata) { writer in
                    try await writer.write(contents.message)
                    return contents.trailingMetadata
                }
                self.accepted = .success(contents)
            case .failure(let error):
                self.accepted = .failure(error)
            }
        }
    }
    
    // MARK: - RPC Error
    
    public struct RPCError: Sendable, Hashable, Error {
        public struct Code: Hashable, Sendable, CustomStringConvertible {
            public var rawValue: Int { Int(self.wrapped.rawValue) }
            
            internal var wrapped: Status.Code.Wrapped
            private init(code: Status.Code.Wrapped) {
                self.wrapped = code
            }
            
            public init?(_ code: Status.Code) {
                if code == .ok {
                    return nil
                } else {
                    self.wrapped = code.wrapped
                }
            }
            
            public var description: String {
                String(describing: self.wrapped)
            }
            
            public func hash(into hasher: inout Hasher) {
                hasher.combine(self.wrapped.rawValue)
            }
            
            public static func == (lhs: Code, rhs: Code) -> Bool {
                return lhs.wrapped.rawValue == rhs.wrapped.rawValue
            }
            
            public static let cancelled = Code(code: Status.Code.cancelled.wrapped)
            public static let unknown = Code(code: Status.Code.unknown.wrapped)
            public static let invalidArgument = Code(code: Status.Code.invalidArgument.wrapped)
            public static let deadlineExceeded = Code(code: Status.Code.deadlineExceeded.wrapped)
            public static let notFound = Code(code: Status.Code.notFound.wrapped)
            public static let alreadyExists = Code(code: Status.Code.alreadyExists.wrapped)
            public static let permissionDenied = Code(code: Status.Code.permissionDenied.wrapped)
            public static let resourceExhausted = Code(code: Status.Code.resourceExhausted.wrapped)
            public static let failedPrecondition = Code(code: Status.Code.failedPrecondition.wrapped)
            public static let aborted = Code(code: Status.Code.aborted.wrapped)
            public static let outOfRange = Code(code: Status.Code.outOfRange.wrapped)
            public static let unimplemented = Code(code: Status.Code.unimplemented.wrapped)
            public static let internalError = Code(code: Status.Code.internalError.wrapped)
            public static let unavailable = Code(code: Status.Code.unavailable.wrapped)
            public static let dataLoss = Code(code: Status.Code.dataLoss.wrapped)
            public static let unauthenticated = Code(code: Status.Code.unauthenticated.wrapped)
        }
        
        public var code: Code
        public var message: String
        public var metadata: Metadata
        public var cause: (any Error)?
        
        public init(
            code: Code,
            message: String,
            metadata: Metadata = [:],
            cause: (any Error)? = nil
        ) {
            if let rpcErrorCause = cause as? RPCError {
                self = .init(code: code, message: message, metadata: metadata, cause: rpcErrorCause)
            } else {
                self.code = code
                self.message = message
                self.metadata = metadata
                self.cause = cause
            }
        }
        
        public init(
            code: Code,
            message: String,
            metadata: Metadata = [:],
            cause: RPCError
        ) {
            if cause.code == code {
                self.code = code
                self.message = message + " \(cause.message)"
                var mergedMetadata = metadata
                for (key, value) in cause.metadata {
                    mergedMetadata[key] = value
                }
                self.metadata = mergedMetadata
                self.cause = cause.cause
            } else {
                self.code = code
                self.message = message
                self.metadata = metadata
                self.cause = cause
            }
        }
        
        public init?(status: Status, metadata: Metadata = [:]) {
            guard let code = Code(status.code) else { return nil }
            self.init(code: code, message: status.message, metadata: metadata)
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(self.code)
            hasher.combine(self.message)
            hasher.combine(self.metadata)
        }
        
        public static func == (lhs: RPCError, rhs: RPCError) -> Bool {
            return lhs.code == rhs.code && lhs.message == rhs.message && lhs.metadata == rhs.metadata
        }
    }
    
    // MARK: - Server Interceptor (simplified)
    
    public protocol ServerInterceptor: Sendable {}
    
    public struct ConditionalInterceptor: Sendable {
        public let interceptor: any ServerInterceptor
        private let _applies: (MethodDescriptor) -> Bool
        
        public init(interceptor: any ServerInterceptor, applies: @escaping (MethodDescriptor) -> Bool) {
            self.interceptor = interceptor
            self._applies = applies
        }
        
        public func applies(to descriptor: MethodDescriptor) -> Bool {
            return _applies(descriptor)
        }
    }
    
    // MARK: - Server RPC Executor (simplified stub)
    
    /// Internal executor for server RPC calls
    ///
    /// Note: This is a simplified stub implementation. In a full gRPC implementation,
    /// this would handle streaming, message framing, and protocol-level details.
    /// For our use case with the embedding channel, we use unary calls and handle
    /// message serialization/deserialization at a higher level, so this executor
    /// is not actively used.
    @usableFromInline
    internal enum ServerRPCExecutor {
        /// Executes a server RPC handler
        ///
        /// This method is intentionally minimal as the embedding channel proxy
        /// handles execution differently. The actual RPC handling is done through
        /// the type-erased handlers registered in RPCRouter.
        ///
        /// - Parameters:
        ///   - context: Server context for the RPC
        ///   - stream: Bidirectional stream for request/response
        ///   - deserializer: Deserializer for input messages
        ///   - serializer: Serializer for output messages
        ///   - interceptors: Interceptors to apply (currently unused in stub)
        ///   - handler: The handler function to execute
        @usableFromInline
        static func execute<Input, Output, Bytes: GRPCContiguousBytes>(
            context: ServerContext,
            stream: RPCStream<
            RPCAsyncSequence<RPCRequestPart<Bytes>, any Error>,
            RPCWriter<RPCResponsePart<Bytes>>.Closable
            >,
            deserializer: some MessageDeserializer<Input>,
            serializer: some MessageSerializer<Output>,
            interceptors: [any ServerInterceptor],
            handler: @Sendable @escaping (
                StreamingServerRequest<Input>,
                ServerContext
            ) async throws -> StreamingServerResponse<Output>
        ) async {
            // Simplified stub implementation - no operation performed
            // The embedding channel proxy uses a different execution path through
            // the type-erased handlers in RPCRouter's registration callback
        }
    }
    
    // MARK: - RPC Router
    
    /// Protocol for RPC services that can be registered with an RPC router
    public protocol RegistrableRPCService: Sendable {
        /// Registers all methods of this service with the provided router
        /// - Parameter router: The router to register methods with
        func registerMethods<Transport: ServerTransport>(with router: inout RPCRouter<Transport>)
    }
    
    // Helper class for capturing messages from a writer
    // Note: This class is not Sendable and should only be used locally within a single async context.
    // It is never passed across concurrency boundaries.
    @usableFromInline
    internal class MessageCapturingWriter<Element>: RPCWriterProtocol {
        @usableFromInline
        var capturedMessage: Element?
        
        @usableFromInline
        init() {
            self.capturedMessage = nil
        }
        
        @usableFromInline
        func write(_ element: Element) async throws {
            // Capture only the first message
            if capturedMessage == nil {
                capturedMessage = element
            }
        }
        
        @usableFromInline
        func write(contentsOf elements: some Sequence<Element>) async throws {
            // Capture only the first message
            for element in elements {
                if capturedMessage == nil {
                    capturedMessage = element
                    break
                }
            }
        }
    }
    
    /// RPC router for handling incoming RPC requests
    ///
    /// The router maintains a registry of RPC methods and their handlers.
    /// It supports registering handlers for individual methods and interceptors for cross-cutting concerns.
    ///
    /// Example:
    /// ```swift
    /// var router = RPCRouter<MyTransport>()
    /// router.registerHandler(
    ///     forMethod: myMethodDescriptor,
    ///     deserializer: myDeserializer,
    ///     serializer: mySerializer,
    ///     handler: { request, context in
    ///         // Handle request...
    ///     }
    /// )
    /// ```
    public struct RPCRouter<Transport: ServerTransport>: Sendable {
        @usableFromInline
        struct RPCHandler: Sendable {
            @usableFromInline
            var _fn: @Sendable (
                _ stream: RPCStream<
                RPCAsyncSequence<RPCRequestPart<Transport.Bytes>, any Error>,
                RPCWriter<RPCResponsePart<Transport.Bytes>>.Closable
                >,
                _ context: ServerContext,
                _ interceptors: [any ServerInterceptor]
            ) async -> Void
            
            @usableFromInline
            init(_fn: @escaping @Sendable (
                _ stream: RPCStream<
                RPCAsyncSequence<RPCRequestPart<Transport.Bytes>, any Error>,
                RPCWriter<RPCResponsePart<Transport.Bytes>>.Closable
                >,
                _ context: ServerContext,
                _ interceptors: [any ServerInterceptor]
            ) async -> Void) {
                self._fn = _fn
            }
            
            @inlinable
            static func create<Input, Output>(
                method: MethodDescriptor,
                deserializer: some MessageDeserializer<Input>,
                serializer: some MessageSerializer<Output>,
                handler: @Sendable @escaping (
                    _ request: StreamingServerRequest<Input>,
                    _ context: ServerContext
                ) async throws -> StreamingServerResponse<Output>
            ) -> RPCHandler {
                let fn: @Sendable (
                    RPCStream<
                    RPCAsyncSequence<RPCRequestPart<Transport.Bytes>, any Error>,
                    RPCWriter<RPCResponsePart<Transport.Bytes>>.Closable
                    >,
                    ServerContext,
                    [any ServerInterceptor]
                ) async -> Void = { stream, context, interceptors in
                    await ServerRPCExecutor.execute(
                        context: context,
                        stream: stream,
                        deserializer: deserializer,
                        serializer: serializer,
                        interceptors: interceptors,
                        handler: handler
                    )
                }
                return RPCHandler(_fn: fn)
            }
            
            @inlinable
            func handle(
                stream: RPCStream<
                RPCAsyncSequence<RPCRequestPart<Transport.Bytes>, any Error>,
                RPCWriter<RPCResponsePart<Transport.Bytes>>.Closable
                >,
                context: ServerContext,
                interceptors: [any ServerInterceptor]
            ) async {
                await self._fn(stream, context, interceptors)
            }
        }
        
        @usableFromInline
        var handlers: [MethodDescriptor: (handler: RPCHandler, interceptors: [any ServerInterceptor])]
        
        // Callback to capture handler registrations
        @usableFromInline
        var registrationCallback: ((MethodDescriptor, any MessageDeserializerProtocol, any MessageSerializerProtocol, @Sendable @escaping (Any, ServerContext) async throws -> Any) -> Void)?
        
        /// Creates a new RPC router
        /// - Parameter registrationCallback: Optional callback invoked when handlers are registered
        public init(registrationCallback: ((MethodDescriptor, any MessageDeserializerProtocol, any MessageSerializerProtocol, @Sendable @escaping (Any, ServerContext) async throws -> Any) -> Void)? = nil) {
            self.handlers = [:]
            self.registrationCallback = registrationCallback
        }
        
        /// Sets the registration callback for this router
        /// - Parameter callback: The callback to invoke when handlers are registered
        public mutating func setRegistrationCallback(_ callback: @escaping (MethodDescriptor, any MessageDeserializerProtocol, any MessageSerializerProtocol, @Sendable @escaping (Any, ServerContext) async throws -> Any) -> Void) {
            self.registrationCallback = callback
        }
        
        public var methods: [MethodDescriptor] {
            Array(self.handlers.keys)
        }
        
        public var count: Int {
            self.handlers.count
        }
        
        public func hasHandler(forMethod descriptor: MethodDescriptor) -> Bool {
            return self.handlers.keys.contains(descriptor)
        }
        
        /// Registers a handler for a specific RPC method
        ///
        /// - Parameters:
        ///   - descriptor: The method descriptor identifying the RPC method
        ///   - deserializer: Deserializer for the request message type
        ///   - serializer: Serializer for the response message type
        ///   - handler: The handler function to process requests
        @inlinable
        public mutating func registerHandler<Input: Sendable, Output: Sendable>(
            forMethod descriptor: MethodDescriptor,
            deserializer: some MessageDeserializer<Input>,
            serializer: some MessageSerializer<Output>,
            handler: @Sendable @escaping (
                _ request: StreamingServerRequest<Input>,
                _ context: ServerContext
            ) async throws -> StreamingServerResponse<Output>
        ) {
            let rpcHandler = RPCHandler.create(
                method: descriptor,
                deserializer: deserializer,
                serializer: serializer,
                handler: handler
            )
            self.handlers[descriptor] = (rpcHandler, [])
            
            // Call registration callback if set
            if let callback = registrationCallback {
                // Create type-erased wrappers
                let anyDeserializer = AnyMessageDeserializerWrapper(deserializer)
                let anySerializer = AnyMessageSerializerWrapper(serializer)
                
                // Create type-erased handler
                let anyHandler: @Sendable (Any, ServerContext) async throws -> Any = { request, context in
                    // Convert request to Input type
                    guard let inputMessage = request as? Input else {
                        throw RPCError(
                            code: .internalError,
                            message: "Type mismatch in handler: expected \(Input.self), got \(type(of: request))"
                        )
                    }
                    
                    // Create streaming request
                    let messages = RPCAsyncSequence<Input, any Error> {
                        var hasReturned = false
                        return RPCAsyncSequence.Iterator {
                            guard !hasReturned else { return nil }
                            hasReturned = true
                            return inputMessage
                        }
                    }
                    let streamingRequest = StreamingServerRequest<Input>(metadata: [:], messages: messages)
                    
                    // Call handler
                    let response = try await handler(streamingRequest, context)
                    
                    // Extract message from response
                    switch response.accepted {
                    case .success(let contents):
                        var extractedMessage: Output?
                        var extractionError: Error?
                        
                        // Create a writer that captures the first message
                        let capturingWriter = MessageCapturingWriter<Output>()
                        let writer: RPCWriter<Output> = RPCWriter(wrapping: capturingWriter)
                        
                        do {
                            _ = try await contents.producer(writer)
                            extractedMessage = capturingWriter.capturedMessage
                        } catch {
                            extractionError = error
                        }
                        
                        if let error = extractionError {
                            throw error
                        }
                        
                        guard let message = extractedMessage else {
                            throw RPCError(
                                code: .internalError,
                                message: "Response producer did not write any messages for method \(descriptor.fullyQualifiedMethod)"
                            )
                        }
                        
                        return message
                    case .failure(let error):
                        throw error
                    }
                }
                
                callback(descriptor, anyDeserializer, anySerializer, anyHandler)
            }
        }
        
        /// Removes a handler for a specific RPC method
        /// - Parameter descriptor: The method descriptor identifying the RPC method to remove
        /// - Returns: `true` if a handler was removed, `false` if no handler existed
        @discardableResult
        public mutating func removeHandler(forMethod descriptor: MethodDescriptor) -> Bool {
            return self.handlers.removeValue(forKey: descriptor) != nil
        }
        
        /// Registers interceptors to be applied to matching methods
        /// - Parameter pipeline: Array of conditional interceptors to register
        @inlinable
        public mutating func registerInterceptors(
            pipeline: [ConditionalInterceptor]
        ) {
            for descriptor in self.handlers.keys {
                let applicableOperations = pipeline.filter { $0.applies(to: descriptor) }
                if !applicableOperations.isEmpty {
                    self.handlers[descriptor]?.interceptors = applicableOperations.map { $0.interceptor }
                }
            }
        }
    }
    
    // Helper protocols for type erasure
    
    /// Protocol for deserializing messages from Data in a type-erased manner
    public protocol MessageDeserializerProtocol {
        /// Deserializes data into a message of any type
        /// - Parameter data: The serialized data
        /// - Returns: The deserialized message
        /// - Throws: An error if deserialization fails
        func deserialize(_ data: Data) async throws -> Any
    }
    
    /// Protocol for serializing messages to Data in a type-erased manner
    public protocol MessageSerializerProtocol {
        /// Serializes a message of any type to data
        /// - Parameter message: The message to serialize
        /// - Returns: The serialized data
        /// - Throws: An error if serialization fails
        func serialize(_ message: Any) async throws -> Data
    }
    
    /// Type-erased wrapper for message deserializers
    public struct AnyMessageDeserializerWrapper: MessageDeserializerProtocol {
        private let _deserialize: (Data) async throws -> Any
        
        /// Creates a type-erased wrapper around a typed deserializer
        /// - Parameter deserializer: The typed deserializer to wrap
        public init<Input>(_ deserializer: some MessageDeserializer<Input>) {
            self._deserialize = { data in
                try await deserializer.deserialize(data)
            }
        }
        
        public func deserialize(_ data: Data) async throws -> Any {
            return try await _deserialize(data)
        }
    }
    
    /// Type-erased wrapper for message serializers
    public struct AnyMessageSerializerWrapper: MessageSerializerProtocol {
        private let _serialize: (Any) async throws -> Data
        
        /// Creates a type-erased wrapper around a typed serializer
        /// - Parameter serializer: The typed serializer to wrap
        public init<Output>(_ serializer: some MessageSerializer<Output>) {
            self._serialize = { message in
                guard let typedMessage = message as? Output else {
                    throw RPCError(
                        code: .internalError,
                        message: "Invalid response type for serialization: expected \(Output.self), got \(type(of: message))"
                    )
                }
                return try await serializer.serialize(typedMessage)
            }
        }
        
        public func serialize(_ message: Any) async throws -> Data {
            return try await _serialize(message)
        }
    }
}

// Extension for Data to conform to GRPCContiguousBytes
extension Data: FlutterEmbeddingGRPCCore.GRPCContiguousBytes {}

// Extension for RPCWriterProtocol
extension FlutterEmbeddingGRPCCore.RPCWriterProtocol {
    public func write<Elements: AsyncSequence>(
        contentsOf elements: Elements
    ) async throws where Elements.Element == Element {
        for try await element in elements {
            try await self.write(element)
        }
    }
}
