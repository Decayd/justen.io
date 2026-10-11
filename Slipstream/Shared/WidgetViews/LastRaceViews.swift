import SwiftUI
import WidgetKit

struct LastRaceWidgetView: View {
    let context: WidgetRenderContext

    var body: some View {
        if let results = context.snapshot.latestRaceResults, let race = context.snapshot.standingsRace(round: results.round) {
            switch context.size {
            case .small: LastRaceSmall(context: context, race: race, results: results)
            case .medium: LastRaceMedium(context: context, race: race, results: results)
            case .large: LastRaceLarge(context: context, race: race, results: results)
            case .extraLarge: LastRaceExtraLarge(context: context, race: race, results: results)
            case .circular: LastRaceCircular(results: results)
            case .rectangular: LastRaceRectangular(context: context, race: race, results: results)
            case .inline: LastRaceInline(context: context, race: race, results: results)
            }
        } else {
            NoStandingsView(context: context)
        }
    }
}

private func podiumEntries(_ results: RoundResults, context: WidgetRenderContext, withGaps: Bool = false) -> [PodiumEntry] {
    results.podium.map { result in
        PodiumEntry(
            position: Int(result.positionText) ?? 0,
            code: result.driver.code,
            team: context.teamRGB(result.constructor?.id),
            detail: withGaps ? (result.positionText == "1" ? "WINNER" : result.time) : nil
        )
    }
}

private struct RaceHeader: View {
    let context: WidgetRenderContext
    let race: Race
    var title: String? = nil
    var size: CGFloat = 9
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 5) {
            if context.showFlags { FlagText(flag: context.flag(for: race), size: size + 4) }
            CapsLabel(title ?? race.shortName, size: size, color: palette.secondary)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            CapsLabel("R\(race.round)", size: size - 0.5, color: palette.tertiary)
        }
    }
}

// MARK: - Small

private struct LastRaceSmall: View {
    let context: WidgetRenderContext
    let race: Race
    let results: RoundResults

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RaceHeader(context: context, race: race)
            PodiumView(entries: podiumEntries(results, context: context), codeSize: 12)
        }
        .widgetPadding(.small)
    }
}

// MARK: - Medium

private struct LastRaceMedium: View {
    let context: WidgetRenderContext
    let race: Race
    let results: RoundResults
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                RaceHeader(context: context, race: race)
                PodiumView(entries: podiumEntries(results, context: context), codeSize: 12)
            }
            .frame(width: 128)

            VStack(alignment: .leading, spacing: 0) {
                CapsLabel("Classification", size: 8, color: palette.tertiary)
                    .padding(.bottom, 3)
                ForEach(Array(results.race.dropFirst(3).prefix(5).enumerated()), id: \.offset) { _, result in
                    ClassificationRow(context: context, result: result, compact: true)
                        .frame(maxHeight: .infinity)
                }
                if let fastest = results.fastestLap {
                    FastestLapRow(context: context, result: fastest)
                        .padding(.top, 2)
                }
            }
        }
        .widgetPadding(.medium)
    }
}

private struct ClassificationRow: View {
    let context: WidgetRenderContext
    let result: RaceResult
    var compact = false
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 6) {
            Text(result.isClassified ? result.positionText : "–")
                .font(Typo.number(compact ? 10 : 11, weight: .heavy))
                .foregroundStyle(palette.tertiary)
                .frame(width: 16, alignment: .leading)
            TeamStripe(color: context.teamColor(result.constructor?.id), width: 3, height: compact ? 13 : 16)
            if compact {
                Text(result.driver.code)
                    .font(Typo.code(12, weight: .heavy))
                    .foregroundStyle(palette.primary)
            } else {
                Text(result.driver.familyName.uppercased())
                    .font(Typo.display(10.5, weight: .heavy))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: 92, alignment: .leading)
                if let gained = result.positionsGained, gained != 0 {
                    PositionsDelta(value: gained)
                }
            }
            Spacer(minLength: 2)
            Text(result.gapText)
                .font(Typo.number(compact ? 10 : 10.5, weight: .semibold))
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if !compact {
                Text(result.points > 0 ? "+\(Fmt.points(result.points))" : "")
                    .font(Typo.number(10.5, weight: .heavy))
                    .foregroundStyle(palette.accent)
                    .frame(width: 26, alignment: .trailing)
            }
        }
    }
}

private struct PositionsDelta: View {
    let value: Int
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 1) {
            Image(systemName: value > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.system(size: 6))
            Text("\(abs(value))")
                .font(Typo.number(9, weight: .bold))
        }
        .foregroundStyle(value > 0 ? Color(hex: "#2FBF71") : Color(hex: "#FF5A4F"))
    }
}

private struct FastestLapRow: View {
    let context: WidgetRenderContext
    let result: RaceResult
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(WidgetPalette.purple)
                .frame(width: 16, alignment: .leading)
                .widgetAccentable()
            Text(result.driver.code)
                .font(Typo.code(12, weight: .heavy))
                .foregroundStyle(palette.primary)
            Spacer(minLength: 2)
            Text(result.fastestLapTime ?? "Fastest lap")
                .font(Typo.number(10, weight: .bold))
                .foregroundStyle(WidgetPalette.purple)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(WidgetPalette.purple.opacity(0.14), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Large

private struct LastRaceLarge: View {
    let context: WidgetRenderContext
    let race: Race
    let results: RoundResults
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                if context.showFlags { FlagText(flag: context.flag(for: race), size: 15) }
                CapsLabel("Round \(race.round) · \(Fmt.day(race.start))", size: 9)
                Spacer(minLength: 0)
                CapsLabel("Result", size: 9, color: palette.tertiary)
            }
            Text(race.name.uppercased())
                .font(Typo.display(17))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 5)

            PodiumView(entries: podiumEntries(results, context: context, withGaps: true), codeSize: 14, showDetail: true)
                .frame(height: 112)
                .padding(.horizontal, 30)
                .padding(.top, 10)

            Rectangle().fill(palette.hairline).frame(height: 1).padding(.vertical, 8)

            VStack(spacing: 0) {
                ForEach(Array(results.race.dropFirst(3).prefix(7).enumerated()), id: \.offset) { _, result in
                    ClassificationRow(context: context, result: result)
                        .frame(maxHeight: .infinity)
                }
            }
            if let fastest = results.fastestLap {
                FastestLapRow(context: context, result: fastest)
                    .padding(.top, 6)
            }
        }
        .widgetPadding(context.size)
    }
}

// MARK: - Extra large (iPad)

private struct LastRaceExtraLarge: View {
    let context: WidgetRenderContext
    let race: Race
    let results: RoundResults
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .top, spacing: 26) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    if context.showFlags { FlagText(flag: context.flag(for: race), size: 15) }
                    CapsLabel("Round \(race.round) · \(Fmt.day(race.start))", size: 9)
                }
                Text(race.name.uppercased())
                    .font(Typo.display(19))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 5)
                PodiumView(entries: podiumEntries(results, context: context, withGaps: true), codeSize: 15, showDetail: true)
                    .padding(.top, 14)
                if let fastest = results.fastestLap {
                    FastestLapRow(context: context, result: fastest)
                        .padding(.top, 10)
                }
            }
            .frame(width: 300)

            VStack(spacing: 0) {
                HStack {
                    CapsLabel("Classification", size: 8, color: palette.tertiary)
                    Spacer()
                    CapsLabel("Pts", size: 8, color: palette.tertiary)
                }
                .padding(.bottom, 4)
                ForEach(Array(results.race.dropFirst(3).prefix(10).enumerated()), id: \.offset) { _, result in
                    ClassificationRow(context: context, result: result)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .widgetPadding(.extraLarge)
    }
}

// MARK: - Lock Screen

private struct LastRaceCircular: View {
    let results: RoundResults

    var body: some View {
        ZStack {
            AccessoryCircleBackground()
            VStack(spacing: 0) {
                Image(systemName: "trophy.fill").font(.system(size: 12, weight: .bold))
                Text(results.winner?.driver.code ?? "—").font(Typo.display(14, weight: .heavy)).minimumScaleFactor(0.6)
            }
            .widgetAccentable()
        }
    }
}

private struct LastRaceRectangular: View {
    let context: WidgetRenderContext
    let race: Race
    let results: RoundResults

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill").font(.system(size: 10, weight: .bold))
                Text(race.shortName.uppercased())
                    .font(Typo.label(10, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .widgetAccentable()
            ForEach(Array(results.podium.enumerated()), id: \.offset) { index, result in
                HStack(spacing: 5) {
                    Text("\(index + 1)").font(Typo.number(11, weight: .heavy)).opacity(0.7)
                    Text(result.driver.code).font(Typo.display(11.5, weight: .heavy))
                    Spacer(minLength: 2)
                    Text(index == 0 ? "WIN" : (result.time ?? "")).font(Typo.number(10.5, weight: .semibold)).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LastRaceInline: View {
    let context: WidgetRenderContext
    let race: Race
    let results: RoundResults

    var body: some View {
        let flag = context.showFlags ? "\(context.flag(for: race)) " : ""
        Text("🏆 \(results.winner?.driver.code ?? "—") wins \(flag)\(race.shortName)")
    }
}
