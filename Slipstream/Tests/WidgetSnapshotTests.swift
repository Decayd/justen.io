import SwiftUI
import XCTest
@testable import Slipstream

/// Renders every widget design to PNG contact sheets for visual review.
/// Set SNAPSHOT_DIR (or TEST_RUNNER_SNAPSHOT_DIR with xcodebuild) to choose the output folder.
@MainActor
final class WidgetSnapshotTests: XCTestCase {
    private let snapshot = SampleData.snapshot()
    private lazy var stats = SeasonStats(snapshot: snapshot)

    private var outputDirectory: URL {
        let path = ProcessInfo.processInfo.environment["SNAPSHOT_DIR"]
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("slipstream-snapshots").path
        let url = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testRenderWidgetGallery() throws {
        for content in WidgetContent.allCases {
            for scheme in [ColorScheme.dark, .light] {
                let design = WidgetDesign(content: content, theme: .auto, accent: .racingRed)
                try render(GallerySheet(design: design, snapshot: snapshot, stats: stats), scheme: scheme,
                           name: "\(content.rawValue)-\(scheme == .dark ? "dark" : "light")")
            }
        }
    }

    func testRenderThemeVariants() throws {
        let variants: [(String, WidgetDesign)] = [
            ("driver-livery", WidgetDesign(content: .driver, driverId: "max_verstappen")),
            ("team-livery", WidgetDesign(content: .team, constructorId: "ferrari")),
            ("nextRace-glow", WidgetDesign(content: .nextRace, theme: .glow, accent: .purple)),
            ("driverStandings-glow", WidgetDesign(content: .driverStandings, theme: .glow, accent: .blue)),
            ("titleFight-paper", WidgetDesign(content: .titleFight, theme: .paper, accent: .racingRed)),
        ]
        for (name, design) in variants {
            try render(GallerySheet(design: design, snapshot: snapshot, stats: stats), scheme: .dark, name: name)
        }
    }

    private func render<V: View>(_ view: V, scheme: ColorScheme, name: String) throws {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, scheme))
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.uiImage, "Rendering \(name) failed")
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: outputDirectory.appendingPathComponent("\(name).png"))
    }
}

/// Every size of one design on a single sheet.
private struct GallerySheet: View {
    let design: WidgetDesign
    let snapshot: SeasonSnapshot
    let stats: SeasonStats
    @Environment(\.colorScheme) private var colorScheme

    private func canvas(_ size: WidgetSize) -> some View {
        WidgetCanvas(design: design, snapshot: snapshot, stats: stats, size: size, now: SampleData.referenceDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("\(design.content.title) · \(design.theme.title) · \(colorScheme == .dark ? "Dark" : "Light")")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
            HStack(alignment: .top, spacing: 20) {
                canvas(.small)
                canvas(.medium)
            }
            HStack(alignment: .top, spacing: 20) {
                canvas(.large)
                VStack(alignment: .leading, spacing: 16) {
                    canvas(.circular)
                    canvas(.rectangular)
                    canvas(.inline)
                        .font(.system(size: 15, weight: .medium))
                }
                .padding(18)
                .background(
                    LinearGradient(colors: [Color(hex: "#273055"), Color(hex: "#0B0D18")], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
            }
            canvas(.extraLarge)
        }
        .padding(24)
        .frame(width: 790, alignment: .leading)
        .background(colorScheme == .dark ? Color(hex: "#2A2B31") : Color(hex: "#D9DBE1"))
    }
}
