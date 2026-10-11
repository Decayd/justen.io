import SwiftUI
import WidgetKit

struct SlipstreamEntry: TimelineEntry {
    let date: Date
    let snapshot: SeasonSnapshot?
    let design: WidgetDesign
    let settings: AppSettings
    var isSample = false
}

extension WidgetSize {
    init(_ family: WidgetFamily) {
        switch family {
        case .systemSmall: self = .small
        case .systemMedium: self = .medium
        case .systemLarge: self = .large
        case .systemExtraLarge: self = .extraLarge
        case .accessoryCircular: self = .circular
        case .accessoryRectangular: self = .rectangular
        case .accessoryInline: self = .inline
        @unknown default: self = .small
        }
    }
}

extension RenderStyle {
    init(_ mode: WidgetRenderingMode) {
        if mode == .accented {
            self = .accented
        } else if mode == .vibrant {
            self = .vibrant
        } else {
            self = .fullColor
        }
    }
}

/// Builds entries and reload policies shared by every widget kind.
enum TimelineFactory {
    static func placeholder(design: WidgetDesign) -> SlipstreamEntry {
        SlipstreamEntry(date: Date(), snapshot: SampleData.snapshot(now: Date()), design: design, settings: AppSettings(), isSample: true)
    }

    /// Gallery previews must be instant: use cached data, or the sample season.
    static func preview(design: WidgetDesign, isPreview: Bool) async -> SlipstreamEntry {
        let settings = AppSettings.load()
        if let cached = SnapshotStore.cachedSnapshot() {
            return SlipstreamEntry(date: Date(), snapshot: cached, design: design, settings: settings)
        }
        if !isPreview, let fresh = await SnapshotStore.shared.snapshot(maxAge: 6 * 3600) {
            return SlipstreamEntry(date: Date(), snapshot: fresh, design: design, settings: settings)
        }
        return SlipstreamEntry(date: Date(), snapshot: SampleData.snapshot(now: Date()), design: design, settings: settings, isSample: true)
    }

    static func timeline(design: WidgetDesign) async -> Timeline<SlipstreamEntry> {
        let now = Date()
        let cached = SnapshotStore.cachedSnapshot()
        let maxAge = WidgetSchedule.refreshInterval(now: now, snapshot: cached)
        let snapshot = await SnapshotStore.shared.snapshot(maxAge: maxAge, now: now)
        let settings = AppSettings.load()

        let entries = WidgetSchedule.entryDates(now: now, snapshot: snapshot, design: design).map {
            SlipstreamEntry(date: $0, snapshot: snapshot, design: design, settings: settings)
        }
        return Timeline(entries: entries, policy: .after(WidgetSchedule.nextReload(now: now, snapshot: snapshot)))
    }
}

/// The view every widget kind renders.
struct SlipstreamWidgetView: View {
    let entry: SlipstreamEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showsWidgetContainerBackground) private var showsBackground

    var body: some View {
        let size = WidgetSize(family)
        if let snapshot = entry.snapshot {
            let context = WidgetRenderContext.make(
                design: entry.design,
                snapshot: snapshot,
                size: size,
                now: entry.date,
                renderStyle: RenderStyle(renderingMode),
                colorScheme: colorScheme,
                settings: entry.settings,
                showsBackground: showsBackground
            )
            WidgetContentView(context: context)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView(palette: context.palette)
                }
                .widgetURL(entry.design.deepLink)
        } else {
            NoDataView(size: size)
                .environment(\.palette, .preview)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView(palette: .preview)
                }
        }
    }
}
