import AppIntents
import WidgetKit

// MARK: - Entities

struct DriverEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { TypeDisplayRepresentation(name: "Driver") }
    static var defaultQuery: DriverQuery { DriverQuery() }

    var id: String
    var name: String
    var team: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(team)")
    }
}

struct DriverQuery: EntityQuery {
    func entities(for identifiers: [DriverEntity.ID]) async throws -> [DriverEntity] {
        all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [DriverEntity] {
        all()
    }

    func defaultResult() async -> DriverEntity? {
        let favorite = AppSettings.load().favoriteDriverId
        return all().first { $0.id == favorite } ?? all().first
    }

    private func all() -> [DriverEntity] {
        let snapshot = SnapshotStore.cachedSnapshot() ?? SampleData.snapshot(now: Date())
        return snapshot.driverStandings.map {
            DriverEntity(id: $0.driver.id, name: $0.driver.fullName, team: $0.constructor.map(TeamPalette.shortName) ?? "")
        }
    }
}

struct TeamEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { TypeDisplayRepresentation(name: "Team") }
    static var defaultQuery: TeamQuery { TeamQuery() }

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TeamQuery: EntityQuery {
    func entities(for identifiers: [TeamEntity.ID]) async throws -> [TeamEntity] {
        all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [TeamEntity] {
        all()
    }

    func defaultResult() async -> TeamEntity? {
        let favorite = AppSettings.load().favoriteTeamId
        return all().first { $0.id == favorite } ?? all().first
    }

    private func all() -> [TeamEntity] {
        let snapshot = SnapshotStore.cachedSnapshot() ?? SampleData.snapshot(now: Date())
        return snapshot.constructorStandings.map {
            TeamEntity(id: $0.constructor.id, name: TeamPalette.shortName(for: $0.constructor))
        }
    }
}

struct DesignEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation { TypeDisplayRepresentation(name: "Widget Design") }
    static var defaultQuery: DesignQuery { DesignQuery() }

    var id: UUID
    var name: String
    var detail: String

    init(design: WidgetDesign) {
        id = design.id
        name = design.name
        detail = "\(design.content.title) · \(design.theme.title)"
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(detail)")
    }
}

struct DesignQuery: EntityQuery {
    func entities(for identifiers: [DesignEntity.ID]) async throws -> [DesignEntity] {
        DesignStore.load().filter { identifiers.contains($0.id) }.map(DesignEntity.init)
    }

    func suggestedEntities() async throws -> [DesignEntity] {
        DesignStore.load().map(DesignEntity.init)
    }

    func defaultResult() async -> DesignEntity? {
        DesignStore.load().first.map(DesignEntity.init)
    }
}

// MARK: - Configuration intents

struct DriverWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Driver" }
    static var description: IntentDescription { "Follow one driver's championship." }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Driver")
    var driver: DriverEntity?
}

struct TeamWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Team" }
    static var description: IntentDescription { "Follow one constructor." }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Team")
    var team: TeamEntity?
}

struct StudioWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "My Widget" }
    static var description: IntentDescription { "Show a widget you designed in Slipstream's Widget Studio." }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Design")
    var design: DesignEntity?
}
