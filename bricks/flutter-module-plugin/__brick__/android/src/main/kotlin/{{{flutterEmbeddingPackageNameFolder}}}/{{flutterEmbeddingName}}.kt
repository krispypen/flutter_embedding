package {{flutterEmbeddingPackageName}}

import android.content.Context
import androidx.fragment.app.FragmentActivity
import be.krispypen.plugins.flutter_embedding.FlutterEmbedding
import be.krispypen.plugins.flutter_embedding.FlutterEmbeddingFlutterFragment
import be.krispypen.plugins.flutter_embedding.HandoverResponderInterface

/**
 * Completion handler interface for async operations.
 * This is a local interface to avoid requiring implementors to import from flutter_embedding.
 */
interface CompletionHandler<T> {
    fun onSuccess(data: T?)
    fun onFailure(e: Exception)
}
{{#handoversToHostServices}}
import {{type}}Grpc
{{/handoversToHostServices}}{{#handoversToFlutterServices}}import {{type}}Grpc.{{type}}FutureStub
import {{type}}Grpc
{{/handoversToFlutterServices}}
import HandoversToFlutterServiceOuterClass.{{startParamsMessage}}
import android.R
import io.flutter.embedding.engine.FlutterEngine
import io.grpc.Attributes
import io.grpc.BindableService
import io.grpc.MethodDescriptor
import io.grpc.ServerCall
import io.grpc.ServerCallHandler
import io.grpc.Status
import io.grpc.stub.StreamObserver
import java.io.ByteArrayInputStream
import java.io.InputStream
import java.util.concurrent.CompletableFuture

class {{flutterEmbeddingName}} {

    companion object LazyHolder {
        val INSTANCE = {{flutterEmbeddingName}}()
        
        fun instance(): {{flutterEmbeddingName}} {
            return INSTANCE
        }
    }

    fun startEngine(
        context: Context,
        startParams: {{startParamsMessage}},
        {{#handoversToHostServices}}
        {{name}}: {{type}}Grpc.{{type}}ImplBase,
        {{/handoversToHostServices}}
        completion: CompletionHandler<Boolean>?
    ) {
        //startConfig is a map with one key "startParams" and one value which is the startParams serialized to a int array
        val startConfig = "{\"startParams\":" +  startParams.toByteArray().map { it.toInt() }.toString() + "}"
        var handoverResponder: HandoverResponderInterface = object : HandoverResponderInterface {
            override fun invokeHandover(
                name: String,
                data: Map<String?, Any?>,
                completion: be.krispypen.plugins.flutter_embedding.CompletionHandler<in Any>?
            ) {
                val serviceName = name
                val serviceMethod = data["method"] as String
                val serviceData: ByteArray? = data["data"] as ByteArray?;
                val services = listOf<BindableService>(
                    {{#handoversToHostServices}}
                    {{name}},
                    {{/handoversToHostServices}}
                )
                for (service in services) {
                    val serviceDescriptor = service.bindService().serviceDescriptor
                    if(serviceDescriptor.name == serviceName){
                        val methods = service.bindService().methods
                        for(method in methods){
                            if (method.methodDescriptor.bareMethodName == serviceMethod) {
                                // 1. Parse the request
                                val request: Any = method.methodDescriptor.parseRequest(ByteArrayInputStream(serviceData))

                                // 2. Set up futures to capture the async response or error
                                val responseFuture = CompletableFuture<Any?>()
                                val errorFuture = CompletableFuture<Status>()

                                // 3. Create a "fake" ServerCall to capture the service's output
                                val fakeServerCall = object : ServerCall<Any, Any>() {
                                    private var responseValue: Any? = null

                                    // This is called by the service's responseObserver.onNext()
                                    override fun sendMessage(message: Any?) {
                                        responseValue = message
                                    }

                                    // This is called by the service's responseObserver.onCompleted() or onError()


                                    // --- Other methods (mostly no-op for this use case) ---
                                    override fun request(numMessages: Int) { /* No-op */ }
                                    override fun sendHeaders(headers: io.grpc.Metadata?) {
                                        /* No-op */
                                    }

                                    override fun isReady(): Boolean = true
                                    override fun close(
                                        status: Status?,
                                        trailers: io.grpc.Metadata?
                                    ) {
                                        if (status!=null && status.isOk) {
                                            responseFuture.complete(responseValue)
                                        } else {
                                            // The service implementation called onError()
                                            errorFuture.complete(status)
                                        }
                                    }

                                    override fun isCancelled(): Boolean = false

                                    @Suppress("UNCHECKED_CAST")
                                    override fun getMethodDescriptor(): MethodDescriptor<Any, Any> {
                                        // This is needed internally by some gRPC logic
                                        return method.methodDescriptor as MethodDescriptor<Any, Any>
                                    }
                                    override fun getAttributes(): Attributes = Attributes.EMPTY
                                    override fun getAuthority(): String? = null
                                }

                                try {
                                    // 4. Get the handler and start the call
                                    val handler = method.serverCallHandler

                                    // 5. Start the call. This returns the listener that the service wants.
                                    // We must pass our fakeServerCall to it.
                                    @Suppress("UNCHECKED_CAST")
                                    val listener: ServerCall.Listener<Any> =
                                        (handler as ServerCallHandler<Any, Any>).startCall(fakeServerCall, io.grpc.Metadata())

                                    // 6. Simulate the client (transport) sending the request message
                                    listener.onMessage(request)

                                    // 7. Simulate the client finishing the stream (CRITICAL for unary)
                                    listener.onHalfClose()

                                    // 8. Handle response asynchronously to allow for user interaction (dialogs, etc.)
                                    val methodDesc = method.methodDescriptor
                                    responseFuture.whenComplete { response, throwable ->
                                        if (throwable != null) {
                                            println("Error: gRPC service implementation failed: ${throwable.message}")
                                            completion?.onFailure(Exception(throwable))
                                        } else {
                                            // 9. Serialize the response
                                            var responseData: ByteArray = byteArrayOf()
                                            if (response != null) {
                                                // Use the method's own marshaller to serialize
                                                @Suppress("UNCHECKED_CAST")
                                                val responseStream: InputStream =
                                                    (methodDesc.responseMarshaller as MethodDescriptor.Marshaller<Any>).stream(response)
                                                responseData = responseStream.readBytes()
                                            }

                                            println("Successfully called '$serviceMethod'. Response size: ${responseData.size} bytes")
                                            
                                            completion?.onSuccess(responseData)
                                        }
                                    }
                                    
                                    // Also handle error future
                                    errorFuture.whenComplete { status, _ ->
                                        if (status != null) {
                                            println("Error: gRPC service implementation failed with status: ${status.code} - ${status.description}")
                                            completion?.onFailure(Exception("gRPC error: ${status.code} - ${status.description}"))
                                        }
                                    }

                                    return

                                } catch (e: Exception) {
                                    println("Error during dynamic call invocation: ${e.message}")
                                    e.printStackTrace()
                                    completion?.onFailure(e)
                                }
                            }
                        }
                    }
                }
            }
        }
        val wrappedCompletion = if (completion != null) {
            object : be.krispypen.plugins.flutter_embedding.CompletionHandler<Boolean> {
                override fun onSuccess(data: Boolean?) {
                    completion.onSuccess(data)
                }
                override fun onFailure(e: Exception) {
                    completion.onFailure(e)
                }
            }
        } else null
        FlutterEmbedding.instance().startEngine(context, startConfig, handoverResponder, wrappedCompletion)
    }

    fun getEngine(): FlutterEngine? {
        return FlutterEmbedding.instance().getEngine()
    }

    fun startScreen(context: Context) {
        FlutterEmbedding.instance().startScreen(context)
    }

    fun stopEngine() {
        FlutterEmbedding.instance().stopEngine()
    }

    fun invokeHandover(
        eventName: String,
        data: Map<String, Any>,
        completion: CompletionHandler<Any?>?
    ) {
        val wrappedCompletion = if (completion != null) {
            object : be.krispypen.plugins.flutter_embedding.CompletionHandler<Any?> {
                override fun onSuccess(data: Any?) {
                    completion.onSuccess(data)
                }
                override fun onFailure(e: Exception) {
                    completion.onFailure(e)
                }
            }
        } else null
        FlutterEmbedding.instance().invokeHandover(eventName, data, wrappedCompletion)
    }

    fun getOrCreateFragment(activity: FragmentActivity): FlutterEmbeddingFlutterFragment {
        return FlutterEmbedding.instance().getOrCreateFragment(activity)
    }

    fun getOrCreateFragment(
        activity: FragmentActivity,
        containerViewId: Int?
    ): FlutterEmbeddingFlutterFragment {
        return FlutterEmbedding.instance().getOrCreateFragment(activity, containerViewId)
    }

    fun getOrCreateFragment(
        activity: FragmentActivity,
        subclass: Class<out FlutterEmbeddingFlutterFragment>
    ): FlutterEmbeddingFlutterFragment {
        return FlutterEmbedding.instance().getOrCreateFragment(activity, subclass)
    }

    fun getOrCreateFragment(
        activity: FragmentActivity,
        subclass: Class<out FlutterEmbeddingFlutterFragment>,
        containerViewId: Int?
    ): FlutterEmbeddingFlutterFragment {
        return FlutterEmbedding.instance().getOrCreateFragment(activity, subclass, containerViewId)
    }

    fun clearFragment(activity: FragmentActivity) {
        FlutterEmbedding.instance().clearFragment(activity)
    }

{{#handoversToFlutterServices}}
    fun {{name}}(): {{type}}FutureStub {
        val channel = FlutterGRPCChannel(INSTANCE)
        return {{type}}Grpc.newFutureStub(channel)
    }
{{/handoversToFlutterServices}}
}