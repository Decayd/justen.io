import SwiftUI

// MARK: - Widget sizes

/// WidgetKit families, mirrored so shared views can be previewed inside the app.
enum WidgetSize: String, Codable, CaseIterable, Identifiable, Sendable {
    case small, medium, large, extraLarge, circular, rectangular, inline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra Large"
        case .circular: "Circular"
        case .rectangular: "Rectangular"
        case .inline: "Inline"
        }
    }

    var isAccessory: Bool { self == .circular || self == .rectangular || self == .inline }

    /// Home Screen sizes on a 6.1"/6.3" iPhone (iPad for extra large), in points.
    var nominalSize: CGSize {
        switch self {
        case .small: CGSize(width: 158, height: 158)
        case .medium: CGSize(width: 338, height: 158)
        case .large: CGSize(width: 338, height: 354)
        case .extraLarge: CGSize(width: 715, height: 330)
        case .circular: CGSize(width: 72, height: 72)
        case .rectangular: CGSize(width: 160, height: 72)
        case .inline: CGSize(width: 234, height: 26)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small, .medium, .large, .extraLarge: 22
        case .circular: 36
        case .rectangular: 12
        case .inline: 6
        }
    }

    /// Padding applied inside home screen widgets (content margins are handled by us).
    var padding: CGFloat {
        switch self {
        case .small: 14
        case .medium: 15
        case .large, .extraLarge: 16
        case .circular, .rectangular, .inline: 0
        }
    }

    static let homeScreen: [WidgetSize] = [.small, .medium, .large]
    static let lockScreen: [WidgetSize] = [.circular, .rectangular, .inline]
}

enum RenderStyle: Sendable {
    /// Normal colourful rendering.
    case fullColor
    /// Tinted / clear Home Screen: only opacity survives, accentable views get the tint.
    case accented
    /// Lock Screen and StandBy night mode: monochrome vibrancy.
    case vibrant
}

// MARK: - Themes

enum WidgetTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case auto, carbon, paper, glow, team

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: "Auto"
        case .carbon: "Carbon"
        case .paper: "Paper"
        case .glow: "Glow"
        case .team: "Livery"
        }
    }

    var subtitle: String {
        switch self {
        case .auto: "Follows Light and Dark Mode"
        case .carbon: "Deep charcoal"
        case .paper: "Clean and bright"
        case .glow: "Carbon with an accent glow"
        case .team: "Full team colours"
        }
    }
}

enum AccentStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case racingRed, team, purple, green, blue, gold, silver

    var id: String { rawValue }

    var title: String {
        switch self {
        case .racingRed: "Racing Red"
        case .team: "Team"
        case .purple: "Purple Sector"
        case .green: "Personal Best"
        case .blue: "Electric"
        case .gold: "Podium Gold"
        case .silver: "Silver Arrow"
        }
    }

    /// Fixed colour, or nil when the accent follows the team.
    var rgb: RGB? {
        switch self {
        case .racingRed: RGB(hex: "#E10600")
        case .team: nil
        case .purple: RGB(hex: "#A855F7")
        case .green: RGB(hex: "#22C55E")
        case .blue: RGB(hex: "#3B82F6")
        case .gold: RGB(hex: "#F5C542")
        case .silver: RGB(hex: "#C9D1DB")
        }
    }
}

// MARK: - Resolved palette

/// Concrete colours for one rendered widget.
struct WidgetPalette: Sendable {
    enum Background: Sendable {
        case carbon
        case paper
        case glow(RGB)
        case team(RGB)
        case none
    }

    var isDark: Bool
    var primary: Color
    var secondary: Color
    var tertiary: Color
    var hairline: Color
    var track: Color
    var card: Color
    var accentRGB: RGB
    var background: Background
    var renderStyle: RenderStyle

    var accent: Color { accentRGB.legible(onDark: isDark).color }

    /// True when the background itself is a team colour.
    var isLivery: Bool {
        if case .team = background { return true }
        return false
    }

    /// A team colour that stays legible on this palette's background.
    func team(_ rgb: RGB) -> Color {
        if isLivery { return primary }
        return rgb.legible(onDark: isDark).color
    }

    func team(_ constructorId: String?, season: Int? = nil) -> Color {
        team(TeamPalette.rgb(for: constructorId, season: season))
    }

    static let gold = Color(hex: "#F2C14E")
    static let silver = Color(hex: "#C7CED8")
    static let bronze = Color(hex: "#D08A54")
    static let purple = Color(hex: "#B65CFF")
    static let live = Color(hex: "#FF3B30")

    static func dark(accent: RGB, background: Background, style: RenderStyle = .fullColor) -> WidgetPalette {
        WidgetPalette(
            isDark: true,
            primary: .white,
            secondary: .white.opacity(0.64),
            tertiary: .white.opacity(0.4),
            hairline: .white.opacity(0.1),
            track: .white.opacity(0.1),
            card: .white.opacity(0.07),
            accentRGB: accent,
            background: background,
            renderStyle: style
        )
    }

    static func light(accent: RGB) -> WidgetPalette {
        let ink = Color(.sRGB, red: 0.05, green: 0.05, blue: 0.07, opacity: 1)
        return WidgetPalette(
            isDark: false,
            primary: ink,
            secondary: ink.opacity(0.6),
            tertiary: ink.opacity(0.38),
            hairline: ink.opacity(0.09),
            track: ink.opacity(0.07),
            card: ink.opacity(0.045),
            accentRGB: accent,
            background: .paper,
            renderStyle: .fullColor
        )
    }

    static func livery(_ team: RGB, accent: RGB) -> WidgetPalette {
        let ink = team.onColor
        let isDark = !team.isLight
        return WidgetPalette(
            isDark: isDark,
            primary: ink.color,
            secondary: ink.color.opacity(0.74),
            tertiary: ink.color.opacity(0.5),
            hairline: ink.color.opacity(0.16),
            track: ink.color.opacity(0.18),
            card: ink.color.opacity(0.12),
            accentRGB: ink,
            background: .team(team),
            renderStyle: .fullColor
        )
    }

    /// Resolves a design's theme for the current appearance and rendering mode.
    static func resolve(
        theme: WidgetTheme,
        accent: AccentStyle,
        teamRGB: RGB?,
        colorScheme: ColorScheme,
        renderStyle: RenderStyle
    ) -> WidgetPalette {
        let fallbackTeam = teamRGB ?? RGB(hex: "#E10600")
        let accentRGB = accent.rgb ?? fallbackTeam
        if renderStyle != .fullColor {
            return .dark(accent: accentRGB, background: .none, style: renderStyle)
        }
        switch theme {
        case .auto:
            return colorScheme == .dark ? .dark(accent: accentRGB, background: .carbon) : .light(accent: accentRGB)
        case .carbon:
            return .dark(accent: accentRGB, background: .carbon)
        case .paper:
            return .light(accent: accentRGB)
        case .glow:
            return .dark(accent: accentRGB, background: .glow(accentRGB))
        case .team:
            return .livery(fallbackTeam, accent: accentRGB)
        }
    }

    static let preview = WidgetPalette.dark(accent: RGB(hex: "#E10600"), background: .carbon)
}

private struct WidgetPaletteKey: EnvironmentKey {
    static let defaultValue = WidgetPalette.preview
}

extension EnvironmentValues {
    var palette: WidgetPalette {
        get { self[WidgetPaletteKey.self] }
        set { self[WidgetPaletteKey.self] = newValue }
    }
}

// MARK: - Backgrounds

struct WidgetBackgroundView: View {
    let palette: WidgetPalette

    var body: some View {
        switch palette.background {
        case .carbon:
            CarbonBackground()
        case .paper:
            LinearGradient(colors: [.white, Color(hex: "#ECEEF2")], startPoint: .top, endPoint: .bottom)
        case .glow(let rgb):
            ZStack {
                CarbonBackground()
                GeometryReader { proxy in
                    let radius = max(proxy.size.width, proxy.size.height)
                    RadialGradient(
                        colors: [rgb.color.opacity(0.55), rgb.color.opacity(0.12), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: radius
                    )
                    RadialGradient(
                        colors: [rgb.darker(0.2).color.opacity(0.28), .clear],
                        center: .bottomLeading,
                        startRadius: 0,
                        endRadius: radius * 0.7
                    )
                }
            }
        case .team(let rgb):
            ZStack {
                LinearGradient(
                    colors: [rgb.lighter(0.06).color, rgb.darker(0.32).color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LiveryStripes(color: rgb.onColor.color)
            }
        case .none:
            Color.clear
        }
    }
}

private struct CarbonBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#1D1E25"), Color(hex: "#0B0C10")], startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.white.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .center)
        }
    }
}

/// Subtle diagonal speed stripes for livery backgrounds.
private struct LiveryStripes: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            Path { path in
                for i in 0..<3 {
                    let x = w * (0.52 + CGFloat(i) * 0.14)
                    path.move(to: CGPoint(x: x, y: h))
                    path.addLine(to: CGPoint(x: x + h * 0.7, y: 0))
                }
            }
            .stroke(color.opacity(0.07), style: StrokeStyle(lineWidth: w * 0.07, lineCap: .butt))
        }
    }
}
