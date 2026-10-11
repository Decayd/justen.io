import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Favourite driver", selection: favoriteDriver) {
                        Text("Championship leader").tag(String?.none)
                        ForEach(model.previewSnapshot.driverStandings) { standing in
                            Text(standing.driver.fullName).tag(String?.some(standing.driver.id))
                        }
                    }
                    Picker("Favourite team", selection: favoriteTeam) {
                        Text("Championship leader").tag(String?.none)
                        ForEach(model.previewSnapshot.constructorStandings) { standing in
                            Text(TeamPalette.shortName(for: standing.constructor)).tag(String?.some(standing.constructor.id))
                        }
                    }
                } header: {
                    Text("Favourites")
                } footer: {
                    Text("Driver and Team widgets show your favourites unless you pick someone else while editing the widget.")
                }

                Section {
                    Picker("Style", selection: defaultTheme) {
                        ForEach(WidgetTheme.allCases.filter { $0 != .team }) { Text($0.title).tag($0) }
                    }
                    Picker("Accent", selection: defaultAccent) {
                        ForEach(AccentStyle.allCases) { Text($0.title).tag($0) }
                    }
                } header: {
                    Text("Ready-made widgets")
                } footer: {
                    Text("Applies to the Next Race, Standings, Race Result, Calendar and Title Fight widgets. Design your own in the Widgets tab.")
                }

                Section {
                    Button {
                        Task { await model.refresh(force: true) }
                    } label: {
                        HStack {
                            Text("Refresh now")
                            Spacer()
                            if model.isRefreshing { ProgressView() }
                        }
                    }
                    if let fetched = model.snapshot?.fetchedAt {
                        LabeledContent("Last updated", value: fetched.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let error = model.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Data")
                }

                Section {
                    Link("Jolpica-F1 API", destination: URL(string: "https://github.com/jolpica/jolpica-f1")!)
                    Link("Circuit outlines (bacinger/f1-circuits, MIT)", destination: URL(string: "https://github.com/bacinger/f1-circuits")!)
                } header: {
                    Text("Sources")
                } footer: {
                    Text("Slipstream is an unofficial app and is not associated with Formula 1 companies. F1, Formula One and related marks are trademarks of Formula One Licensing B.V.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var favoriteDriver: Binding<String?> {
        Binding(get: { model.settings.favoriteDriverId }, set: { value in model.update { $0.favoriteDriverId = value } })
    }

    private var favoriteTeam: Binding<String?> {
        Binding(get: { model.settings.favoriteTeamId }, set: { value in model.update { $0.favoriteTeamId = value } })
    }

    private var defaultTheme: Binding<WidgetTheme> {
        Binding(get: { model.settings.defaultTheme }, set: { value in model.update { $0.defaultTheme = value } })
    }

    private var defaultAccent: Binding<AccentStyle> {
        Binding(get: { model.settings.defaultAccent }, set: { value in model.update { $0.defaultAccent = value } })
    }
}
