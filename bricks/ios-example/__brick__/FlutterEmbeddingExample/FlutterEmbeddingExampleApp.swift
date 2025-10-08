//
//  FlutterEmbeddingExampleApp.swift
//  FlutterEmbeddingExample
//
//  Created by Kris Pypen on 29/09/2025.
//

import SwiftUI
import UIKit

struct ContentViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ContentView {
        return ContentView()
    }
    
    func updateUIViewController(_ uiViewController: ContentView, context: Context) {
        // No updates needed
    }
}

@main
struct FlutterEmbeddingExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentViewWrapper()
        }
    }
}
