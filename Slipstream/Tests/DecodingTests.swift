import XCTest
@testable import Slipstream

/// Fixtures follow the response examples in the Jolpica-F1 documentation.
final class DecodingTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(JolpicaDTO.Envelope<T>.self, from: Data(json.utf8)).data
    }

    func testDriverStandings() throws {
        let payload = try decode(JolpicaDTO.StandingsPayload.self, """
        {"MRData":{"xmlns":"","series":"f1","url":"http://api.jolpi.ca/ergast/f1/2020/drivers/gasly/driverstandings/","limit":"30","offset":"0","total":"1",
        "StandingsTable":{"season":"2020","driverId":"gasly","round":"17","StandingsLists":[{"season":"2020","round":"17","DriverStandings":[
        {"position":"10","positionText":"10","points":"75","wins":"1",
         "Driver":{"driverId":"gasly","permanentNumber":"10","code":"GAS","url":"http://en.wikipedia.org/wiki/Pierre_Gasly","givenName":"Pierre","familyName":"Gasly","dateOfBirth":"1996-02-07","nationality":"French"},
         "Constructors":[{"constructorId":"alphatauri","url":"http://en.wikipedia.org/wiki/Scuderia_AlphaTauri","name":"AlphaTauri","nationality":"Italian"}]}]}]}}}
        """)
        let dto = try XCTUnwrap(payload.standingsTable.lists.first?.driverStandings?.first)
        let standing = JolpicaMapper.driverStanding(dto, fallbackPosition: 1)
        XCTAssertEqual(standing.position, 10)
        XCTAssertEqual(standing.points, 75)
        XCTAssertEqual(standing.wins, 1)
        XCTAssertEqual(standing.driver.code, "GAS")
        XCTAssertEqual(standing.driver.number, "10")
        XCTAssertEqual(standing.constructor?.id, "alphatauri")
        XCTAssertEqual(payload.standingsTable.lists.first?.round, "17")
    }

    func testHistoricDriverWithoutCodeGetsFallback() throws {
        let payload = try decode(JolpicaDTO.StandingsPayload.self, """
        {"MRData":{"total":"42","StandingsTable":{"season":"1972","round":"12","StandingsLists":[{"season":"1972","round":"12","DriverStandings":[
        {"position":"1","positionText":"1","points":"61","wins":"5",
         "Driver":{"driverId":"emerson_fittipaldi","givenName":"Emerson","familyName":"Fittipaldi","dateOfBirth":"1946-12-12","nationality":"Brazilian"},
         "Constructors":[{"constructorId":"team_lotus","name":"Team Lotus","nationality":"British"}]}]}]}}}
        """)
        let dto = try XCTUnwrap(payload.standingsTable.lists.first?.driverStandings?.first)
        let standing = JolpicaMapper.driverStanding(dto, fallbackPosition: 1)
        XCTAssertEqual(standing.driver.code, "FIT")
        XCTAssertNil(standing.driver.number)
        XCTAssertEqual(Flags.nationality(standing.driver.nationality), "🇧🇷")
    }

    func testScheduleWithSessions() throws {
        let payload = try decode(JolpicaDTO.RacePayload.self, """
        {"MRData":{"limit":"30","offset":"0","total":"24","RaceTable":{"season":"2024","Races":[
        {"season":"2024","round":"1","url":"https://en.wikipedia.org/wiki/2024_Bahrain_Grand_Prix","raceName":"Bahrain Grand Prix",
         "Circuit":{"circuitId":"bahrain","url":"http://en.wikipedia.org/wiki/Bahrain_International_Circuit","circuitName":"Bahrain International Circuit",
           "Location":{"lat":"26.0325","long":"50.5106","locality":"Sakhir","country":"Bahrain"}},
         "date":"2024-03-02","time":"15:00:00Z",
         "FirstPractice":{"date":"2024-02-29","time":"11:30:00Z"},
         "SecondPractice":{"date":"2024-02-29","time":"15:00:00Z"},
         "ThirdPractice":{"date":"2024-03-01","time":"12:30:00Z"},
         "Qualifying":{"date":"2024-03-01","time":"16:00:00Z"}},
        {"season":"2024","round":"5","raceName":"Chinese Grand Prix",
         "Circuit":{"circuitId":"shanghai","circuitName":"Shanghai International Circuit","Location":{"lat":"31.3389","long":"121.22","locality":"Shanghai","country":"China"}},
         "date":"2024-04-21","time":"07:00:00Z",
         "FirstPractice":{"date":"2024-04-19","time":"03:30:00Z"},
         "SprintQualifying":{"date":"2024-04-19","time":"07:30:00Z"},
         "Sprint":{"date":"2024-04-20","time":"03:00:00Z"},
         "Qualifying":{"date":"2024-04-20","time":"07:00:00Z"}}]}}}
        """)
        let races = payload.raceTable.races.compactMap(JolpicaMapper.race)
        XCTAssertEqual(races.count, 2)

        let bahrain = races[0]
        XCTAssertEqual(bahrain.round, 1)
        XCTAssertEqual(bahrain.shortName, "Bahrain")
        XCTAssertEqual(bahrain.sessions.map(\.kind), [.practice1, .practice2, .practice3, .qualifying, .race])
        XCTAssertEqual(bahrain.start, ISO8601DateFormatter().date(from: "2024-03-02T15:00:00Z"))
        XCTAssertFalse(bahrain.isSprintWeekend)
        XCTAssertNotNil(CircuitCatalog.outline(for: bahrain.circuit), "Bundled track outline should exist for Bahrain")

        let china = races[1]
        XCTAssertTrue(china.isSprintWeekend)
        XCTAssertEqual(china.sessions.map(\.kind), [.practice1, .sprintQualifying, .sprint, .qualifying, .race])
        XCTAssertEqual(Flags.country(china.circuit.country), "🇨🇳")
    }

    func testRaceWithoutTimeIsStillParsed() throws {
        let payload = try decode(JolpicaDTO.RacePayload.self, """
        {"MRData":{"total":"1","RaceTable":{"Races":[{"season":"1950","round":"1","raceName":"British Grand Prix",
        "Circuit":{"circuitId":"silverstone","circuitName":"Silverstone Circuit","Location":{"lat":"52.0786","long":"-1.01694","locality":"Silverstone","country":"UK"}},
        "date":"1950-05-13"}]}}}
        """)
        let race = try XCTUnwrap(payload.raceTable.races.compactMap(JolpicaMapper.race).first)
        XCTAssertFalse(race.raceSession.hasTime)
        XCTAssertEqual(Flags.country(race.circuit.country), "🇬🇧")
    }

    func testResultsSplitAcrossPagesAreMerged() throws {
        func result(_ position: Int, _ id: String, _ code: String, points: String) -> String {
            """
            {"number":"\(position)","position":"\(position)","positionText":"\(position)","points":"\(points)",
             "Driver":{"driverId":"\(id)","code":"\(code)","givenName":"A","familyName":"\(id.capitalized)","nationality":"British"},
             "Constructor":{"constructorId":"mclaren","name":"McLaren","nationality":"British"},
             "grid":"\(position)","laps":"71","status":"Finished","Time":{"millis":"5034543","time":"1:23:54.543"},
             "FastestLap":{"rank":"\(position)","lap":"62","Time":{"time":"1:06.200"}}}
            """
        }
        let race = #"{"season":"2021","round":"9","raceName":"Austrian Grand Prix","Circuit":{"circuitId":"red_bull_ring","circuitName":"Red Bull Ring","Location":{"locality":"Spielberg","country":"Austria"}},"date":"2021-07-04","time":"13:00:00Z","Results":[RESULTS]}"#
        let pageOne = try decode(JolpicaDTO.RacePayload.self, #"{"MRData":{"total":"3","RaceTable":{"Races":["# + race.replacingOccurrences(of: "RESULTS", with: result(1, "norris", "NOR", points: "25") + "," + result(2, "piastri", "PIA", points: "18")) + "]}}}")
        let pageTwo = try decode(JolpicaDTO.RacePayload.self, #"{"MRData":{"total":"3","RaceTable":{"Races":["# + race.replacingOccurrences(of: "RESULTS", with: result(3, "russell", "RUS", points: "15")) + "]}}}")

        let merged = JolpicaMapper.mergeResults(race: pageOne.raceTable.races + pageTwo.raceTable.races, sprint: [], qualifying: [])
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].race.map(\.driver.code), ["NOR", "PIA", "RUS"])
        XCTAssertEqual(merged[0].winner?.driver.code, "NOR")
        XCTAssertEqual(merged[0].fastestLap?.driver.code, "NOR")
        XCTAssertEqual(merged[0].podium.count, 3)
    }

    func testResultLabels() {
        let driver = Driver(id: "x", code: "XXX", givenName: "X", familyName: "X", nationality: "")
        func make(_ text: String, grid: Int? = nil) -> RaceResult {
            RaceResult(position: nil, positionText: text, points: 0, driver: driver, constructor: nil, grid: grid, laps: nil, status: "", time: nil, fastestLapRank: nil, fastestLapTime: nil)
        }
        XCTAssertEqual(make("3").label, "P3")
        XCTAssertEqual(make("R").label, "DNF")
        XCTAssertEqual(make("D").label, "DSQ")
        XCTAssertEqual(make("W").label, "DNS")
        XCTAssertEqual(make("5", grid: 9).positionsGained, 4)
        XCTAssertEqual(make("5", grid: 0).positionsGained, 17)
        XCTAssertNil(make("R", grid: 3).positionsGained)
    }
}
