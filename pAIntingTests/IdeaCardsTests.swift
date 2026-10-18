import Testing
@testable import pAInting

/// Deterministic generator (SplitMix64) so card deals are reproducible.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@MainActor
struct IdeaCardsViewModelTests {
    @Test func startsWithSixDistinctAnimals() {
        let model = IdeaCardsViewModel(generator: SeededGenerator(state: 1))
        #expect(model.currentCategory == .animal)
        #expect(model.options.count == IdeaCardsViewModel.cardsPerStep)
        #expect(Set(model.options).count == IdeaCardsViewModel.cardsPerStep)
        #expect(model.options.allSatisfy { $0.category == .animal })
    }

    @Test func selectingAdvancesThroughClothesAndAccessories() throws {
        let model = IdeaCardsViewModel(generator: SeededGenerator(state: 2))
        let animal = try #require(model.options.first)
        model.select(animal)
        #expect(model.currentCategory == .clothing)
        #expect(model.options.count == IdeaCardsViewModel.cardsPerStep)
        #expect(model.options.allSatisfy { $0.category == .clothing })

        let clothing = try #require(model.options.first)
        model.select(clothing)
        #expect(model.currentCategory == .accessory)
        #expect(model.options.allSatisfy { $0.category == .accessory })

        #expect(model.options.count == IdeaCardsViewModel.cardsPerStep)

        let accessory = try #require(model.options.first)
        model.select(accessory)
        #expect(model.isComplete)
        #expect(model.options.isEmpty)
        #expect(model.selections == [animal, clothing, accessory])
    }

    /// RF-1, RF-3, RF-5: every step deals six different ideas of its category.
    @Test(arguments: 0..<20)
    func everyStepDealsSixDistinctIdeas(seed: UInt64) throws {
        let model = IdeaCardsViewModel(generator: SeededGenerator(state: seed))
        for category in IdeaCategory.allCases {
            #expect(model.currentCategory == category)
            #expect(model.options.count == IdeaCardsViewModel.cardsPerStep)
            #expect(Set(model.options).count == IdeaCardsViewModel.cardsPerStep)
            #expect(model.options.allSatisfy { $0.category == category })
            model.select(try #require(model.options.first))
        }
    }

    /// RF-2, RF-4, RF-6: each card shows a single emoji and no letters.
    @Test func everyIdeaIsShownAsASingleEmoji() {
        for idea in IdeaCatalog.standard.ideas {
            let hasLetters = idea.emoji.contains { $0.isLetter }
            let isEmoji = idea.emoji.unicodeScalars.contains { $0.properties.isEmojiPresentation || $0 == "\u{FE0F}" }
            #expect(idea.emoji.count == 1, "\(idea.id)")
            #expect(!hasLetters, "\(idea.id)")
            #expect(isEmoji, "\(idea.id)")
        }
    }

    @Test func ignoresIdeasNotOnTheCards() throws {
        let model = IdeaCardsViewModel(generator: SeededGenerator(state: 3))
        let clothing = try #require(IdeaCatalog.standard.ideas(for: .clothing).first)
        model.select(clothing)
        #expect(model.selections.isEmpty)
        #expect(model.currentCategory == .animal)
    }

    @Test func goBackAndRestartUndoSelections() throws {
        let model = IdeaCardsViewModel(generator: SeededGenerator(state: 4))
        model.select(try #require(model.options.first))
        model.select(try #require(model.options.first))
        model.goBack()
        #expect(model.selections.count == 1)
        #expect(model.currentCategory == .clothing)

        model.restart()
        #expect(model.selections.isEmpty)
        #expect(model.currentCategory == .animal)
        #expect(model.options.count == IdeaCardsViewModel.cardsPerStep)
    }

    @Test func catalogHasEnoughUniqueIdeasPerCategory() {
        let ids = IdeaCatalog.standard.ideas.map(\.id)
        #expect(Set(ids).count == ids.count)
        for category in IdeaCategory.allCases {
            #expect(IdeaCatalog.standard.ideas(for: category).count > IdeaCardsViewModel.cardsPerStep)
        }
    }
}

struct PromptAssistantTests {
    private func idea(_ id: String) throws -> Idea {
        try #require(IdeaCatalog.standard.ideas.first { $0.id == id })
    }

    @Test func templateCombinesTheThreeIdeas() async throws {
        let ideas = [try idea("dog"), try idea("dress"), try idea("umbrella")]
        let prompt = await TemplatePromptAssistant().prompt(for: ideas)
        #expect(prompt == "a cute dog wearing a dress with an umbrella")
    }

    @Test func templateSkipsMissingCategories() throws {
        #expect(TemplatePromptAssistant.template(for: [try idea("elephant")]) == "a cute elephant")
        #expect(TemplatePromptAssistant.template(for: []) == "a cute character")
    }

    /// CL-4: without Apple Intelligence the prompt falls back to the template.
    @Test func foundationModelsFallsBackToTemplateWhenUnavailable() async throws {
        let ideas = [try idea("cat"), try idea("coat"), try idea("crown")]
        let assistant = FoundationModelsPromptAssistant(availability: { .unavailable(.appleIntelligenceNotEnabled) })
        let prompt = await assistant.prompt(for: ideas)
        #expect(prompt == "a cute cat wearing a coat with a crown")
    }
}
