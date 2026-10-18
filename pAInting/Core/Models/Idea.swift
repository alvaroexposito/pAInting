import Foundation

/// The kind of idea offered at each step of the idea cards flow, in the order
/// the child picks them.
enum IdeaCategory: Int, CaseIterable, Sendable {
    case animal
    case clothing
    case accessory

    /// SF Symbol shown as a placeholder while the category hasn't been picked yet.
    var placeholderSymbol: String {
        switch self {
        case .animal: "pawprint.fill"
        case .clothing: "tshirt.fill"
        case .accessory: "sparkles"
        }
    }

    /// Spoken name of the category, used for accessibility.
    var name: LocalizedStringResource {
        switch self {
        case .animal: LocalizedStringResource("Animal", comment: "Idea category: animals")
        case .clothing: LocalizedStringResource("Clothes", comment: "Idea category: clothes")
        case .accessory: LocalizedStringResource("Accessory", comment: "Idea category: accessories")
        }
    }
}

/// A single idea shown on a card. Children don't need to read: the card shows
/// the emoji, while the localized name is only used for VoiceOver.
struct Idea: Identifiable, Hashable, Sendable {
    /// Stable identifier, e.g. `"dog"`.
    let id: String
    let category: IdeaCategory
    /// Picture shown on the card.
    let emoji: String
    /// Localized name, read by VoiceOver.
    let name: LocalizedStringResource
    /// English phrase used to build the image prompt (English is the language
    /// best supported by the image model), e.g. `"a dog"`.
    let promptPhrase: String

    static func == (lhs: Idea, rhs: Idea) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// The set of ideas the cards are drawn from.
struct IdeaCatalog: Sendable {
    let ideas: [Idea]

    /// Ideas belonging to `category`.
    func ideas(for category: IdeaCategory) -> [Idea] {
        ideas.filter { $0.category == category }
    }
}

extension IdeaCatalog {
    /// Built-in catalog. Every category has more than six ideas so each session
    /// shows a different random selection.
    static let standard = IdeaCatalog(ideas: animals + clothes + accessories)

    private static let animals: [Idea] = [
        Idea(id: "dog", category: .animal, emoji: "🐶", name: LocalizedStringResource("Dog", comment: "Animal idea card"), promptPhrase: "a dog"),
        Idea(id: "cat", category: .animal, emoji: "🐱", name: LocalizedStringResource("Cat", comment: "Animal idea card"), promptPhrase: "a cat"),
        Idea(id: "butterfly", category: .animal, emoji: "🦋", name: LocalizedStringResource("Butterfly", comment: "Animal idea card"), promptPhrase: "a butterfly"),
        Idea(id: "elephant", category: .animal, emoji: "🐘", name: LocalizedStringResource("Elephant", comment: "Animal idea card"), promptPhrase: "an elephant"),
        Idea(id: "lion", category: .animal, emoji: "🦁", name: LocalizedStringResource("Lion", comment: "Animal idea card"), promptPhrase: "a lion"),
        Idea(id: "rabbit", category: .animal, emoji: "🐰", name: LocalizedStringResource("Rabbit", comment: "Animal idea card"), promptPhrase: "a rabbit"),
        Idea(id: "bear", category: .animal, emoji: "🐻", name: LocalizedStringResource("Bear", comment: "Animal idea card"), promptPhrase: "a bear"),
        Idea(id: "panda", category: .animal, emoji: "🐼", name: LocalizedStringResource("Panda", comment: "Animal idea card"), promptPhrase: "a panda"),
        Idea(id: "fox", category: .animal, emoji: "🦊", name: LocalizedStringResource("Fox", comment: "Animal idea card"), promptPhrase: "a fox"),
        Idea(id: "frog", category: .animal, emoji: "🐸", name: LocalizedStringResource("Frog", comment: "Animal idea card"), promptPhrase: "a frog"),
        Idea(id: "monkey", category: .animal, emoji: "🐵", name: LocalizedStringResource("Monkey", comment: "Animal idea card"), promptPhrase: "a monkey"),
        Idea(id: "giraffe", category: .animal, emoji: "🦒", name: LocalizedStringResource("Giraffe", comment: "Animal idea card"), promptPhrase: "a giraffe"),
        Idea(id: "turtle", category: .animal, emoji: "🐢", name: LocalizedStringResource("Turtle", comment: "Animal idea card"), promptPhrase: "a turtle"),
        Idea(id: "penguin", category: .animal, emoji: "🐧", name: LocalizedStringResource("Penguin", comment: "Animal idea card"), promptPhrase: "a penguin"),
        Idea(id: "unicorn", category: .animal, emoji: "🦄", name: LocalizedStringResource("Unicorn", comment: "Animal idea card"), promptPhrase: "a unicorn"),
        Idea(id: "octopus", category: .animal, emoji: "🐙", name: LocalizedStringResource("Octopus", comment: "Animal idea card"), promptPhrase: "an octopus"),
    ]

    private static let clothes: [Idea] = [
        Idea(id: "dress", category: .clothing, emoji: "👗", name: LocalizedStringResource("Dress", comment: "Clothes idea card"), promptPhrase: "a dress"),
        Idea(id: "coat", category: .clothing, emoji: "🧥", name: LocalizedStringResource("Coat", comment: "Clothes idea card"), promptPhrase: "a coat"),
        Idea(id: "tshirt", category: .clothing, emoji: "👕", name: LocalizedStringResource("T-shirt", comment: "Clothes idea card"), promptPhrase: "a t-shirt"),
        Idea(id: "jeans", category: .clothing, emoji: "👖", name: LocalizedStringResource("Jeans", comment: "Clothes idea card"), promptPhrase: "jeans"),
        Idea(id: "socks", category: .clothing, emoji: "🧦", name: LocalizedStringResource("Socks", comment: "Clothes idea card"), promptPhrase: "striped socks"),
        Idea(id: "shorts", category: .clothing, emoji: "🩳", name: LocalizedStringResource("Shorts", comment: "Clothes idea card"), promptPhrase: "shorts"),
        Idea(id: "kimono", category: .clothing, emoji: "👘", name: LocalizedStringResource("Kimono", comment: "Clothes idea card"), promptPhrase: "a kimono"),
        Idea(id: "swimsuit", category: .clothing, emoji: "🩱", name: LocalizedStringResource("Swimsuit", comment: "Clothes idea card"), promptPhrase: "a swimsuit"),
        Idea(id: "shirt", category: .clothing, emoji: "👔", name: LocalizedStringResource("Shirt and tie", comment: "Clothes idea card"), promptPhrase: "a shirt and tie"),
        Idea(id: "blouse", category: .clothing, emoji: "👚", name: LocalizedStringResource("Blouse", comment: "Clothes idea card"), promptPhrase: "a blouse"),
        Idea(id: "boots", category: .clothing, emoji: "👢", name: LocalizedStringResource("Boots", comment: "Clothes idea card"), promptPhrase: "boots"),
        Idea(id: "sneakers", category: .clothing, emoji: "👟", name: LocalizedStringResource("Sneakers", comment: "Clothes idea card"), promptPhrase: "sneakers"),
    ]

    private static let accessories: [Idea] = [
        Idea(id: "umbrella", category: .accessory, emoji: "☂️", name: LocalizedStringResource("Umbrella", comment: "Accessory idea card"), promptPhrase: "an umbrella"),
        Idea(id: "tophat", category: .accessory, emoji: "🎩", name: LocalizedStringResource("Top hat", comment: "Accessory idea card"), promptPhrase: "a top hat"),
        Idea(id: "sunhat", category: .accessory, emoji: "👒", name: LocalizedStringResource("Sun hat", comment: "Accessory idea card"), promptPhrase: "a sun hat"),
        Idea(id: "sunglasses", category: .accessory, emoji: "🕶️", name: LocalizedStringResource("Sunglasses", comment: "Accessory idea card"), promptPhrase: "sunglasses"),
        Idea(id: "glasses", category: .accessory, emoji: "👓", name: LocalizedStringResource("Glasses", comment: "Accessory idea card"), promptPhrase: "glasses"),
        Idea(id: "bow", category: .accessory, emoji: "🎀", name: LocalizedStringResource("Bow", comment: "Accessory idea card"), promptPhrase: "a bow"),
        Idea(id: "crown", category: .accessory, emoji: "👑", name: LocalizedStringResource("Crown", comment: "Accessory idea card"), promptPhrase: "a crown"),
        Idea(id: "backpack", category: .accessory, emoji: "🎒", name: LocalizedStringResource("Backpack", comment: "Accessory idea card"), promptPhrase: "a backpack"),
        Idea(id: "handbag", category: .accessory, emoji: "👜", name: LocalizedStringResource("Handbag", comment: "Accessory idea card"), promptPhrase: "a handbag"),
        Idea(id: "cap", category: .accessory, emoji: "🧢", name: LocalizedStringResource("Cap", comment: "Accessory idea card"), promptPhrase: "a cap"),
        Idea(id: "scarf", category: .accessory, emoji: "🧣", name: LocalizedStringResource("Scarf", comment: "Accessory idea card"), promptPhrase: "a scarf"),
        Idea(id: "gloves", category: .accessory, emoji: "🧤", name: LocalizedStringResource("Gloves", comment: "Accessory idea card"), promptPhrase: "gloves"),
        Idea(id: "watch", category: .accessory, emoji: "⌚️", name: LocalizedStringResource("Watch", comment: "Accessory idea card"), promptPhrase: "a wristwatch"),
    ]
}
