import SwiftUI
import WidgetKit

private struct InAppPreviewKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True when a widget view is drawn inside the app (Studio previews, snapshots).
    var isInAppPreview: Bool {
        get { self[InAppPreviewKey.self] }
        set { self[InAppPreviewKey.self] = newValue }
    }
}

/// The standard Lock Screen circle backdrop, simulated for in-app previews.
struct AccessoryCircleBackground: View {
    @Environment(\.isInAppPreview) private var isInAppPreview

    var body: some View {
        if isInAppPreview {
            Circle().fill(.white.opacity(0.16))
        } else {
            AccessoryWidgetBackground()
        }
    }
}

/// A circular gauge ring for Lock Screen widgets.
struct RingGauge: View {
    let fraction: Double
    var lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(fraction, 0.02), 1)))
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
        }
        .padding(lineWidth / 2)
    }
}
