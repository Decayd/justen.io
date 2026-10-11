import Foundation

/// When widgets should refresh their data and which moments need their own timeline entry.
enum WidgetSchedule {
    /// How old data may be before we hit the network: tighter during race weekends.
    static func refreshInterval(now: Date, snapshot: SeasonSnapshot?) -> TimeInterval {
        guard let snapshot, let race = snapshot.nextRace(after: now) else { return 6 * 3600 }
        let weekend = (race.weekendStart.addingTimeInterval(-12 * 3600))...(race.end.addingTimeInterval(6 * 3600))
        return weekend.contains(now) ? 1800 : 6 * 3600
    }

    /// Entry dates so countdowns tick over exactly on the hour boundaries and sessions flip to live on time.
    static func entryDates(now: Date, snapshot: SeasonSnapshot?, design: WidgetDesign) -> [Date] {
        var dates: Set<Date> = [now]
        guard let snapshot, let race = snapshot.nextRace(after: now) else { return [now] }
        let horizon = now.addingTimeInterval(24 * 3600)

        for session in race.sessions {
            for boundary in [session.start, session.end] where boundary > now && boundary < horizon {
                dates.insert(boundary)
            }
        }

        let countsDown: Bool
        switch design.content {
        case .nextRace, .calendar, .driver: countsDown = true
        default: countsDown = false
        }
        if countsDown {
            let targets = Set([
                snapshot.countdownTarget(for: race, now: now, mode: design.countdown).start,
                race.raceSession.start,
            ])
            // One entry on every whole-hour boundary before each target inside the horizon,
            // so "3 DAYS 14 HRS" ticks over exactly when it should.
            for target in targets where target > now {
                let remainingHours = Int(target.timeIntervalSince(now) / 3600)
                let firstHour = max(1, Int((target.timeIntervalSince(horizon) / 3600).rounded(.up)))
                guard remainingHours >= firstHour else { continue }
                for hours in firstHour...remainingHours {
                    let date = target.addingTimeInterval(-Double(hours) * 3600)
                    if date > now && date < horizon { dates.insert(date) }
                }
            }
        }
        return dates.sorted().prefix(60).map { $0 }
    }

    static func nextReload(now: Date, snapshot: SeasonSnapshot?) -> Date {
        guard let snapshot else { return now.addingTimeInterval(15 * 60) }
        var candidates = [now.addingTimeInterval(refreshInterval(now: now, snapshot: snapshot) == 1800 ? 2 * 3600 : 6 * 3600)]
        if snapshot.isMissingRecentResults(now: now) {
            candidates.append(now.addingTimeInterval(20 * 60))
        }
        if let resultsDue = snapshot.nextResultsDate(after: now) {
            candidates.append(resultsDue.addingTimeInterval(30 * 60))
        }
        return max(candidates.min() ?? now.addingTimeInterval(3600), now.addingTimeInterval(5 * 60))
    }
}
