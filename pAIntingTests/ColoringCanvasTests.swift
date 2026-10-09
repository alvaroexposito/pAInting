import Testing
import UIKit
@testable import pAInting

struct ColoringCanvasTests {
    private let red = PaintColor(red: 255, green: 0, blue: 0)
    private let blue = PaintColor(red: 0, green: 0, blue: 255)
    private let white = PaintColor(red: 255, green: 255, blue: 255)

    private func sampleImage() throws -> CGImage {
        let data = try #require(MockImageGenerationService.sampleLineArt())
        return try #require(UIImage(data: data)?.cgImage)
    }

    private func makeCanvas() throws -> ColoringCanvas {
        try #require(ColoringCanvas(lineArt: try sampleImage()))
    }

    @Test func fillStaysInsideClosedRegion() throws {
        var canvas = try makeCanvas()
        // Interior del sol (círculo centrado en 420, 90).
        let filled = canvas.fill(x: 420, y: 90, with: red)
        #expect(filled)
        #expect(canvas.color(atX: 420, y: 90) == red)
        // El cielo, fuera del sol, sigue blanco.
        #expect(canvas.color(atX: 20, y: 20) == white)
    }

    @Test func refillingRecolorsWholeRegion() throws {
        var canvas = try makeCanvas()
        canvas.fill(x: 420, y: 90, with: red)
        let recolored = canvas.fill(x: 420, y: 90, with: blue)
        #expect(recolored)
        #expect(canvas.color(atX: 400, y: 80) == blue)
        // Mismo color otra vez: no hay cambios.
        let repeated = canvas.fill(x: 420, y: 90, with: blue)
        #expect(!repeated)
    }

    @Test func tapOnLineOrOutsideDoesNothing() throws {
        var canvas = try makeCanvas()
        let outsideLeft = canvas.fill(x: -1, y: 10, with: red)
        let outsideRight = canvas.fill(x: canvas.width, y: 10, with: red)
        // Borde izquierdo de la casa (línea vertical en x = 80).
        let onLine = canvas.fill(x: 80, y: 300, with: red)
        #expect(!outsideLeft)
        #expect(!outsideRight)
        #expect(!onLine)
    }

    @Test func clearRestoresOutline() throws {
        var canvas = try makeCanvas()
        canvas.fill(x: 20, y: 20, with: blue)
        canvas.clear()
        #expect(canvas.color(atX: 20, y: 20) == white)
        #expect(canvas.makeCGImage() != nil)
    }

    @Test func restoresPreviousColoredState() throws {
        var canvas = try makeCanvas()
        canvas.fill(x: 420, y: 90, with: red)
        let colored = try #require(canvas.makeCGImage())
        let reloaded = try #require(ColoringCanvas(lineArt: try sampleImage(), colored: colored))
        #expect(reloaded.color(atX: 420, y: 90) == red)
    }

    @Test func converterProducesBlackAndWhiteImage() throws {
        let data = try #require(MockImageGenerationService.sampleLineArt())
        let output = try #require(LineArtConverter.lineArt(from: data))
        let image = try #require(UIImage(data: output)?.cgImage)
        let canvas = try #require(ColoringCanvas(lineArt: image))
        let lines = canvas.lineMask.filter { $0 }.count
        #expect(lines > 0)
        #expect(lines < canvas.lineMask.count / 2)
    }
}
