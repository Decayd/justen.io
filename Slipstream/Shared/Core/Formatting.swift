import Foundation

enum Fmt {
    /// "312" or "12.5".
    static func points(_ value: Double) -> String {
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%.1f", value)
    }

    /// Typographic minus for gaps: "−14".
    static func gap(_ value: Double) -> String {
        if value == 0 { return "0" }
        return (value < 0 ? "−" : "+") + points(abs(value))
    }

    static func ordinal(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// "FRI"
    static func weekday(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
    }

    /// "14:00" or "2:00 PM" following the user's locale.
    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }

    /// "5 Oct" / "Oct 5" following the user's locale.
    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    /// "3–5 Oct" for a race weekend.
    static func weekend(_ race: Race) -> String {
        let calendar = Calendar.current
        let start = race.weekendStart
        let end = race.start
        if calendar.isDate(start, equalTo: end, toGranularity: .month) {
            let first = start.formatted(.dateTime.day())
            return "\(first)–\(day(end))"
        }
        return "\(day(start)) – \(day(end))"
    }

    /// "Sun 20:00"
    static func sessionMoment(_ date: Date) -> String {
        "\(date.formatted(.dateTime.weekday(.abbreviated))) \(time(date))"
    }

    static func relativeAge(_ date: Date, now: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: now)
    }
}

/// Breaks the time to a session into the coarse pieces the widgets display.
struct Countdown: Hashable {
    enum Phase: Hashable {
        /// More than a day away: days and hours.
        case days(Int, hours: Int)
        /// Less than a day: hours and minutes.
        case hours(Int, minutes: Int)
        /// Less than an hour: show a live ticking timer.
        case final
        /// The session is on track.
        case live
        /// The session is over.
        case finished
    }

    let now: Date
    let start: Date
    let end: Date

    init(now: Date, session: Session) {
        self.now = now
        self.start = session.start
        self.end = session.end
    }

    init(now: Date, target: Date, duration: TimeInterval = 0) {
        self.now = now
        self.start = target
        self.end = target.addingTimeInterval(duration)
    }

    var remaining: TimeInterval { max(0, start.timeIntervalSince(now)) }

    var phase: Phase {
        if now >= end { return .finished }
        if now >= start { return .live }
        let seconds = Int(remaining)
        if seconds >= 24 * 3600 {
            return .days(seconds / 86_400, hours: (seconds % 86_400) / 3600)
        }
        if seconds >= 3600 {
            return .hours(seconds / 3600, minutes: (seconds % 3600) / 60)
        }
        return .final
    }

    /// "3d 14h", "5h 20m", "42m", "LIVE".
    var compact: String {
        switch phase {
        case .days(let d, let h): return h > 0 ? "\(d)d \(h)h" : "\(d)d"
        case .hours(let h, let m): return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        case .final: return "\(max(1, Int(remaining) / 60))m"
        case .live: return "LIVE"
        case .finished: return "Done"
        }
    }
}
