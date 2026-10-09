import SwiftUI
import SwiftData
import OSLog

/// Pantalla para colorear una silueta tocando las zonas con el color elegido.
struct ColoringView: View {
    let artwork: Artwork

    @Environment(\.scenePhase) private var scenePhase
    @State private var model: ColoringModel?
    @State private var loadFailed = false
    @State private var customColor: Color = .red
    @State private var isConfirmingClear = false

    var body: some View {
        Group {
            if let model {
                content(model)
            } else if loadFailed {
                ContentUnavailableView(
                    "Nothing to color",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("This artwork doesn't have an outline image.")
                )
            } else {
                ProgressView()
            }
        }
        .navigationTitle(artwork.prompt)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onDisappear { save() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { save() }
        }
    }

    @ViewBuilder
    private func content(_ model: ColoringModel) -> some View {
        VStack(spacing: 16) {
            canvas(model)
            palettePicker(model)
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Undo", systemImage: "arrow.uturn.backward") { model.undo() }
                    .disabled(!model.canUndo)
                    .accessibilityIdentifier("coloring.undo")
                Button("Clear", systemImage: "eraser") { isConfirmingClear = true }
                    .accessibilityIdentifier("coloring.clear")
            }
        }
        .confirmationDialog("Clear all colors?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button("Clear", role: .destructive) { model.clear() }
        }
    }

    private func canvas(_ model: ColoringModel) -> some View {
        Group {
            if let image = model.image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(model.pixelSize, contentMode: .fit)
                    .overlay {
                        GeometryReader { proxy in
                            Color.clear
                                .contentShape(.rect)
                                .onTapGesture { location in
                                    Task { await model.fill(at: location, in: proxy.size) }
                                }
                        }
                    }
                    .overlay {
                        if model.isFilling { ProgressView() }
                    }
                    .clipShape(.rect(cornerRadius: 12))
                    .shadow(radius: 2)
                    .accessibilityElement()
                    .accessibilityLabel(Text("Coloring canvas"))
                    .accessibilityHint(Text("Tap an area to fill it with the selected color."))
                    .accessibilityIdentifier("coloring.canvas")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func palettePicker(_ model: ColoringModel) -> some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Picker("Palette", selection: $model.selectedPalette) {
                    ForEach(ColorPalette.all) { palette in
                        Text(palette.name).tag(palette)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("coloring.palette")
                Spacer()
                ColorPicker("Custom color", selection: $customColor, supportsOpacity: false)
                    .labelsHidden()
                    .accessibilityIdentifier("coloring.customColor")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(model.selectedPalette.colors.enumerated()), id: \.offset) { index, paint in
                        SwatchButton(color: paint.color, isSelected: paint == model.selectedColor) {
                            model.selectedColor = paint
                        }
                        .accessibilityLabel(Text("Color \(index + 1)"))
                        .accessibilityIdentifier("coloring.color.\(index)")
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
        }
        .onChange(of: customColor) { _, newValue in
            model.selectedColor = PaintColor(UIColor(newValue))
        }
    }

    private func load() async {
        guard model == nil else { return }
        let lineArtData = artwork.lineArtData
        let imageData = artwork.imageData

        let canvas = await Task.detached(priority: .userInitiated) { () -> (ColoringCanvas, Data?)? in
            // Obras antiguas sin silueta: se genera a partir de la imagen guardada.
            var newLineArt: Data?
            let outline: Data
            if let lineArtData {
                outline = lineArtData
            } else if let imageData, let converted = LineArtConverter.lineArt(from: imageData) {
                outline = converted
                newLineArt = converted
            } else {
                return nil
            }
            guard let lineImage = UIImage(data: outline)?.cgImage else { return nil }
            let colored = lineArtData != nil ? imageData.flatMap { UIImage(data: $0)?.cgImage } : nil
            guard let canvas = ColoringCanvas(lineArt: lineImage, colored: colored) else { return nil }
            return (canvas, newLineArt)
        }.value

        guard let (canvas, newLineArt) = canvas else {
            Logger.app.error("Couldn't load coloring canvas for artwork \(artwork.id)")
            loadFailed = true
            return
        }
        if let newLineArt {
            artwork.lineArtData = newLineArt
        }
        model = ColoringModel(canvas: canvas)
    }

    private func save() {
        guard let model, model.hasChanges, let data = model.pngData() else { return }
        artwork.imageData = data
        model.markSaved()
    }
}

private struct SwatchButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay { Circle().strokeBorder(.secondary.opacity(0.4), lineWidth: 1) }
                .padding(3)
                .overlay {
                    if isSelected { Circle().strokeBorder(.tint, lineWidth: 3) }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    let container = try! ModelContainer(for: Artwork.self, configurations: .init(isStoredInMemoryOnly: true))
    let artwork = Artwork(prompt: "A happy cat", hue: 0.3, lineArtData: MockImageGenerationService.sampleLineArt())
    container.mainContext.insert(artwork)
    return NavigationStack {
        ColoringView(artwork: artwork)
    }
    .modelContainer(container)
}
