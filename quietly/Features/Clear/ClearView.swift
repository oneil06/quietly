//
//  ClearView.swift
//  quietly
//
//  Tab 1: Clear - Freeform brain dump screen.
//

import SwiftUI
import CoreData

struct ClearView: View {
    @ObservedObject var entitlements = EntitlementsManager.shared
    
    @Binding var prefilledText: String
    @Binding var navigateToDecisions: Bool
    
    @State private var inputText: String = ""
    @State private var inputMode: InputMode = .text
    @State private var isProcessing: Bool = false
    @State private var showResults: Bool = false
    @State private var showPaywall: Bool = false
    
    // Extracted results
    @State private var extractionResult: ExtractionResult?
    @State private var currentBrainDump: BrainDump?
    
    // Voice placeholder text
    @State private var voicePlaceholderText: String = ""
    
    enum InputMode: String, CaseIterable {
        case text = "Text"
        case voice = "Voice"
    }
    
    private var currentText: String {
        inputMode == .text ? inputText : voicePlaceholderText
    }
    
    private var isButtonDisabled: Bool {
        currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Segmented Control
                    Picker("Input Mode", selection: $inputMode) {
                        ForEach(InputMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, QuietlySpacing.outerPadding)
                    .padding(.top, 8)
                    
                    // Main Input Area
                    VStack {
                        if inputMode == .text {
                            textInputArea
                        } else {
                            voiceInputArea
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Process Button
                    VStack(spacing: 12) {
                        if !entitlements.isPro {
                            Text(entitlements.canProcessToday ? "\(entitlements.remainingProcesses) process remaining today" : "Daily limit reached")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            handleProcess()
                        } label: {
                            Text("Process")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(isButtonDisabled ? Color.gray : Color.accentColor)
                                .cornerRadius(12)
                        }
                        .disabled(isButtonDisabled)
                    }
                    .padding(.horizontal, QuietlySpacing.outerPadding)
                    .padding(.bottom, 24)
                }
                .background(QuietlyColors.background)
                .toolbar(.hidden, for: .navigationBar)
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
            }
            
            // Processing Overlay
            if isProcessing {
                ProcessingOverlayView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Clear your mind.")
                    .font(QuietlyTypography.title)
                
                Text("Freeform. No structure required.")
                    .font(QuietlyTypography.body)
                    .foregroundColor(QuietlyColors.secondaryText)
            }
            
            Spacer()
            
            ClarityRing(size: 44, isResolved: false)
        }
        .padding(.horizontal, QuietlySpacing.outerPadding)
        .padding(.top, 8)
    }
    
    // MARK: - Text Input
    private var textInputArea: some View {
        TextField("Start typing…", text: $inputText, axis: .vertical)
            .textFieldStyle(.plain)
            .padding(QuietlySpacing.cardPadding)
            .background(QuietlyColors.cardFill)
            .cornerRadius(QuietlySpacing.cornerRadius)
            .padding(.horizontal, QuietlySpacing.outerPadding)
            .padding(.top, 16)
            .lineLimit(8...20)
            .accessibilityLabel("Brain dump text input")
            .accessibilityHint("Type your thoughts freely")
    }
    
    // MARK: - Voice Input Area (Placeholder)
    private var voiceInputArea: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Button {
                // Simulate voice input with placeholder text
                voicePlaceholderText = "I need to finish the project by Friday. Should I take the new job offer or stay at my current position? I'm worried about the deadline. Maybe I should delegate some tasks."
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
            }
            
            Text("Voice recording")
                .font(QuietlyTypography.body)
                .foregroundColor(QuietlyColors.secondaryText)
            
            Text("Tap to simulate voice input")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !voicePlaceholderText.isEmpty {
                ScrollView {
                    Text(voicePlaceholderText)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .padding()
                        .background(QuietlyColors.cardFill)
                        .cornerRadius(8)
                }
                .frame(maxHeight: 150)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(QuietlyColors.cardFill)
        .cornerRadius(QuietlySpacing.cornerRadius)
        .padding(.horizontal, QuietlySpacing.outerPadding)
        .padding(.top, 16)
    }
    
    // MARK: - Actions
    private func handleProcess() {
        // Check if user can process today
        guard entitlements.canProcessToday else {
            showPaywall = true
            return
        }
        
        // Show processing overlay
        withAnimation(.easeInOut(duration: 0.3)) {
            isProcessing = true
        }
        
        // Process after delay (simulating extraction time)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            performExtraction()
        }
    }
    
    private func performExtraction() {
        let textToProcess = currentText
        
        // Run extraction
        let extractor = LocalExtractor()
        let result = extractor.extract(from: textToProcess)
        
        // Save to Core Data
        let context = PersistenceController.shared.container.viewContext
        
        // Create brain dump
        let dump = BrainDump(context: context)
        dump.id = UUID()
        dump.rawText = textToProcess
        dump.mode = inputMode.rawValue
        dump.createdAt = Date()
        dump.processedAt = Date()
        
        // Create extracted items AND automatically create TaskItems for tasks
        for taskText in result.tasks {
            // Normalize text for deduplication
            let normalizedText = normalizeText(taskText)
            
            // Check for duplicates within the same BrainDump
            if !isDuplicateTask(normalizedText, in: dump, context: context) {
                // Create ExtractedItem
                let item = ExtractedItem(context: context)
                item.id = UUID()
                item.text = taskText
                item.type = "task"
                item.createdAt = Date()
                item.sourceDump = dump
                item.isPromotedToTask = true
                
                // Automatically create TaskItem
                let task = TaskItem(context: context)
                task.id = UUID()
                task.title = taskText
                task.createdAt = Date()
                task.isCompleted = false
                task.sourceKind = "clear"
                task.sourceDump = dump
                
                // Link them together
                item.linkedTask = task
            }
        }
        
        // Create decisions from extracted decisions
        for decisionDraft in result.decisions {
            // Create ExtractedItem for the decision
            let item = ExtractedItem(context: context)
            item.id = UUID()
            item.text = decisionDraft.question
            item.type = "decision"
            item.createdAt = Date()
            item.sourceDump = dump
            
            // Create Decision record
            let decision = Decision(context: context)
            decision.id = UUID()
            decision.question = decisionDraft.question
            decision.optionA = decisionDraft.optionA
            decision.optionB = decisionDraft.optionB
            decision.status = "active"
            decision.createdAt = Date()
            decision.isLockedPreview = !entitlements.isPro
            decision.sourceDump = dump
            
            // Only add analysis for Pro users
            if entitlements.isPro {
                decision.analysis = decisionDraft.analysis
                decision.suggestedNextStep = decisionDraft.nextStep
            }
            
            // Link the extracted item to the decision
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
        
        // Save context
        do {
            try context.save()
        } catch {
            print("Failed to save: \(error)")
        }
        
        // Increment usage
        entitlements.incrementProcessUsage()
        
        // Update state
        extractionResult = result
        currentBrainDump = dump
        
        // Hide processing overlay and show results
        withAnimation(.easeInOut(duration: 0.3)) {
            isProcessing = false
        }
        
        showResults = true
    }
    
    // MARK: - Deduplication Helpers
    private func normalizeText(_ text: String) -> String {
        // Trim whitespace, collapse multiple spaces, lowercase
        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }
    
    private func isDuplicateTask(_ normalizedText: String, in dump: BrainDump, context: NSManagedObjectContext) -> Bool {
        // Check for existing tasks with same normalized text from the same BrainDump
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
}

#Preview {
    ClearView(prefilledText: .constant(""), navigateToDecisions: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
