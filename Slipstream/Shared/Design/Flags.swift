import Foundation

/// Emoji flags for Ergast nationalities ("Dutch") and countries ("UK").
enum Flags {
    static func emoji(iso code: String) -> String {
        let base: UInt32 = 127_397
        var result = ""
        for scalar in code.uppercased().unicodeScalars {
            guard let flagScalar = UnicodeScalar(base + scalar.value) else { return "🏁" }
            result.unicodeScalars.append(flagScalar)
        }
        return result.isEmpty ? "🏁" : result
    }

    static func nationality(_ value: String) -> String {
        guard let iso = nationalities[value] else { return "🏁" }
        return emoji(iso: iso)
    }

    static func country(_ value: String) -> String {
        guard let iso = countries[value] else { return "🏁" }
        return emoji(iso: iso)
    }

    private static let nationalities: [String: String] = [
        "American": "US", "American-Italian": "US", "Argentine": "AR", "Argentinian": "AR", "Australian": "AU",
        "Austrian": "AT", "Belgian": "BE", "Brazilian": "BR", "British": "GB", "Canadian": "CA", "Chilean": "CL",
        "Chinese": "CN", "Colombian": "CO", "Czech": "CZ", "Danish": "DK", "Dutch": "NL", "East German": "DE",
        "Estonian": "EE", "Finnish": "FI", "French": "FR", "German": "DE", "Hong Kong": "HK", "Hungarian": "HU",
        "Indian": "IN", "Indonesian": "ID", "Irish": "IE", "Israeli": "IL", "Italian": "IT", "Japanese": "JP",
        "Liechtensteiner": "LI", "Malaysian": "MY", "Mexican": "MX", "Monegasque": "MC", "New Zealander": "NZ",
        "Polish": "PL", "Portuguese": "PT", "Rhodesian": "ZW", "Russian": "RU", "South African": "ZA",
        "Spanish": "ES", "Swedish": "SE", "Swiss": "CH", "Thai": "TH", "Uruguayan": "UY", "Venezuelan": "VE",
        "Emirati": "AE", "Saudi": "SA", "Korean": "KR", "Moroccan": "MA", "Norwegian": "NO", "Romanian": "RO",
    ]

    private static let countries: [String: String] = [
        "Australia": "AU", "Austria": "AT", "Azerbaijan": "AZ", "Bahrain": "BH", "Belgium": "BE", "Brazil": "BR",
        "Canada": "CA", "China": "CN", "France": "FR", "Germany": "DE", "Hungary": "HU", "India": "IN",
        "Italy": "IT", "Japan": "JP", "Korea": "KR", "South Korea": "KR", "Malaysia": "MY", "Mexico": "MX",
        "Monaco": "MC", "Morocco": "MA", "Netherlands": "NL", "Portugal": "PT", "Qatar": "QA", "Russia": "RU",
        "Saudi Arabia": "SA", "Singapore": "SG", "South Africa": "ZA", "Spain": "ES", "Sweden": "SE",
        "Switzerland": "CH", "Turkey": "TR", "Türkiye": "TR", "UAE": "AE", "United Arab Emirates": "AE",
        "UK": "GB", "United Kingdom": "GB", "USA": "US", "United States": "US", "Argentina": "AR",
        "Vietnam": "VN", "Thailand": "TH", "Indonesia": "ID", "Rwanda": "RW",
    ]
}
