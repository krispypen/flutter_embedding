package {{flutterEmbeddingPackageName}}

import android.content.Context
import androidx.fragment.app.FragmentActivity
import be.krispypen.plugins.flutter_embedding.FlutterEmbedding
import be.krispypen.plugins.flutter_embedding.FlutterEmbeddingFlutterFragment
import be.krispypen.plugins.flutter_embedding.HandoverResponderInterface
import be.krispypen.plugins.flutter_embedding.CompletionHandler
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
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

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
                completion: CompletionHandler<in Any>?
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

                                    // 8. Wait for the response to arrive in our fakeServerCall
                                    val response: Any? = responseFuture.get(10, TimeUnit.SECONDS)

                                    // 9. Serialize the response
                                    var responseData: ByteArray = byteArrayOf()
                                    if (response != null) {
                                        // Use the method's own marshaller to serialize
                                        @Suppress("UNCHECKED_CAST")
                                        val responseStream: InputStream =
                                            (method.methodDescriptor.responseMarshaller as MethodDescriptor.Marshaller<Any>).stream(response)
                                        responseData = responseStream.readBytes()
                                    }

                                    println("Successfully called '$serviceMethod'. Response size: ${responseData.size} bytes")
                                    
                                    completion?.onSuccess(responseData)

                                    break

                                } catch (e: Exception) {
                                    // Handle timeouts or gRPC errors
                                    if (errorFuture.isDone) {
                                        val status = errorFuture.getNow(null)
                                        println("Error: gRPC service implementation failed with status: ${status.code} - ${status.description}")
                                    } else if (e is TimeoutException) {
                                        println("Error: gRPC method call timed out")
                                    } else {
                                        println("Error during dynamic call invocation: ${e.message}")
                                        e.printStackTrace()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        FlutterEmbedding.instance().startEngine(context, startConfig, handoverResponder, completion)
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
        FlutterEmbedding.instance().invokeHandover(eventName, data, completion)
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