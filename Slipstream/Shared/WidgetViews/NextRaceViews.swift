import SwiftUI
import WidgetKit

struct NextRaceWidgetView: View {
    let context: WidgetRenderContext

    var body: some View {
        if let race = context.snapshot.nextRace(after: context.now) {
            let target = context.snapshot.countdownTarget(for: race, now: context.now, mode: context.design.countdown)
            switch context.size {
            case .small: NextRaceSmall(context: context, race: race, target: target)
            case .medium: NextRaceMedium(context: context, race: race, target: target)
            case .large: NextRaceLarge(context: context, race: race, target: target)
            case .extraLarge: NextRaceExtraLarge(context: context, race: race, target: target)
            case .circular: NextRaceCircular(context: context, race: race, target: target)
            case .rectangular: NextRaceRectangular(context: context, race: race, target: target)
            case .inline: NextRaceInline(context: context, race: race, target: target)
            }
        } else {
            SeasonOverView(context: context)
        }
    }
}

/// "RACE · SUN 20:00", or "QUALIFYING · ON TRACK" while live.
func sessionCaption(_ session: Session, now: Date) -> String {
    switch session.state(at: now) {
    case .live: return "\(session.kind.label) · on track"
    case .finished: return "\(session.kind.label) · finished"
    case .upcoming: return "\(session.kind.label) · \(Fmt.sessionMoment(session.start))"
    }
}

// MARK: - Small

private struct NextRaceSmall: View {
    let context: WidgetRenderContext
    let race: Race
    let target: Session
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                if context.showFlags { FlagText(flag: context.flag(for: race), size: 13) }
                CapsLabel("Round \(race.round)", size: 8.5)
                Spacer(minLength: 0)
                if race.isSprintWeekend { SprintBadge(compact: true) }
            }
            if context.design.showTrackMap {
                TrackMapView(circuit: race.circuit, color: palette.accent, lineWidth: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 3)
            } else {
                Spacer(minLength: 6)
            }
            Text(race.shortName.uppercased())
                .font(Typo.display(context.design.showTrackMap ? 14 : 17))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            CountdownText(
                countdown: Countdown(now: context.now, session: target),
                numberSize: context.design.showTrackMap ? 19 : 26,
                unitSize: 8
            )
            .padding(.top, 1)
            CapsLabel(sessionCaption(target, now: context.now), size: 7.5, color: palette.tertiary)
                .minimumScaleFactor(0.7)
                .padding(.top, 2)
        }
        .widgetPadding(.small)
    }
}

// MARK: - Medium

private struct NextRaceMedium: View {
    let context: WidgetRenderContext
    let race: Race
    let target: Session
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 4) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            if context.showFlags { FlagText(flag: context.flag(for: race), size: 14) }
                            CapsLabel("Round \(race.round)", size: 8.5)
                                .minimumScaleFactor(0.75)
                        }
                        if race.isSprintWeekend { SprintBadge() }
                    }
                    .layoutPriority(1)
                    Spacer(minLength: 2)
                    if context.design.showTrackMap {
                        TrackMapView(circuit: race.circuit, color: palette.accent, lineWidth: 1.8)
                            .frame(width: 60, height: 42)
                    }
                }
                Spacer(minLength: 2)
                Text(race.shortName.uppercased())
                    .font(Typo.display(17))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("\(race.circuit.locality) · \(Fmt.weekend(race))")
                    .font(Typo.text(10, weight: .medium))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                CountdownText(countdown: Countdown(now: context.now, session: target), numberSize: 21, unitSize: 8)
                CapsLabel(target.state(at: context.now) == .upcoming ? "until \(target.kind.label)" : target.kind.label,
                          size: 7.5, color: palette.tertiary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(palette.hairline)
                .frame(width: 1)

            ScheduleList(race: race, now: context.now, highlight: target)
                .frame(width: 122)
        }
        .widgetPadding(.medium)
    }
}

// MARK: - Large

private struct NextRaceLarge: View {
    let context: WidgetRenderContext
    let race: Race
    let target: Session
    @Environment(\.palette) private var palette

    private var outline: CircuitOutline? { CircuitCatalog.outline(for: race.circuit) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                if context.showFlags { FlagText(flag: context.flag(for: race), size: 15) }
                CapsLabel("Round \(race.round) of \(context.snapshot.races.count)", size: 9)
                Spacer(minLength: 0)
                if race.isSprintWeekend { SprintBadge() }
            }
            Text(race.name.uppercased())
                .font(Typo.display(18))
                .foregroundStyle(palette.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .padding(.top, 6)
            Text(race.circuit.name)
                .font(Typo.text(11, weight: .medium))
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
                .padding(.top, 2)

            if context.design.showTrackMap {
                ZStack(alignment: .bottom) {
                    TrackMapView(circuit: race.circuit, color: palette.accent, lineWidth: 2.6)
                        .padding(.bottom, 14)
                    HStack(alignment: .bottom) {
                        if let length = outline?.lengthText {
                            MiniStat(label: "Length", value: length)
                        }
                        Spacer(minLength: 0)
                        if let first = outline?.firstGP {
                            MiniStat(label: "First GP", value: "\(first)", alignment: .trailing)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 8)
            } else {
                Spacer(minLength: 10)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                CountdownText(countdown: Countdown(now: context.now, session: target), numberSize: 26, unitSize: 9)
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 1) {
                    CapsLabel(target.state(at: context.now) == .upcoming ? "until \(target.kind.label)" : target.kind.label,
                              size: 7.5, color: palette.tertiary)
                    Text(Fmt.sessionMoment(target.start))
                        .font(Typo.text(11, weight: .semibold))
                        .foregroundStyle(palette.secondary)
                }
            }

            Rectangle()
                .fill(palette.hairline)
                .frame(height: 1)
                .padding(.vertical, 8)

            WeekendGrid(race: race, now: context.now, highlight: target)
        }
        .widgetPadding(context.size)
    }
}

// MARK: - Extra large (iPad)

private struct NextRaceExtraLarge: View {
    let context: WidgetRenderContext
    let race: Race
    let target: Session
    @Environment(\.palette) private var palette

    private var outline: CircuitOutline? { CircuitCatalog.outline(for: race.circuit) }

    var body: some View {
        HStack(alignment: .top, spacing: 26) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    if context.showFlags { FlagText(flag: context.flag(for: race), size: 15) }
                    CapsLabel("Round \(race.round) of \(context.snapshot.races.count)", size: 9)
                    if race.isSprintWeekend { SprintBadge() }
                }
                Text(race.name.uppercased())
                    .font(Typo.display(20))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 6)
                Text("\(race.circuit.name) · \(race.circuit.locality)")
                    .font(Typo.text(11, weight: .medium))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .padding(.top, 2)
                TrackMapView(circuit: race.circuit, color: palette.accent, lineWidth: 3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 10)
                HStack {
                    if let length = outline?.lengthText { MiniStat(label: "Length", value: length) }
                    Spacer(minLength: 0)
                    if let first = outline?.firstGP { MiniStat(label: "First GP", value: "\(first)", alignment: .trailing) }
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                CapsLabel(target.state(at: context.now) == .upcoming ? "until \(target.kind.label)" : target.kind.label,
                          size: 8, color: palette.tertiary)
                CountdownText(countdown: Countdown(now: context.now, session: target), numberSize: 34, unitSize: 10)
                    .padding(.top, 4)
                Text(Fmt.sessionMoment(target.start))
                    .font(Typo.text(12, weight: .semibold))
                    .foregroundStyle(palette.secondary)
                    .padding(.top, 2)
                Rectangle()
                    .fill(palette.hairline)
                    .frame(height: 1)
                    .padding(.vertical, 12)
                WeekendGrid(race: race, now: context.now, highlight: target)
                Spacer(minLength: 0)
            }
            .frame(width: 300)
        }
        .widgetPadding(.extraLarge)
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    var alignment: HorizontalAlignment = .leading
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            CapsLabel(label, size: 7, color: palette.tertiary)
            Text(value)
                .font(Typo.number(11, weight: .bold))
                .foregroundStyle(palette.secondary)
        }
    }
}

// MARK: - Schedule

/// One row per session: day, session, local start time and state.
struct ScheduleList: View {
    let race: Race
    let now: Date
    let highlight: Session?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(race.sessions.enumerated()), id: \.offset) { index, session in
                ScheduleRow(
                    session: session,
                    showDay: index == 0 || !Calendar.current.isDate(session.start, inSameDayAs: race.sessions[index - 1].start),
                    state: session.state(at: now),
                    isHighlighted: session == highlight
                )
                .frame(maxHeight: .infinity)
            }
        }
    }
}

private struct ScheduleRow: View {
    let session: Session
    let showDay: Bool
    let state: SessionState
    let isHighlighted: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 5) {
            Text(showDay ? Fmt.weekday(session.start) : "")
                .font(Typo.label(7.5, weight: .bold))
                .foregroundStyle(palette.tertiary)
                .frame(width: 24, alignment: .leading)
            Text(session.kind.shortLabel)
                .font(Typo.code(11, weight: .heavy))
                .foregroundStyle(isHighlighted ? palette.accent : palette.primary)
                .lineLimit(1)
            Spacer(minLength: 2)
            switch state {
            case .live:
                LiveBadge()
            case .finished:
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(palette.tertiary)
                Text(Fmt.time(session.start))
                    .font(Typo.number(10.5, weight: .medium))
                    .foregroundStyle(palette.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            case .upcoming:
                Text(Fmt.time(session.start))
                    .font(Typo.number(10.5, weight: isHighlighted ? .heavy : .semibold))
                    .foregroundStyle(isHighlighted ? palette.accent : palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .opacity(state == .finished ? 0.75 : 1)
    }
}

/// Sessions grouped by day: "FRI  FP1 10:30  FP2 14:00".
struct WeekendGrid: View {
    let race: Race
    let now: Date
    let highlight: Session?
    @Environment(\.palette) private var palette

    private var days: [[Session]] {
        var groups: [[Session]] = []
        for session in race.sessions {
            if let last = groups.last?.last, Calendar.current.isDate(last.start, inSameDayAs: session.start) {
                groups[groups.count - 1].append(session)
            } else {
                groups.append([session])
            }
        }
        return groups
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, sessions in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(Fmt.weekday(sessions[0].start))
                            .font(Typo.label(9, weight: .heavy))
                            .foregroundStyle(palette.secondary)
                        Text(sessions[0].start.formatted(.dateTime.day()))
                            .font(Typo.number(9, weight: .semibold))
                            .foregroundStyle(palette.tertiary)
                    }
                    .frame(width: 30, alignment: .leading)
                    ForEach(Array(sessions.enumerated()), id: \.offset) { _, session in
                        SessionPill(session: session, state: session.state(at: now), isHighlighted: session == highlight)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

private struct SessionPill: View {
    let session: Session
    let state: SessionState
    let isHighlighted: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 5) {
            Text(session.kind.shortLabel)
                .font(Typo.code(10.5, weight: .heavy))
                .foregroundStyle(isHighlighted ? palette.accent : palette.primary)
            if state == .live {
                LiveBadge()
            } else {
                Text(Fmt.time(session.start))
                    .font(Typo.number(10.5, weight: .semibold))
                    .foregroundStyle(state == .finished ? palette.tertiary : palette.secondary)
            }
        }
        .lineLimit(1)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(isHighlighted ? palette.accent.opacity(0.16) : palette.card, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .opacity(state == .finished ? 0.6 : 1)
    }
}

// MARK: - Lock Screen

private struct NextRaceCircular: View {
    let context: WidgetRenderContext
    let race: Race
    let target: Session

    var body: some View {
        let countdown = Countdown(now: context.now, session: target)
        ZStack {
            AccessoryCircleBackground()
            VStack(spacing: -1) {
                Text(target.kind.shortLabel)
                    .font(Typo.label(7, weight: .heavy))
                    .opacity(0.8)
                switch countdown.phase {
                case .days(let days, _):
                    value("\(days)", unit: days == 1 ? "DAY" : "DAYS")
                case .hours(let hours, _):
                    value("\(hours)", unit: hours == 1 ? "HR" : "HRS")
                case .final:
                    Text(timerInterval: context.now...max(context.now, target.start), countsDown: true)
                        .font(Typo.number(13, weight: .heavy))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 52)
                case .live:
                    Text("LIVE").font(Typo.display(13, weight: .black))
                case .finished:
                    Image(systemName: "flag.checkered").font(.system(size: 16, weight: .bold))
                }
            }
            .widgetAccentable()
        }
    }

    private func value(_ number: String, unit: String) -> some View {
        VStack(spacing: -2) {
            Text(number)
                .font(Typo.display(22, weight: .heavy))
                .minimumScaleFactor(0.6)
            Text(unit)
                .font(Typo.label(7, weight: .heavy))
        }
    }
}

private struct NextRaceRectangular: View {
    let context: WidgetRenderContext
    let race: Race
    let target: Session

    var body: some View {
        let countdown = Countdown(now: context.now, session: target)
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                if context.showFlags { Text(context.flag(for: race)).font(.system(size: 12)) }
                Text(race.shortName.uppercased())
                    .font(Typo.display(13, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .widgetAccentable()
            }
            Text("\(target.kind.label) · \(Fmt.sessionMoment(target.start))")
                .font(Typo.text(12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Group {
                switch countdown.phase {
                case .live: Text("On track now")
                case .final: Text("Starts in ") + Text(timerInterval: context.now...max(context.now, target.start), countsDown: true)
                default: Text("Starts in \(countdown.compact)")
                }
            }
            .font(Typo.text(12, weight: .regular))
            .opacity(0.75)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NextRaceInline: View {
    let context: WidgetRenderContext
    let race: Race
    let target: Session

    var body: some View {
        let countdown = Countdown(now: context.now, session: target)
        let flag = context.showFlags ? "\(context.flag(for: race)) " : ""
        Text("\(flag)\(race.shortName) · \(target.kind.shortLabel.capitalized) \(countdown.compact)")
    }
}

// MARK: - Off season

struct SeasonOverView: View {
    let context: WidgetRenderContext
    @Environment(\.palette) private var palette

    private var champion: DriverStanding? { context.snapshot.driverStandings.first }

    var body: some View {
        switch context.size {
        case .inline:
            Text("🏆 \(champion?.driver.code ?? "F1") · \(String(context.season)) Champion")
        case .circular:
            ZStack {
                AccessoryCircleBackground()
                VStack(spacing: 0) {
                    Image(systemName: "trophy.fill").font(.system(size: 13, weight: .bold))
                    Text(champion?.driver.code ?? "F1").font(Typo.display(13, weight: .heavy))
                }
                .widgetAccentable()
            }
        case .rectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("\(String(context.season)) CHAMPION").font(Typo.label(10, weight: .heavy)).widgetAccentable()
                Text(champion?.driver.fullName ?? "Season complete").font(Typo.text(13, weight: .bold)).lineLimit(1)
                Text("New calendar coming soon").font(Typo.text(12)).opacity(0.75).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            WidgetMessage(
                symbol: "trophy.fill",
                title: "\(String(context.season)) World Champion",
                message: champion.map { "\($0.driver.fullName) · \(Fmt.points($0.points)) pts" } ?? "The season is complete."
            )
            .widgetPadding(context.size)
        }
    }
}
