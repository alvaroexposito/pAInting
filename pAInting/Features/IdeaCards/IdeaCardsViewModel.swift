import Foundation
import Observation

/// State of the idea cards flow: the child picks an animal, then a piece of
/// clothing, then an accessory, each from a random set of cards.
@MainActor
@Observable
final class IdeaCardsViewModel {
    /// Number of cards shown at each step.
    static let cardsPerStep = 6

    /// Ideas picked so far, in category order.
    private(set) var selections: [Idea] = []
    /// Cards currently offered to the child.
    private(set) var options: [Idea] = []

    private let catalog: IdeaCatalog
    private var generator: any RandomNumberGenerator

    /// Category being picked, or `nil` once every category has a selection.
    var currentCategory: IdeaCategory? {
        IdeaCategory(rawValue: selections.count)
    }

    var isComplete: Bool { currentCategory == nil }

    /// - Parameters:
    ///   - catalog: ideas the cards are drawn from.
    ///   - generator: source of randomness; inject a seeded one in tests.
    init(catalog: IdeaCatalog = .standard, generator: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.catalog = catalog
        self.generator = generator
        dealCards()
    }

    /// Picks `idea` for the current category and deals the cards of the next one.
    func select(_ idea: Idea) {
        guard let category = currentCategory, idea.category == category, options.contains(idea) else { return }
        selections.append(idea)
        dealCards()
    }

    /// Undoes the last selection and deals a fresh set for that category.
    func goBack() {
        guard !selections.isEmpty else { return }
        selections.removeLast()
        dealCards()
    }

    /// Clears every selection and starts again from the animals.
    func restart() {
        selections.removeAll()
        dealCards()
    }

    /// Draws a random set of cards for the current category.
    private func dealCards() {
        guard let category = currentCategory else {
            options = []
            return
        }
        options = Array(catalog.ideas(for: category).shuffled(using: &generator).prefix(Self.cardsPerStep))
    }
}
