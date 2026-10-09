import Foundation
import SwiftData

/// Una obra generada y guardada en la galería.
@Model
final class Artwork {
    var id: UUID
    var prompt: String
    var createdAt: Date
    /// Tono (0...1) usado por la imagen de marcador de posición.
    var hue: Double
    /// Estado coloreado actual (PNG); es lo que se muestra en la galería.
    /// `nil` si la obra se creó sin imagen.
    @Attribute(.externalStorage) var imageData: Data?
    /// Silueta original para colorear (PNG, líneas negras sobre blanco).
    /// Delimita las zonas de relleno y permite volver a empezar.
    @Attribute(.externalStorage) var lineArtData: Data?

    init(
        id: UUID = UUID(),
        prompt: String,
        createdAt: Date = .now,
        hue: Double,
        imageData: Data? = nil,
        lineArtData: Data? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.createdAt = createdAt
        self.hue = hue
        self.imageData = imageData ?? lineArtData
        self.lineArtData = lineArtData
    }
}
