//
//  IntelligenceExtractor.swift
//  quietly
//
//  On-device Apple Intelligence extractor using FoundationModels.
//  Requires iOS 26+ with Apple Intelligence enabled.
//

import Foundation
import FoundationModels

// MARK: - Generable Output Types

@Generable
struct BrainAnalysis {
    @Guide(description: "Concrete action items the user needs to do. Detect implicit tasks, not just explicit 'I need to' statements. For example 'I've been meaning to call my mom' is a task.")
    var tasks: [AnalyzedTask]

    @Guide(description: "Decisions the user needs to make. Detect uncertainty and deliberation, not just explicit 'should I' phrasing.")
    var decisions: [AnalyzedDecision]

    @Guide(description: "Worries, anxieties, or fears the user expressed, even implicitly.")
    var worries: [String]

    @Guide(description: "Ideas, possibilities, or things the user is exploring or curious about.")
    var ideas: [String]

    @Guide(description: "Life areas this brain dump touches. Choose from: Work, Finance, Health, Relationships, Home, Personal Growth, Travel, Creativity, Spirituality.")
    var themes: [String]

    @Guide(description: "One clear, empathetic sentence summarizing what seems to matter most to the user right now.")
    var summary: String
}

@Generable
struct AnalyzedTask {
    @Guide(description: "The task written as a clear, actionable sentence.")
    var text: String

    @Guide(description: "Priority level. Use 'urgent' if there are urgency cues (deadlines, today, ASAP, overdue). Use 'thisWeek' for near-term items. Use 'someday' for vague or distant items.")
    var priority: String
}

@Generable
struct AnalyzedDecision {
    @Guide(description: "The decision framed as a clear question.")
    var question: String

    @Guide(description: "First option if the user mentioned a specific choice, otherwise leave empty.")
    var optionA: String

    @Guide(description: "Second option if the user mentioned a specific choice, otherwise leave empty.")
    var optionB: String
}

// MARK: - Intelligence Extractor

@available(iOS 26.0, macOS 26.0, *)
class IntelligenceExtractor: ExtractorProtocol {

    private let instructions = """
    You are a mental clarity assistant inside a calm, focused app called Quietly.

    Your job is to deeply analyze a user's free-form brain dump — the raw, unfiltered thoughts they've written or spoken — and extract what's really there.

    Be thorough and empathetic:
    - Find IMPLICIT tasks, not just explicit ones. "I've been meaning to call my mom" = task. "The car needs an oil change" = task.
    - Find IMPLICIT decisions. "Not sure if I should stay or go" = decision. "Torn between two options" = decision.
    - Detect emotional weight — what is this person actually stressed about?
    - Assign priority honestly based on urgency signals in the text.
    - Keep task text concise and actionable (verb-first when possible).
    - Write the summary as a warm, insightful observation — not a list.
    """

    var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    func extract(from text: String) async throws -> ExtractionResult {
        let session = LanguageModelSession(instructions: instructions)

        let response = try await session.respond(
            to: text,
            generating: BrainAnalysis.self
        )

        let analysis = response.content
        return convert(analysis)
    }

    private func convert(_ analysis: BrainAnalysis) -> ExtractionResult {
        let tasks = analysis.tasks.map { t in
            ExtractedTask(
                text: t.text,
                priority: TaskPriority(rawValue: t.priority) ?? .someday
            )
        }

        let decisions = analysis.decisions.map { d in
            DecisionDraft(
                question: d.question,
                optionA: d.optionA.isEmpty ? nil : d.optionA,
                optionB: d.optionB.isEmpty ? nil : d.optionB,
                analysis: nil,
                nextStep: nil
            )
        }

        return ExtractionResult(
            tasks: tasks,
            decisions: decisions,
            worries: analysis.worries,
            ideas: analysis.ideas,
            themes: analysis.themes,
            insights: analysis.summary.isEmpty ? [] : [analysis.summary],
            summary: analysis.summary.isEmpty ? nil : analysis.summary
        )
    }
}
