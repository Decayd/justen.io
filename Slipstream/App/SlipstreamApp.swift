import SwiftUI

@main
struct SlipstreamApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(Color(hex: "#E10600"))
                .preferredColorScheme(Self.forcedColorScheme)
                .onOpenURL { model.open($0) }
        }
    }
}

extension SlipstreamApp {
    /// `-SlipstreamColorScheme dark|light` pins the appearance (used by screenshot tests).
    static var forcedColorScheme: ColorScheme? {
        switch UserDefaults.standard.string(forKey: "SlipstreamColorScheme") {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            HomeView()
                .tabItem { Label("Paddock", systemImage: "flag.checkered") }
                .tag(AppTab.home)
            StandingsView()
                .tabItem { Label("Standings", systemImage: "list.number") }
                .tag(AppTab.standings)
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)
            StudioView()
                .tabItem { Label("Widgets", systemImage: "square.grid.2x2.fill") }
                .tag(AppTab.studio)
        }
        .environment(\.palette, .app(colorScheme))
        .task { await model.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await model.refresh() }
            }
        }
    }
}
