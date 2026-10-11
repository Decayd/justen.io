import Observation
import SwiftUI
import WidgetKit

enum AppTab: Hashable {
    case home, standings, calendar, studio
}

enum Route: Hashable {
    /// A driver page; `season` is nil for the current season.
    case driver(String, season: Int? = nil)
    case team(String, season: Int? = nil)
    case race(season: Int, round: Int)
}

@MainActor
@Observable
final class AppModel {
    private(set) var snapshot: SeasonSnapshot? = nil
    private(set) var stats: SeasonStats? = nil
    private(set) var isRefreshing = false
    private(set) var lastError: String? = nil
    private(set) var designs: [WidgetDesign] = []
    private(set) var settings = AppSettings.load()
    private var archives: [Int: SeasonSnapshot] = [:]

    var selectedTab: AppTab = .home
    var homePath: [Route] = []
    var standingsPath: [Route] = []
    var calendarPath: [Route] = []
    var standingsSegment: StandingsSegment = .drivers

    /// Previews fall back to the illustrative season until real data arrives.
    var previewSnapshot: SeasonSnapshot { snapshot ?? Self.sample }
    var previewStats: SeasonStats { stats ?? Self.sampleStats }
    var isShowingSampleData: Bool { snapshot == nil }

    private static let sample = SampleData.snapshot(now: Date())
    private static let sampleStats = SeasonStats(snapshot: sample)

    /// Tests and screenshots run against the illustrative season, offline.
    let usesSampleData = ProcessInfo.processInfo.arguments.contains("-SlipstreamSampleData")
        || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init() {
        let cached = usesSampleData ? SampleData.snapshot(now: Date()) : SnapshotStore.cachedSnapshot()
        snapshot = cached
        stats = cached.map { SeasonStats(snapshot: $0) }
        designs = usesSampleData ? [] : DesignStore.load()
    }

    // MARK: Data

    func refresh(force: Bool = false) async {
        guard !isRefreshing, !usesSampleData else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let fresh: SeasonSnapshot
            if force || snapshot == nil {
                fresh = try await SnapshotStore.shared.refresh()
            } else if let current = await SnapshotStore.shared.snapshot(maxAge: 30 * 60) {
                fresh = current
            } else {
                fresh = try await SnapshotStore.shared.refresh()
            }
            let changed = fresh != snapshot
            snapshot = fresh
            stats = SeasonStats(snapshot: fresh)
            lastError = nil
            if changed { WidgetCenter.shared.reloadAllTimelines() }
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// The current season, or a past season's archive.
    func season(_ year: Int) async throws -> SeasonSnapshot {
        if let snapshot, snapshot.standingsSeason == year { return snapshot }
        if let cached = archives[year] { return cached }
        let archive = try await SnapshotStore.shared.archive(season: year)
        archives[year] = archive
        return archive
    }

    // MARK: Designs

    func save(_ design: WidgetDesign) {
        var updated = design
        updated.updatedAt = Date()
        if let index = designs.firstIndex(where: { $0.id == design.id }) {
            designs[index] = updated
        } else {
            designs.insert(updated, at: 0)
        }
        persistDesigns()
    }

    func delete(_ design: WidgetDesign) {
        designs.removeAll { $0.id == design.id }
        persistDesigns()
    }

    func duplicate(_ design: WidgetDesign) {
        var copy = design
        copy.id = UUID()
        copy.name = "\(design.name) copy"
        copy.createdAt = Date()
        save(copy)
    }

    private func persistDesigns() {
        DesignStore.save(designs)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Settings

    func update(_ change: (inout AppSettings) -> Void) {
        var copy = settings
        change(&copy)
        guard copy != settings else { return }
        settings = copy
        copy.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Deep links

    func open(_ url: URL) {
        guard url.scheme == "slipstream" else { return }
        var parts: [String] = []
        if let host = url.host() { parts.append(host) }
        parts += url.pathComponents.filter { $0 != "/" }
        switch parts.first {
        case "calendar":
            selectedTab = .calendar
        case "results":
            if let race = snapshot?.latestRace {
                selectedTab = .calendar
                calendarPath = [.race(season: race.season, round: race.round)]
            } else {
                selectedTab = .calendar
            }
        case "standings":
            selectedTab = .standings
            standingsPath = []
            standingsSegment = parts.dropFirst().first == "constructors" ? .constructors : .drivers
        case "driver":
            selectedTab = .standings
            if let id = parts.dropFirst().first { standingsPath = [.driver(id)] }
        case "team":
            selectedTab = .standings
            if let id = parts.dropFirst().first { standingsPath = [.team(id)] }
        default:
            selectedTab = .home
        }
    }
}

enum StandingsSegment: String, CaseIterable, Identifiable {
    case drivers, constructors
    var id: String { rawValue }
    var title: String { self == .drivers ? "Drivers" : "Constructors" }
}
