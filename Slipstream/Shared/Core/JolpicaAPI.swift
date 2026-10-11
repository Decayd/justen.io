import Foundation

/// Raw response shapes of the Jolpica-F1 API (Ergast compatible).
/// https://github.com/jolpica/jolpica-f1/tree/main/docs
enum JolpicaDTO {
    struct Envelope<Payload: Decodable>: Decodable {
        let data: Payload
        enum CodingKeys: String, CodingKey { case data = "MRData" }
    }

    struct RacePayload: Decodable {
        let limit: String?
        let offset: String?
        let total: String?
        let raceTable: RaceTable
        enum CodingKeys: String, CodingKey { case limit, offset, total, raceTable = "RaceTable" }
    }

    struct RaceTable: Decodable {
        let season: String?
        let races: [Race]
        enum CodingKeys: String, CodingKey { case season, races = "Races" }
    }

    struct StandingsPayload: Decodable {
        let total: String?
        let standingsTable: StandingsTable
        enum CodingKeys: String, CodingKey { case total, standingsTable = "StandingsTable" }
    }

    struct StandingsTable: Decodable {
        let season: String?
        let round: String?
        let lists: [StandingsList]
        enum CodingKeys: String, CodingKey { case season, round, lists = "StandingsLists" }
    }

    struct StandingsList: Decodable {
        let season: String?
        let round: String?
        let driverStandings: [DriverStanding]?
        let constructorStandings: [ConstructorStanding]?
        enum CodingKeys: String, CodingKey {
            case season, round
            case driverStandings = "DriverStandings"
            case constructorStandings = "ConstructorStandings"
        }
    }

    struct DriverStanding: Decodable {
        let position: String?
        let positionText: String?
        let points: String
        let wins: String?
        let driver: Driver
        let constructors: [Constructor]?
        enum CodingKeys: String, CodingKey {
            case position, positionText, points, wins
            case driver = "Driver"
            case constructors = "Constructors"
        }
    }

    struct ConstructorStanding: Decodable {
        let position: String?
        let positionText: String?
        let points: String
        let wins: String?
        let constructor: Constructor
        enum CodingKeys: String, CodingKey {
            case position, positionText, points, wins
            case constructor = "Constructor"
        }
    }

    struct Driver: Decodable {
        let driverId: String
        let permanentNumber: String?
        let code: String?
        let givenName: String
        let familyName: String
        let dateOfBirth: String?
        let nationality: String?
    }

    struct Constructor: Decodable {
        let constructorId: String
        let name: String
        let nationality: String?
    }

    struct Race: Decodable {
        let season: String
        let round: String
        let raceName: String
        let circuit: Circuit
        let date: String
        let time: String?
        let firstPractice: SessionTime?
        let secondPractice: SessionTime?
        let thirdPractice: SessionTime?
        let qualifying: SessionTime?
        let sprint: SessionTime?
        let sprintQualifying: SessionTime?
        let sprintShootout: SessionTime?
        let results: [Result]?
        let sprintResults: [Result]?
        let qualifyingResults: [QualifyingResult]?

        enum CodingKeys: String, CodingKey {
            case season, round, raceName, date, time
            case circuit = "Circuit"
            case firstPractice = "FirstPractice"
            case secondPractice = "SecondPractice"
            case thirdPractice = "ThirdPractice"
            case qualifying = "Qualifying"
            case sprint = "Sprint"
            case sprintQualifying = "SprintQualifying"
            case sprintShootout = "SprintShootout"
            case results = "Results"
            case sprintResults = "SprintResults"
            case qualifyingResults = "QualifyingResults"
        }
    }

    struct SessionTime: Decodable {
        let date: String
        let time: String?
    }

    struct Circuit: Decodable {
        let circuitId: String
        let circuitName: String
        let location: Location
        enum CodingKeys: String, CodingKey { case circuitId, circuitName, location = "Location" }
    }

    struct Location: Decodable {
        let lat: String?
        let long: String?
        let locality: String?
        let country: String?
    }

    struct Result: Decodable {
        let number: String?
        let position: String?
        let positionText: String?
        let points: String?
        let driver: Driver
        let constructor: Constructor?
        let grid: String?
        let laps: String?
        let status: String?
        let time: TimeValue?
        let fastestLap: FastestLap?

        enum CodingKeys: String, CodingKey {
            case number, position, positionText, points, grid, laps, status
            case driver = "Driver"
            case constructor = "Constructor"
            case time = "Time"
            case fastestLap = "FastestLap"
        }
    }

    struct TimeValue: Decodable {
        let millis: String?
        let time: String?
    }

    struct FastestLap: Decodable {
        let rank: String?
        let lap: String?
        let time: TimeValue?
        enum CodingKeys: String, CodingKey { case rank, lap, time = "Time" }
    }

    struct QualifyingResult: Decodable {
        let number: String?
        let position: String?
        let driver: Driver
        let constructor: Constructor?
        let q1: String?
        let q2: String?
        let q3: String?

        enum CodingKeys: String, CodingKey {
            case number, position
            case driver = "Driver"
            case constructor = "Constructor"
            case q1 = "Q1"
            case q2 = "Q2"
            case q3 = "Q3"
        }
    }
}

// MARK: - Mapping to domain models

enum JolpicaMapper {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let isoFractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Combines Ergast's separate date ("2026-10-04") and UTC time ("12:00:00Z") fields.
    static func date(_ day: String, _ time: String?) -> (date: Date, hasTime: Bool)? {
        if var time, !time.isEmpty {
            if !time.hasSuffix("Z") && !time.contains("+") { time += "Z" }
            let stamp = "\(day)T\(time)"
            if let date = isoFormatter.date(from: stamp) ?? isoFractionalFormatter.date(from: stamp) {
                return (date, true)
            }
        }
        // No start time published (older seasons): assume early afternoon UTC.
        if let date = isoFormatter.date(from: "\(day)T13:00:00Z") {
            return (date, false)
        }
        return nil
    }

    static func driver(_ dto: JolpicaDTO.Driver) -> Driver {
        let fallbackCode = String(dto.familyName.folding(options: .diacriticInsensitive, locale: nil)
            .replacingOccurrences(of: " ", with: "")
            .prefix(3)).uppercased()
        return Driver(
            id: dto.driverId,
            code: (dto.code?.isEmpty == false ? dto.code! : fallbackCode),
            number: dto.permanentNumber,
            givenName: dto.givenName,
            familyName: dto.familyName,
            nationality: dto.nationality ?? "",
            dateOfBirth: dto.dateOfBirth
        )
    }

    static func constructor(_ dto: JolpicaDTO.Constructor) -> Constructor {
        Constructor(id: dto.constructorId, name: dto.name, nationality: dto.nationality ?? "")
    }

    static func race(_ dto: JolpicaDTO.Race) -> Race? {
        guard let season = Int(dto.season), let round = Int(dto.round) else { return nil }
        let circuit = Circuit(
            id: dto.circuit.circuitId,
            name: dto.circuit.circuitName,
            locality: dto.circuit.location.locality ?? "",
            country: dto.circuit.location.country ?? "",
            latitude: dto.circuit.location.lat.flatMap(Double.init),
            longitude: dto.circuit.location.long.flatMap(Double.init)
        )
        var sessions: [Session] = []
        func add(_ kind: SessionKind, _ value: JolpicaDTO.SessionTime?) {
            guard let value, let parsed = date(value.date, value.time) else { return }
            sessions.append(Session(kind: kind, start: parsed.date, hasTime: parsed.hasTime))
        }
        add(.practice1, dto.firstPractice)
        add(.practice2, dto.secondPractice)
        add(.practice3, dto.thirdPractice)
        add(.sprintQualifying, dto.sprintQualifying ?? dto.sprintShootout)
        add(.sprint, dto.sprint)
        add(.qualifying, dto.qualifying)
        if let parsed = date(dto.date, dto.time) {
            sessions.append(Session(kind: .race, start: parsed.date, hasTime: parsed.hasTime))
        }
        guard sessions.contains(where: { $0.kind == .race }) else { return nil }
        sessions.sort { $0.start < $1.start }
        return Race(season: season, round: round, name: dto.raceName, circuit: circuit, sessions: sessions)
    }

    static func result(_ dto: JolpicaDTO.Result) -> RaceResult {
        let positionText = dto.positionText ?? dto.position ?? "-"
        return RaceResult(
            position: dto.position.flatMap { Int($0) },
            positionText: positionText,
            points: dto.points.flatMap { Double($0) } ?? 0,
            driver: driver(dto.driver),
            constructor: dto.constructor.map(constructor),
            grid: dto.grid.flatMap { Int($0) },
            laps: dto.laps.flatMap { Int($0) },
            status: dto.status ?? "",
            time: dto.time?.time,
            fastestLapRank: dto.fastestLap?.rank.flatMap { Int($0) },
            fastestLapTime: dto.fastestLap?.time?.time
        )
    }

    static func qualifying(_ dto: JolpicaDTO.QualifyingResult) -> QualifyingResult {
        QualifyingResult(
            position: dto.position.flatMap { Int($0) },
            driver: driver(dto.driver),
            constructor: dto.constructor.map(constructor),
            q1: dto.q1?.nilIfEmpty,
            q2: dto.q2?.nilIfEmpty,
            q3: dto.q3?.nilIfEmpty
        )
    }

    static func driverStanding(_ dto: JolpicaDTO.DriverStanding, fallbackPosition: Int) -> DriverStanding {
        DriverStanding(
            position: dto.position.flatMap { Int($0) } ?? fallbackPosition,
            positionText: dto.positionText ?? dto.position ?? "\(fallbackPosition)",
            points: Double(dto.points) ?? 0,
            wins: dto.wins.flatMap { Int($0) } ?? 0,
            driver: driver(dto.driver),
            constructors: (dto.constructors ?? []).map(constructor)
        )
    }

    static func constructorStanding(_ dto: JolpicaDTO.ConstructorStanding, fallbackPosition: Int) -> ConstructorStanding {
        ConstructorStanding(
            position: dto.position.flatMap { Int($0) } ?? fallbackPosition,
            positionText: dto.positionText ?? dto.position ?? "\(fallbackPosition)",
            points: Double(dto.points) ?? 0,
            wins: dto.wins.flatMap { Int($0) } ?? 0,
            constructor: constructor(dto.constructor)
        )
    }

    /// Merges paginated race tables (a race can be split across pages) into per-round results.
    static func mergeResults(race: [JolpicaDTO.Race], sprint: [JolpicaDTO.Race], qualifying: [JolpicaDTO.Race]) -> [RoundResults] {
        var byRound: [Int: RoundResults] = [:]
        func entry(_ round: Int) -> RoundResults { byRound[round] ?? RoundResults(round: round) }
        for dto in race {
            guard let round = Int(dto.round) else { continue }
            var value = entry(round)
            value.race += (dto.results ?? []).map(JolpicaMapper.result)
            byRound[round] = value
        }
        for dto in sprint {
            guard let round = Int(dto.round) else { continue }
            var value = entry(round)
            value.sprint += (dto.sprintResults ?? []).map(JolpicaMapper.result)
            byRound[round] = value
        }
        for dto in qualifying {
            guard let round = Int(dto.round) else { continue }
            var value = entry(round)
            value.qualifying += (dto.qualifyingResults ?? []).map(JolpicaMapper.qualifying)
            byRound[round] = value
        }
        return byRound.values
            .map { value in
                var sorted = value
                sorted.race.sort { ($0.position ?? 999) < ($1.position ?? 999) }
                sorted.sprint.sort { ($0.position ?? 999) < ($1.position ?? 999) }
                sorted.qualifying.sort { ($0.position ?? 999) < ($1.position ?? 999) }
                return sorted
            }
            .sorted { $0.round < $1.round }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Client

enum JolpicaError: LocalizedError {
    case badStatus(Int)
    case rateLimited
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): "The F1 data service returned an error (\(code))."
        case .rateLimited: "The F1 data service is busy. Try again in a minute."
        case .invalidResponse: "The F1 data service sent an unexpected response."
        }
    }
}

/// Minimal client for https://api.jolpi.ca with pagination and polite request pacing
/// (the public API allows 4 requests per second and 500 per hour).
actor JolpicaClient {
    static let shared = JolpicaClient()

    private let baseURL = URL(string: "https://api.jolpi.ca/ergast/f1/")!
    private let session: URLSession
    private var lastRequest = Date.distantPast
    private let minimumSpacing: TimeInterval = 0.3
    private let pageSize = 100

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 60
            configuration.waitsForConnectivity = false
            configuration.httpAdditionalHeaders = ["User-Agent": "Slipstream/1.0 (iOS widgets app)"]
            self.session = URLSession(configuration: configuration)
        }
    }

    /// The calendar for a season. Pass "current" for the current season.
    func races(season: String) async throws -> [Race] {
        let payload: JolpicaDTO.RacePayload = try await get("\(season)/races.json", limit: pageSize)
        return payload.raceTable.races.compactMap(JolpicaMapper.race)
    }

    func driverStandings(season: Int) async throws -> (round: Int, standings: [DriverStanding]) {
        let payload: JolpicaDTO.StandingsPayload = try await get("\(season)/driverstandings.json", limit: pageSize)
        let list = payload.standingsTable.lists.first
        let standings = (list?.driverStandings ?? []).enumerated().map { index, dto in
            JolpicaMapper.driverStanding(dto, fallbackPosition: index + 1)
        }
        let round = Int(list?.round ?? payload.standingsTable.round ?? "") ?? 0
        return (round, standings)
    }

    func constructorStandings(season: Int) async throws -> (round: Int, standings: [ConstructorStanding]) {
        let payload: JolpicaDTO.StandingsPayload = try await get("\(season)/constructorstandings.json", limit: pageSize)
        let list = payload.standingsTable.lists.first
        let standings = (list?.constructorStandings ?? []).enumerated().map { index, dto in
            JolpicaMapper.constructorStanding(dto, fallbackPosition: index + 1)
        }
        let round = Int(list?.round ?? payload.standingsTable.round ?? "") ?? 0
        return (round, standings)
    }

    /// Race, sprint and qualifying classifications for every round of a season.
    func results(season: Int) async throws -> [RoundResults] {
        let race = try await allPages("\(season)/results.json")
        let sprint = (try? await allPages("\(season)/sprint.json")) ?? []
        let qualifying = (try? await allPages("\(season)/qualifying.json")) ?? []
        return JolpicaMapper.mergeResults(race: race, sprint: sprint, qualifying: qualifying)
    }

    // MARK: Plumbing

    private func allPages(_ path: String) async throws -> [JolpicaDTO.Race] {
        var offset = 0
        var races: [JolpicaDTO.Race] = []
        while true {
            let payload: JolpicaDTO.RacePayload = try await get(path, limit: pageSize, offset: offset)
            races += payload.raceTable.races
            let total = Int(payload.total ?? "") ?? 0
            offset += pageSize
            if offset >= total || payload.raceTable.races.isEmpty { break }
        }
        return races
    }

    private func get<T: Decodable>(_ path: String, limit: Int, offset: Int = 0) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),
        ]
        let url = components.url!

        var attempt = 0
        while true {
            try await pace()
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else { throw JolpicaError.invalidResponse }
            if http.statusCode == 429 {
                attempt += 1
                if attempt > 2 { throw JolpicaError.rateLimited }
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_500_000_000)
                continue
            }
            guard (200..<300).contains(http.statusCode) else { throw JolpicaError.badStatus(http.statusCode) }
            return try JSONDecoder().decode(JolpicaDTO.Envelope<T>.self, from: data).data
        }
    }

    private func pace() async throws {
        let wait = minimumSpacing - Date().timeIntervalSince(lastRequest)
        if wait > 0 {
            try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
        }
        lastRequest = Date()
    }
}
