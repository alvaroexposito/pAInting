import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Convierte una imagen cualquiera en una página para colorear: contornos negros
/// gruesos sobre fondo blanco, sin grises, para que el relleno por zonas funcione.
enum LineArtConverter {
    /// Tamaño máximo del lado mayor. Limita la memoria y el coste del relleno.
    static let maxDimension: CGFloat = 1024

    private static let context = CIContext()

    static func lineArt(from data: Data) -> Data? {
        guard let input = CIImage(data: data, options: [.applyOrientationProperty: true]) else { return nil }
        let image = scaledToFit(input)
        let extent = image.extent

        // Contornos negros sobre transparente a partir de los bordes de la imagen.
        let outlines = CIFilter.lineOverlay()
        outlines.inputImage = image
        outlines.nrNoiseLevel = 0.07
        outlines.nrSharpness = 0.71
        outlines.edgeIntensity = 1
        outlines.threshold = 0.1
        outlines.contrast = 50
        guard let lines = outlines.outputImage else { return nil }

        let white = CIImage(color: .white).cropped(to: extent)
        let onWhite = lines.composited(over: white)

        // Binariza para que no queden grises que confundan al relleno.
        let threshold = CIFilter.colorThreshold()
        threshold.inputImage = onWhite
        threshold.threshold = 0.5
        guard let binary = threshold.outputImage else { return nil }

        // Engrosa las líneas (el mínimo expande el negro) para cerrar huecos pequeños.
        let thicken = CIFilter.morphologyMinimum()
        thicken.inputImage = binary
        thicken.radius = 1.5
        guard let thick = thicken.outputImage?.cropped(to: extent) else { return nil }

        guard let cgImage = context.createCGImage(thick, from: extent) else { return nil }
        return UIImage(cgImage: cgImage).pngData()
    }

    private static func scaledToFit(_ image: CIImage) -> CIImage {
        let longest = max(image.extent.width, image.extent.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return scaled.transformed(by: CGAffineTransform(translationX: -scaled.extent.minX, y: -scaled.extent.minY))
    }
}
