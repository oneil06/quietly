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
import UIKit

struct ClearView: View {
    @ObservedObject var entitlements = EntitlementsManager.shared

    @Binding var prefilledText: String
    @Binding var navigateToDecisions: Bool

    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var showResults: Bool = false
    @State private var showPaywall: Bool = false

    @State private var processingCompleted: Bool = false
    @State private var processingError: String? = nil

    @State private var extractionResult: ExtractionResult?
    @State private var currentBrainDump: BrainDump?

    @State private var inputMode: InputMode = .write
    @FocusState private var isTextEditorFocused: Bool

    enum InputMode { case write, talk }

    // Recording
    @State private var isRecording: Bool = false
    @State private var isPaused: Bool = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioURL: URL?
    @State private var showPermissionAlert: Bool = false
    @State private var isTranscribing: Bool = false
    @State private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    @State private var recognitionTask: SFSpeechRecognitionTask?

    private var isButtonDisabled: Bool {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isRecording
    }

    var body: some View {
        ZStack {
            QuietlyColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                modePicker
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                inputCard
                    .padding(.horizontal, 16)

                Spacer()

                bottomBar
                    .padding(.horizontal, 16)
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
            if newValue { navigateToDecisions = false }
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
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow microphone and speech recognition access in Settings to use voice recording.")
        }
        .overlay {
            if isProcessing {
                ProcessingOverlayContainer(
                    isProcessing: $isProcessing,
                    processingCompleted: $processingCompleted,
                    processingError: $processingError,
                    onComplete: {
                        if extractionResult != nil && currentBrainDump != nil {
                            showResults = true
                        }
                    },
                    onErrorDismiss: {
                        processingError = nil
                        processingCompleted = false
                    }
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
                Text("Your Thoughts, Organized Quietly.")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(QuietlyColors.mutedText)
            }
            Spacer()
            if !entitlements.isPro {
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                        Text("Pro")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(QuietlyColors.primaryBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(QuietlyColors.green)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Mode Picker
    private var modePicker: some View {
        HStack(spacing: 0) {
            modeButton("Write", mode: .write)
            modeButton("Talk", mode: .talk)
        }
    }

    private func modeButton(_ title: String, mode: InputMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { inputMode = mode }
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: inputMode == mode ? .bold : .regular))
                    .foregroundColor(QuietlyColors.primaryBlue)
                Rectangle()
                    .fill(inputMode == mode ? QuietlyColors.primaryBlue : QuietlyColors.primaryBlue.opacity(0.15))
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Input Card
    private var inputCard: some View {
        Group {
            if inputMode == .write {
                writeModeCard
            } else {
                talkModeCard
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.07), radius: 16, x: 0, y: 4)
    }

    // MARK: - Write Mode
    private var writeModeCard: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $inputText)
                .scrollContentBackground(.hidden)
                .foregroundColor(QuietlyColors.darkText)
                .font(.system(size: 17))
                .padding(20)
                .focused($isTextEditorFocused)
                .contentShape(Rectangle())

            if inputText.isEmpty && !isTextEditorFocused {
                Text("What's on your mind?")
                    .font(.system(size: 17))
                    .foregroundColor(QuietlyColors.mutedText.opacity(0.7))
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .allowsHitTesting(false)
            }

            // Character hint when text is short
            if !inputText.isEmpty && inputText.count < 20 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Keep going…")
                            .font(.system(size: 12))
                            .foregroundColor(QuietlyColors.mutedText.opacity(0.5))
                            .padding(16)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { isTextEditorFocused = true }
    }

    // MARK: - Talk Mode
    private var talkModeCard: some View {
        Group {
            if isTranscribing {
                transcribingView
            } else if isRecording {
                recordingActiveView
            } else {
                recordingIdleView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var recordingIdleView: some View {
        VStack(spacing: 16) {
            Spacer()
            Button(action: { startRecording() }) {
                ZStack {
                    Circle()
                        .fill(QuietlyColors.micRed.opacity(0.1))
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(QuietlyColors.micRed.opacity(0.2))
                        .frame(width: 112, height: 112)
                    Circle()
                        .fill(QuietlyColors.micRed)
                        .frame(width: 88, height: 88)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            Text("Tap to Record")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(QuietlyColors.mutedText)
            Spacer()
        }
    }

    private var recordingActiveView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Status label
            HStack(spacing: 8) {
                if !isPaused {
                    Circle()
                        .fill(QuietlyColors.micRed)
                        .frame(width: 8, height: 8)
                }
                Text(isPaused ? "Paused" : "Recording...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(QuietlyColors.darkText)
            }

            // Waveform
            HStack(spacing: 3) {
                ForEach(0..<24, id: \.self) { _ in
                    AudioBarView(isActive: !isPaused)
                }
            }
            .frame(height: 52)
            .padding(.horizontal, 24)

            // Controls
            HStack(spacing: 32) {
                Button(action: { togglePause() }) {
                    ZStack {
                        Circle()
                            .fill(QuietlyColors.primaryBlue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 20))
                            .foregroundColor(QuietlyColors.primaryBlue)
                    }
                }
                .buttonStyle(.plain)

                Button(action: { stopRecording() }) {
                    ZStack {
                        Circle()
                            .fill(QuietlyColors.primaryBlue)
                            .frame(width: 80, height: 80)
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private var transcribingView: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
                .scaleEffect(1.3)
                .tint(QuietlyColors.primaryBlue)
            Text("Transcribing...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(QuietlyColors.mutedText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Audio Bar
    private struct AudioBarView: View {
        var isActive: Bool
        @State private var barHeight: CGFloat = 8

        var body: some View {
            RoundedRectangle(cornerRadius: 2)
                .fill(QuietlyColors.primaryBlue)
                .frame(width: 4, height: barHeight)
                .animation(
                    isActive
                        ? Animation.easeInOut(duration: Double.random(in: 0.2...0.5)).repeatForever(autoreverses: true)
                        : .linear(duration: 0.2),
                    value: barHeight
                )
                .onAppear { barHeight = CGFloat.random(in: 8...48) }
                .onChange(of: isActive) { _, active in
                    barHeight = active ? CGFloat.random(in: 8...48) : 8
                }
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 10) {
            if !entitlements.isPro && entitlements.canProcessToday {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                    Text("\(entitlements.remainingProcesses) free clear\(entitlements.remainingProcesses == 1 ? "" : "s") remaining today")
                        .font(.system(size: 12))
                }
                .foregroundColor(QuietlyColors.mutedText)
            }

            Button(action: { handleProcess() }) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("AI Analysis")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(QuietlyColors.primaryBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isButtonDisabled ? Color.gray.opacity(0.2) : QuietlyColors.green)
                .cornerRadius(28)
            }
            .disabled(isButtonDisabled)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isButtonDisabled)
        }
    }

    // MARK: - Recording — iOS only
    #if canImport(UIKit)
    private func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { micAllowed in
            guard micAllowed else {
                DispatchQueue.main.async { showPermissionAlert = true }
                return
            }
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    guard status == .authorized else {
                        showPermissionAlert = true
                        return
                    }
                    beginAudioRecording()
                }
            }
        }
    }

    private func beginAudioRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let fileURL = getDocumentsDirectory().appendingPathComponent("quietly_recording.m4a")
            audioURL = fileURL

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            withAnimation(.easeInOut(duration: 0.3)) {
                isRecording = true
                isPaused = false
            }
        } catch {
            DispatchQueue.main.async {
                processingError = "Could not start recording. Please try again."
            }
        }
    }

    private func togglePause() {
        guard let recorder = audioRecorder else { return }
        if isPaused { recorder.record() } else { recorder.pause() }
        withAnimation(.easeInOut(duration: 0.2)) { isPaused.toggle() }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording = false
            isPaused = false
            isTranscribing = true
        }

        guard let url = audioURL else { isTranscribing = false; return }

        transcribeSpeech(from: url) { transcribed in
            DispatchQueue.main.async {
                isTranscribing = false
                if let text = transcribed, !text.isEmpty {
                    inputText = text
                    withAnimation(.easeInOut(duration: 0.2)) { inputMode = .write }
                }
            }
        }
    }

    private func transcribeSpeech(from url: URL, completion: @escaping (String?) -> Void) {
        if speechRecognizer == nil { speechRecognizer = SFSpeechRecognizer() }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { completion(nil); return }

        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        recognitionTask = recognizer.recognitionTask(with: request) { [self] result, error in
            self.recognitionTask = nil
            if error != nil { completion(nil); return }
            if let result = result, result.isFinal {
                completion(result.bestTranscription.formattedString)
            }
        }
    }
    #else
    private func startRecording() {}
    private func togglePause() {}
    private func stopRecording() {
        withAnimation(.easeInOut(duration: 0.3)) { isRecording = false; isPaused = false }
    }
    #endif

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Extraction
    private func handleProcess() {
        guard entitlements.canProcessToday else { showPaywall = true; return }
        processingCompleted = false
        processingError = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) { isProcessing = true }
        Task { await performExtraction() }
    }

    private func performExtraction() async {
        let textToProcess = inputText
        do {
            // Try Apple Intelligence; fall back to local extractor on any failure
            let result: ExtractionResult = await {
                if #available(iOS 26.0, *) {
                    do {
                        let ext = IntelligenceExtractor()
                        if ext.isAvailable {
                            return try await ext.extract(from: textToProcess)
                        }
                    } catch {
                        // Apple Intelligence unavailable or failed — use local fallback
                    }
                }
                return LocalExtractor().extractSync(from: textToProcess)
            }()

            guard !result.tasks.isEmpty || !result.decisions.isEmpty || !result.worries.isEmpty || !result.ideas.isEmpty else {
                processingError = "No items found. Try adding more detail."
                return
            }

            let context = PersistenceController.shared.container.viewContext
            let dump = BrainDump(context: context)
            dump.id = UUID(); dump.rawText = textToProcess
            dump.mode = inputMode == .write ? "text" : "voice"
            dump.createdAt = Date(); dump.processedAt = Date()

            for extractedTask in result.tasks {
                let normalized = normalizeText(extractedTask.text)
                guard !isDuplicateTask(normalized, in: dump, context: context) else { continue }
                let item = ExtractedItem(context: context)
                item.id = UUID(); item.text = extractedTask.text; item.type = "task"
                item.createdAt = Date(); item.sourceDump = dump; item.isPromotedToTask = true
                let task = TaskItem(context: context)
                task.id = UUID(); task.title = extractedTask.text; task.createdAt = Date()
                task.isCompleted = false; task.sourceKind = "clear"; task.sourceDump = dump
                item.linkedTask = task
            }

            for decisionDraft in result.decisions {
                let item = ExtractedItem(context: context)
                item.id = UUID(); item.text = decisionDraft.question; item.type = "decision"
                item.createdAt = Date(); item.sourceDump = dump
                let decision = Decision(context: context)
                decision.id = UUID(); decision.question = decisionDraft.question
                decision.optionA = decisionDraft.optionA; decision.optionB = decisionDraft.optionB
                decision.status = "active"; decision.createdAt = Date()
                decision.isLockedPreview = !entitlements.isPro; decision.sourceDump = dump
                if entitlements.isPro {
                    decision.analysis = decisionDraft.analysis
                    decision.suggestedNextStep = decisionDraft.nextStep
                }
                item.linkedDecision = decision
            }

            for worryText in result.worries {
                let item = ExtractedItem(context: context)
                item.id = UUID(); item.text = worryText; item.type = "worry"
                item.createdAt = Date(); item.sourceDump = dump
            }

            for ideaText in result.ideas {
                let item = ExtractedItem(context: context)
                item.id = UUID(); item.text = ideaText; item.type = "idea"
                item.createdAt = Date(); item.sourceDump = dump
            }

            try context.save()
            entitlements.incrementProcessUsage()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            extractionResult = result
            currentBrainDump = dump
            processingCompleted = true

        } catch {
            processingError = "Something went wrong. Please try again."
        }
    }

    private func normalizeText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }

    private func isDuplicateTask(_ normalized: String, in dump: BrainDump, context: NSManagedObjectContext) -> Bool {
        let fetch: NSFetchRequest<ExtractedItem> = ExtractedItem.fetchRequest()
        fetch.predicate = NSPredicate(format: "type == 'task' AND sourceDump == %@ AND isPromotedToTask == YES", dump)
        let existing = (try? context.fetch(fetch)) ?? []
        return existing.contains { normalizeText($0.text ?? "") == normalized }
    }
}

#Preview {
    ClearView(prefilledText: .constant(""), navigateToDecisions: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
