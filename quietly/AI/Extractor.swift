//
//  Extractor.swift
//  quietly
//
//  Enhanced extraction logic with more detailed analysis.
//

import Foundation

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
    let tasks: [String]
    let decisions: [DecisionDraft]
    let worries: [String]
    let ideas: [String]
    let themes: [String]
    let insights: [String]
}

// MARK: - Extractor Protocol
protocol ExtractorProtocol {
    func extract(from text: String) -> ExtractionResult
}

// MARK: - Enhanced Local Extractor
class LocalExtractor: ExtractorProtocol {
    
    // MARK: - Keywords
    private let taskKeywords = [
        "need to", "must", "should", "have to", "gotta", "todo", "to-do", 
        "action", "do this", "finish", "complete", "start", "call", "email", 
        "send", "buy", "get", "pick up", "schedule", "book", "apply", 
        "submit", "register", "renew", "check", "review", "organize", 
        "prepare", "arrange", "confirm", "follow up", "respond", "remind me"
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
    
    // MARK: - Theme Keywords
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
    
    // MARK: - Extract
    func extract(from text: String) -> ExtractionResult {
        return extract(text: text)
    }
    
    func extract(text: String) -> ExtractionResult {
        let lowercased = text.lowercased()
        let sentences = splitIntoSentences(text)
        
        var tasks: [String] = []
        var decisions: [DecisionDraft] = []
        var worries: [String] = []
        var ideas: [String] = []
        var themes: [String] = []
        var insights: [String] = []
        
        // Categorize each sentence
        for sentence in sentences {
            let s = sentence.lowercased()
            
            if containsAny(s, keywords: taskKeywords) {
                let cleaned = cleanSentence(sentence)
                if !cleaned.isEmpty && !tasks.contains(where: { $0.lowercased() == cleaned.lowercased() }) {
                    tasks.append(cleaned)
                }
            } else if containsAny(s, keywords: decisionKeywords) {
                let decision = createDecisionDraft(from: sentence)
                if !decisions.contains(where: { $0.question.lowercased() == decision.question.lowercased() }) {
                    decisions.append(decision)
                }
            } else if containsAny(s, keywords: worryKeywords) {
                let cleaned = cleanSentence(sentence)
                if !cleaned.isEmpty && !worries.contains(where: { $0.lowercased() == cleaned.lowercased() }) {
                    worries.append(cleaned)
                }
            } else if containsAny(s, keywords: ideaKeywords) {
                let cleaned = cleanSentence(sentence)
                if !cleaned.isEmpty && !ideas.contains(where: { $0.lowercased() == cleaned.lowercased() }) {
                    ideas.append(cleaned)
                }
            }
        }
        
        // Extract themes from categories
        for (category, keywords) in themeCategories {
            for keyword in keywords {
                if lowercased.contains(keyword) && !themes.contains(category) {
                    themes.append(category)
                    break
                }
            }
        }
        
        // Generate insights
        insights = generateInsights(
            text: text,
            tasks: tasks,
            decisions: decisions,
            worries: worries,
            ideas: ideas,
            sentences: sentences
        )
        
        // Fallback: if nothing extracted, add the full text as an idea
        if tasks.isEmpty && decisions.isEmpty && worries.isEmpty && ideas.isEmpty {
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                ideas.append(cleaned)
            }
        }
        
        return ExtractionResult(
            tasks: tasks,
            decisions: decisions,
            worries: worries,
            ideas: ideas,
            themes: themes,
            insights: insights
        )
    }
    
    // MARK: - Create Decision Draft
    private func createDecisionDraft(from sentence: String) -> DecisionDraft {
        let cleaned = cleanSentence(sentence)
        
        // Try to detect options (e.g., "A or B")
        let lowercased = cleaned.lowercased()
        var optionA: String? = nil
        var optionB: String? = nil
        
        if lowercased.contains(" or ") {
            let parts = cleaned.components(separatedBy: " or ")
            if parts.count >= 2 {
                optionA = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                optionB = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Generate analysis placeholder
        let analysis = "This decision involves weighing different options and considering their outcomes."
        
        // Generate next step
        let nextStep = "Consider listing pros and cons for each option."
        
        return DecisionDraft(
            question: cleaned,
            optionA: optionA,
            optionB: optionB,
            analysis: analysis,
            nextStep: nextStep
        )
    }
    
    // MARK: - Generate Insights
    private func generateInsights(
        text: String,
        tasks: [String],
        decisions: [DecisionDraft],
        worries: [String],
        ideas: [String],
        sentences: [String]
    ) -> [String] {
        var insights: [String] = []
        
        // Insight: Mental load assessment
        let totalItems = tasks.count + decisions.count + worries.count + ideas.count
        if totalItems > 5 {
            insights.append("Your mind is carrying a lot right now. Consider addressing one thing at a time.")
        } else if totalItems > 0 {
            insights.append("A focused session can help you make progress on these items.")
        }
        
        // Insight: Decision burden
        if decisions.count > 2 {
            insights.append("Multiple decisions are weighing on you. Pick the smallest one to resolve first.")
        }
        
        // Insight: Worry patterns
        if worries.count > tasks.count {
            insights.append("Your worries outnumber your tasks. Writing them down is a good first step.")
        }
        
        // Insight: Action ratio
        if !tasks.isEmpty && tasks.count > decisions.count {
            insights.append("You have clear actions to take. Start with the quickest task to build momentum.")
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    private func splitIntoSentences(_ text: String) -> [String] {
        // Split by common sentence terminators
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return sentences.isEmpty ? [text] : sentences
    }
    
    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        return keywords.contains { text.contains($0) }
    }
    
    private func cleanSentence(_ sentence: String) -> String {
        var cleaned = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common prefixes
        let prefixesToRemove = ["- ", "* ", "• ", "1. ", "2. ", "3. ", "4. ", "5. "]
        for prefix in prefixesToRemove {
            if cleaned.lowercased().hasPrefix(prefix.lowercased()) {
                cleaned = String(cleaned.dropFirst(prefix.count))
            }
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
