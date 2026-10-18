import Foundation
import FoundationModels
import OSLog

/// Builds the text prompt sent to the image generator from the ideas the
/// child picked on the cards.
protocol PromptAssistantService: Sendable {
    func prompt(for ideas: [Idea]) async -> String
}

/// Deterministic prompt built from a fixed template. Used when Apple
/// Intelligence isn't available, and in previews and tests.
struct TemplatePromptAssistant: PromptAssistantService {
    func prompt(for ideas: [Idea]) async -> String {
        Self.template(for: ideas)
    }

    /// Joins the ideas as "a cute <animal> wearing <clothing> with <accessory>",
    /// skipping any category that wasn't picked.
    static func template(for ideas: [Idea]) -> String {
        func phrase(_ category: IdeaCategory) -> String? {
            ideas.first { $0.category == category }?.promptPhrase
        }
        var prompt = phrase(.animal).map { "a cute \($0.droppingArticle)" } ?? "a cute character"
        if let clothing = phrase(.clothing) { prompt += " wearing \(clothing)" }
        if let accessory = phrase(.accessory) { prompt += " with \(accessory)" }
        return prompt
    }
}

/// Uses the on-device Foundation Models language model to turn the picked
/// ideas into a short, vivid scene description. Falls back to the template
/// when the model is unavailable or fails.
struct FoundationModelsPromptAssistant: PromptAssistantService {
    private static let instructions = """
        You write prompts for a children's coloring book image generator. \
        Given a short description, reply with one simple, friendly English \
        sentence of at most 20 words that describes the scene. Keep every \
        element of the description. Reply only with the sentence.
        """

    func prompt(for ideas: [Idea]) async -> String {
        let base = TemplatePromptAssistant.template(for: ideas)
        guard case .available = SystemLanguageModel.default.availability else {
            Logger.app.info("Foundation Models unavailable; using template prompt")
            return base
        }
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(to: base)
            let text = response.content
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
            return text.isEmpty ? base : text
        } catch {
            Logger.app.error("Prompt assistant failed: \(error.localizedDescription)")
            return base
        }
    }
}

private extension String {
    /// Removes a leading English indefinite article ("a dog" -> "dog").
    var droppingArticle: String {
        for article in ["a ", "an "] where hasPrefix(article) {
            return String(dropFirst(article.count))
        }
        return self
    }
}
