require "json"

Pod::Spec.new do |s|
  s.name         = "FlutterEmbeddingRNModule"
  s.description  = <<-DESC
                  React native module for embedding Flutter
                  DESC
  s.source_files = "ios-rn/*.{h,c,cc,cpp,m,mm,swift}"
  # Only expose the main header as public
  s.public_header_files = "ios-rn/FlutterEmbeddingRNModule.h"
  s.static_framework = true

  s.dependency "React-Core"
  s.dependency 'Flutter'
  s.dependency 'FlutterEmbeddingModule-Debug'
  s.dependency 'FlutterEmbeddingModule-Release'


  s.pod_target_xcconfig    = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '$(inherited) -framework Flutter -framework FlutterPluginRegistrant -framework flutter_embedding'
  }
  s.preserve_paths = "**/*.xcframework"
  s.version       ='1.0.0'
  s.summary       = 'A new flutter module project.'
  s.homepage      = 'https://krispypen.be'
  s.license       = 'MIT'
  s.source        = { :git =>'https://krispypen.be', :tag => "1.0.0" }
  s.authors       = { 'Kris Pypen' => 'kris.pypen@gmail.com' }
  s.platforms     = { :ios => "11.0" }
  s.swift_version = '5.0'
  s.requires_arc  = true
end