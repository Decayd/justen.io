import Foundation

/// A single race outcome rendered as a coloured chip ("P1", "DNF"…).
struct ResultBadge: Hashable, Identifiable, Sendable {
    enum Kind: Sendable { case win, podium, points, finish, retired }

    var round: Int
    var label: String
    var position: Int?
    var points: Double
    var kind: Kind
    var raceName: String
    var country: String

    var id: Int { round }

    init(result: RaceResult, round: Int, race: Race?) {
        let finish = Int(result.positionText)
        let kind: Kind
        if let finish {
            kind = finish == 1 ? .win : finish <= 3 ? .podium : result.points > 0 ? .points : .finish
        } else {
            kind = .retired
        }
        self.round = round
        self.label = result.label
        self.position = finish
        self.points = result.points
        self.kind = kind
        self.raceName = race?.shortName ?? ""
        self.country = race?.circuit.country ?? ""
    }
}

struct DriverSeasonStats: Hashable, Sendable {
    var starts = 0
    var wins = 0
    var podiums = 0
    var poles = 0
    var retirements = 0
    var pointsFinishes = 0
    var fastestLaps = 0
    var sprintWins = 0
    var bestFinish: Int?
    var bestQualifying: Int?
    var finishTotal = 0
    var finishCount = 0
    var results: [ResultBadge] = []

    var averageFinish: Double? {
        finishCount > 0 ? Double(finishTotal) / Double(finishCount) : nil
    }

    func recent(_ count: Int) -> [ResultBadge] { Array(results.suffix(count)) }
}

struct TeamSeasonStats: Hashable, Sendable {
    var wins = 0
    var podiums = 0
    var oneTwos = 0
    var poles = 0
    var retirements = 0
    /// Points scored per driver for this team (race + sprint).
    var driverPoints: [String: Double] = [:]
}

struct ProgressPoint: Hashable, Identifiable, Sendable {
    var round: Int
    var points: Double
    var id: Int { round }
}

struct HeadToHead: Hashable, Sendable {
    var teammate: Driver
    var raceAhead = 0
    var raceBehind = 0
    var qualifyingAhead = 0
    var qualifyingBehind = 0
}

/// Derived numbers computed once per snapshot: points progression, podiums, poles…
struct SeasonStats: Sendable {
    let rounds: [Int]
    let driverProgress: [String: [ProgressPoint]]
    let teamProgress: [String: [ProgressPoint]]
    let drivers: [String: DriverSeasonStats]
    let teams: [String: TeamSeasonStats]
    private let snapshot: SeasonSnapshot

    init(snapshot: SeasonSnapshot) {
        self.snapshot = snapshot
        let completed = snapshot.results
            .filter { !$0.race.isEmpty || !$0.sprint.isEmpty }
            .sorted { $0.round < $1.round }
        rounds = completed.map(\.round)

        var drivers: [String: DriverSeasonStats] = [:]
        var teams: [String: TeamSeasonStats] = [:]
        var driverTotals: [String: Double] = [:]
        var teamTotals: [String: Double] = [:]
        var driverProgress: [String: [ProgressPoint]] = [:]
        var teamProgress: [String: [ProgressPoint]] = [:]

        // Make sure everyone in the standings has a progression line, even with zero points.
        for standing in snapshot.driverStandings { driverTotals[standing.driver.id] = 0 }
        for standing in snapshot.constructorStandings { teamTotals[standing.constructor.id] = 0 }

        for round in completed {
            let race = snapshot.standingsRace(round: round.round)

            for result in round.race {
                let id = result.driver.id
                var stats = drivers[id] ?? DriverSeasonStats()
                stats.starts += 1
                stats.results.append(ResultBadge(result: result, round: round.round, race: race))
                if let position = Int(result.positionText) {
                    if position == 1 { stats.wins += 1 }
                    if position <= 3 { stats.podiums += 1 }
                    stats.bestFinish = min(stats.bestFinish ?? position, position)
                    stats.finishTotal += position
                    stats.finishCount += 1
                } else {
                    stats.retirements += 1
                }
                if result.points > 0 { stats.pointsFinishes += 1 }
                if result.fastestLapRank == 1 { stats.fastestLaps += 1 }
                drivers[id] = stats
                driverTotals[id, default: 0] += result.points

                if let team = result.constructor?.id {
                    var teamStats = teams[team] ?? TeamSeasonStats()
                    if let position = Int(result.positionText) {
                        if position == 1 { teamStats.wins += 1 }
                        if position <= 3 { teamStats.podiums += 1 }
                    } else {
                        teamStats.retirements += 1
                    }
                    teamStats.driverPoints[id, default: 0] += result.points
                    teams[team] = teamStats
                    teamTotals[team, default: 0] += result.points
                }
            }

            // One-two finishes.
            let topTwo = round.race.filter { Int($0.positionText) == 1 || Int($0.positionText) == 2 }
            if topTwo.count == 2, let team = topTwo[0].constructor?.id, topTwo[1].constructor?.id == team {
                teams[team, default: TeamSeasonStats()].oneTwos += 1
            }

            for result in round.sprint {
                let id = result.driver.id
                if Int(result.positionText) == 1 { drivers[id, default: DriverSeasonStats()].sprintWins += 1 }
                driverTotals[id, default: 0] += result.points
                if let team = result.constructor?.id {
                    teams[team, default: TeamSeasonStats()].driverPoints[id, default: 0] += result.points
                    teamTotals[team, default: 0] += result.points
                }
            }

            for result in round.qualifying {
                guard let position = result.position else { continue }
                let id = result.driver.id
                var stats = drivers[id] ?? DriverSeasonStats()
                if position == 1 { stats.poles += 1 }
                stats.bestQualifying = min(stats.bestQualifying ?? position, position)
                drivers[id] = stats
                if position == 1, let team = result.constructor?.id {
                    teams[team, default: TeamSeasonStats()].poles += 1
                }
            }

            for (id, total) in driverTotals {
                driverProgress[id, default: []].append(ProgressPoint(round: round.round, points: total))
            }
            for (id, total) in teamTotals {
                teamProgress[id, default: []].append(ProgressPoint(round: round.round, points: total))
            }
        }

        self.drivers = drivers
        self.teams = teams
        self.driverProgress = driverProgress
        self.teamProgress = teamProgress
    }

    func driver(_ id: String) -> DriverSeasonStats {
        drivers[id] ?? DriverSeasonStats()
    }

    func team(_ id: String) -> TeamSeasonStats {
        teams[id] ?? TeamSeasonStats()
    }

    /// Cumulative points with a leading zero so lines start from the origin.
    func progress(driver id: String) -> [ProgressPoint] {
        withOrigin(driverProgress[id] ?? [])
    }

    func progress(team id: String) -> [ProgressPoint] {
        withOrigin(teamProgress[id] ?? [])
    }

    private func withOrigin(_ points: [ProgressPoint]) -> [ProgressPoint] {
        guard let first = points.first else { return [] }
        return [ProgressPoint(round: first.round - 1, points: 0)] + points
    }

    /// Race and qualifying battle against the teammate the driver shared most rounds with.
    func headToHead(driver id: String) -> HeadToHead? {
        var counts: [String: HeadToHead] = [:]
        for round in snapshot.results {
            guard let mine = round.race.first(where: { $0.driver.id == id }),
                  let team = mine.constructor?.id,
                  let theirs = round.race.first(where: { $0.driver.id != id && $0.constructor?.id == team }) else { continue }
            var record = counts[theirs.driver.id] ?? HeadToHead(teammate: theirs.driver)
            if (mine.position ?? 99) < (theirs.position ?? 99) { record.raceAhead += 1 } else { record.raceBehind += 1 }
            if let myQuali = round.qualifying.first(where: { $0.driver.id == id })?.position,
               let theirQuali = round.qualifying.first(where: { $0.driver.id == theirs.driver.id })?.position {
                if myQuali < theirQuali { record.qualifyingAhead += 1 } else { record.qualifyingBehind += 1 }
            }
            counts[theirs.driver.id] = record
        }
        return counts.values.max { ($0.raceAhead + $0.raceBehind) < ($1.raceAhead + $1.raceBehind) }
    }
}
