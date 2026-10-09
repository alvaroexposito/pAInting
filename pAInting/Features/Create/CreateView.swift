import SwiftUI
import SwiftData
import ImagePlayground
import OSLog

struct CreateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    @State private var prompt = ""
    @State private var isGenerating = false
    @State private var isShowingImagePlayground = false
    @State private var errorMessage: String?
    @State private var artworkToColor: Artwork?

    /// Alternativa usada cuando el dispositivo no admite Image Playground
    /// (simulador, previews, dispositivos sin Apple Intelligence).
    var fallbackService: ImageGenerationService = MockImageGenerationService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Prompt") {
                    TextField("A fox painting at sunset…", text: $prompt, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("create.prompt")
                }
                Section {
                    Button {
                        if supportsImagePlayground {
                            errorMessage = nil
                            isShowingImagePlayground = true
                        } else {
                            Task { await generateWithFallback() }
                        }
                    } label: {
                        HStack {
                            Text("Generate")
                            if isGenerating { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(trimmedPrompt.isEmpty || isGenerating)
                    .accessibilityIdentifier("create.generate")
                } footer: {
                    Text("You'll get an outline to color in.")
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Create")
            .imagePlaygroundSheet(
                isPresented: $isShowingImagePlayground,
                concepts: [.text(trimmedPrompt), .text(Self.coloringPageConcept)]
            ) { url in
                Task { await saveImage(at: url) }
            }
            .imagePlaygroundGenerationStyle(.sketch)
            .navigationDestination(item: $artworkToColor) { artwork in
                ColoringView(artwork: artwork)
            }
        }
    }

    /// Concepto añadido al prompt para orientar al modelo hacia una página para
    /// colorear. Se envía en inglés porque es el idioma mejor soportado.
    private static let coloringPageConcept = "coloring book page, clean black outlines, white background, no shading"

    private var trimmedPrompt: String { prompt.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func hue(for prompt: String) -> Double {
        Double(abs(prompt.hashValue) % 360) / 360
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
            errorMessage = String(localized: "The image couldn't be created. Try a different prompt.")
            return
        }
        insertArtwork(prompt: trimmedPrompt, hue: hue(for: trimmedPrompt), lineArt: lineArt)
    }

    private func generateWithFallback() async {
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        do {
            let image = try await fallbackService.generate(prompt: trimmedPrompt)
            insertArtwork(prompt: image.prompt, hue: image.hue, lineArt: image.imageData)
        } catch {
            Logger.app.error("Generation failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    private func insertArtwork(prompt: String, hue: Double, lineArt: Data?) {
        let artwork = Artwork(prompt: prompt, hue: hue, lineArtData: lineArt)
        modelContext.insert(artwork)
        self.prompt = ""
        if lineArt != nil {
            artworkToColor = artwork
        }
    }
}

#Preview {
    CreateView(fallbackService: MockImageGenerationService(delay: .milliseconds(200)))
        .modelContainer(for: Artwork.self, inMemory: true)
}
