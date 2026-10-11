import Foundation

/// Illustrative season used for widget placeholders, gallery previews before the first
/// download, and snapshot tests. It uses the 2026 grid and calendar shape with
/// **synthetic, made-up results** — never shown as real data in the app.
enum SampleData {
    /// A fixed moment a few days before the Singapore round, used by snapshot tests.
    static let referenceDate: Date = ISO8601DateFormatter().date(from: "2026-10-07T12:00:00Z")!

    private struct Entry {
        let id: String
        let code: String
        let number: String
        let given: String
        let family: String
        let nationality: String
        let team: String
        let pace: Double
    }

    private static let teams: [String: (name: String, nationality: String)] = [
        "mclaren": ("McLaren", "British"),
        "mercedes": ("Mercedes", "German"),
        "red_bull": ("Red Bull", "Austrian"),
        "ferrari": ("Ferrari", "Italian"),
        "williams": ("Williams", "British"),
        "rb": ("RB F1 Team", "Italian"),
        "aston_martin": ("Aston Martin", "British"),
        "haas": ("Haas F1 Team", "American"),
        "audi": ("Audi", "German"),
        "alpine": ("Alpine F1 Team", "French"),
        "cadillac": ("Cadillac F1 Team", "American"),
    ]

    private static let grid: [Entry] = [
        Entry(id: "norris", code: "NOR", number: "1", given: "Lando", family: "Norris", nationality: "British", team: "mclaren", pace: 0.95),
        Entry(id: "piastri", code: "PIA", number: "81", given: "Oscar", family: "Piastri", nationality: "Australian", team: "mclaren", pace: 0.93),
        Entry(id: "russell", code: "RUS", number: "63", given: "George", family: "Russell", nationality: "British", team: "mercedes", pace: 0.94),
        Entry(id: "antonelli", code: "ANT", number: "12", given: "Andrea Kimi", family: "Antonelli", nationality: "Italian", team: "mercedes", pace: 0.88),
        Entry(id: "max_verstappen", code: "VER", number: "3", given: "Max", family: "Verstappen", nationality: "Dutch", team: "red_bull", pace: 0.94),
        Entry(id: "hadjar", code: "HAD", number: "6", given: "Isack", family: "Hadjar", nationality: "French", team: "red_bull", pace: 0.8),
        Entry(id: "leclerc", code: "LEC", number: "16", given: "Charles", family: "Leclerc", nationality: "Monegasque", team: "ferrari", pace: 0.9),
        Entry(id: "hamilton", code: "HAM", number: "44", given: "Lewis", family: "Hamilton", nationality: "British", team: "ferrari", pace: 0.87),
        Entry(id: "albon", code: "ALB", number: "23", given: "Alexander", family: "Albon", nationality: "Thai", team: "williams", pace: 0.76),
        Entry(id: "sainz", code: "SAI", number: "55", given: "Carlos", family: "Sainz", nationality: "Spanish", team: "williams", pace: 0.77),
        Entry(id: "arvid_lindblad", code: "LIN", number: "41", given: "Arvid", family: "Lindblad", nationality: "British", team: "rb", pace: 0.7),
        Entry(id: "lawson", code: "LAW", number: "30", given: "Liam", family: "Lawson", nationality: "New Zealander", team: "rb", pace: 0.72),
        Entry(id: "alonso", code: "ALO", number: "14", given: "Fernando", family: "Alonso", nationality: "Spanish", team: "aston_martin", pace: 0.78),
        Entry(id: "stroll", code: "STR", number: "18", given: "Lance", family: "Stroll", nationality: "Canadian", team: "aston_martin", pace: 0.68),
        Entry(id: "ocon", code: "OCO", number: "31", given: "Esteban", family: "Ocon", nationality: "French", team: "haas", pace: 0.71),
        Entry(id: "bearman", code: "BEA", number: "87", given: "Oliver", family: "Bearman", nationality: "British", team: "haas", pace: 0.73),
        Entry(id: "hulkenberg", code: "HUL", number: "27", given: "Nico", family: "Hülkenberg", nationality: "German", team: "audi", pace: 0.72),
        Entry(id: "bortoleto", code: "BOR", number: "5", given: "Gabriel", family: "Bortoleto", nationality: "Brazilian", team: "audi", pace: 0.71),
        Entry(id: "gasly", code: "GAS", number: "10", given: "Pierre", family: "Gasly", nationality: "French", team: "alpine", pace: 0.7),
        Entry(id: "colapinto", code: "COL", number: "43", given: "Franco", family: "Colapinto", nationality: "Argentine", team: "alpine", pace: 0.66),
        Entry(id: "perez", code: "PER", number: "11", given: "Sergio", family: "Pérez", nationality: "Mexican", team: "cadillac", pace: 0.64),
        Entry(id: "bottas", code: "BOT", number: "77", given: "Valtteri", family: "Bottas", nationality: "Finnish", team: "cadillac", pace: 0.63),
    ]

    private struct RaceSeed {
        let name: String
        let circuitId: String
        let circuit: String
        let locality: String
        let country: String
        let raceUTC: String
        let sprint: Bool
    }

    private static let calendar: [RaceSeed] = [
        RaceSeed(name: "Australian Grand Prix", circuitId: "albert_park", circuit: "Albert Park Grand Prix Circuit", locality: "Melbourne", country: "Australia", raceUTC: "2026-03-08T04:00:00Z", sprint: false),
        RaceSeed(name: "Chinese Grand Prix", circuitId: "shanghai", circuit: "Shanghai International Circuit", locality: "Shanghai", country: "China", raceUTC: "2026-03-15T07:00:00Z", sprint: true),
        RaceSeed(name: "Japanese Grand Prix", circuitId: "suzuka", circuit: "Suzuka Circuit", locality: "Suzuka", country: "Japan", raceUTC: "2026-03-29T05:00:00Z", sprint: false),
        RaceSeed(name: "Bahrain Grand Prix", circuitId: "bahrain", circuit: "Bahrain International Circuit", locality: "Sakhir", country: "Bahrain", raceUTC: "2026-04-12T15:00:00Z", sprint: false),
        RaceSeed(name: "Saudi Arabian Grand Prix", circuitId: "jeddah", circuit: "Jeddah Corniche Circuit", locality: "Jeddah", country: "Saudi Arabia", raceUTC: "2026-04-19T17:00:00Z", sprint: false),
        RaceSeed(name: "Miami Grand Prix", circuitId: "miami", circuit: "Miami International Autodrome", locality: "Miami", country: "USA", raceUTC: "2026-05-03T20:00:00Z", sprint: true),
        RaceSeed(name: "Canadian Grand Prix", circuitId: "villeneuve", circuit: "Circuit Gilles Villeneuve", locality: "Montreal", country: "Canada", raceUTC: "2026-05-24T18:00:00Z", sprint: true),
        RaceSeed(name: "Monaco Grand Prix", circuitId: "monaco", circuit: "Circuit de Monaco", locality: "Monte-Carlo", country: "Monaco", raceUTC: "2026-06-07T13:00:00Z", sprint: false),
        RaceSeed(name: "Barcelona-Catalunya Grand Prix", circuitId: "catalunya", circuit: "Circuit de Barcelona-Catalunya", locality: "Montmeló", country: "Spain", raceUTC: "2026-06-14T13:00:00Z", sprint: false),
        RaceSeed(name: "Austrian Grand Prix", circuitId: "red_bull_ring", circuit: "Red Bull Ring", locality: "Spielberg", country: "Austria", raceUTC: "2026-06-28T13:00:00Z", sprint: false),
        RaceSeed(name: "British Grand Prix", circuitId: "silverstone", circuit: "Silverstone Circuit", locality: "Silverstone", country: "UK", raceUTC: "2026-07-05T14:00:00Z", sprint: true),
        RaceSeed(name: "Belgian Grand Prix", circuitId: "spa", circuit: "Circuit de Spa-Francorchamps", locality: "Spa", country: "Belgium", raceUTC: "2026-07-19T13:00:00Z", sprint: false),
        RaceSeed(name: "Hungarian Grand Prix", circuitId: "hungaroring", circuit: "Hungaroring", locality: "Budapest", country: "Hungary", raceUTC: "2026-07-26T13:00:00Z", sprint: false),
        RaceSeed(name: "Dutch Grand Prix", circuitId: "zandvoort", circuit: "Circuit Park Zandvoort", locality: "Zandvoort", country: "Netherlands", raceUTC: "2026-08-23T13:00:00Z", sprint: true),
        RaceSeed(name: "Italian Grand Prix", circuitId: "monza", circuit: "Autodromo Nazionale di Monza", locality: "Monza", country: "Italy", raceUTC: "2026-09-06T13:00:00Z", sprint: false),
        RaceSeed(name: "Spanish Grand Prix", circuitId: "madring", circuit: "Madring", locality: "Madrid", country: "Spain", raceUTC: "2026-09-13T13:00:00Z", sprint: false),
        RaceSeed(name: "Azerbaijan Grand Prix", circuitId: "baku", circuit: "Baku City Circuit", locality: "Baku", country: "Azerbaijan", raceUTC: "2026-09-26T11:00:00Z", sprint: false),
        RaceSeed(name: "Singapore Grand Prix", circuitId: "marina_bay", circuit: "Marina Bay Street Circuit", locality: "Marina Bay", country: "Singapore", raceUTC: "2026-10-11T12:00:00Z", sprint: true),
        RaceSeed(name: "United States Grand Prix", circuitId: "americas", circuit: "Circuit of the Americas", locality: "Austin", country: "USA", raceUTC: "2026-10-25T19:00:00Z", sprint: false),
        RaceSeed(name: "Mexico City Grand Prix", circuitId: "rodriguez", circuit: "Autódromo Hermanos Rodríguez", locality: "Mexico City", country: "Mexico", raceUTC: "2026-11-01T20:00:00Z", sprint: false),
        RaceSeed(name: "São Paulo Grand Prix", circuitId: "interlagos", circuit: "Autódromo José Carlos Pace", locality: "São Paulo", country: "Brazil", raceUTC: "2026-11-08T17:00:00Z", sprint: false),
        RaceSeed(name: "Las Vegas Grand Prix", circuitId: "vegas", circuit: "Las Vegas Strip Street Circuit", locality: "Las Vegas", country: "USA", raceUTC: "2026-11-22T04:00:00Z", sprint: false),
        RaceSeed(name: "Qatar Grand Prix", circuitId: "losail", circuit: "Lusail International Circuit", locality: "Lusail", country: "Qatar", raceUTC: "2026-11-29T16:00:00Z", sprint: false),
        RaceSeed(name: "Abu Dhabi Grand Prix", circuitId: "yas_marina", circuit: "Yas Marina Circuit", locality: "Abu Dhabi", country: "UAE", raceUTC: "2026-12-06T13:00:00Z", sprint: false),
    ]

    /// Deterministic pseudo-random numbers so previews are stable.
    private struct SplitMix {
        var state: UInt64

        mutating func next() -> Double {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            z ^= z >> 31
            return Double(z % 1_000_000) / 1_000_000
        }
    }

    private static let racePoints: [Double] = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
    private static let sprintPoints: [Double] = [8, 7, 6, 5, 4, 3, 2, 1]

    static func snapshot(now: Date = referenceDate) -> SeasonSnapshot {
        let iso = ISO8601DateFormatter()
        let races: [Race] = calendar.enumerated().map { index, seed in
            let start = iso.date(from: seed.raceUTC)!
            let hour: TimeInterval = 3600
            let day: TimeInterval = 86_400
            let sessions: [Session]
            if seed.sprint {
                sessions = [
                    Session(kind: .practice1, start: start - 2 * day - 2.5 * hour, hasTime: true),
                    Session(kind: .sprintQualifying, start: start - 2 * day + 1.5 * hour, hasTime: true),
                    Session(kind: .sprint, start: start - day - 2 * hour, hasTime: true),
                    Session(kind: .qualifying, start: start - day + 2 * hour, hasTime: true),
                    Session(kind: .race, start: start, hasTime: true),
                ]
            } else {
                sessions = [
                    Session(kind: .practice1, start: start - 2 * day - 2.5 * hour, hasTime: true),
                    Session(kind: .practice2, start: start - 2 * day + 1 * hour, hasTime: true),
                    Session(kind: .practice3, start: start - day - 2.5 * hour, hasTime: true),
                    Session(kind: .qualifying, start: start - day + 1 * hour, hasTime: true),
                    Session(kind: .race, start: start, hasTime: true),
                ]
            }
            let circuit = Circuit(id: seed.circuitId, name: seed.circuit, locality: seed.locality, country: seed.country)
            return Race(season: 2026, round: index + 1, name: seed.name, circuit: circuit, sessions: sessions)
        }

        let drivers = grid.map { entry in
            Driver(id: entry.id, code: entry.code, number: entry.number, givenName: entry.given, familyName: entry.family, nationality: entry.nationality)
        }
        let constructors = Dictionary(uniqueKeysWithValues: teams.map { id, info in
            (id, Constructor(id: id, name: info.name, nationality: info.nationality))
        })

        var random = SplitMix(state: 2026)
        var results: [RoundResults] = []
        for race in races where race.end <= now {
            var round = RoundResults(round: race.round)

            func order(noise: Double) -> [Int] {
                grid.indices
                    .map { ($0, grid[$0].pace + random.next() * noise) }
                    .sorted { $0.1 > $1.1 }
                    .map(\.0)
            }

            let qualifyingOrder = order(noise: 0.12)
            round.qualifying = qualifyingOrder.enumerated().map { position, index in
                QualifyingResult(
                    position: position + 1,
                    driver: drivers[index],
                    constructor: constructors[grid[index].team],
                    q1: String(format: "1:%02d.%03d", 30 + position / 4, Int(random.next() * 999)),
                    q2: position < 15 ? String(format: "1:%02d.%03d", 29 + position / 5, Int(random.next() * 999)) : nil,
                    q3: position < 10 ? String(format: "1:29.%03d", 100 + position * 61) : nil
                )
            }

            var raceOrder = order(noise: 0.16)
            let retirements = Int(random.next() * 3)
            let retired = Array(raceOrder.suffix(retirements))
            raceOrder.removeLast(retirements)
            let fastest = raceOrder[Int(random.next() * 5)]
            let winnerMillis = 5_400_000 + Int(random.next() * 600_000)
            var gap = 0.0
            round.race = (raceOrder + retired).enumerated().map { position, index in
                let classified = position < raceOrder.count
                let grid = (qualifyingOrder.firstIndex(of: index) ?? position) + 1
                gap += position == 0 ? 0 : 1.2 + random.next() * 6
                let time: String? = classified ? (position == 0 ? formatRaceTime(winnerMillis) : String(format: "+%.3f", gap)) : nil
                return RaceResult(
                    position: position + 1,
                    positionText: classified ? "\(position + 1)" : "R",
                    points: classified && position < 10 ? racePoints[position] : 0,
                    driver: drivers[index],
                    constructor: constructors[self.grid[index].team],
                    grid: grid,
                    laps: classified ? 57 : 20 + Int(random.next() * 30),
                    status: classified ? (position < 14 ? "Finished" : "Lapped") : "Retired",
                    time: time,
                    fastestLapRank: index == fastest ? 1 : nil,
                    fastestLapTime: index == fastest ? String(format: "1:3%d.%03d", 1 + Int(random.next() * 4), Int(random.next() * 999)) : nil
                )
            }

            if race.isSprintWeekend {
                round.sprint = order(noise: 0.14).enumerated().map { position, index in
                    RaceResult(
                        position: position + 1,
                        positionText: "\(position + 1)",
                        points: position < 8 ? sprintPoints[position] : 0,
                        driver: drivers[index],
                        constructor: constructors[grid[index].team],
                        grid: nil, laps: 19, status: "Finished",
                        time: position == 0 ? "30:12.345" : String(format: "+%.3f", Double(position) * 1.9),
                        fastestLapRank: nil, fastestLapTime: nil
                    )
                }
            }
            results.append(round)
        }

        // Standings from the generated results.
        var driverPoints: [String: Double] = [:]
        var driverWins: [String: Int] = [:]
        var teamPoints: [String: Double] = [:]
        var teamWins: [String: Int] = [:]
        for round in results {
            for result in round.race + round.sprint {
                driverPoints[result.driver.id, default: 0] += result.points
                if let team = result.constructor?.id { teamPoints[team, default: 0] += result.points }
            }
            if let winner = round.race.first {
                driverWins[winner.driver.id, default: 0] += 1
                if let team = winner.constructor?.id { teamWins[team, default: 0] += 1 }
            }
        }

        let driverStandings = grid.indices
            .sorted { (driverPoints[grid[$0].id] ?? 0) > (driverPoints[grid[$1].id] ?? 0) }
            .enumerated()
            .map { position, index in
                DriverStanding(
                    position: position + 1,
                    positionText: "\(position + 1)",
                    points: driverPoints[grid[index].id] ?? 0,
                    wins: driverWins[grid[index].id] ?? 0,
                    driver: drivers[index],
                    constructors: [constructors[grid[index].team]].compactMap { $0 }
                )
            }

        let constructorStandings = constructors.values
            .sorted { (teamPoints[$0.id] ?? 0) > (teamPoints[$1.id] ?? 0) }
            .enumerated()
            .map { position, constructor in
                ConstructorStanding(
                    position: position + 1,
                    positionText: "\(position + 1)",
                    points: teamPoints[constructor.id] ?? 0,
                    wins: teamWins[constructor.id] ?? 0,
                    constructor: constructor
                )
            }

        return SeasonSnapshot(
            season: 2026,
            races: races,
            standingsSeason: 2026,
            standingsRound: results.last?.round ?? 0,
            standingsRaces: races,
            driverStandings: driverStandings,
            constructorStandings: constructorStandings,
            results: results,
            fetchedAt: now,
            resultsFetchedAt: now
        )
    }

    private static func formatRaceTime(_ millis: Int) -> String {
        let hours = millis / 3_600_000
        let minutes = (millis / 60_000) % 60
        let seconds = (millis / 1000) % 60
        return String(format: "%d:%02d:%02d.%03d", hours, minutes, seconds, millis % 1000)
    }
}
