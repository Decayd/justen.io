import SwiftUI
import WidgetKit

// MARK: - Typography

enum Typo {
    /// Wide, heavy display type in the spirit of F1 broadcast graphics.
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.expanded)
    }

    /// Small all-caps labels.
    static func label(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).width(.expanded)
    }

    static func text(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }

    static func number(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).monospacedDigit()
    }

    /// Driver codes ("VER") and other tight uppercase tokens.
    static func code(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }
}

// MARK: - Labels

struct CapsLabel: View {
    let text: String
    var size: CGFloat = 9
    var color: Color?
    @Environment(\.palette) private var palette

    init(_ text: String, size: CGFloat = 9, color: Color? = nil) {
        self.text = text
        self.size = size
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(Typo.label(size))
            .tracking(size * 0.04)
            .foregroundStyle(color ?? palette.secondary)
            .lineLimit(1)
    }
}

struct FlagText: View {
    let flag: String
    var size: CGFloat = 13

    var body: some View {
        Text(flag)
            .font(.system(size: size))
            .fixedSize()
    }
}

// MARK: - Team and position marks

struct TeamStripe: View {
    let color: Color
    var width: CGFloat = 3
    var height: CGFloat?

    var body: some View {
        RoundedRectangle(cornerRadius: width / 2, style: .continuous)
            .fill(color)
            .frame(width: width, height: height)
            .widgetAccentable()
    }
}

struct PositionBadge: View {
    let position: Int
    var size: CGFloat = 18
    var podiumColors = true
    @Environment(\.palette) private var palette

    private var fill: Color {
        guard podiumColors, palette.renderStyle == .fullColor, !palette.isLivery else { return palette.card }
        switch position {
        case 1: return WidgetPalette.gold
        case 2: return WidgetPalette.silver
        case 3: return WidgetPalette.bronze
        default: return palette.card
        }
    }

    private var ink: Color {
        guard podiumColors, palette.renderStyle == .fullColor, !palette.isLivery, position <= 3 else {
            return palette.secondary
        }
        return Color(hex: "#15161B")
    }

    var body: some View {
        Text("\(position)")
            .font(Typo.number(size * 0.58, weight: .heavy))
            .foregroundStyle(ink)
            .frame(width: size, height: size)
            .background(fill, in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

/// A capsule bar showing a value relative to the leader.
struct PointsBar: View {
    let fraction: Double
    let color: Color
    var height: CGFloat = 6
    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { proxy in
            let clamped = CGFloat(min(max(fraction, 0), 1))
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(palette.track)
                Capsule(style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.7), color], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, proxy.size.width * clamped))
                    .widgetAccentable()
            }
        }
        .frame(height: height)
    }
}

/// Two segments in one bar, e.g. how a team's points split between its drivers.
struct SplitBar: View {
    let segments: [(value: Double, color: Color)]
    var total: Double
    var height: CGFloat = 6
    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                ForEach(Array(segments.enumerated()), id: \.offset) { item in
                    let width = total > 0 ? proxy.size.width * CGFloat(item.element.value / total) : 0
                    Capsule(style: .continuous)
                        .fill(item.element.color.opacity(item.offset == 0 ? 1 : 0.55))
                        .frame(width: max(0, width - 2))
                }
                Spacer(minLength: 0)
            }
            .background(Capsule(style: .continuous).fill(palette.track))
            .widgetAccentable()
        }
        .frame(height: height)
    }
}

struct SprintBadge: View {
    var compact = false
    @Environment(\.palette) private var palette

    var body: some View {
        Text(compact ? "S" : "SPRINT")
            .font(Typo.label(compact ? 8 : 7.5, weight: .heavy))
            .tracking(0.4)
            .foregroundStyle(palette.isDark ? Color.black : Color.white)
            .padding(.horizontal, compact ? 4 : 5)
            .padding(.vertical, 2)
            .background(palette.accent, in: Capsule())
            .widgetAccentable()
    }
}

struct LiveBadge: View {
    var text = "LIVE"
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 3) {
            Circle().fill(WidgetPalette.live).frame(width: 5, height: 5)
            Text(text)
                .font(Typo.label(8, weight: .heavy))
                .foregroundStyle(palette.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(WidgetPalette.live.opacity(0.18), in: Capsule())
        .widgetAccentable()
    }
}

/// A coloured chip for a race result: gold win, podium, points, no points, retirement.
struct ResultChip: View {
    let badge: ResultBadge
    var width: CGFloat = 26
    var height: CGFloat = 18
    @Environment(\.palette) private var palette

    private var fill: Color {
        if palette.renderStyle != .fullColor || palette.isLivery {
            switch badge.kind {
            case .win, .podium: return palette.primary.opacity(0.9)
            case .points: return palette.primary.opacity(0.45)
            case .finish: return palette.primary.opacity(0.18)
            case .retired: return palette.primary.opacity(0.08)
            }
        }
        switch badge.kind {
        case .win: return WidgetPalette.gold
        case .podium: return badge.position == 2 ? WidgetPalette.silver : WidgetPalette.bronze
        case .points: return Color(hex: "#2FBF71")
        case .finish: return palette.card
        case .retired: return WidgetPalette.live.opacity(0.22)
        }
    }

    private var ink: Color {
        if palette.renderStyle != .fullColor || palette.isLivery {
            switch badge.kind {
            case .win, .podium: return palette.isLivery ? (palette.isDark ? .black : .white) : .black
            default: return palette.primary
            }
        }
        switch badge.kind {
        case .win, .podium, .points: return Color(hex: "#111216")
        case .finish: return palette.secondary
        case .retired: return palette.isDark ? Color(hex: "#FF8A80") : Color(hex: "#C62828")
        }
    }

    var body: some View {
        Text(badge.position.map { "\($0)" } ?? badge.label)
            .font(Typo.number(badge.position == nil ? 7.5 : 10, weight: .heavy))
            .foregroundStyle(ink)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: width, height: height)
            .background(fill, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var valueSize: CGFloat = 18
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(Typo.display(valueSize, weight: .heavy))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            CapsLabel(label, size: 7.5, color: palette.tertiary)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Countdown

/// "3 DAYS 14 HRS" with big numerals and small units, as one scalable Text.
struct CountdownText: View {
    let countdown: Countdown
    var numberSize: CGFloat = 26
    var unitSize: CGFloat = 9
    @Environment(\.palette) private var palette

    var body: some View {
        switch countdown.phase {
        case .days(let days, let hours):
            pair(days, days == 1 ? "DAY" : "DAYS", hours, "HRS")
        case .hours(let hours, let minutes):
            pair(hours, hours == 1 ? "HR" : "HRS", minutes, "MIN")
        case .final:
            Text(timerInterval: countdown.now...max(countdown.now, countdown.start), countsDown: true)
                .font(Typo.number(numberSize, weight: .heavy).width(.expanded))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        case .live:
            HStack(spacing: 5) {
                Circle().fill(WidgetPalette.live).frame(width: numberSize * 0.3, height: numberSize * 0.3)
                Text("LIVE")
                    .font(Typo.display(numberSize * 0.8, weight: .black))
                    .foregroundStyle(palette.primary)
            }
            .widgetAccentable()
        case .finished:
            Text("DONE")
                .font(Typo.display(numberSize * 0.8, weight: .black))
                .foregroundStyle(palette.secondary)
        }
    }

    private func pair(_ a: Int, _ aUnit: String, _ b: Int, _ bUnit: String) -> some View {
        let text = b == 0
            ? number(a) + unit(" \(aUnit)")
            : number(a) + unit(" \(aUnit)  ") + number(b) + unit(" \(bUnit)")
        return text
            .foregroundStyle(palette.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
    }

    private func number(_ value: Int) -> Text {
        Text("\(value)").font(Typo.display(numberSize, weight: .heavy).monospacedDigit())
    }

    private func unit(_ value: String) -> Text {
        Text(value).font(Typo.label(unitSize, weight: .heavy))
    }
}

// MARK: - Podium

struct PodiumEntry: Hashable {
    var position: Int
    var code: String
    var team: RGB
    var detail: String?
}

/// Three podium blocks (2–1–3) in team colours.
struct PodiumView: View {
    let entries: [PodiumEntry]
    var codeSize: CGFloat = 12
    var showDetail = false
    @Environment(\.palette) private var palette

    var body: some View {
        GeometryReader { proxy in
            let labelHeight = codeSize + (showDetail ? 13 : 4)
            let maxBlock = max(0, proxy.size.height - labelHeight - 2)
            HStack(alignment: .bottom, spacing: 5) {
                block(entry(2), height: maxBlock * 0.72)
                block(entry(1), height: maxBlock)
                block(entry(3), height: maxBlock * 0.52)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func entry(_ position: Int) -> PodiumEntry? {
        entries.first { $0.position == position }
    }

    @ViewBuilder
    private func block(_ entry: PodiumEntry?, height: CGFloat) -> some View {
        VStack(spacing: 2) {
            if let entry {
                Text(entry.code)
                    .font(Typo.code(codeSize))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if showDetail, let detail = entry.detail {
                    Text(detail)
                        .font(Typo.number(8, weight: .semibold))
                        .foregroundStyle(palette.tertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            ZStack(alignment: .top) {
                UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 6, style: .continuous)
                    .fill(fill(for: entry))
                    .widgetAccentable()
                if let entry {
                    Text("\(entry.position)")
                        .font(Typo.display(min(22, max(10, height * 0.34)), weight: .black))
                        .foregroundStyle(ink(for: entry))
                        .padding(.top, 4)
                }
            }
            .frame(height: max(height, 8))
        }
        .frame(maxWidth: .infinity)
    }

    private func fill(for entry: PodiumEntry?) -> LinearGradient {
        guard let entry, palette.renderStyle == .fullColor, !palette.isLivery else {
            let base = palette.primary.opacity(entry == nil ? 0.1 : (entry!.position == 1 ? 0.9 : 0.55))
            return LinearGradient(colors: [base, base], startPoint: .top, endPoint: .bottom)
        }
        let rgb = entry.team.legible(onDark: palette.isDark)
        return LinearGradient(colors: [rgb.lighter(0.1).color, rgb.darker(0.25).color], startPoint: .top, endPoint: .bottom)
    }

    private func ink(for entry: PodiumEntry) -> Color {
        guard palette.renderStyle == .fullColor, !palette.isLivery else {
            return palette.isDark ? .black : .white
        }
        return entry.team.legible(onDark: palette.isDark).onColor.color.opacity(0.9)
    }
}

// MARK: - Empty state

struct WidgetMessage: View {
    let symbol: String
    let title: String
    let message: String
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(palette.accent)
                .widgetAccentable()
            Spacer(minLength: 0)
            Text(title)
                .font(Typo.display(13))
                .foregroundStyle(palette.primary)
            Text(message)
                .font(Typo.text(11, weight: .medium))
                .foregroundStyle(palette.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
