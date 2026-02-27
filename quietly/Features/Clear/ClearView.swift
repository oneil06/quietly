//
//  ClearView.swift
//  quietly
//
//  Tab 1: Clear - Freeform brain dump screen.
//

import SwiftUI
import CoreData
import AVFoundation
import Speech
#if canImport(AppKit)
import AppKit
#endif

struct ClearView: View {
    @ObservedObject var entitlements = EntitlementsManager.shared
    
    @Binding var prefilledText: String
    @Binding var navigateToDecisions: Bool
    
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var showResults: Bool = false
    @State private var showPaywall: Bool = false
    
    // Extracted results
    @State private var extractionResult: ExtractionResult?
    @State private var currentBrainDump: BrainDump?
    
    // MARK: - UI State for Segmented Control
    @State private var inputMode: InputMode = .write
    
    enum InputMode {
        case write
        case talk
    }
    
    // MARK: - Recording State
    @State private var isRecording: Bool = false
    @State private var isPaused: Bool = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioURL: URL?
    
    private var isButtonDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            // MARK: - Background: Solid Blue
            QuietlyColors.quietBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // MARK: - Header Section
                VStack(spacing: 8) {
                    Text("Quiet Your Mind")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(QuietlyColors.headerText)
                    
                    Text("by writing or talking it out")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(QuietlyColors.headerText)
                }
                .padding(.bottom, 24)
                
                // MARK: - Segmented Control
                segmentedControl
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // MARK: - Main Input Card
                inputCard
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // MARK: - Primary CTA Button
                ctaButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            if !prefilledText.isEmpty {
                inputText = prefilledText
                prefilledText = ""
            }
        }
        .onChange(of: navigateToDecisions) { _, newValue in
            if newValue {
                navigateToDecisions = false
            }
        }
        .sheet(isPresented: $showResults) {
            if let result = extractionResult, let dump = currentBrainDump {
                ResultsView(
                    result: result,
                    brainDump: dump,
                    inputText: $inputText,
                    onDismiss: { showResults = false },
                    navigateToDecisions: $navigateToDecisions
                )
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .overlay {
            if isProcessing {
                ProcessingOverlayView()
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Segmented Control
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            // Write Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    inputMode = .write
                }
            } label: {
                Text("Write")
                    .font(.system(size: 16, weight: inputMode == .write ? .heavy : .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 19)
                            .fill(inputMode == .write ? QuietlyColors.segmentedSelected : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            
            // Talk Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    inputMode = .talk
                }
            } label: {
                Text("Talk")
                    .font(.system(size: 16, weight: inputMode == .talk ? .heavy : .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 19)
                            .fill(inputMode == .talk ? QuietlyColors.segmentedSelected : Color.clear)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(height: 44)
        .background(QuietlyColors.segmentedBackground)
        .cornerRadius(22)
    }
    
    // MARK: - Input Card
    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if inputMode == .write {
                writeModeContent
            } else {
                talkModeContent
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: inputCardHeight)
        .background(QuietlyColors.inputCardBackground)
        .cornerRadius(28)
    }
    
    private let inputCardHeight: CGFloat = 400
    
    // MARK: - Write Mode Content
    private var writeModeContent: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $inputText)
                .scrollContentBackground(.hidden)
                .foregroundColor(Color(red: 0.2, green: 0.25, blue: 0.3))
                .font(.system(size: 17, weight: .medium))
                .padding(20)
            
            if inputText.isEmpty {
                Text("What's on your mind?")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(QuietlyColors.placeholderText)
                    .padding(24)
                    .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Talk Mode Content
    private var talkModeContent: some View {
        VStack(spacing: 20) {
            if !isRecording {
                // Idle state
                VStack(spacing: 12) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color(red: 0.81, green: 0.05, blue: 0.13), lineWidth: 1.5)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .fill(Color(red: 0.81, green: 0.05, blue: 0.13))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    Text("Tap to Record")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.51, green: 0.58, blue: 0.65))
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    startRecording()
                }
            } else {
                // Recording state
                VStack(spacing: 20) {
                    Text(isPaused ? "Paused" : "Recording...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(red: 0.51, green: 0.58, blue: 0.65))
                    
                    // Audio visualization
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { index in
                            AudioBarView(isActive: !isPaused)
                        }
                    }
                    .frame(height: 40)
                    
                    // Control buttons
                    HStack(spacing: 24) {
                        Button {
                            togglePause()
                        } label: {
                            Circle()
                                .fill(Color(red: 0.83, green: 0.84, blue: 0.92))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(red: 0.51, green: 0.58, blue: 0.65))
                                )
                        }
                        
                        Button {
                            stopRecording()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0, green: 0.35, blue: 0.94))
                                    .frame(width: 100, height: 100)
                                
                                Rectangle()
                                    .fill(.white)
                                    .frame(width: 40, height: 38)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Audio Bar View
    private struct AudioBarView: View {
        var isActive: Bool
        @State private var height: CGFloat = 30
        
        var body: some View {
            Rectangle()
                .fill(Color(red: 0, green: 0.35, blue: 0.94))
                .frame(width: 7, height: height)
                .animation(
                    isActive ? 
                        Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)
                        : Animation.linear(duration: 0.3),
                    value: height
                )
                .onAppear {
                    updateHeight()
                }
                .onChange(of: isActive) { _, newValue in
                    if newValue {
                        updateHeight()
                    } else {
                        height = 30
                    }
                }
        }
        
        private func updateHeight() {
            height = CGFloat.random(in: 20...60)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if isActive {
                    updateHeight()
                }
            }
        }
    }
    
    // MARK: - Recording Methods
    #if canImport(UIKit)
    private func startRecording() {
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                guard authStatus == .authorized else {
                    // Show permission denied alert
                    return
                }
                
                // Configure audio session
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    // Create audio file URL
                    let audioFilename = self.getDocumentsDirectory().appendingPathComponent("recording.m4a")
                    self.audioURL = audioFilename
                    
                    // Set up audio recorder
                    let settings = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100.0,
                        AVNumberOfChannelsKey: 2,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    
                    self.audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                    self.audioRecorder?.isMeteringEnabled = true
                    self.audioRecorder?.record()
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isRecording = true
                        self.isPaused = false
                    }
                    
                } catch {
                    print("Error configuring audio session: \(error)")
                }
            }
        }
    }
    #else
    private func startRecording() {
        // Voice recording not supported on macOS in this implementation
    }
    #endif
    
    #if canImport(UIKit)
    private func togglePause() {
        guard let recorder = audioRecorder else { return }
        
        if isPaused {
            recorder.record()
        } else {
            recorder.pause()
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isPaused.toggle()
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording = false
            isPaused = false
        }
        
        // Convert speech to text
        if let audioURL = audioURL {
            convertSpeechToText(from: audioURL) { result in
                DispatchQueue.main.async {
                    inputText = result ?? "Sample transcript of your recording"
                }
            }
        }
    }
    #else
    private func togglePause() {
        // Not supported on macOS
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording = false
            isPaused = false
        }
        
        // On macOS, prompt for text input instead
        inputText = ""
    }
    #endif
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // MARK: - CTA Button
    private var ctaButton: some View {
        VStack(spacing: 10) {
            if !entitlements.isPro && entitlements.canProcessToday {
                Text("\(entitlements.remainingProcesses) clear remaining today")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Button {
                handleProcess()
            } label: {
                Text("AI Analysis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(QuietlyColors.buttonBlueText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(QuietlyColors.buttonGreenBackground)
                    .cornerRadius(27)
            }
            .disabled(isButtonDisabled)
            .opacity(isButtonDisabled ? 0.5 : 1.0)
            .scaleEffect(isButtonDisabled ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isButtonDisabled)
        }
    }
    
    // MARK: - Actions
    private func handleProcess() {
        guard entitlements.canProcessToday else {
            showPaywall = true
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isProcessing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            performExtraction()
        }
    }
    
    private func performExtraction() {
        let textToProcess = inputText
        
        let extractor = LocalExtractor()
        let result = extractor.extract(from: textToProcess)
        
        let context = PersistenceController.shared.container.viewContext
        
        let dump = BrainDump(context: context)
        dump.id = UUID()
        dump.rawText = textToProcess
        dump.mode = inputMode == .write ? "text" : "voice"
        dump.createdAt = Date()
        dump.processedAt = Date()
        
        for taskText in result.tasks {
            let normalizedText = normalizeText(taskText)
            
            if !isDuplicateTask(normalizedText, in: dump, context: context) {
                let item = ExtractedItem(context: context)
                item.id = UUID()
                item.text = taskText
                item.type = "task"
                item.createdAt = Date()
                item.sourceDump = dump
                item.isPromotedToTask = true
                
                let task = TaskItem(context: context)
                task.id = UUID()
                task.title = taskText
                task.createdAt = Date()
                task.isCompleted = false
                task.sourceKind = "clear"
                task.sourceDump = dump
                
                item.linkedTask = task
            }
        }
        
        for decisionDraft in result.decisions {
            let item = ExtractedItem(context: context)
            item.id = UUID()
            item.text = decisionDraft.question
            item.type = "decision"
            item.createdAt = Date()
            item.sourceDump = dump
            
            let decision = Decision(context: context)
            decision.id = UUID()
            decision.question = decisionDraft.question
            decision.optionA = decisionDraft.optionA
            decision.optionB = decisionDraft.optionB
            decision.status = "active"
            decision.createdAt = Date()
            decision.isLockedPreview = !entitlements.isPro
            decision.sourceDump = dump
            
            if entitlements.isPro {
                decision.analysis = decisionDraft.analysis
                decision.suggestedNextStep = decisionDraft.nextStep
            }
            
            item.linkedDecision = decision
        }
        
        for worryText in result.worries {
            let item = ExtractedItem(context: context)
            item.id = UUID()
            item.text = worryText
            item.type = "worry"
            item.createdAt = Date()
            item.sourceDump = dump
        }
        
        for ideaText in result.ideas {
            let item = ExtractedItem(context: context)
            item.id = UUID()
            item.text = ideaText
            item.type = "idea"
            item.createdAt = Date()
            item.sourceDump = dump
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to save: \(error)")
        }
        
        entitlements.incrementProcessUsage()
        
        extractionResult = result
        currentBrainDump = dump
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isProcessing = false
        }
        
        showResults = true
    }
    
    // MARK: - Deduplication Helpers
    private func normalizeText(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }
    
    private func isDuplicateTask(_ normalizedText: String, in dump: BrainDump, context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<ExtractedItem> = ExtractedItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == 'task' AND sourceDump == %@ AND isPromotedToTask == YES", dump)
        
        do {
            let existingItems = try context.fetch(fetchRequest)
            for item in existingItems {
                if let text = item.text {
                    if normalizeText(text) == normalizedText {
                        return true
                    }
                }
            }
        } catch {
            print("Error checking for duplicates: \(error)")
        }
        
        return false
    }
    
    // MARK: - Speech to Text
    #if canImport(UIKit)
    private func convertSpeechToText(from url: URL, completion: @escaping (String?) -> Void) {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer?.recognitionTask(with: request) { result, error in
            guard result != nil, error == nil else {
                completion(nil)
                return
            }
            
            if let result = result {
                completion(result.bestTranscription.formattedString)
            }
        }
    }
    #endif
}

#Preview {
    ClearView(prefilledText: .constant(""), navigateToDecisions: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
