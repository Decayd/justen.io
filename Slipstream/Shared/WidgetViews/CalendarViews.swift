import SwiftUI
import WidgetKit

struct CalendarWidgetView: View {
    let context: WidgetRenderContext

    var body: some View {
        let races = context.snapshot.upcomingRaces(after: context.now, limit: limit)
        if races.isEmpty {
            SeasonOverView(context: context)
        } else {
            switch context.size {
            case .inline:
                NextRaceWidgetView(context: context)
            case .circular:
                SeasonProgressCircular(context: context)
            case .rectangular:
                CalendarRectangular(context: context, races: races)
            default:
                CalendarList(context: context, races: races)
            }
        }
    }

    private var limit: Int {
        switch context.size {
        case .small: 3
        case .medium: 4
        case .large: 8
        case .extraLarge: 8
        case .rectangular: 3
        default: 1
        }
    }
}

private struct CalendarList: View {
    let context: WidgetRenderContext
    let races: [Race]
    @Environment(\.palette) private var palette

    private var isSmall: Bool { context.size == .small }
    private var completed: Int { context.snapshot.races.filter { $0.end <= context.now }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer(minLength: isSmall ? 6 : 8)
            VStack(spacing: isSmall ? 6 : rowSpacing) {
                ForEach(Array(races.enumerated()), id: \.offset) { index, race in
                    if isSmall {
                        CompactRaceRow(context: context, race: race, isNext: index == 0)
                    } else {
                        CalendarRow(context: context, race: race, isNext: index == 0)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .widgetPadding(context.size)
    }

    private var rowSpacing: CGFloat {
        context.size == .medium ? 3 : 6
    }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 6) {
            CapsLabel(isSmall ? "Up next" : "\(String(context.snapshot.season)) Calendar", size: 9)
            Spacer(minLength: 0)
            if !isSmall {
                CapsLabel("\(completed) of \(context.snapshot.races.count) done", size: 8.5, color: palette.tertiary)
            }
        }
        if !isSmall {
            SeasonProgressBar(completed: completed, total: context.snapshot.races.count)
                .padding(.top, 6)
        }
    }
}

struct SeasonProgressBar: View {
    let completed: Int
    let total: Int
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index < completed ? palette.accent : palette.track)
                    .frame(height: 4)
                    .widgetAccentable(index < completed)
            }
        }
    }
}

private struct CalendarRow: View {
    let context: WidgetRenderContext
    let race: Race
    let isNext: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 8) {
            Text("R\(race.round)")
                .font(Typo.number(9.5, weight: .heavy))
                .foregroundStyle(palette.tertiary)
                .frame(width: 24, alignment: .leading)
            if context.showFlags { FlagText(flag: context.flag(for: race), size: 14) }
            VStack(alignment: .leading, spacing: 0) {
                Text(race.shortName.uppercased())
                    .font(Typo.display(isNext ? 12 : 11, weight: .heavy))
                    .foregroundStyle(isNext ? palette.primary : palette.primary.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if context.size != .medium || isNext {
                    Text(race.circuit.locality)
                        .font(Typo.text(9.5, weight: .medium))
                        .foregroundStyle(palette.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if race.isSprintWeekend { SprintBadge(compact: true) }
            if isNext {
                Text(Countdown(now: context.now, session: race.raceSession).compact)
                    .font(Typo.number(11, weight: .heavy))
                    .foregroundStyle(palette.accent)
                    .widgetAccentable()
            } else {
                Text(Fmt.weekend(race))
                    .font(Typo.number(10.5, weight: .semibold))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, isNext ? 8 : 0)
        .padding(.vertical, isNext ? 5 : 0)
        .background {
            if isNext {
                RoundedRectangle(cornerRadius: 9, style: .continuous).fill(palette.card)
            }
        }
        .padding(.horizontal, isNext ? 0 : 8)
    }
}

private struct CompactRaceRow: View {
    let context: WidgetRenderContext
    let race: Race
    let isNext: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 6) {
            if context.showFlags { FlagText(flag: context.flag(for: race), size: isNext ? 16 : 13) }
            VStack(alignment: .leading, spacing: 0) {
                Text(race.shortName.uppercased())
                    .font(Typo.display(isNext ? 12 : 10.5, weight: .heavy))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Text(isNext ? "in \(Countdown(now: context.now, session: race.raceSession).compact)" : Fmt.weekend(race))
                    .font(Typo.number(isNext ? 10.5 : 9.5, weight: isNext ? .bold : .medium))
                    .foregroundStyle(isNext ? palette.accent : palette.tertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            if race.isSprintWeekend { SprintBadge(compact: true) }
        }
    }
}

private struct CalendarRectangular: View {
    let context: WidgetRenderContext
    let races: [Race]

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(races.prefix(3).enumerated()), id: \.offset) { index, race in
                HStack(spacing: 4) {
                    Text(race.shortName.uppercased())
                        .font(Typo.display(index == 0 ? 12 : 11, weight: index == 0 ? .heavy : .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 2)
                    Text(index == 0 ? Countdown(now: context.now, session: race.raceSession).compact : Fmt.day(race.start))
                        .font(Typo.number(11, weight: .semibold))
                }
                .opacity(index == 0 ? 1 : 0.75)
                .widgetAccentable(index == 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A ring showing how much of the season has been run.
struct SeasonProgressCircular: View {
    let context: WidgetRenderContext

    var body: some View {
        let total = max(context.snapshot.races.count, 1)
        let done = context.snapshot.races.filter { $0.end <= context.now }.count
        ZStack {
            AccessoryCircleBackground()
            RingGauge(fraction: Double(done) / Double(total), lineWidth: 4.5)
                .padding(3)
            VStack(spacing: -2) {
                Text("\(done)").font(Typo.display(18, weight: .heavy))
                Text("OF \(total)").font(Typo.label(7, weight: .heavy)).opacity(0.75)
            }
        }
    }
}
