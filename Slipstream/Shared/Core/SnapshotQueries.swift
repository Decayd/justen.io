import Foundation

/// How a countdown chooses its target session.
enum CountdownMode: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Race start until the weekend begins, then the next session.
    case smart
    /// Always count down to lights out of the Grand Prix.
    case race
    /// Always count down to the next session on track.
    case nextSession

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smart: "Smart"
        case .race: "Race start"
        case .nextSession: "Next session"
        }
    }
}

extension SeasonSnapshot {
    /// The race currently happening or the next one on the calendar.
    func nextRace(after now: Date) -> Race? {
        races.first { $0.end > now }
    }

    /// The race after `race` in the calendar.
    func race(after race: Race) -> Race? {
        races.first { $0.round > race.round }
    }

    func upcomingRaces(after now: Date, limit: Int) -> [Race] {
        Array(races.filter { $0.end > now }.prefix(limit))
    }

    /// The session a countdown should point at for `race`.
    func countdownTarget(for race: Race, now: Date, mode: CountdownMode) -> Session {
        switch mode {
        case .race:
            return race.raceSession
        case .nextSession:
            return race.nextSession(after: now) ?? race.raceSession
        case .smart:
            let weekendIsClose = now >= race.weekendStart.addingTimeInterval(-24 * 60 * 60)
            return weekendIsClose ? (race.nextSession(after: now) ?? race.raceSession) : race.raceSession
        }
    }

    // MARK: Results

    func results(round: Int) -> RoundResults? {
        results.first { $0.round == round }
    }

    /// Calendar entry for a round in the standings season.
    func standingsRace(round: Int) -> Race? {
        standingsRaces.first { $0.round == round }
    }

    /// The most recent round with a race classification.
    var latestRaceResults: RoundResults? {
        results.last { !$0.race.isEmpty }
    }

    var latestRace: Race? {
        latestRaceResults.flatMap { standingsRace(round: $0.round) }
    }

    // MARK: Standings helpers

    func driverStanding(id: String) -> DriverStanding? {
        driverStandings.first { $0.driver.id == id }
    }

    func constructorStanding(id: String) -> ConstructorStanding? {
        constructorStandings.first { $0.constructor.id == id }
    }

    var leaderPoints: Double { driverStandings.first?.points ?? 0 }
    var constructorLeaderPoints: Double { constructorStandings.first?.points ?? 0 }

    /// Drivers who drove for a constructor this season, ordered by points.
    func drivers(of constructorId: String) -> [DriverStanding] {
        driverStandings.filter { $0.constructor?.id == constructorId }
    }

    var totalRounds: Int { standingsRaces.count }

    var remainingRaces: [Race] {
        standingsRaces.filter { $0.round > standingsRound }
    }

    /// The most points a driver can still score this season.
    var maxPointsRemaining: Double {
        let fastestLap = 2019...2024 ~= standingsSeason ? 1.0 : 0
        let sprint = standingsSeason >= 2022 ? 8.0 : 3.0
        return pointsRemaining(perRace: 25 + fastestLap, perSprint: sprint)
    }

    /// The most points a constructor can still score (a one-two every weekend).
    var maxConstructorPointsRemaining: Double {
        let fastestLap = 2019...2024 ~= standingsSeason ? 1.0 : 0
        let sprint = standingsSeason >= 2022 ? 15.0 : 5.0
        return pointsRemaining(perRace: 43 + fastestLap, perSprint: sprint)
    }

    private func pointsRemaining(perRace: Double, perSprint: Double) -> Double {
        let remaining = remainingRaces
        let sprints = remaining.filter(\.isSprintWeekend).count
        return Double(remaining.count) * perRace + Double(sprints) * perSprint
    }

    /// Drivers who can still mathematically win the title.
    var contenders: [DriverStanding] {
        let leader = leaderPoints
        let available = maxPointsRemaining
        return driverStandings.filter { $0.points + available >= leader }
    }

    /// True when a session that produces a classification finished recently
    /// but its results are not in the snapshot yet.
    func isMissingRecentResults(now: Date) -> Bool {
        for race in standingsRaces {
            let r = results(round: race.round)
            for session in race.sessions where session.kind.producesResults {
                let sinceEnd = now.timeIntervalSince(session.end)
                // Give the data a moment to be published, and stop chasing after three days.
                guard sinceEnd > 20 * 60, sinceEnd < 72 * 60 * 60 else { continue }
                switch session.kind {
                case .race where r?.race.isEmpty ?? true: return true
                case .sprint where r?.sprint.isEmpty ?? true: return true
                case .qualifying where r?.qualifying.isEmpty ?? true: return true
                default: continue
                }
            }
        }
        // A new season has started but we still show last year's tables.
        if season != standingsSeason, races.contains(where: { $0.end.addingTimeInterval(20 * 60) < now }) {
            return true
        }
        return false
    }

    /// Whether this snapshot should be refreshed from the network.
    func shouldRefresh(now: Date, maxAge: TimeInterval) -> Bool {
        let age = now.timeIntervalSince(fetchedAt)
        if version != SeasonSnapshot.currentVersion || age > maxAge { return true }
        // Chase fresh results, but not more often than every 15 minutes.
        return age > 15 * 60 && isMissingRecentResults(now: now)
    }

    /// When the next session that produces results finishes, if any.
    func nextResultsDate(after now: Date) -> Date? {
        races.flatMap(\.sessions)
            .filter { $0.kind.producesResults && $0.end > now }
            .map(\.end)
            .min()
    }
}
