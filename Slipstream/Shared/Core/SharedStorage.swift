import Foundation

/// Locations shared between the app and its widget extension.
enum SharedStorage {
    static let appGroupID = "group.io.justen.slipstream"

    /// The App Group container, or the app's own caches directory when the
    /// group is unavailable (unsigned simulator builds, missing entitlement).
    static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url
        }
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func fileURL(_ name: String) -> URL {
        containerURL.appendingPathComponent(name, isDirectory: false)
    }

    static func read<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        guard let data = try? Data(contentsOf: fileURL(name)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(T.self, from: data)
    }

    static func write<T: Encodable>(_ value: T, to name: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(value)
        try data.write(to: fileURL(name), options: .atomic)
    }
}

/// Loads, caches and refreshes the season snapshot. Used by both the app and the widgets.
actor SnapshotStore {
    static let shared = SnapshotStore()

    private static let fileName = "season-snapshot.json"
    private let client: JolpicaClient
    private var memory: SeasonSnapshot?
    private var inFlight: Task<SeasonSnapshot, Error>?

    init(client: JolpicaClient = .shared) {
        self.client = client
    }

    /// The last saved snapshot, read synchronously (used by widget placeholders and intents).
    nonisolated static func cachedSnapshot() -> SeasonSnapshot? {
        guard let snapshot = SharedStorage.read(SeasonSnapshot.self, from: fileName),
              snapshot.version == SeasonSnapshot.currentVersion else { return nil }
        return snapshot
    }

    func cached() -> SeasonSnapshot? {
        if let memory { return memory }
        memory = Self.cachedSnapshot()
        return memory
    }

    /// Returns cached data when fresh enough, otherwise refreshes. Falls back to stale data on failure.
    func snapshot(maxAge: TimeInterval, now: Date = Date()) async -> SeasonSnapshot? {
        let current = cached()
        if let current, !current.shouldRefresh(now: now, maxAge: maxAge) {
            return current
        }
        do {
            return try await refresh()
        } catch {
            return current
        }
    }

    /// Fetches the latest calendar, standings and (when needed) results.
    @discardableResult
    func refresh() async throws -> SeasonSnapshot {
        if let inFlight { return try await inFlight.value }
        let previous = cached()
        let client = self.client
        let task = Task { try await Self.fetch(client: client, previous: previous) }
        inFlight = task
        defer { inFlight = nil }
        let snapshot = try await task.value
        memory = snapshot
        try? SharedStorage.write(snapshot, to: Self.fileName)
        return snapshot
    }

    private static func fetch(client: JolpicaClient, previous: SeasonSnapshot?) async throws -> SeasonSnapshot {
        let now = Date()
        let races = try await client.races(season: "current")
        let season = races.first?.season ?? Calendar(identifier: .gregorian).component(.year, from: now)

        var standingsSeason = season
        var standingsRaces = races
        var drivers = try await client.driverStandings(season: season)
        if drivers.standings.isEmpty {
            // Pre-season: show last year's final tables.
            standingsSeason = season - 1
            drivers = try await client.driverStandings(season: standingsSeason)
            standingsRaces = (try? await client.races(season: "\(standingsSeason)")) ?? []
        }
        let constructors = (try? await client.constructorStandings(season: standingsSeason))?.standings ?? []

        // Results are the heaviest request; reuse them when nothing new has happened.
        var results: [RoundResults]
        var resultsFetchedAt: Date
        if let previous,
           previous.standingsSeason == standingsSeason,
           previous.standingsRound == drivers.round,
           previous.version == SeasonSnapshot.currentVersion,
           !previous.isMissingRecentResults(now: now) {
            results = previous.results
            resultsFetchedAt = previous.resultsFetchedAt ?? previous.fetchedAt
        } else {
            results = try await client.results(season: standingsSeason)
            resultsFetchedAt = now
        }

        return SeasonSnapshot(
            season: season,
            races: races,
            standingsSeason: standingsSeason,
            standingsRound: drivers.round,
            standingsRaces: standingsRaces,
            driverStandings: drivers.standings,
            constructorStandings: constructors,
            results: results,
            fetchedAt: now,
            resultsFetchedAt: resultsFetchedAt
        )
    }

    // MARK: Past seasons

    /// A complete archive of a past season (cached forever once the season is over).
    func archive(season: Int) async throws -> SeasonSnapshot {
        let name = "season-\(season).json"
        if let cached = SharedStorage.read(SeasonSnapshot.self, from: name), cached.version == SeasonSnapshot.currentVersion {
            return cached
        }
        let races = try await client.races(season: "\(season)")
        let drivers = try await client.driverStandings(season: season)
        let constructors = (try? await client.constructorStandings(season: season))?.standings ?? []
        let results = try await client.results(season: season)
        let snapshot = SeasonSnapshot(
            season: season,
            races: races,
            standingsSeason: season,
            standingsRound: drivers.round,
            standingsRaces: races,
            driverStandings: drivers.standings,
            constructorStandings: constructors,
            results: results,
            fetchedAt: Date(),
            resultsFetchedAt: Date()
        )
        // Only finished seasons are immutable.
        if let last = races.last, last.end < Date() {
            try? SharedStorage.write(snapshot, to: name)
        }
        return snapshot
    }
}
