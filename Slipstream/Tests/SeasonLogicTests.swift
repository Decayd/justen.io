import XCTest
@testable import Slipstream

final class SeasonLogicTests: XCTestCase {
    private let snapshot = SampleData.snapshot()
    private var now: Date { SampleData.referenceDate }

    func testSampleSeasonIsConsistent() {
        XCTAssertEqual(snapshot.races.count, 24)
        XCTAssertEqual(snapshot.standingsRound, 17)
        XCTAssertEqual(snapshot.driverStandings.count, 22)
        XCTAssertEqual(snapshot.constructorStandings.count, 11)
        let points = snapshot.driverStandings.map(\.points)
        XCTAssertEqual(points, points.sorted(by: >), "Standings must be ordered by points")
    }

    func testProgressionMatchesStandings() {
        let stats = SeasonStats(snapshot: snapshot)
        for standing in snapshot.driverStandings {
            let progress = stats.progress(driver: standing.driver.id)
            XCTAssertEqual(progress.first?.points, 0, "Lines start at zero")
            XCTAssertEqual(progress.last?.points ?? 0, standing.points, accuracy: 0.001, standing.driver.code)
        }
        for standing in snapshot.constructorStandings {
            XCTAssertEqual(stats.progress(team: standing.constructor.id).last?.points ?? 0, standing.points, accuracy: 0.001)
        }
        let wins = snapshot.driverStandings.reduce(0) { $0 + stats.driver($1.driver.id).wins }
        XCTAssertEqual(wins, 17, "One winner per completed round")
    }

    func testNextRaceAndSmartCountdown() throws {
        let race = try XCTUnwrap(snapshot.nextRace(after: now))
        XCTAssertEqual(race.shortName, "Singapore")
        XCTAssertTrue(race.isSprintWeekend)

        // Days before the weekend, smart mode counts down to the race itself.
        XCTAssertEqual(snapshot.countdownTarget(for: race, now: now, mode: .smart).kind, .race)
        // Once the weekend is close it follows each session.
        let friday = race.weekendStart.addingTimeInterval(-3600)
        XCTAssertEqual(snapshot.countdownTarget(for: race, now: friday, mode: .smart).kind, .practice1)
        XCTAssertEqual(snapshot.countdownTarget(for: race, now: now, mode: .nextSession).kind, .practice1)
    }

    func testCountdownPhases() {
        let target = now.addingTimeInterval(3 * 86_400 + 5 * 3600 + 120)
        XCTAssertEqual(Countdown(now: now, target: target).phase, .days(3, hours: 5))
        XCTAssertEqual(Countdown(now: now, target: now.addingTimeInterval(7_500)).phase, .hours(2, minutes: 5))
        XCTAssertEqual(Countdown(now: now, target: now.addingTimeInterval(900)).phase, .final)
        XCTAssertEqual(Countdown(now: now, target: now.addingTimeInterval(-60), duration: 3600).phase, .live)
        XCTAssertEqual(Countdown(now: now, target: target).compact, "3d 5h")
    }

    func testPointsStillAvailable() {
        // Seven rounds left after round 17, one of them (Singapore) a sprint weekend.
        XCTAssertEqual(snapshot.remainingRaces.count, 7)
        XCTAssertEqual(snapshot.maxPointsRemaining, 7 * 25 + 8)
        XCTAssertEqual(snapshot.maxConstructorPointsRemaining, 7 * 43 + 15)
        XCTAssertFalse(snapshot.contenders.isEmpty)
    }

    func testTimelineEntriesTickOnHourBoundaries() throws {
        let design = WidgetDesign(content: .nextRace)
        let race = try XCTUnwrap(snapshot.nextRace(after: now))
        let dates = WidgetSchedule.entryDates(now: now, snapshot: snapshot, design: design)
        XCTAssertEqual(dates.first, now)
        XCTAssertGreaterThan(dates.count, 20, "Hourly entries for the next day")
        XCTAssertTrue(dates.allSatisfy { $0 >= now && $0 < now.addingTimeInterval(24 * 3600) })
        // Each entry after the first sits exactly on a whole hour before the race start.
        for date in dates.dropFirst() {
            let hours = race.start.timeIntervalSince(date) / 3600
            XCTAssertEqual(hours, hours.rounded(), accuracy: 0.0001)
        }
        let reload = WidgetSchedule.nextReload(now: now, snapshot: snapshot)
        XCTAssertGreaterThan(reload, now)
    }

    func testMissingResultsTriggerRefresh() {
        var stale = snapshot
        // Pretend the Azerbaijan race finished but its results haven't landed yet.
        stale.results.removeLast()
        let justAfter = stale.standingsRace(round: 17)!.end.addingTimeInterval(3600)
        stale.fetchedAt = justAfter.addingTimeInterval(-30 * 60)
        XCTAssertTrue(stale.isMissingRecentResults(now: justAfter))
        XCTAssertTrue(stale.shouldRefresh(now: justAfter, maxAge: 6 * 3600))
        XCTAssertFalse(snapshot.shouldRefresh(now: now, maxAge: 6 * 3600))
    }

    func testTeamColoursStayLegible() {
        let cadillac = TeamPalette.rgb(for: "cadillac", season: 2026)
        XCTAssertGreaterThan(cadillac.legible(onDark: true).luminance, cadillac.luminance)
        let haas = TeamPalette.rgb(for: "haas", season: 2026)
        XCTAssertLessThanOrEqual(haas.legible(onDark: false).luminance, haas.luminance)
        XCTAssertEqual(TeamPalette.rgb(for: "mclaren", season: 2026).hex, "#FF8000")
    }

    func testEveryCalendarCircuitHasATrackOutline() {
        for race in snapshot.races {
            XCTAssertNotNil(CircuitCatalog.outline(for: race.circuit), race.circuit.id)
        }
    }
}
