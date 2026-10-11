import SwiftUI
import WidgetKit

/// A circuit outline from the bundled `circuits.json`
/// (generated from bacinger/f1-circuits, MIT License, by `tools/build_circuits.py`).
struct CircuitOutline: Decodable, Sendable {
    let key: String
    let ids: [String]
    let name: String
    let locality: String
    let length: Int?
    let firstGP: Int?
    /// Normalised bounding box; the longest side is 1.
    let w: Double
    let h: Double
    /// Flattened x, y pairs inside the bounding box.
    let p: [Double]

    var points: [CGPoint] {
        stride(from: 0, to: p.count - 1, by: 2).map { CGPoint(x: p[$0], y: p[$0 + 1]) }
    }

    /// "4.928 km"
    var lengthText: String? {
        guard let length else { return nil }
        return String(format: "%.3f km", Double(length) / 1000)
    }
}

enum CircuitCatalog {
    private struct File: Decodable {
        let circuits: [CircuitOutline]
    }

    static let all: [CircuitOutline] = {
        guard let url = Bundle.main.url(forResource: "circuits", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        return file.circuits
    }()

    private static let byID: [String: CircuitOutline] = {
        var map: [String: CircuitOutline] = [:]
        for outline in all {
            for id in outline.ids { map[id] = outline }
        }
        return map
    }()

    static func outline(for circuit: Circuit) -> CircuitOutline? {
        if let match = byID[circuit.id] { return match }
        return all.first { $0.locality.caseInsensitiveCompare(circuit.locality) == .orderedSame }
    }
}

/// Fits an outline into a rectangle, turning it 90° when that draws it noticeably larger.
private struct TrackTransform {
    let scale: CGFloat
    let origin: CGPoint
    let rotated: Bool
    let height: CGFloat

    init(outline: CircuitOutline, rect: CGRect) {
        let w = CGFloat(max(outline.w, 0.0001))
        let h = CGFloat(max(outline.h, 0.0001))
        let upright = min(rect.width / w, rect.height / h)
        let turned = min(rect.width / h, rect.height / w)
        rotated = turned > upright * 1.15
        scale = rotated ? turned : upright
        let drawnW = (rotated ? h : w) * scale
        let drawnH = (rotated ? w : h) * scale
        origin = CGPoint(x: rect.midX - drawnW / 2, y: rect.midY - drawnH / 2)
        height = h
    }

    func apply(_ point: CGPoint) -> CGPoint {
        let local = rotated ? CGPoint(x: height - point.y, y: point.x) : point
        return CGPoint(x: origin.x + local.x * scale, y: origin.y + local.y * scale)
    }
}

struct TrackShape: Shape {
    let outline: CircuitOutline
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let transform = TrackTransform(outline: outline, rect: rect.insetBy(dx: inset, dy: inset))
        let points = outline.points
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: transform.apply(first))
        for point in points.dropFirst() {
            path.addLine(to: transform.apply(point))
        }
        path.closeSubpath()
        return path
    }
}

/// A dot on the start/finish line.
struct TrackStartMarker: Shape {
    let outline: CircuitOutline
    var inset: CGFloat = 0
    var radius: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        let transform = TrackTransform(outline: outline, rect: rect.insetBy(dx: inset, dy: inset))
        guard let first = outline.points.first else { return Path() }
        let center = transform.apply(first)
        return Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }
}

struct TrackMapView: View {
    let circuit: Circuit
    var color: Color
    var lineWidth: CGFloat = 2.5
    var glow = true
    var showStart = true
    @Environment(\.palette) private var palette

    var body: some View {
        if let outline = CircuitCatalog.outline(for: circuit) {
            let inset = lineWidth * 1.5
            ZStack {
                if glow && palette.renderStyle == .fullColor {
                    TrackShape(outline: outline, inset: inset)
                        .stroke(color.opacity(palette.isDark ? 0.5 : 0.22), style: StrokeStyle(lineWidth: lineWidth * 3, lineCap: .round, lineJoin: .round))
                        .blur(radius: lineWidth * 1.4)
                }
                TrackShape(outline: outline, inset: inset)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .widgetAccentable()
                if showStart {
                    TrackStartMarker(outline: outline, inset: inset, radius: max(1.8, lineWidth * 1.1))
                        .fill(palette.primary)
                }
            }
        } else {
            Image(systemName: "flag.checkered")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color.opacity(0.7))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
