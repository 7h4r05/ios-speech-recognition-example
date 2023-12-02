//
//  SpeechRecognitionApp.swift
//  SpeechRecognition
//
//  Created by Dariusz Zabrzeński on 11/11/2023.
//

import SwiftUI

@main
struct SpeechRecognitionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel())
        }
    }
}
