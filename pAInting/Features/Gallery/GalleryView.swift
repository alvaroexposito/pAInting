import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Artwork.createdAt, order: .reverse) private var artworks: [Artwork]

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if artworks.isEmpty {
                    ContentUnavailableView(
                        "No artworks yet",
                        systemImage: "photo.on.rectangle",
                        description: Text("Create your first painting from the Create tab.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(artworks) { artwork in
                                NavigationLink(value: artwork) {
                                    ArtworkCard(artwork: artwork)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("gallery.artwork")
                                .contextMenu {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        modelContext.delete(artwork)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationDestination(for: Artwork.self) { artwork in
                ColoringView(artwork: artwork)
            }
        }
    }
}

private struct ArtworkCard: View {
    let artwork: Artwork

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if let data = artwork.imageData, let uiImage = UIImage(data: data) {
                    Color.clear
                        .overlay {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipShape(.rect(cornerRadius: 12))
                } else {
                    // Marcador de posición para obras creadas sin imagen real.
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color(hue: artwork.hue, saturation: 0.7, brightness: 0.95),
                                     Color(hue: (artwork.hue + 0.15).truncatingRemainder(dividingBy: 1),
                                           saturation: 0.8, brightness: 0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            Text(artwork.prompt)
                .font(.caption)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    GalleryView()
        .modelContainer(for: Artwork.self, inMemory: true)
}
