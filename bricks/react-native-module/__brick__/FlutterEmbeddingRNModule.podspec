require "json"

Pod::Spec.new do |s|
  s.name         = "FlutterEmbeddingRNModule"
  s.version      = '{{flutterModuleVersion}}'
  s.summary      = 'React Native module for embedding Flutter - {{moduleName}}'
  s.description  = <<-DESC
                  React Native module for embedding Flutter applications
                  DESC
  s.homepage     = 'https://github.com/krispypen/flutter_embedding'
  s.license      = 'MIT'
  s.source       = { :git => 'https://github.com/krispypen/flutter_embedding.git', :tag => "{{flutterModuleVersion}}" }
  s.authors      = { 'Flutter Embedding' => 'flutter-embedding@example.com' }
  s.platforms    = { :ios => "12.0" }
  s.swift_version = '5.0'
  s.requires_arc = true

  s.source_files = "ios-rn/*.{h,c,cc,cpp,m,mm,swift}"
  s.public_header_files = "ios-rn/FlutterEmbeddingRNModule.h"
  s.static_framework = true
  s.preserve_paths = "**/*.xcframework"

  s.dependency "React-Core"
  s.dependency 'Flutter'
  s.dependency 'FlutterEmbeddingModule-Debug'
  s.dependency 'FlutterEmbeddingModule-Release'

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '$(inherited) -framework Flutter -framework FlutterPluginRegistrant -framework flutter_embedding'
  }
end