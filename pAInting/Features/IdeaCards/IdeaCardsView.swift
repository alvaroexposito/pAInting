import SwiftUI

/// Grid of picture cards the child taps to pick an animal, a piece of clothing
/// and an accessory. No reading is required: every card is an emoji.
struct IdeaCardsView: View {
    let model: IdeaCardsViewModel
    /// Called once the last category has been picked.
    var onComplete: ([Idea]) -> Void

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SelectionProgressView(selections: model.selections)
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(model.options.enumerated()), id: \.element.id) { index, idea in
                        IdeaCard(idea: idea, hue: Self.hue(for: index)) {
                            select(idea)
                        }
                        .accessibilityIdentifier("ideas.card.\(index)")
                        // Cards of the previous step disappear at once: if they
                        // animated out, they would sit over the new cards and
                        // swallow the child's next tap.
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .identity))
                    }
                }
            }
            .padding()
            .animation(.spring(duration: 0.4), value: model.options)
        }
        .toolbar {
            if !model.selections.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "arrow.uturn.backward") { model.goBack() }
                        .accessibilityIdentifier("ideas.back")
                }
            }
        }
    }

    private func select(_ idea: Idea) {
        model.select(idea)
        if model.isComplete {
            onComplete(model.selections)
        }
    }

    /// Spreads the card colors around the color wheel.
    private static func hue(for index: Int) -> Double {
        Double(index) / Double(IdeaCardsViewModel.cardsPerStep)
    }
}

/// Large rectangular card showing one idea as a picture.
private struct IdeaCard: View {
    let idea: Idea
    let hue: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hue: hue, saturation: 0.35, brightness: 1))
                .overlay {
                    Text(idea.emoji)
                        .font(.system(size: 72))
                        .minimumScaleFactor(0.5)
                }
                .aspectRatio(4 / 3, contentMode: .fit)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(idea.name))
    }
}

/// One slot per category showing what has been picked so far, so the child can
/// see their progress without reading.
struct SelectionProgressView: View {
    let selections: [Idea]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(IdeaCategory.allCases, id: \.self) { category in
                slot(for: category)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func slot(for category: IdeaCategory) -> some View {
        let idea = selections.first { $0.category == category }
        let isCurrent = idea == nil && category.rawValue == selections.count
        RoundedRectangle(cornerRadius: 16)
            .fill(.background.secondary)
            .overlay {
                if let idea {
                    Text(idea.emoji).font(.system(size: 40))
                } else {
                    Image(systemName: category.placeholderSymbol)
                        .font(.title)
                        .foregroundStyle(isCurrent ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                }
            }
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 16).strokeBorder(.tint, lineWidth: 3)
                }
            }
            .frame(width: 72, height: 72)
            .accessibilityElement()
            .accessibilityLabel(idea.map { Text($0.name) } ?? Text(category.name))
            .accessibilityAddTraits(idea != nil ? .isSelected : [])
            .accessibilityIdentifier("ideas.slot.\(category.rawValue)")
    }
}

#Preview {
    NavigationStack {
        IdeaCardsView(model: IdeaCardsViewModel()) { _ in }
    }
}
