import SwiftUI

/// Team colours keyed by Jolpica/Ergast constructor IDs.
/// Modern values follow the official broadcast colours (via FastF1's published constants).
enum TeamPalette {
    static let modern: [String: String] = [
        "mclaren": "#FF8000",
        "ferrari": "#E80020",
        "mercedes": "#27F4D2",
        "red_bull": "#3671C6",
        "aston_martin": "#229971",
        "alpine": "#0093CC",
        "williams": "#64C4FF",
        "rb": "#6692FF",
        "haas": "#B6BABD",
        "sauber": "#52E252",
        "audi": "#FF2D00",
        "cadillac": "#444444",
    ]

    /// Season-specific overrides where a team's colour changed.
    static let seasonal: [Int: [String: String]] = [
        2018: ["force_india": "#F596C8", "racing_point": "#F596C8", "haas": "#828282", "mercedes": "#00D2BE",
               "red_bull": "#1E41FF", "renault": "#FFF500", "sauber": "#9B0000", "toro_rosso": "#469BFF",
               "williams": "#E6E6E6", "ferrari": "#DC0000"],
        2019: ["alfa": "#9B0000", "haas": "#BD9E57", "ferrari": "#DC0000", "mclaren": "#FF8700", "mercedes": "#00D2BE",
               "racing_point": "#F596C8", "red_bull": "#1E41FF", "renault": "#FFF500", "toro_rosso": "#469BFF",
               "williams": "#E6E6E6"],
        2020: ["alfa": "#9B0000", "alphatauri": "#C8CCD2", "ferrari": "#DC0000", "haas": "#787878", "mclaren": "#FF8700",
               "mercedes": "#00D2BE", "racing_point": "#F596C8", "red_bull": "#1E41FF", "renault": "#FFF500",
               "williams": "#0082FA"],
        2021: ["alfa": "#900000", "alphatauri": "#2B4562", "alpine": "#0090FF", "aston_martin": "#006F62",
               "ferrari": "#DC0004", "haas": "#E6E6E6", "mclaren": "#FF9800", "mercedes": "#00D2BE",
               "red_bull": "#0600EF", "williams": "#005AFF"],
        2022: ["alfa": "#B12039", "alphatauri": "#4E7C9B", "alpine": "#2293D1", "aston_martin": "#2D826D",
               "ferrari": "#ED1C24", "mclaren": "#F58020", "mercedes": "#6CD3BF", "red_bull": "#1E5BC6",
               "williams": "#37BEDD"],
        2023: ["alfa": "#C92D4B", "alphatauri": "#5E8FAA", "alpine": "#2293D1", "aston_martin": "#358C75",
               "ferrari": "#F91536", "mclaren": "#F58020", "mercedes": "#6CD3BF", "williams": "#37BEDD"],
        2024: ["ferrari": "#E8002D"],
    ]

    /// Approximate colours for historic constructors.
    static let historic: [String: String] = [
        "renault": "#FFD700", "force_india": "#F596C8", "racing_point": "#F596C8", "toro_rosso": "#469BFF",
        "alphatauri": "#5E8FAA", "alfa": "#C92D4B", "lotus_f1": "#C9A227", "manor": "#E2231A",
        "marussia": "#8B0000", "caterham": "#0B6B3A", "hrt": "#B2945E", "virgin": "#CC0000",
        "lotus_racing": "#0B5D3B", "brawn": "#C9F31D", "bmw_sauber": "#2F64B4", "toyota": "#E0001B",
        "honda": "#E6E6E6", "super_aguri": "#E2001A", "spyker": "#FF6A00", "spyker_mf1": "#FF6A00",
        "mf1": "#A51C30", "jordan": "#F4D20E", "midland": "#A51C30", "jaguar": "#0F5B3B", "bar": "#C8CCD2",
        "minardi": "#3A3A3A", "arrows": "#FF8000", "prost": "#1846A0", "stewart": "#D8D8D8",
        "benetton": "#2DB24B", "tyrrell": "#1F3B8F", "ligier": "#0052A5", "brabham": "#1C4F9C",
        "team_lotus": "#0B5D3B", "march": "#2B3990", "lola": "#C8102E", "matra": "#1D4F9C",
        "cooper": "#1A5E1A", "brm": "#1A5E1A", "vanwall": "#1A5E1A", "maserati": "#C8102E",
        "footwork": "#E6E6E6", "larrousse": "#1E64C8", "dallara": "#C8102E", "leyton": "#2A8FBD",
        "osella": "#1E4BA0", "zakspeed": "#C8102E", "shadow": "#3A3A3A", "wolf": "#1E2A5A",
        "hesketh": "#E6E6E6", "surtees": "#1E4BA0", "penske": "#1E4BA0", "ensign": "#1E4BA0",
    ]

    static func rgb(for constructorId: String?, season: Int? = nil) -> RGB {
        guard let id = constructorId else { return RGB(hex: "#8E8E93") }
        if let season, let hex = seasonal[season]?[id] { return RGB(hex: hex) }
        if let hex = modern[id] ?? historic[id] { return RGB(hex: hex) }
        return fallback(for: id)
    }

    static func color(for constructorId: String?, season: Int? = nil) -> Color {
        rgb(for: constructorId, season: season).color
    }

    /// A stable, pleasant colour for teams we don't know.
    static func fallback(for id: String) -> RGB {
        let hues: [String] = ["#5B8DEF", "#E86A6A", "#46B39D", "#D9A441", "#9C7BEA", "#4FB7D9", "#E07AB5", "#7DB955"]
        let index = id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7FFFFFFF } % hues.count
        return RGB(hex: hues[index])
    }

    /// Short, broadcast-style team names.
    static func shortName(for constructor: Constructor) -> String {
        switch constructor.id {
        case "red_bull": "Red Bull"
        case "rb": "Racing Bulls"
        case "aston_martin": "Aston Martin"
        case "sauber": "Sauber"
        case "alfa": "Alfa Romeo"
        case "alphatauri": "AlphaTauri"
        case "racing_point": "Racing Point"
        case "force_india": "Force India"
        default: constructor.name.replacingOccurrences(of: " F1 Team", with: "")
        }
    }

    /// Three-letter team code for tight spaces.
    static func code(for constructor: Constructor) -> String {
        switch constructor.id {
        case "mclaren": "MCL"
        case "ferrari": "FER"
        case "mercedes": "MER"
        case "red_bull": "RBR"
        case "aston_martin": "AMR"
        case "alpine": "ALP"
        case "williams": "WIL"
        case "rb": "RB"
        case "haas": "HAA"
        case "sauber": "SAU"
        case "audi": "AUD"
        case "cadillac": "CAD"
        default: String(constructor.name.filter(\.isLetter).prefix(3)).uppercased()
        }
    }
}
