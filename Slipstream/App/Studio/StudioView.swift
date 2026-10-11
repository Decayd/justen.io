import SwiftUI

struct StudioView: View {
    @Environment(AppModel.self) private var model
    @State private var editing: WidgetDesign?
    @State private var showTemplates = false
    @State private var showHowTo = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro
                    SampleDataBanner()

                    if !model.designs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle("My widgets")
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(model.designs) { design in
                                    DesignTile(design: design)
                                        .onTapGesture { editing = design }
                                        .contextMenu {
                                            Button("Edit", systemImage: "slider.horizontal.3") { editing = design }
                                            Button("Duplicate", systemImage: "plus.square.on.square") { model.duplicate(design) }
                                            Button("Delete", systemImage: "trash", role: .destructive) { model.delete(design) }
                                        }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle("Start from a template")
                        ForEach(WidgetContent.allCases) { content in
                            TemplateCard(content: content) {
                                editing = WidgetDesign(content: content)
                            }
                        }
                    }

                    howToCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Widget Studio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(WidgetContent.allCases) { content in
                            Button(content.title, systemImage: content.symbol) {
                                editing = WidgetDesign(content: content)
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New widget")
                }
            }
            .sheet(item: $editing) { design in
                DesignEditorView(design: design, isNew: !model.designs.contains { $0.id == design.id })
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Build widgets with live F1 data, preview them at real size, then add them to your Home Screen or Lock Screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var howToCard: some View {
        Card {
            SectionTitle("Add a widget")
            VStack(alignment: .leading, spacing: 12) {
                HowToStep(number: 1, text: "Touch and hold an empty area of your Home Screen or Lock Screen, then tap **Edit** → **Add Widget**.")
                HowToStep(number: 2, text: "Search for **Slipstream** and choose a ready-made widget, or **My Widgets** for your own designs.")
                HowToStep(number: 3, text: "Pick a size. For My Widgets, tap the widget while editing and choose one of your designs.")
            }
            .padding(.top, 12)
        }
    }
}

private struct HowToStep: View {
    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(Typo.number(13, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(AppColors.red, in: Circle())
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A saved design shown as a scaled-down small widget.
private struct DesignTile: View {
    let design: WidgetDesign
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetCanvas(
                design: design,
                snapshot: model.previewSnapshot,
                stats: model.previewStats,
                size: .small,
                settings: model.settings
            )
            .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
            .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 1) {
                Text(design.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(design.content.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

/// A template with a live medium-size preview.
private struct TemplateCard: View {
    let content: WidgetContent
    let action: () -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: content.symbol)
                        .font(.headline)
                        .foregroundStyle(AppColors.red)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(content.title).font(.headline)
                        Text(content.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.red)
                }
                ScaledCanvas(
                    design: WidgetDesign(content: content),
                    snapshot: model.previewSnapshot,
                    stats: model.previewStats,
                    size: .medium,
                    settings: model.settings
                )
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Scales a widget canvas down to fit the available width.
struct ScaledCanvas: View {
    let design: WidgetDesign
    let snapshot: SeasonSnapshot
    var stats: SeasonStats?
    let size: WidgetSize
    var settings = AppSettings()

    var body: some View {
        let nominal = size.nominalSize
        GeometryReader { proxy in
            let scale = min(1, proxy.size.width / nominal.width)
            WidgetCanvas(design: design, snapshot: snapshot, stats: stats, size: size, settings: settings)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: proxy.size.width, height: nominal.height * scale, alignment: .topLeading)
        }
        .aspectRatio(nominal.width / nominal.height, contentMode: .fit)
    }
}
