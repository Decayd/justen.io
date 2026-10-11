import Foundation

/// What a widget shows.
enum WidgetContent: String, Codable, CaseIterable, Identifiable, Sendable {
    case nextRace, calendar, driverStandings, constructorStandings, lastRace, driver, team, titleFight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nextRace: "Next Race"
        case .calendar: "Calendar"
        case .driverStandings: "Drivers' Standings"
        case .constructorStandings: "Constructors' Standings"
        case .lastRace: "Race Result"
        case .driver: "Driver"
        case .team: "Team"
        case .titleFight: "Title Fight"
        }
    }

    var summary: String {
        switch self {
        case .nextRace: "Countdown, track map and the weekend schedule in your time zone."
        case .calendar: "The next rounds at a glance, with sprint weekends marked."
        case .driverStandings: "The championship order with points bars in team colours."
        case .constructorStandings: "Team standings with each driver's share of the points."
        case .lastRace: "The podium and classification from the latest Grand Prix."
        case .driver: "One driver: position, points, wins, podiums and recent form."
        case .team: "One team: position, points and how its drivers compare."
        case .titleFight: "Points progression of the contenders and what's still possible."
        }
    }

    var symbol: String {
        switch self {
        case .nextRace: "flag.checkered"
        case .calendar: "calendar"
        case .driverStandings: "list.number"
        case .constructorStandings: "car.2.fill"
        case .lastRace: "trophy.fill"
        case .driver: "person.fill"
        case .team: "shield.lefthalf.filled"
        case .titleFight: "chart.line.uptrend.xyaxis"
        }
    }

    var needsDriver: Bool { self == .driver }
    var needsTeam: Bool { self == .team }
    var usesCountdown: Bool { self == .nextRace || self == .calendar }
    var usesTrackMap: Bool { self == .nextRace }
    var supportsLivery: Bool { self == .driver || self == .team }

    var defaultTheme: WidgetTheme { supportsLivery ? .team : .auto }
    var defaultAccent: AccentStyle { supportsLivery ? .team : .racingRed }
}

/// A user-built widget: content plus styling. Designs are size-independent; each
/// one renders natively in every widget size.
struct WidgetDesign: Codable, Hashable, Identifiable, Sendable {
    var id = UUID()
    var name: String
    var content: WidgetContent
    var theme: WidgetTheme
    var accent: AccentStyle
    var driverId: String?
    var constructorId: String?
    var countdown: CountdownMode = .smart
    var showTrackMap = true
    var showFlags = true
    var createdAt = Date()
    var updatedAt = Date()

    init(
        name: String? = nil,
        content: WidgetContent,
        theme: WidgetTheme? = nil,
        accent: AccentStyle? = nil,
        driverId: String? = nil,
        constructorId: String? = nil
    ) {
        self.name = name ?? content.title
        self.content = content
        self.theme = theme ?? content.defaultTheme
        self.accent = accent ?? content.defaultAccent
        self.driverId = driverId
        self.constructorId = constructorId
    }

    /// Short description for pickers: "Livery · Racing Red".
    var styleSummary: String {
        "\(theme.title) · \(accent.title)"
    }
}

enum DesignStore {
    private static let fileName = "widget-designs.json"

    static func load() -> [WidgetDesign] {
        SharedStorage.read([WidgetDesign].self, from: fileName) ?? []
    }

    static func save(_ designs: [WidgetDesign]) {
        try? SharedStorage.write(designs, to: fileName)
    }

    static func design(id: UUID) -> WidgetDesign? {
        load().first { $0.id == id }
    }
}

/// App-wide preferences shared with the widget extension.
struct AppSettings: Codable, Hashable, Sendable {
    var favoriteDriverId: String?
    var favoriteTeamId: String?
    var defaultTheme: WidgetTheme = .auto
    var defaultAccent: AccentStyle = .racingRed

    private static let key = "app-settings"

    static func load() -> AppSettings {
        guard let data = SharedStorage.defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else { return AppSettings() }
        return settings
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        SharedStorage.defaults.set(data, forKey: Self.key)
    }
}
