import SwiftUI

/// Paleta de colores predefinida para colorear.
struct ColorPalette: Identifiable, Hashable {
    let id: String
    let name: LocalizedStringResource
    let colors: [PaintColor]

    init(id: String, name: LocalizedStringResource, hex: [UInt32]) {
        self.id = id
        self.name = name
        self.colors = hex.map(PaintColor.init(hex:))
    }

    static func == (lhs: ColorPalette, rhs: ColorPalette) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static let all: [ColorPalette] = [rainbow, pastel, nature, ocean, skin]

    static let rainbow = ColorPalette(id: "rainbow", name: "Rainbow", hex: [
        0xE53935, 0xFB8C00, 0xFDD835, 0x43A047, 0x1E88E5, 0x3949AB, 0x8E24AA, 0x6D4C41, 0x212121, 0xFFFFFF,
    ])

    static let pastel = ColorPalette(id: "pastel", name: "Pastel", hex: [
        0xF8BBD0, 0xFFCCBC, 0xFFF9C4, 0xC8E6C9, 0xB3E5FC, 0xC5CAE9, 0xE1BEE7, 0xD7CCC8, 0xFFFFFF,
    ])

    static let nature = ColorPalette(id: "nature", name: "Nature", hex: [
        0x1B5E20, 0x558B2F, 0x9CCC65, 0xFFEE58, 0xFFA726, 0x8D6E63, 0x5D4037, 0x81D4FA, 0xEF5350,
    ])

    static let ocean = ColorPalette(id: "ocean", name: "Ocean", hex: [
        0x01579B, 0x0288D1, 0x4FC3F7, 0xB2EBF2, 0x00897B, 0x80CBC4, 0xFFE0B2, 0xFF8A65, 0xFFFFFF,
    ])

    static let skin = ColorPalette(id: "skin", name: "Skin & hair", hex: [
        0xFFE0BD, 0xF1C27D, 0xE0AC69, 0xC68642, 0x8D5524, 0x5C3A1E, 0xFAF0BE, 0xB55239, 0x2C222B,
    ])
}

extension PaintColor {
    init(hex: UInt32) {
        self.init(red: UInt8((hex >> 16) & 0xFF), green: UInt8((hex >> 8) & 0xFF), blue: UInt8(hex & 0xFF))
    }

    var color: Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}
