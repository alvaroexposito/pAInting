import SwiftUI
import OSLog

/// Estado de la pantalla de coloreado: lienzo, historial para deshacer y color activo.
@MainActor
@Observable
final class ColoringModel {
    private(set) var image: UIImage?
    private(set) var isFilling = false
    private(set) var hasChanges = false
    var selectedColor: PaintColor = ColorPalette.rainbow.colors[0]
    var selectedPalette: ColorPalette = .rainbow

    private var canvas: ColoringCanvas
    private var history: [[UInt8]] = []
    /// Cada estado ocupa ~4 MB a 1024×1024; se limita para no disparar la memoria.
    private let maxHistory = 15

    var canUndo: Bool { !history.isEmpty }
    var pixelSize: CGSize { CGSize(width: canvas.width, height: canvas.height) }

    init(canvas: ColoringCanvas) {
        self.canvas = canvas
        image = Self.render(canvas)
    }

    /// Rellena la zona tocada. `point` está en el sistema de coordenadas de una
    /// vista de tamaño `viewSize` que muestra la imagen completa.
    func fill(at point: CGPoint, in viewSize: CGSize) async {
        guard !isFilling, viewSize.width > 0, viewSize.height > 0 else { return }
        let x = Int(point.x / viewSize.width * CGFloat(canvas.width))
        let y = Int(point.y / viewSize.height * CGFloat(canvas.height))
        let color = selectedColor
        let current = canvas

        isFilling = true
        defer { isFilling = false }

        // El relleno recorre hasta un millón de píxeles: fuera del hilo principal.
        let result = await Task.detached(priority: .userInitiated) { () -> (ColoringCanvas, UIImage?)? in
            var updated = current
            guard updated.fill(x: x, y: y, with: color) else { return nil }
            return (updated, Self.render(updated))
        }.value

        guard let (updated, rendered) = result else { return }
        pushHistory(canvas.pixels)
        canvas = updated
        image = rendered
        hasChanges = true
    }

    func undo() {
        guard let previous = history.popLast() else { return }
        canvas.restore(previous)
        image = Self.render(canvas)
        hasChanges = true
    }

    func clear() {
        pushHistory(canvas.pixels)
        canvas.clear()
        image = Self.render(canvas)
        hasChanges = true
    }

    func pngData() -> Data? {
        image?.pngData()
    }

    func markSaved() {
        hasChanges = false
    }

    private func pushHistory(_ pixels: [UInt8]) {
        history.append(pixels)
        if history.count > maxHistory { history.removeFirst() }
    }

    nonisolated private static func render(_ canvas: ColoringCanvas) -> UIImage? {
        canvas.makeCGImage().map { UIImage(cgImage: $0) }
    }
}
