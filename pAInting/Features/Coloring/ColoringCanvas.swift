import CoreGraphics
import UIKit

/// Color RGBA de 8 bits por canal, opaco.
struct PaintColor: Equatable, Hashable {
    var red: UInt8
    var green: UInt8
    var blue: UInt8

    init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(_ color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func byte(_ value: CGFloat) -> UInt8 { UInt8((min(max(value, 0), 1) * 255).rounded()) }
        self.init(red: byte(r), green: byte(g), blue: byte(b))
    }
}

/// Lienzo de una página para colorear. Las zonas se delimitan con la máscara de
/// líneas de la silueta original, así que volver a tocar una zona ya pintada la
/// recolorea entera aunque el color anterior sea oscuro.
struct ColoringCanvas: Equatable {
    let width: Int
    let height: Int
    /// `true` donde hay línea de la silueta. Nunca se pinta encima.
    let lineMask: [Bool]
    /// Píxeles RGBA (4 bytes por píxel, fila 0 arriba).
    private(set) var pixels: [UInt8]

    private static let bytesPerPixel = 4

    /// - Parameters:
    ///   - lineArt: silueta (líneas oscuras sobre fondo claro).
    ///   - colored: estado coloreado previo; si no coincide en tamaño se ignora.
    init?(lineArt: CGImage, colored: CGImage? = nil) {
        guard let base = Self.rgbaPixels(of: lineArt) else { return nil }
        width = lineArt.width
        height = lineArt.height
        lineMask = stride(from: 0, to: base.count, by: Self.bytesPerPixel).map { i in
            // Luminancia aproximada; por debajo de la mitad se considera línea.
            let luma = (Int(base[i]) * 299 + Int(base[i + 1]) * 587 + Int(base[i + 2]) * 114) / 1000
            return luma < 128
        }
        if let colored, colored.width == width, colored.height == height,
           let previous = Self.rgbaPixels(of: colored) {
            pixels = previous
        } else {
            pixels = base
        }
    }

    /// Rellena la zona cerrada que contiene el punto (en píxeles).
    /// - Returns: `false` si el punto está fuera, sobre una línea o la zona ya tenía ese color.
    @discardableResult
    mutating func fill(x: Int, y: Int, with color: PaintColor) -> Bool {
        guard x >= 0, y >= 0, x < width, y < height else { return false }
        let start = y * width + x
        guard !lineMask[start] else { return false }
        let o = start * Self.bytesPerPixel
        if pixels[o] == color.red, pixels[o + 1] == color.green, pixels[o + 2] == color.blue {
            return false
        }

        let width = width, height = height
        var visited = [Bool](repeating: false, count: width * height)
        var stack = [start]

        lineMask.withUnsafeBufferPointer { mask in
            visited.withUnsafeMutableBufferPointer { visited in
                pixels.withUnsafeMutableBufferPointer { px in
                    func isOpen(_ i: Int) -> Bool { !mask[i] && !visited[i] }

                    // Relleno por líneas de barrido: expande cada tramo horizontal y
                    // apila un punto por tramo abierto en las filas vecinas.
                    while let seed = stack.popLast() {
                        guard isOpen(seed) else { continue }
                        let row = seed / width * width
                        var left = seed, right = seed
                        while left > row, isOpen(left - 1) { left -= 1 }
                        while right < row + width - 1, isOpen(right + 1) { right += 1 }

                        for i in left...right {
                            visited[i] = true
                            let p = i * 4
                            px[p] = color.red
                            px[p + 1] = color.green
                            px[p + 2] = color.blue
                            px[p + 3] = 255
                        }

                        let y = seed / width
                        for neighborRow in [y - 1, y + 1] where neighborRow >= 0 && neighborRow < height {
                            let offset = (neighborRow - y) * width
                            var inSpan = false
                            for i in left...right {
                                if isOpen(i + offset) {
                                    if !inSpan { stack.append(i + offset); inSpan = true }
                                } else {
                                    inSpan = false
                                }
                            }
                        }
                    }
                }
            }
        }
        return true
    }

    /// Vuelve a la silueta sin colorear.
    mutating func clear() {
        for (index, isLine) in lineMask.enumerated() {
            let p = index * Self.bytesPerPixel
            let value: UInt8 = isLine ? 0 : 255
            pixels[p] = value
            pixels[p + 1] = value
            pixels[p + 2] = value
            pixels[p + 3] = 255
        }
    }

    /// Restaura un estado guardado (para deshacer).
    mutating func restore(_ snapshot: [UInt8]) {
        guard snapshot.count == pixels.count else { return }
        pixels = snapshot
    }

    func color(atX x: Int, y: Int) -> PaintColor? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        let p = (y * width + x) * Self.bytesPerPixel
        return PaintColor(red: pixels[p], green: pixels[p + 1], blue: pixels[p + 2])
    }

    func makeCGImage() -> CGImage? {
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(
            width: width, height: height,
            bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * Self.bytesPerPixel,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )
    }

    /// Dibuja la imagen en un búfer RGBA opaco (fondo blanco bajo la transparencia).
    private static func rgbaPixels(of image: CGImage) -> [UInt8]? {
        let width = image.width, height = image.height
        var buffer = [UInt8](repeating: 255, count: width * height * bytesPerPixel)
        let drawn = buffer.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(
                data: raw.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * bytesPerPixel,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? buffer : nil
    }
}
