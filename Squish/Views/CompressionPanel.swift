import SwiftUI

struct CompressionPanel: View {
    @EnvironmentObject var presetVM: PresetViewModel
    @EnvironmentObject var mainVM: MainViewModel
    @EnvironmentObject var loc: Localizer
    @State private var showNewPresetSheet = false
    @State private var newPresetName = ""

    var body: some View {
        VStack(spacing: 0) {
            // Preset tabs
            presetTabs
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 10) {
                    qualitySection
                    saveSection
                    formatSection
                    resizeSection
                    togglesSection
                    postActionSection
                }
                .padding(16)
            }

            Divider().opacity(0.3)

            // Compress button
            compressButton
                .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showNewPresetSheet) {
            newPresetSheet
        }
    }

    // MARK: - Preset Tabs

    private func pickCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Выбрать"
        if panel.runModal() == .OK, let url = panel.url {
            presetVM.selectedPreset.customOutputPath = url.path
            presetVM.updatePreset(presetVM.selectedPreset)
        }
    }

    private var presetTabs: some View {
        HStack(spacing: 6) {
            Text(loc.tr("Пресеты"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(presetVM.presets) { preset in
                        Button {
                            presetVM.selectPreset(preset)
                        } label: {
                            Text(preset.name)
                                .font(.system(size: 11, weight: presetVM.selectedPreset.id == preset.id ? .semibold : .regular))
                                .foregroundStyle(presetVM.selectedPreset.id == preset.id ? .white : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    presetVM.selectedPreset.id == preset.id
                                        ? Color(hex: "34D399")
                                        : Color(nsColor: .controlBackgroundColor).opacity(0.5)
                                )
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                showNewPresetSheet = true
            } label: {
                Text("+")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String, hint: String, trailing: String? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "34D399"))
                .frame(width: 16)

            Text(loc.tr(title))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.85))

            InfoHint(text: loc.tr(hint))

            Spacer()

            if let trailing {
                Text(loc.tr(trailing))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "34D399"))
            }
        }
    }

    /// Пример имени файла для предпросмотра путей.
    private var exampleFileName: String {
        let fmt = presetVM.selectedPreset.format
        let ext = fmt == .original ? "png" : fmt.fileExtension
        return "\(loc.tr("фото")).\(ext)"
    }

    // MARK: - Quality

    private var qualitySection: some View {
        SectionCard {
            VStack(spacing: 10) {
                sectionHeader(
                    icon: "dial.medium",
                    title: "Качество",
                    hint: "Насколько сильно сжимать. Ниже качество — меньше файл, но заметнее потери.",
                    trailing: presetVM.selectedPreset.qualityLevel.shortName
                )

                QualitySlider(level: Binding(
                    get: { presetVM.selectedPreset.qualityLevel },
                    set: { newLevel in
                        presetVM.selectedPreset.qualityLevel = newLevel
                        presetVM.updatePreset(presetVM.selectedPreset)
                    }
                ))

                HStack {
                    Text(loc.tr("Меньше файл"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary.opacity(0.4))
                    Spacer()
                    Text(loc.tr("Выше качество"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary.opacity(0.4))
                }
            }
        }
    }

    // MARK: - Save

    private var saveSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(
                    icon: "folder",
                    title: "Куда сохранять",
                    hint: "Исходная — рядом с оригиналом. Спросить — выбор папки при каждом сжатии. Указать — постоянная папка."
                )

                Picker("", selection: Binding(
                    get: { presetVM.selectedPreset.saveLocation },
                    set: {
                        presetVM.selectedPreset.saveLocation = $0
                        presetVM.updatePreset(presetVM.selectedPreset)
                    }
                )) {
                    Text(loc.tr("Исходная")).tag(SaveLocation.original)
                    Text(loc.tr("Спросить")).tag(SaveLocation.ask)
                    Text(loc.tr("Указать")).tag(SaveLocation.custom)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)

                if presetVM.selectedPreset.saveLocation == .custom {
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        Text(presetVM.selectedPreset.customOutputPath.isEmpty
                             ? loc.tr("Папка не выбрана")
                             : (presetVM.selectedPreset.customOutputPath as NSString).abbreviatingWithTildeInPath)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(presetVM.selectedPreset.customOutputPath.isEmpty ? 0.5 : 1.0))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(loc.tr("Обзор…")) {
                            pickCustomFolder()
                        }
                        .controlSize(.small)
                    }
                }

                Divider().opacity(0.15)

                // Subfolder
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Toggle("", isOn: Binding(
                            get: { presetVM.selectedPreset.useSubfolder },
                            set: {
                                presetVM.selectedPreset.useSubfolder = $0
                                presetVM.updatePreset(presetVM.selectedPreset)
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .labelsHidden()

                        Text(loc.tr("В подпапку"))
                            .font(.system(size: 11))
                            .foregroundStyle(.primary.opacity(0.75))

                        Spacer()

                        TextField("squished", text: Binding(
                            get: { presetVM.selectedPreset.subfolder },
                            set: {
                                presetVM.selectedPreset.subfolder = $0
                                presetVM.updatePreset(presetVM.selectedPreset)
                            }
                        ))
                        .font(.system(size: 10))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .disabled(!presetVM.selectedPreset.useSubfolder)
                    }

                    if presetVM.selectedPreset.useSubfolder {
                        Text("\(presetVM.selectedPreset.subfolder)/\(exampleFileName)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.secondary.opacity(0.4))
                            .padding(.leading, 22)
                    }
                }

                // Suffix
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Toggle("", isOn: Binding(
                            get: { presetVM.selectedPreset.useSuffix },
                            set: {
                                presetVM.selectedPreset.useSuffix = $0
                                presetVM.updatePreset(presetVM.selectedPreset)
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .labelsHidden()

                        Text(loc.tr("Добавить суффикс"))
                            .font(.system(size: 11))
                            .foregroundStyle(.primary.opacity(0.75))

                        Spacer()

                        TextField("-squished", text: Binding(
                            get: { presetVM.selectedPreset.suffix },
                            set: {
                                presetVM.selectedPreset.suffix = $0
                                presetVM.updatePreset(presetVM.selectedPreset)
                            }
                        ))
                        .font(.system(size: 10))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .disabled(!presetVM.selectedPreset.useSuffix)
                    }

                    if presetVM.selectedPreset.useSuffix {
                        let base = loc.tr("фото")
                        let ext = presetVM.selectedPreset.format == .original ? "png" : presetVM.selectedPreset.format.fileExtension
                        Text("\(base)\(presetVM.selectedPreset.suffix).\(ext)")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.secondary.opacity(0.4))
                            .padding(.leading, 22)
                    }
                }
            }
        }
    }

    // MARK: - Format

    private var formatSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(
                    icon: "photo",
                    title: "Формат на выходе",
                    hint: "«Оригинал» — сохранить тот же формат. Или конвертировать в JPEG/PNG/HEIC. WebP появится в будущей версии."
                )

                HStack {
                    Text(loc.tr("Конвертировать в"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { presetVM.selectedPreset.format },
                        set: {
                            presetVM.selectedPreset.format = $0
                            presetVM.updatePreset(presetVM.selectedPreset)
                        }
                    )) {
                        ForEach(ImageFormat.allCases) { format in
                            Text(loc.tr(format.displayName)).tag(format)
                        }
                    }
                    .frame(width: 110)
                }
            }
        }
    }

    // MARK: - Resize

    private var resizeSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(
                    icon: "aspectratio",
                    title: "Размер",
                    hint: "Максимальные ширина и высота в пикселях. 0 — не менять. Пропорции сохраняются."
                )

                HStack(spacing: 8) {
                    Text(loc.tr("Ширина"))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    TextField("0", value: Binding(
                        get: { presetVM.selectedPreset.resizeWidth },
                        set: {
                            presetVM.selectedPreset.resizeWidth = $0
                            presetVM.updatePreset(presetVM.selectedPreset)
                        }
                    ), format: .number)
                    .font(.system(size: 11))
                    .textFieldStyle(.roundedBorder)

                    Text("\u{00D7}")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary.opacity(0.4))

                    Text(loc.tr("Высота"))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    TextField("0", value: Binding(
                        get: { presetVM.selectedPreset.resizeHeight },
                        set: {
                            presetVM.selectedPreset.resizeHeight = $0
                            presetVM.updatePreset(presetVM.selectedPreset)
                        }
                    ), format: .number)
                    .font(.system(size: 11))
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    // MARK: - Options

    private var togglesSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    icon: "slider.horizontal.3",
                    title: "Опции",
                    hint: "Дополнительные параметры обработки."
                )

                Toggle(isOn: Binding(
                    get: { presetVM.selectedPreset.skipOptimized },
                    set: {
                        presetVM.selectedPreset.skipOptimized = $0
                        presetVM.updatePreset(presetVM.selectedPreset)
                    }
                )) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(loc.tr("Пропускать уже сжатые"))
                            .font(.system(size: 11))
                            .foregroundStyle(.primary.opacity(0.75))
                        Text(loc.tr("Файлы с суффиксом не трогаются повторно"))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(Color(hex: "34D399"))

                Toggle(isOn: Binding(
                    get: { presetVM.selectedPreset.preserveMetadata },
                    set: {
                        presetVM.selectedPreset.preserveMetadata = $0
                        presetVM.updatePreset(presetVM.selectedPreset)
                    }
                )) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(loc.tr("Сохранять метаданные"))
                            .font(.system(size: 11))
                            .foregroundStyle(.primary.opacity(0.75))
                        Text(loc.tr("EXIF, геолокация, дата съёмки"))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(Color(hex: "34D399"))
            }
        }
    }

    // MARK: - Post Action

    private var postActionSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(
                    icon: "doc.on.clipboard",
                    title: "Действие после",
                    hint: "Что скопировать в буфер обмена после сжатия каждого файла. Путь — путь к файлу. Файл — сам файл. MD — Markdown-ссылку."
                )

                Picker("", selection: Binding(
                    get: { presetVM.selectedPreset.postAction },
                    set: {
                        presetVM.selectedPreset.postAction = $0
                        presetVM.updatePreset(presetVM.selectedPreset)
                    }
                )) {
                    Text(loc.tr("Ничего")).tag(PostAction.none)
                    Text(loc.tr("Путь")).tag(PostAction.copyPath)
                    Text(loc.tr("Файл")).tag(PostAction.copyFile)
                    Text("MD").tag(PostAction.copyMarkdown)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
            }
        }
    }

    // MARK: - Compress Button

    private var compressButton: some View {
        Button {
            if mainVM.isProcessing {
                mainVM.cancelCompression()
            } else {
                mainVM.compressAll(preset: presetVM.selectedPreset)
            }
        } label: {
            HStack {
                if mainVM.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                    Text(mainVM.isCancelling ? loc.tr("Останавливается…") : loc.tr("Остановить"))
                        .font(.system(size: 13, weight: .semibold))
                } else {
                    Text(loc.tr("Сжать всё"))
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                mainVM.isProcessing
                    ? Color(hex: "e5484d")
                    : (mainVM.items.isEmpty ? Color(hex: "34D399").opacity(0.5) : Color(hex: "34D399"))
            )
            .foregroundStyle(.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(mainVM.items.isEmpty && !mainVM.isProcessing)
    }

    // MARK: - New Preset Sheet

    private var newPresetSheet: some View {
        VStack(spacing: 16) {
            Text(loc.tr("Новый пресет"))
                .font(.headline)

            TextField(loc.tr("Название"), text: $newPresetName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)

            HStack(spacing: 12) {
                Button(loc.tr("Отмена")) {
                    newPresetName = ""
                    showNewPresetSheet = false
                }

                Button(loc.tr("Создать")) {
                    if !newPresetName.isEmpty {
                        presetVM.addPreset(name: newPresetName)
                        newPresetName = ""
                        showNewPresetSheet = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "34D399"))
                .disabled(newPresetName.isEmpty)
            }
        }
        .padding(24)
    }
}

// MARK: - Quality Slider

struct QualitySlider: View {
    @Binding var level: QualityLevel

    var body: some View {
        GeometryReader { geo in
            let steps = QualityLevel.allCases.count
            let stepWidth = geo.size.width / CGFloat(steps - 1)
            let currentIndex = CGFloat(level.rawValue - 1)
            let thumbX = currentIndex * stepWidth

            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(height: 6)

                // Active track
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(hex: "2a9d6e"), Color(hex: "34D399")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: thumbX + 8, height: 6)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .offset(x: thumbX - 8)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                let index = Int(round(x / stepWidth))
                                let clamped = max(0, min(steps - 1, index))
                                if let newLevel = QualityLevel(rawValue: clamped + 1) {
                                    level = newLevel
                                }
                            }
                    )
            }
        }
        .frame(height: 16)
    }
}

// MARK: - Section Card

struct SectionCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
    }
}

// MARK: - Info Hint (hover tooltip)

struct InfoHint: View {
    let text: String
    @State private var isHovering = false

    var body: some View {
        Image(systemName: "info.circle")
            .font(.system(size: 11))
            .foregroundStyle(.secondary.opacity(isHovering ? 0.95 : 0.5))
            .frame(width: 18, height: 18)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                Text(text)
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 220, alignment: .leading)
                    .padding(12)
            }
    }
}
