import SwiftUI

enum EditorPreviewSize: String, CaseIterable, Identifiable {
    case small, medium, large, lockScreen
    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .lockScreen: "Lock Screen"
        }
    }

    var widgetSize: WidgetSize? {
        switch self {
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .lockScreen: nil
        }
    }
}

enum PreviewAppearance: String, CaseIterable, Identifiable {
    case dark, light, tinted
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct DesignEditorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var design: WidgetDesign
    @State private var previewSize: EditorPreviewSize = .small
    @State private var appearance: PreviewAppearance = .dark
    @State private var confirmDelete = false
    let isNew: Bool

    init(design: WidgetDesign, isNew: Bool) {
        _design = State(initialValue: design)
        self.isNew = isNew
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PreviewStage(design: design, size: previewSize, appearance: appearance)

                    VStack(spacing: 10) {
                        Picker("Size", selection: $previewSize) {
                            ForEach(EditorPreviewSize.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Picker("Appearance", selection: $appearance) {
                            ForEach(PreviewAppearance.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    nameSection
                    contentSection
                    if design.content.needsDriver { driverSection }
                    if design.content.needsTeam { teamSection }
                    themeSection
                    accentSection
                    optionsSection

                    if !isNew {
                        Button("Delete Widget", role: .destructive) { confirmDelete = true }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isNew ? "New Widget" : "Edit Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.save(design)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(design.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete this widget?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    model.delete(design)
                    dismiss()
                }
            } message: {
                Text("Widgets on your Home Screen using this design will fall back to the default.")
            }
        }
    }

    // MARK: Sections

    private var nameSection: some View {
        EditorSection(title: "Name") {
            TextField("Widget name", text: $design.name)
                .textFieldStyle(.plain)
                .font(.body.weight(.semibold))
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var contentSection: some View {
        EditorSection(title: "Shows") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WidgetContent.allCases) { content in
                        ChoiceChip(title: content.title, symbol: content.symbol, isSelected: design.content == content) {
                            select(content)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
            Text(design.content.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    private var driverSection: some View {
        EditorSection(title: "Driver") {
            Picker("Driver", selection: Binding(
                get: { design.driverId ?? model.settings.favoriteDriverId ?? model.previewSnapshot.driverStandings.first?.driver.id ?? "" },
                set: { design.driverId = $0 }
            )) {
                ForEach(model.previewSnapshot.driverStandings) { standing in
                    Text("\(standing.driver.fullName) · \(standing.constructor.map(TeamPalette.shortName) ?? "")")
                        .tag(standing.driver.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var teamSection: some View {
        EditorSection(title: "Team") {
            Picker("Team", selection: Binding(
                get: { design.constructorId ?? model.settings.favoriteTeamId ?? model.previewSnapshot.constructorStandings.first?.constructor.id ?? "" },
                set: { design.constructorId = $0 }
            )) {
                ForEach(model.previewSnapshot.constructorStandings) { standing in
                    Text(TeamPalette.shortName(for: standing.constructor)).tag(standing.constructor.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var themeSection: some View {
        EditorSection(title: "Style") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WidgetTheme.allCases.filter { $0 != .team || design.content.supportsLivery }) { theme in
                        ThemeSwatch(theme: theme, teamRGB: subjectTeamRGB, accent: accentRGB, isSelected: design.theme == theme) {
                            design.theme = theme
                        }
                    }
                }
                .padding(.horizontal, 1)
                .padding(.vertical, 2)
            }
            Text(design.theme.subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    private var accentSection: some View {
        EditorSection(title: "Accent") {
            HStack(spacing: 12) {
                ForEach(AccentStyle.allCases) { accent in
                    AccentDot(color: (accent.rgb ?? subjectTeamRGB).color, isTeam: accent == .team, isSelected: design.accent == accent) {
                        design.accent = accent
                    }
                    .accessibilityLabel(accent.title)
                }
            }
            Text(design.accent.title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    private var optionsSection: some View {
        EditorSection(title: "Options") {
            VStack(spacing: 14) {
                Toggle("Show flags", isOn: $design.showFlags)
                if design.content.usesTrackMap {
                    Toggle("Show track map", isOn: $design.showTrackMap)
                }
                if design.content.usesCountdown {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Count down to")
                        Picker("Count down to", selection: $design.countdown) {
                            ForEach(CountdownMode.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Text("Smart counts down to the race, then to each session once the weekend begins.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.body)
        }
    }

    // MARK: Helpers

    private var subjectTeamRGB: RGB {
        let snapshot = model.previewSnapshot
        switch design.content {
        case .driver:
            let id = design.driverId ?? model.settings.favoriteDriverId
            let standing = id.flatMap { snapshot.driverStanding(id: $0) } ?? snapshot.driverStandings.first
            return TeamPalette.rgb(for: standing?.constructor?.id, season: snapshot.standingsSeason)
        default:
            let id = design.constructorId ?? model.settings.favoriteTeamId ?? snapshot.constructorStandings.first?.constructor.id
            return TeamPalette.rgb(for: id, season: snapshot.standingsSeason)
        }
    }

    private var accentRGB: RGB { design.accent.rgb ?? subjectTeamRGB }

    private func select(_ content: WidgetContent) {
        guard content != design.content else { return }
        let previous = design.content
        if design.name == previous.title { design.name = content.title }
        if isNew {
            design.theme = content.defaultTheme
            design.accent = content.defaultAccent
        } else if design.theme == .team && !content.supportsLivery {
            design.theme = .glow
        }
        design.content = content
    }
}

// MARK: - Building blocks

private struct EditorSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title)
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct ChoiceChip: View {
    let title: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(isSelected ? AppColors.red : Color(.tertiarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ThemeSwatch: View {
    let theme: WidgetTheme
    let teamRGB: RGB
    let accent: RGB
    let isSelected: Bool
    let action: () -> Void

    private var palette: WidgetPalette {
        switch theme {
        case .auto, .carbon: .dark(accent: accent, background: .carbon)
        case .paper: .light(accent: accent)
        case .glow: .dark(accent: accent, background: .glow(accent))
        case .team: .livery(teamRGB, accent: accent)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if theme == .auto {
                        HStack(spacing: 0) {
                            WidgetBackgroundView(palette: .light(accent: accent))
                            WidgetBackgroundView(palette: .dark(accent: accent, background: .carbon))
                        }
                    } else {
                        WidgetBackgroundView(palette: palette)
                    }
                    Text("Aa")
                        .font(Typo.display(15, weight: .heavy))
                        .foregroundStyle(theme == .auto ? Color.gray : palette.primary)
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isSelected ? AppColors.red : Color.primary.opacity(0.08), lineWidth: isSelected ? 3 : 1)
                }
                Text(theme.title)
                    .font(.caption.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct AccentDot: View {
    let color: Color
    let isTeam: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(color)
                if isTeam {
                    Image(systemName: "car.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 34, height: 34)
            .overlay {
                Circle().strokeBorder(Color.primary.opacity(isSelected ? 0.9 : 0), lineWidth: 2.5).padding(-5)
            }
            .padding(5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview stage

/// A wallpaper "device" with the widget drawn at its real size.
struct PreviewStage: View {
    let design: WidgetDesign
    let size: EditorPreviewSize
    let appearance: PreviewAppearance
    @Environment(AppModel.self) private var model

    private var scheme: ColorScheme { appearance == .light ? .light : .dark }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Wallpaper(appearance: appearance)
                if let widgetSize = size.widgetSize {
                    let nominal = widgetSize.nominalSize
                    let scale = min(1, (proxy.size.width - 28) / nominal.width)
                    canvas(widgetSize)
                        .scaleEffect(scale)
                        .frame(width: nominal.width * scale, height: nominal.height * scale)
                        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
                } else {
                    lockScreen
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(height: stageHeight)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .environment(\.colorScheme, scheme)
        .animation(.snappy, value: size)
    }

    private var stageHeight: CGFloat {
        switch size {
        case .small: 230
        case .medium: 230
        case .large: 420
        case .lockScreen: 300
        }
    }

    @ViewBuilder
    private func canvas(_ widgetSize: WidgetSize) -> some View {
        let base = WidgetCanvas(
            design: design,
            snapshot: model.previewSnapshot,
            stats: model.previewStats,
            size: widgetSize,
            settings: model.settings,
            renderStyle: appearance == .tinted ? .accented : .fullColor
        )
        if appearance == .tinted {
            base.colorMultiply(Color(hex: "#FFD9B0"))
        } else {
            base
        }
    }

    private var lockScreen: some View {
        VStack(spacing: 4) {
            WidgetCanvas(design: design, snapshot: model.previewSnapshot, stats: model.previewStats, size: .inline, settings: model.settings)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
            Text(Date.now, format: .dateTime.hour().minute())
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.bottom, 6)
            HStack(spacing: 14) {
                WidgetCanvas(design: design, snapshot: model.previewSnapshot, stats: model.previewStats, size: .circular, settings: model.settings)
                WidgetCanvas(design: design, snapshot: model.previewSnapshot, stats: model.previewStats, size: .rectangular, settings: model.settings)
            }
        }
        .padding(.horizontal, 12)
    }
}

private struct Wallpaper: View {
    let appearance: PreviewAppearance

    var body: some View {
        switch appearance {
        case .light:
            LinearGradient(colors: [Color(hex: "#C9D6FF"), Color(hex: "#E2E2E2")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            ZStack {
                LinearGradient(colors: [Color(hex: "#1B2140"), Color(hex: "#090A12")], startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [Color(hex: "#5B3CC4").opacity(0.55), .clear], center: .bottomLeading, startRadius: 0, endRadius: 320)
            }
        case .tinted:
            LinearGradient(colors: [Color(hex: "#3A2A1A"), Color(hex: "#0E0B08")], startPoint: .top, endPoint: .bottom)
        }
    }
}
