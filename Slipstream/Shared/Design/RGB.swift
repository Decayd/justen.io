import SwiftUI

/// A plain sRGB colour we can reason about (contrast, mixing) without UIKit.
struct RGB: Hashable, Codable, Sendable {
    var r: Double
    var g: Double
    var b: Double

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespaces))
        let value = UInt64(cleaned, radix: 16) ?? 0x808080
        self.init(
            r: Double((value >> 16) & 0xFF) / 255,
            g: Double((value >> 8) & 0xFF) / 255,
            b: Double(value & 0xFF) / 255
        )
    }

    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: 1) }

    var hex: String {
        String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
    }

    /// WCAG relative luminance.
    var luminance: Double {
        func channel(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    var isLight: Bool { luminance > 0.42 }

    func mixed(with other: RGB, _ amount: Double) -> RGB {
        RGB(r: r + (other.r - r) * amount, g: g + (other.g - g) * amount, b: b + (other.b - b) * amount)
    }

    func lighter(_ amount: Double) -> RGB { mixed(with: .white, amount) }
    func darker(_ amount: Double) -> RGB { mixed(with: .black, amount) }

    /// Nudges a team colour so it stays visible on the given background.
    func legible(onDark dark: Bool) -> RGB {
        if dark {
            return luminance < 0.06 ? lighter(0.45) : luminance < 0.12 ? lighter(0.25) : self
        }
        return luminance > 0.8 ? darker(0.35) : luminance > 0.6 ? darker(0.18) : self
    }

    /// Black or white, whichever reads better on top of this colour.
    var onColor: RGB { isLight ? RGB(r: 0.06, g: 0.06, b: 0.08) : .white }

    static let white = RGB(r: 1, g: 1, b: 1)
    static let black = RGB(r: 0, g: 0, b: 0)
}

extension Color {
    init(hex: String) {
        self = RGB(hex: hex).color
    }
}
