//
//  ContentView.swift
//  SpeechRecognition
//
//  Created by Dariusz Zabrzeński on 11/11/2023.
//

import SwiftUI
import Speech
import AVFoundation

public class ContentViewModel: NSObject, SFSpeechRecognizerDelegate, ObservableObject{
    @Published var recordButtonLabel = ""
    @Published var recordButtonEnabled = false
    @Published var alertVisible = false
    @Published var alertText = ""
    @Published var backgroundColor: Color = .white
    @Published var lastText: String = ""
    
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
            if available {
                self.recordButtonLabel = "Start recording"
                self.recordButtonEnabled = true
            } else {
                self.recordButtonLabel = "Recognition not available"
                self.recordButtonEnabled = false
            }
        }
    public func markButtonActive() {
        self.recordButtonLabel = "Start recording"
        self.recordButtonEnabled = true
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    private let audioEngine = AVAudioEngine()
    private var lmConfiguration: SFSpeechLanguageModel.Configuration {
        let outputDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dynamicLanguageModel = outputDir.appendingPathComponent("LM")
        let dynamicVocabulary = outputDir.appendingPathComponent("Vocab")
        return SFSpeechLanguageModel.Configuration(languageModel: dynamicLanguageModel, vocabulary: dynamicVocabulary)
    }
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    
    var body: some View {
        VStack {
            Text(viewModel.lastText)
            Button(action: {
                audioEngine.isRunning ? stopRecording() : initiateRecording()
            }, label: {
                Text(viewModel.recordButtonLabel)
            })
            .disabled(!viewModel.recordButtonEnabled)
        }
        .padding()
        .onAppear(){
            self.requestAuthorization()
            
        }
        .background(viewModel.backgroundColor)
        .alert(viewModel.alertText, isPresented: $viewModel.alertVisible, actions: {
                
            }
        )
    }
    
    init(viewModel: ContentViewModel, recognitionRequest: SFSpeechAudioBufferRecognitionRequest? = nil, recognitionTask: SFSpeechRecognitionTask? = nil) {
        self.viewModel = viewModel
        self.recognitionRequest = recognitionRequest
        self.recognitionTask = recognitionTask
    }
    
    private func initiateRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.showAlert("Microphone is not available")
            return
        }
        let inputNode = audioEngine.inputNode
        
        setupSpeechRecognition()
        
        recognitionTask = viewModel.speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
            var isFinal = false
            
            if let result = result {
                
                
                isFinal = result.isFinal
                
                if (result.bestTranscription.segments.count == 4 && result.bestTranscription.formattedString.contains("Set background to")){
                    switch result.bestTranscription.segments.last?.substring{
                    case "green":
                        viewModel.backgroundColor = .green
                    case "blue":
                        viewModel.backgroundColor = .blue
                    case "red":
                        viewModel.backgroundColor = .red
                    default:
                        print("Color not recognized")
                    }
                }
                if (result.bestTranscription.segments.count == 3 && result.bestTranscription.formattedString.contains("I am")){
                    switch result.bestTranscription.segments.last?.substring{
                    case "sea":
                        viewModel.backgroundColor = .blue
                    case "fire":
                        viewModel.backgroundColor = .orange
                    default:
                        print("Be whoever you want to be")
                    }
                }
                viewModel.lastText = result.bestTranscription.formattedString
            }
            
            if error != nil{
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
        }


        audioEngine.prepare()
        do {
            try audioEngine.start()
            self.viewModel.recordButtonLabel = "Recording. Tap to stop"
        } catch {
            print("Something's not right")
        }
        
    }
    
    private func stopRecording() {
        self.audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        self.recognitionRequest = nil
        self.recognitionTask = nil
        
        self.viewModel.recordButtonEnabled = true
        self.viewModel.recordButtonLabel = "Start recording"
    }

    
    private func setupSpeechRecognition() {
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = self.recognitionRequest else {
            
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true
        recognitionRequest.customizedLanguageModel = self.lmConfiguration
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.setUpTrainingData()
                case .denied:
                    self.viewModel.recordButtonEnabled = false
                    self.viewModel.recordButtonLabel = "Speech permission denied"
                    
                    
                case .restricted:
                    self.viewModel.recordButtonEnabled = false
                    self.viewModel.recordButtonLabel = "Speech is restricted"
                    
                    
                default:
                    self.viewModel.recordButtonEnabled = false
                    self.viewModel.recordButtonLabel = "Unknown authorization state"
                }
            }
        }
    }
    
    private func setUpTrainingData() {
        Task.detached {
            do {
                let assetUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "MLData", ofType: "bin")!)
                try await SFSpeechLanguageModel.prepareCustomLanguageModel(for: assetUrl,
                                                                           clientIdentifier: "site.modista.speechRecognizer.SpeechRecognition",
                                                                           configuration: self.lmConfiguration)
                await self.viewModel.markButtonActive()
                
            } catch {
                fatalError("Cannot prepare custom LM: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(_ title: String){
        self.viewModel.alertText = title
        self.viewModel.alertVisible = true
    }
    
}


