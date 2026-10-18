import SwiftUI
import SwiftData
import ImagePlayground
import OSLog

/// First tab: the child picks an animal, clothes and an accessory on picture
/// cards, and a coloring page is generated from those ideas.
struct CreateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    @State private var cards = IdeaCardsViewModel()
    /// Prompt built from the picked ideas, sent to the image generator.
    @State private var prompt = ""
    @State private var isGenerating = false
    @State private var isShowingImagePlayground = false
    @State private var errorMessage: String?
    @State private var artworkToColor: Artwork?

    /// Alternativa usada cuando el dispositivo no admite Image Playground
    /// (simulador, previews, dispositivos sin Apple Intelligence).
    var fallbackService: ImageGenerationService = MockImageGenerationService()
    /// Turns the picked ideas into an image prompt.
    var promptAssistant: PromptAssistantService = FoundationModelsPromptAssistant()

    var body: some View {
        NavigationStack {
            Group {
                if cards.isComplete {
                    generationView
                } else {
                    IdeaCardsView(model: cards) { _ in
                        Task { await generate() }
                    }
                }
            }
            .navigationTitle("Create")
            .imagePlaygroundSheet(
                isPresented: $isShowingImagePlayground,
                concepts: [.text(prompt), .text(Self.coloringPageConcept)]
            ) { url in
                Task { await saveImage(at: url) }
            }
            .imagePlaygroundGenerationStyle(.sketch)
            .navigationDestination(item: $artworkToColor) { artwork in
                ColoringView(artwork: artwork)
            }
        }
    }

    /// Shown once the three ideas are picked: the selection, progress while the
    /// image is created, and icon buttons to retry or start over.
    private var generationView: some View {
        VStack(spacing: 32) {
            Spacer()
            SelectionProgressView(selections: cards.selections)
            if isGenerating {
                ProgressView()
                    .controlSize(.large)
                    .accessibilityIdentifier("create.progress")
            } else {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 24) {
                    Button("Start over", systemImage: "arrow.counterclockwise") {
                        errorMessage = nil
                        cards.restart()
                    }
                    .accessibilityIdentifier("create.restart")
                    Button("Generate", systemImage: "wand.and.stars") {
                        Task { await generate() }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("create.generate")
                }
                .labelStyle(.iconOnly)
                .font(.largeTitle)
                .controlSize(.large)
            }
            Spacer()
        }
        .padding()
    }

    /// Concepto añadido al prompt para orientar al modelo hacia una página para
    /// colorear. Se envía en inglés porque es el idioma mejor soportado.
    private static let coloringPageConcept = "coloring book page, clean black outlines, white background, no shading"

    /// Language-independent title for the artwork: the picked emojis.
    private var artworkTitle: String {
        cards.selections.map(\.emoji).joined(separator: " ")
    }

    private func hue(for prompt: String) -> Double {
        Double(abs(prompt.hashValue) % 360) / 360
    }

    /// Builds the prompt from the picked ideas and starts the image generation.
    private func generate() async {
        guard !isGenerating else { return }
        isGenerating = true
        errorMessage = nil
        prompt = await promptAssistant.prompt(for: cards.selections)
        Logger.app.info("Generated prompt: \(prompt, privacy: .private)")
        if supportsImagePlayground {
            // The sheet takes over; `isGenerating` is set again while saving.
            isGenerating = false
            isShowingImagePlayground = true
        } else {
            await generateWithFallback()
        }
    }

    /// Convierte la imagen devuelta por Image Playground en silueta y la guarda.
    /// El sistema la deja en una ubicación temporal, así que se elimina después.
    private func saveImage(at url: URL) async {
        isGenerating = true
        defer {
            isGenerating = false
            try? FileManager.default.removeItem(at: url)
        }
        let lineArt = await Task.detached(priority: .userInitiated) { () -> Data? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return LineArtConverter.lineArt(from: data)
        }.value

        guard let lineArt else {
            Logger.app.error("Couldn't convert generated image to line art")
            errorMessage = String(localized: "The image couldn't be created. Try again.")
            return
        }
        insertArtwork(hue: hue(for: prompt), lineArt: lineArt)
    }

    private func generateWithFallback() async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        do {
            let image = try await fallbackService.generate(prompt: prompt)
            insertArtwork(hue: image.hue, lineArt: image.imageData)
        } catch {
            Logger.app.error("Generation failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Saves the artwork, opens it for coloring and deals new cards for next time.
    private func insertArtwork(hue: Double, lineArt: Data?) {
        let artwork = Artwork(prompt: artworkTitle, hue: hue, lineArtData: lineArt)
        modelContext.insert(artwork)
        if lineArt != nil {
            artworkToColor = artwork
            cards.restart()
        }
    }
}

#Preview {
    CreateView(
        fallbackService: MockImageGenerationService(delay: .milliseconds(200)),
        promptAssistant: TemplatePromptAssistant()
    )
    .modelContainer(for: Artwork.self, inMemory: true)
}
