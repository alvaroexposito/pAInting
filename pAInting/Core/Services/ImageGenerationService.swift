import Foundation
import UIKit

struct GeneratedImage: Equatable {
    let prompt: String
    let hue: Double
    /// Silueta para colorear codificada en PNG (líneas negras sobre blanco).
    var imageData: Data? = nil
}

/// Contrato para el servicio que genera siluetas para colorear. Sustituye la
/// implementación simulada por una que llame a tu API de IA cuando la tengas.
protocol ImageGenerationService {
    func generate(prompt: String) async throws -> GeneratedImage
}

/// Implementación simulada: espera un instante y devuelve una silueta de ejemplo.
struct MockImageGenerationService: ImageGenerationService {
    var delay: Duration = .seconds(1)

    func generate(prompt: String) async throws -> GeneratedImage {
        try await Task.sleep(for: delay)
        let hue = Double(abs(prompt.hashValue) % 360) / 360
        return GeneratedImage(prompt: prompt, hue: hue, imageData: Self.sampleLineArt())
    }

    /// Dibujo sencillo (sol, casa y flor) con zonas cerradas para probar el coloreado.
    static func sampleLineArt(size: CGFloat = 512) -> Data? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))

            let s = size / 512
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * s, y: y * s, width: w * s, height: h * s)
            }
            let path = UIBezierPath()
            // Sol
            path.append(UIBezierPath(ovalIn: rect(370, 40, 100, 100)))
            // Casa
            path.append(UIBezierPath(rect: rect(80, 240, 220, 200)))
            let roof = UIBezierPath()
            roof.move(to: CGPoint(x: 60 * s, y: 240 * s))
            roof.addLine(to: CGPoint(x: 190 * s, y: 120 * s))
            roof.addLine(to: CGPoint(x: 320 * s, y: 240 * s))
            roof.close()
            path.append(roof)
            path.append(UIBezierPath(rect: rect(165, 340, 50, 100)))
            path.append(UIBezierPath(rect: rect(105, 270, 45, 45)))
            path.append(UIBezierPath(rect: rect(230, 270, 45, 45)))
            // Flor
            for angle in stride(from: 0.0, to: 360.0, by: 72.0) {
                let radians = angle * .pi / 180
                let cx = 400 + cos(radians) * 30, cy = 330 + sin(radians) * 30
                path.append(UIBezierPath(ovalIn: rect(cx - 22, cy - 22, 44, 44)))
            }
            path.append(UIBezierPath(ovalIn: rect(385, 315, 30, 30)))
            let stem = UIBezierPath()
            stem.move(to: CGPoint(x: 400 * s, y: 382 * s))
            stem.addLine(to: CGPoint(x: 400 * s, y: 470 * s))
            path.append(stem)
            // Suelo
            let ground = UIBezierPath()
            ground.move(to: CGPoint(x: 0, y: 440 * s))
            ground.addLine(to: CGPoint(x: size, y: 440 * s))
            path.append(ground)

            UIColor.black.setStroke()
            path.lineWidth = 6 * s
            path.stroke()
        }
        return image.pngData()
    }
}
