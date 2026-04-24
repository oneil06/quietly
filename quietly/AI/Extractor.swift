//
//  Extractor.swift
//  quietly
//
//  Data models and fallback local extractor.
//

import Foundation

// MARK: - Task Priority
enum TaskPriority: String, Codable {
    case urgent   = "urgent"    // needs to happen today / very soon
    case thisWeek = "thisWeek"  // should happen this week
    case someday  = "someday"   // can wait, no urgency detected
}

// MARK: - Extracted Task
struct ExtractedTask {
    let text: String
    let priority: TaskPriority
}

// MARK: - Decision Draft
struct DecisionDraft {
    let question: String
    let optionA: String?
    let optionB: String?
    let analysis: String?
    let nextStep: String?
}

// MARK: - Extraction Result
struct ExtractionResult {
    let tasks: [ExtractedTask]
    let decisions: [DecisionDraft]
    let worries: [String]
    let ideas: [String]
    let themes: [String]
    let insights: [String]
    let summary: String?  // key insight from Apple Intelligence
}

// MARK: - Extractor Protocol
protocol ExtractorProtocol {
    func extract(from text: String) async throws -> ExtractionResult
}

// MARK: - Local Extractor (fallback)
class LocalExtractor: ExtractorProtocol {

    // MARK: - Keywords
    private let taskKeywords = [
        "need to", "must", "should", "have to", "gotta", "todo", "to-do",
        "action", "do this", "finish", "complete", "start", "call", "email",
        "send", "buy", "get", "pick up", "schedule", "book", "apply",
        "submit", "register", "renew", "check", "review", "organize",
        "prepare", "arrange", "confirm", "follow up", "respond", "remind me"
    ]

    private let urgentKeywords = [
        "urgent", "asap", "today", "right now", "immediately", "deadline",
        "due", "overdue", "critical", "important", "can't wait", "soon"
    ]

    private let decisionKeywords = [
        "should i", "whether to", "decide", "choice", "either", "or not",
        "pros", "cons", "vs", "versus", "which to", "pick between",
        "what if i", "not sure if", "considering", "weighing",
        "uncertain", "hesitant", "thinking about whether", "wondering if"
    ]

    private let worryKeywords = [
        "worry", "worried", "anxious", "concern", "nervous", "scared",
        "fear", "hope not", "what if", "might", "could go wrong", "stress",
        "overthink", "overwhelm", "dread", "afraid", "not confident",
        "uncertain about", "nervous about", "freaking out", "panic"
    ]

    private let ideaKeywords = [
        "idea", "maybe", "could", "what about", "thought",
        "consider", "interesting", "potential", "perhaps", "might work",
        "worth trying", "why not", "how about", "imagine", "would be cool",
        "should try", "experiment", "explore", "test out"
    ]

    private let themeCategories: [String: [String]] = [
        "Work": ["work", "job", "career", "boss", "colleague", "meeting", "project", "deadline", "office", "employer", "promotion", "salary"],
        "Finance": ["money", "finances", "investment", "savings", "budget", "debt", "income", "expense", "bill", "tax", "retirement"],
        "Health": ["health", "exercise", "fitness", "diet", "sleep", "doctor", "medical", "wellness", "mental health", "therapy"],
        "Relationships": ["relationship", "dating", "partner", "friend", "family", "parent", "spouse", "marriage", "social"],
        "Home": ["home", "house", "apartment", "moving", "rent", "mortgage", "renovate", "decorate"],
        "Personal Growth": ["learning", "skill", "hobby", "goal", "growth", "education", "course", "book", "study"],
        "Travel": ["travel", "vacation", "trip", "flight", "hotel", "destination", "adventure"],
        "Spirituality": ["spiritual", "meditation", "mindfulness", "faith", "religion", "purpose", "meaning"],
        "Creativity": ["create", "art", "music", "write", "design", "project", "creative", "inspiration"]
    ]

    // MARK: - Protocol
    func extract(from text: String) async throws -> ExtractionResult {
        extractSync(from: text)
    }

    // MARK: - Sync implementation
    func extractSync(from text: String) -> ExtractionResult {
        let lowercased = text.lowercased()
        let sentences = splitIntoSentences(text)

        var tasks: [ExtractedTask] = []
        var decisions: [DecisionDraft] = []
        var worries: [String] = []
        var ideas: [String] = []
        var themes: [String] = []

        for sentence in sentences {
            let s = sentence.lowercased()

            if containsAny(s, keywords: taskKeywords) {
                let cleaned = cleanSentence(sentence)
                guard !cleaned.isEmpty, !tasks.contains(where: { $0.text.lowercased() == cleaned.lowercased() }) else { continue }
                let priority: TaskPriority = containsAny(s, keywords: urgentKeywords) ? .urgent : .thisWeek
                tasks.append(ExtractedTask(text: cleaned, priority: priority))
            } else if containsAny(s, keywords: decisionKeywords) {
                let draft = createDecisionDraft(from: sentence)
                guard !decisions.contains(where: { $0.question.lowercased() == draft.question.lowercased() }) else { continue }
                decisions.append(draft)
            } else if containsAny(s, keywords: worryKeywords) {
                let cleaned = cleanSentence(sentence)
                guard !cleaned.isEmpty, !worries.contains(where: { $0.lowercased() == cleaned.lowercased() }) else { continue }
                worries.append(cleaned)
            } else if containsAny(s, keywords: ideaKeywords) {
                let cleaned = cleanSentence(sentence)
                guard !cleaned.isEmpty, !ideas.contains(where: { $0.lowercased() == cleaned.lowercased() }) else { continue }
                ideas.append(cleaned)
            }
        }

        for (category, keywords) in themeCategories {
            if keywords.contains(where: { lowercased.contains($0) }) && !themes.contains(category) {
                themes.append(category)
            }
        }

        let insights = generateInsights(tasks: tasks, decisions: decisions, worries: worries, ideas: ideas)

        if tasks.isEmpty && decisions.isEmpty && worries.isEmpty && ideas.isEmpty {
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty { ideas.append(cleaned) }
        }

        return ExtractionResult(
            tasks: tasks,
            decisions: decisions,
            worries: worries,
            ideas: ideas,
            themes: themes,
            insights: insights,
            summary: insights.first
        )
    }

    // MARK: - Helpers
    private func createDecisionDraft(from sentence: String) -> DecisionDraft {
        let cleaned = cleanSentence(sentence)
        var optionA: String? = nil
        var optionB: String? = nil
        if cleaned.lowercased().contains(" or ") {
            let parts = cleaned.components(separatedBy: " or ")
            if parts.count >= 2 {
                optionA = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                optionB = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return DecisionDraft(
            question: cleaned,
            optionA: optionA,
            optionB: optionB,
            analysis: "This decision involves weighing different options and considering their outcomes.",
            nextStep: "Consider listing pros and cons for each option."
        )
    }

    private func generateInsights(tasks: [ExtractedTask], decisions: [DecisionDraft], worries: [String], ideas: [String]) -> [String] {
        var insights: [String] = []
        let total = tasks.count + decisions.count + worries.count + ideas.count
        if total > 5 {
            insights.append("Your mind is carrying a lot right now. Consider addressing one thing at a time.")
        } else if total > 0 {
            insights.append("A focused session can help you make progress on these items.")
        }
        if decisions.count > 2 {
            insights.append("Multiple decisions are weighing on you. Pick the smallest one to resolve first.")
        }
        if worries.count > tasks.count {
            insights.append("Your worries outnumber your tasks. Writing them down is a good first step.")
        }
        if !tasks.isEmpty && tasks.count > decisions.count {
            insights.append("You have clear actions to take. Start with the quickest task to build momentum.")
        }
        return insights
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return sentences.isEmpty ? [text] : sentences
    }

    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private func cleanSentence(_ sentence: String) -> String {
        var cleaned = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in ["- ", "* ", "• ", "1. ", "2. ", "3. ", "4. ", "5. "] {
            if cleaned.lowercased().hasPrefix(prefix.lowercased()) {
                cleaned = String(cleaned.dropFirst(prefix.count))
            }
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
