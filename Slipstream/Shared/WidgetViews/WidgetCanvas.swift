import SwiftUI

extension WidgetDesign {
    /// Where tapping the widget takes you in the app.
    var deepLink: URL {
        let path: String
        switch content {
        case .nextRace, .calendar: path = "calendar"
        case .driverStandings: path = "standings/drivers"
        case .constructorStandings: path = "standings/constructors"
        case .lastRace: path = "results"
        case .driver: path = driverId.map { "driver/\($0)" } ?? "standings/drivers"
        case .team: path = constructorId.map { "team/\($0)" } ?? "standings/constructors"
        case .titleFight: path = "standings/drivers"
        }
        return URL(string: "slipstream://\(path)")!
    }
}

/// Draws a design exactly as the widget renders it: used by the Studio and by snapshot tests.
struct WidgetCanvas: View {
    let design: WidgetDesign
    let snapshot: SeasonSnapshot
    var stats: SeasonStats?
    let size: WidgetSize
    var now = Date()
    var settings = AppSettings()
    var renderStyle: RenderStyle = .fullColor
    var dimensions: CGSize?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let context = WidgetRenderContext.make(
            design: design,
            snapshot: snapshot,
            stats: stats,
            size: size,
            now: now,
            renderStyle: renderStyle,
            colorScheme: colorScheme,
            settings: settings
        )
        let frame = dimensions ?? size.nominalSize
        Group {
            if size.isAccessory {
                WidgetContentView(context: context)
                    .foregroundStyle(.white)
                    .frame(width: frame.width, height: frame.height, alignment: size == .inline ? .leading : .center)
                    .environment(\.colorScheme, .dark)
            } else {
                WidgetContentView(context: context)
                    .frame(width: frame.width, height: frame.height)
                    .background {
                        if renderStyle == .fullColor {
                            WidgetBackgroundView(palette: context.palette)
                        } else {
                            Rectangle().fill(.ultraThinMaterial)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            }
        }
        .environment(\.isInAppPreview, true)
    }
}
