package {{flutterEmbeddingPackageName}}

import io.grpc.*
import {{flutterEmbeddingPackageName}}.CompletionHandler

/**
 * Custom gRPC Channel implementation that converts requests to binary format,
 * sends them via invokeHandover with request bytes in data map, and converts the response bytes back to the response type.
 */
class FlutterGRPCChannel(
    private val flutterModuleEmbedding: {{flutterEmbeddingName}},
    private val authority: String = "flutter-embedding"
) : Channel() {

    override fun <RequestT : Any, ResponseT : Any> newCall(
        methodDescriptor: MethodDescriptor<RequestT, ResponseT>,
        callOptions: CallOptions
    ): ClientCall<RequestT, ResponseT> {
        return FlutterGRPCClientCall(methodDescriptor, flutterModuleEmbedding)
    }

    override fun authority(): String {
        return authority
    }

    /**
     * Custom ClientCall implementation that handles serialization and deserialization
     */
    private class FlutterGRPCClientCall<RequestT, ResponseT>(
        private val methodDescriptor: MethodDescriptor<RequestT, ResponseT>,
        private val flutterModuleEmbedding: {{flutterEmbeddingName}}
    ) : ClientCall<RequestT, ResponseT>() {

        private var listener: Listener<ResponseT>? = null
        private var requestHeaders: Metadata? = null
        private var responseHeaders: Metadata = Metadata()

        @Throws(Exception::class)
        override fun start(
            responseListener: Listener<ResponseT>,
            headers: Metadata
        ) {
            this.listener = responseListener
            this.requestHeaders = headers
        }

        override fun request(numMessages: Int) {
            // Not applicable for unary calls
        }

        override fun cancel(message: String?, cause: Throwable?) {
            // Cancel the operation if needed
            listener?.onClose(
                Status.CANCELLED.withDescription(message ?: "Cancelled")
                    .withCause(cause),
                responseHeaders
            )
        }

        override fun halfClose() {
            // Not applicable for unary calls - request is sent immediately
        }

        override fun sendMessage(message: RequestT) {
            try {
                // Serialize the request to bytes using the method descriptor's marshaller
                val requestMarshaller = methodDescriptor.requestMarshaller
                val requestInputStream = requestMarshaller.stream(message)
                val requestBytes = requestInputStream.readAllBytes()

                // Get the full method name to use as event name
                val serviceName = methodDescriptor.serviceName!!
                val methodName = methodDescriptor.bareMethodName!!

                // Prepare data map with request bytes
                val data = mapOf("request" to requestBytes, "service" to serviceName, "method" to methodName)

                // Invoke the handler and wait for response
                val completionHandler = object : CompletionHandler<Any?> {
                    override fun onSuccess(result: Any?) {
                        if (result != null) {
                            try {
                                // Extract response bytes from the result
                                val responseBytes = when (result) {
                                    is ByteArray -> result
                                    is List<*> -> {
                                        // Convert List<Byte> or List<Int> to ByteArray if needed
                                        result.mapNotNull { 
                                            when (it) {
                                                is Byte -> it
                                                is Int -> it.toByte()
                                                else -> null
                                            }
                                        }.toByteArray()
                                    }
                                    else -> {
                                        // Try to convert to ByteArray if possible
                                        null
                                    }
                                }

                                if (responseBytes != null) {
                                    // Deserialize the response bytes back to ResponseT using the marshaller
                                    val responseMarshaller = methodDescriptor.responseMarshaller
                                    val responseInputStream = java.io.ByteArrayInputStream(responseBytes)
                                    val response = responseMarshaller.parse(responseInputStream)

                                    // Notify the listener
                                    listener?.onHeaders(responseHeaders)
                                    listener?.onMessage(response)
                                    listener?.onClose(Status.OK, responseHeaders)
                                } else {
                                    listener?.onClose(
                                        Status.INTERNAL.withDescription("Response format not supported: ${result::class.java}"),
                                        responseHeaders
                                    )
                                }
                            } catch (e: Exception) {
                                listener?.onClose(
                                    Status.INTERNAL.withDescription("Failed to deserialize response: ${e.message}")
                                        .withCause(e),
                                    responseHeaders
                                )
                            }
                        } else {
                                listener?.onClose(
                                    Status.INTERNAL.withDescription("No response received"),
                                    responseHeaders
                                )
                        }
                    }

                    override fun onFailure(e: Exception) {
                        listener?.onClose(
                            Status.INTERNAL.withDescription(e.message ?: "Unknown error")
                                .withCause(e),
                            responseHeaders
                        )
                    }
                }
                
                flutterModuleEmbedding.invokeHandover(serviceName, data, completionHandler)
            } catch (e: Exception) {
                listener?.onClose(
                    Status.INTERNAL.withDescription("Failed to serialize request: ${e.message}")
                        .withCause(e),
                    responseHeaders
                )
            }
        }

        override fun isReady(): Boolean {
            return true
        }

        override fun setMessageCompression(enable: Boolean) {
            // Compression not supported in this implementation
        }
    }
}

