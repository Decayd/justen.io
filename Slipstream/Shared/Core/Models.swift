import Foundation

// MARK: - People & teams

struct Driver: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var code: String
    var number: String?
    var givenName: String
    var familyName: String
    var nationality: String
    var dateOfBirth: String?

    var fullName: String { "\(givenName) \(familyName)" }
    var initialName: String { "\(givenName.prefix(1)). \(familyName)" }
}

struct Constructor: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var nationality: String
}

// MARK: - Standings

struct DriverStanding: Codable, Hashable, Identifiable, Sendable {
    var position: Int
    var positionText: String
    var points: Double
    var wins: Int
    var driver: Driver
    var constructors: [Constructor]

    var id: String { driver.id }
    /// The team the driver most recently raced for.
    var constructor: Constructor? { constructors.last }
}

struct ConstructorStanding: Codable, Hashable, Identifiable, Sendable {
    var position: Int
    var positionText: String
    var points: Double
    var wins: Int
    var constructor: Constructor

    var id: String { constructor.id }
}

// MARK: - Calendar

struct Circuit: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var locality: String
    var country: String
    var latitude: Double?
    var longitude: Double?
}

enum SessionKind: String, Codable, CaseIterable, Sendable {
    case practice1, practice2, practice3, sprintQualifying, sprint, qualifying, race

    var shortLabel: String {
        switch self {
        case .practice1: "FP1"
        case .practice2: "FP2"
        case .practice3: "FP3"
        case .sprintQualifying: "SQ"
        case .sprint: "SPRINT"
        case .qualifying: "QUALI"
        case .race: "RACE"
        }
    }

    var label: String {
        switch self {
        case .practice1: "Practice 1"
        case .practice2: "Practice 2"
        case .practice3: "Practice 3"
        case .sprintQualifying: "Sprint Qualifying"
        case .sprint: "Sprint"
        case .qualifying: "Qualifying"
        case .race: "Race"
        }
    }

    /// Typical length of the session, used to decide when a session is live.
    var typicalDuration: TimeInterval {
        switch self {
        case .practice1, .practice2, .practice3, .qualifying: 60 * 60
        case .sprintQualifying: 45 * 60
        case .sprint: 45 * 60
        case .race: 2 * 60 * 60
        }
    }

    /// Sessions whose classification feeds results or standings.
    var producesResults: Bool { self == .qualifying || self == .sprint || self == .race }
}

struct Session: Codable, Hashable, Sendable {
    var kind: SessionKind
    var start: Date
    var hasTime: Bool

    var end: Date { start.addingTimeInterval(kind.typicalDuration) }

    func state(at now: Date) -> SessionState {
        if now < start { return .upcoming }
        if now < end { return .live }
        return .finished
    }
}

enum SessionState: Sendable {
    case upcoming, live, finished
}

struct Race: Codable, Hashable, Identifiable, Sendable {
    var season: Int
    var round: Int
    var name: String
    var circuit: Circuit
    /// All weekend sessions ordered by start time. Always contains the race.
    var sessions: [Session]

    var id: String { "\(season)-\(round)" }

    var raceSession: Session {
        sessions.first { $0.kind == .race } ?? Session(kind: .race, start: sessions.last?.start ?? .distantFuture, hasTime: false)
    }

    var start: Date { raceSession.start }
    var weekendStart: Date { sessions.first?.start ?? start }
    var end: Date { raceSession.end }
    var isSprintWeekend: Bool { sessions.contains { $0.kind == .sprint } }

    /// "Singapore" for "Singapore Grand Prix", "Italy" for "Italian Grand Prix".
    var shortName: String {
        let trimmed = name.replacingOccurrences(of: " Grand Prix", with: "")
        if let place = Race.placeNames[trimmed] { return place }
        return trimmed.isEmpty ? name : trimmed
    }

    /// Race names that are adjectives ("Italian") read better as places in tight layouts.
    private static let placeNames: [String: String] = [
        "Australian": "Australia", "Chinese": "China", "Japanese": "Japan", "Saudi Arabian": "Saudi Arabia",
        "Canadian": "Canada", "Spanish": "Spain", "Barcelona-Catalunya": "Barcelona", "Austrian": "Austria",
        "British": "Britain", "Belgian": "Belgium", "Hungarian": "Hungary", "Dutch": "Netherlands",
        "Italian": "Italy", "Emilia Romagna": "Imola", "Portuguese": "Portugal", "French": "France",
        "German": "Germany", "Russian": "Russia", "Turkish": "Turkey", "Malaysian": "Malaysia",
        "Korean": "Korea", "Indian": "India", "European": "Europe", "Tuscan": "Mugello", "Styrian": "Styria",
        "Brazilian": "Brazil", "Mexican": "Mexico", "Argentine": "Argentina", "South African": "South Africa",
        "Swedish": "Sweden", "Swiss": "Switzerland", "Moroccan": "Morocco", "San Marino": "San Marino",
        "Luxembourg": "Luxembourg", "Pacific": "Pacific", "United States": "United States",
        "United States West": "Long Beach", "Caesars Palace": "Las Vegas", "Pescara": "Pescara",
    ]

    func nextSession(after now: Date) -> Session? {
        sessions.first { $0.end > now }
    }

    func liveSession(at now: Date) -> Session? {
        sessions.first { $0.state(at: now) == .live }
    }
}

// MARK: - Results

struct RaceResult: Codable, Hashable, Sendable {
    var position: Int?
    var positionText: String
    var points: Double
    var driver: Driver
    var constructor: Constructor?
    var grid: Int?
    var laps: Int?
    var status: String
    var time: String?
    var fastestLapRank: Int?
    var fastestLapTime: String?

    /// True when the driver was classified (numeric position text).
    var isClassified: Bool { Int(positionText) != nil }

    /// "P1", "DNF", "DSQ"…
    var label: String {
        if let value = Int(positionText) { return "P\(value)" }
        switch positionText {
        case "R", "N": return "DNF"
        case "D": return "DSQ"
        case "E": return "EX"
        case "W": return "DNS"
        case "F": return "DNQ"
        default: return positionText
        }
    }

    /// Positions gained (positive) or lost from the grid. Pit-lane starts count from the back.
    var positionsGained: Int? {
        guard let grid, let finish = Int(positionText) else { return nil }
        let start = grid == 0 ? 22 : grid
        return start - finish
    }

    /// Gap to the winner as published ("+5.123s", "+1 Lap") or the winning race time.
    var gapText: String {
        if let time { return time }
        if isClassified { return status }
        return label
    }
}

struct QualifyingResult: Codable, Hashable, Sendable {
    var position: Int?
    var driver: Driver
    var constructor: Constructor?
    var q1: String?
    var q2: String?
    var q3: String?

    var bestTime: String? { q3 ?? q2 ?? q1 }
}

struct RoundResults: Codable, Hashable, Sendable {
    var round: Int
    var race: [RaceResult] = []
    var sprint: [RaceResult] = []
    var qualifying: [QualifyingResult] = []

    var winner: RaceResult? { race.first { $0.positionText == "1" } ?? race.first }
    var podium: [RaceResult] { Array(race.filter { $0.isClassified }.prefix(3)) }
    var fastestLap: RaceResult? { race.first { $0.fastestLapRank == 1 } }
    var pole: QualifyingResult? { qualifying.first { $0.position == 1 } }
}

// MARK: - Snapshot

/// Everything the app and widgets need for one season, persisted to the shared container.
struct SeasonSnapshot: Codable, Hashable, Sendable {
    static let currentVersion = 2

    var version: Int = SeasonSnapshot.currentVersion
    /// The calendar season (the "current" season).
    var season: Int
    var races: [Race]
    /// The season the standings and results belong to. Differs from `season`
    /// before the first race of a new year, when last year's tables are shown.
    var standingsSeason: Int
    var standingsRound: Int
    var standingsRaces: [Race]
    var driverStandings: [DriverStanding]
    var constructorStandings: [ConstructorStanding]
    var results: [RoundResults]
    var fetchedAt: Date
    var resultsFetchedAt: Date?
}
