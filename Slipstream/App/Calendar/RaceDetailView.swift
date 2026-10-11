import SwiftUI

struct RaceDetailView: View {
    let season: Int
    let round: Int
    @Environment(AppModel.self) private var model
    @State private var archive: SeasonSnapshot?
    @State private var error: String?

    /// The race plus whichever snapshot holds its results.
    private var resolved: (race: Race, results: RoundResults?)? {
        if let snapshot = model.snapshot {
            if season == snapshot.standingsSeason, let race = snapshot.standingsRace(round: round) {
                return (race, snapshot.results(round: round))
            }
            if season == snapshot.season, let race = snapshot.races.first(where: { $0.round == round }) {
                return (race, nil)
            }
        }
        if let archive, let race = archive.standingsRace(round: round) {
            return (race, archive.results(round: round))
        }
        return nil
    }

    var body: some View {
        ScrollView {
            if let resolved {
                RaceDetailContent(race: resolved.race, results: resolved.results)
                    .padding(16)
            } else if let error {
                ContentUnavailableView("Couldn't load this race", systemImage: "wifi.exclamationmark", description: Text(error))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .task { await loadArchive() }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(resolved?.race.shortName ?? "Race")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadArchive() async {
        do {
            archive = try await model.season(season)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private enum ResultsTab: String, CaseIterable, Identifiable {
    case race = "Race"
    case qualifying = "Qualifying"
    case sprint = "Sprint"
    var id: String { rawValue }
}

private struct RaceDetailContent: View {
    let race: Race
    let results: RoundResults?
    @State private var tab: ResultsTab = .race
    @Environment(\.palette) private var palette

    private var outline: CircuitOutline? { CircuitCatalog.outline(for: race.circuit) }

    private var availableTabs: [ResultsTab] {
        guard let results else { return [] }
        var tabs: [ResultsTab] = []
        if !results.race.isEmpty { tabs.append(.race) }
        if !results.qualifying.isEmpty { tabs.append(.qualifying) }
        if !results.sprint.isEmpty { tabs.append(.sprint) }
        return tabs
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            scheduleCard
            if !availableTabs.isEmpty {
                resultsCard
            }
        }
        .onAppear {
            if let first = availableTabs.first, !availableTabs.contains(tab) { tab = first }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(Flags.country(race.circuit.country)).font(.title)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ROUND \(race.round) · \(String(race.season))")
                        .font(Typo.label(10, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(Fmt.weekend(race).uppercased())
                        .font(Typo.label(10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                if race.isSprintWeekend { SprintBadge() }
            }
            Text(race.name.uppercased())
                .font(Typo.display(24, weight: .heavy))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text("\(race.circuit.name) · \(race.circuit.locality), \(race.circuit.country)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
            TrackMapView(circuit: race.circuit, color: AppColors.red, lineWidth: 3.5)
                .frame(height: 180)
                .padding(.vertical, 6)
            HStack {
                if let length = outline?.lengthText { StatPill(label: "Length", value: length) }
                if let first = outline?.firstGP { StatPill(label: "First GP", value: String(first)) }
                Spacer()
            }
        }
        .padding(18)
        .background(HeroBackground())
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .environment(\.palette, .dark(accent: RGB(hex: "#E10600"), background: .carbon))
        .environment(\.colorScheme, .dark)
    }

    private var scheduleCard: some View {
        Card {
            SectionTitle("Schedule · your time")
            VStack(spacing: 0) {
                ForEach(Array(race.sessions.enumerated()), id: \.offset) { index, session in
                    TimelineView(.periodic(from: .now, by: 60)) { timeline in
                        let state = session.state(at: timeline.date)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.kind.label).font(.body.weight(.semibold))
                                Text(session.start.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            switch state {
                            case .live:
                                LiveBadge(text: "LIVE")
                            case .finished:
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.secondary)
                            case .upcoming:
                                EmptyView()
                            }
                            Text(session.hasTime ? Fmt.time(session.start) : "TBC")
                                .font(Typo.number(15, weight: .bold))
                                .foregroundStyle(state == .finished ? Color.secondary : Color.primary)
                        }
                        .padding(.vertical, 10)
                    }
                    if index < race.sessions.count - 1 { Divider() }
                }
            }
            .padding(.top, 6)
        }
    }

    private var resultsCard: some View {
        Card {
            Picker("Results", selection: $tab) {
                ForEach(availableTabs) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)

            if let results {
                switch tab {
                case .race: classification(results.race, isSprint: false)
                case .sprint: classification(results.sprint, isSprint: true)
                case .qualifying: qualifying(results.qualifying)
                }
            }
        }
    }

    private func classification(_ rows: [RaceResult], isSprint: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, result in
                HStack(spacing: 10) {
                    Text(result.isClassified ? result.positionText : result.label)
                        .font(Typo.number(13, weight: .heavy))
                        .foregroundStyle(result.isClassified ? Color.primary : Color.secondary)
                        .frame(width: 34, alignment: .leading)
                    TeamStripe(color: palette.team(result.constructor?.id, season: race.season), width: 4, height: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 5) {
                            Text(result.driver.familyName).font(.subheadline.weight(.semibold))
                            if result.fastestLapRank == 1 && !isSprint {
                                Image(systemName: "stopwatch.fill")
                                    .font(.caption2)
                                    .foregroundStyle(WidgetPalette.purple)
                            }
                        }
                        Text(result.constructor.map(TeamPalette.shortName) ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(result.gapText)
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if result.points > 0 {
                            Text("+\(Fmt.points(result.points)) pts")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppColors.red)
                        }
                    }
                }
                .padding(.vertical, 8)
                if index < rows.count - 1 { Divider().padding(.leading, 44) }
            }
        }
    }

    private func qualifying(_ rows: [QualifyingResult]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, result in
                HStack(spacing: 10) {
                    Text(result.position.map(String.init) ?? "–")
                        .font(Typo.number(13, weight: .heavy))
                        .frame(width: 34, alignment: .leading)
                    TeamStripe(color: palette.team(result.constructor?.id, season: race.season), width: 4, height: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(result.driver.familyName).font(.subheadline.weight(.semibold))
                        Text(result.constructor.map(TeamPalette.shortName) ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(result.bestTime ?? "No time")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(result.position == 1 ? WidgetPalette.purple : .primary)
                }
                .padding(.vertical, 8)
                if index < rows.count - 1 { Divider().padding(.leading, 44) }
            }
        }
    }
}

private struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(Typo.label(8, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(Typo.number(13, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
