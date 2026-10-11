import SwiftUI

extension WidgetPalette {
    /// The palette app screens use, matching the widgets' look.
    static func app(_ scheme: ColorScheme) -> WidgetPalette {
        let red = RGB(hex: "#E10600")
        return scheme == .dark ? .dark(accent: red, background: .carbon) : .light(accent: red)
    }
}

enum AppColors {
    static let red = Color(hex: "#E10600")
}

/// Rounded content card on grouped backgrounds.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// "DRIVERS' STANDINGS                         See all ›"
struct SectionTitle<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(Typo.label(11, weight: .heavy))
                .tracking(0.5)
                .foregroundStyle(.secondary)
            Spacer()
            trailing
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 4)
    }
}

extension SectionTitle where Trailing == EmptyView {
    init(_ title: String) {
        self.title = title
        self.trailing = EmptyView()
    }
}

/// A dark, glowing hero card used for the next race.
struct HeroBackground: View {
    var accent: Color = AppColors.red

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#1E1F27"), Color(hex: "#0B0C10")], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [accent.opacity(0.5), accent.opacity(0.08), .clear], center: .topTrailing, startRadius: 0, endRadius: 360)
        }
    }
}

struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Typo.display(22, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(Typo.label(9, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Ticking countdown with day / hour / minute / second boxes.
struct LiveCountdown: View {
    let target: Date
    var compact = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let remaining = max(0, Int(target.timeIntervalSince(timeline.date)))
            HStack(spacing: compact ? 6 : 8) {
                unit(remaining / 86_400, "Days")
                unit((remaining % 86_400) / 3600, "Hrs")
                unit((remaining % 3600) / 60, "Min")
                unit(remaining % 60, "Sec")
            }
        }
    }

    private func unit(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%02d", value))
                .font(Typo.display(compact ? 18 : 24, weight: .heavy).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
            Text(label.uppercased())
                .font(Typo.label(8, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(minWidth: compact ? 44 : 54)
        .padding(.vertical, compact ? 6 : 8)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Shown above content while it is illustrative sample data.
struct SampleDataBanner: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.isShowingSampleData {
            HStack(spacing: 10) {
                Image(systemName: model.isRefreshing ? "arrow.triangle.2.circlepath" : "wifi.exclamationmark")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.isRefreshing ? "Loading live data…" : "Showing sample data")
                        .font(.subheadline.weight(.semibold))
                    Text(model.lastError ?? "Previews use an illustrative season until the latest standings download.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !model.isRefreshing {
                    Button("Retry") { Task { await model.refresh(force: true) } }
                        .buttonStyle(.bordered)
                }
            }
            .padding(14)
            .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

/// Empty / loading state for data-driven screens.
struct LoadingState: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 14) {
            if model.isRefreshing {
                ProgressView()
                Text("Loading the latest F1 data…")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "wifi.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Couldn't load F1 data")
                    .font(.headline)
                if let error = model.lastError {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button("Try again") { Task { await model.refresh(force: true) } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .padding()
    }
}

struct DataFooter: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 4) {
            if let fetched = model.snapshot?.fetchedAt {
                Text("Updated \(Fmt.relativeAge(fetched))")
            }
            Text("Data: Jolpica-F1 (Ergast compatible). Not affiliated with Formula 1.")
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
