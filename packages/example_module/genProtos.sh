dart pub global activate protoc_plugin  25.1.0
mkdir lib/protos
protoc --dart_out=grpc:lib/protos protos/host_service.proto protos/embedding_service.proto --java_out=androidtest/ --kotlin_out=androidtestkotlin/ --swift_out=swift/ --grpc-swift-2_out=swift/ --doc_out=markdown,output:./protodocs/ --js_out=jstest/ --proto_path protos
