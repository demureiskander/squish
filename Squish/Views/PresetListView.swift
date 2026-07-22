import SwiftUI

struct PresetListView: View {
    @EnvironmentObject var presetVM: PresetViewModel
    @EnvironmentObject var loc: Localizer
    @State private var editingPreset: CompressionPreset?
    @State private var showNewPresetSheet = false
    @State private var newPresetName = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(loc.tr("Пресеты"))
                    .font(.headline)
                Spacer()

                Button {
                    presetVM.resetToDefaults()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .help(loc.tr("Восстановить стандартные пресеты"))

                Button {
                    showNewPresetSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .help(loc.tr("Новый пресет"))
            }
            .padding()

            Divider()

            List {
                ForEach(presetVM.presets) { preset in
                    PresetRow(
                        preset: preset,
                        isSelected: presetVM.selectedPreset.id == preset.id,
                        canDelete: presetVM.presets.count > 1,
                        onSelect: { presetVM.selectPreset(preset) },
                        onEdit: { editingPreset = preset },
                        onDelete: { presetVM.deletePreset(preset) }
                    )
                }
            }
        }
        .sheet(item: $editingPreset) { preset in
            PresetEditSheet(preset: preset) { updated in
                presetVM.updatePreset(updated)
            }
            .environmentObject(loc)
        }
        .sheet(isPresented: $showNewPresetSheet) {
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
                }
            }
            .padding(24)
        }
    }
}

struct PresetRow: View {
    let preset: CompressionPreset
    let isSelected: Bool
    let canDelete: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var presetVM: PresetViewModel
    @EnvironmentObject var loc: Localizer
    @State private var isRenaming = false
    @State private var draftName = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "34D399"))
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: 3) {
                if isRenaming {
                    TextField(loc.tr("Название"), text: $draftName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                        .focused($nameFocused)
                        .onSubmit(commitRename)
                        .frame(maxWidth: 200)
                } else {
                    Text(preset.name)
                        .font(.system(size: 13, weight: .medium))
                }

                Text("\(loc.tr(preset.qualityLevel.shortName)) · \(loc.tr(preset.format.displayName))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isRenaming {
                Button("OK", action: commitRename)
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "34D399"))
            } else {
                Button {
                    draftName = preset.name
                    isRenaming = true
                    nameFocused = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help(loc.tr("Переименовать"))

                Button(action: onEdit) {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.borderless)
                .help(loc.tr("Настройки пресета"))

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(canDelete ? .red : .secondary.opacity(0.3))
                }
                .buttonStyle(.borderless)
                .disabled(!canDelete)
                .help(canDelete ? loc.tr("Удалить") : loc.tr("Нельзя удалить последний пресет"))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRenaming { onSelect() }
        }
    }

    private func commitRename() {
        presetVM.rename(preset, to: draftName)
        isRenaming = false
    }
}

struct PresetEditSheet: View {
    @State var preset: CompressionPreset
    let onSave: (CompressionPreset) -> Void
    @EnvironmentObject var loc: Localizer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(loc.tr("Редактировать пресет"))
                .font(.headline)

            Form {
                TextField(loc.tr("Название"), text: $preset.name)

                Picker(loc.tr("Качество"), selection: $preset.qualityLevel) {
                    ForEach(QualityLevel.allCases) { level in
                        Text(loc.tr(level.displayName)).tag(level)
                    }
                }

                Picker(loc.tr("Формат"), selection: $preset.format) {
                    ForEach(ImageFormat.allCases) { format in
                        Text(loc.tr(format.displayName)).tag(format)
                    }
                }

                TextField(loc.tr("Ширина"), value: $preset.resizeWidth, format: .number)
                TextField(loc.tr("Высота"), value: $preset.resizeHeight, format: .number)
            }
            .formStyle(.grouped)

            HStack(spacing: 12) {
                Button(loc.tr("Отмена")) { dismiss() }
                Button(loc.tr("Сохранить")) {
                    onSave(preset)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "34D399"))
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}
