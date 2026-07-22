import SwiftUI

struct MetadataPanel: View {
    let item: ImageItem
    @EnvironmentObject var loc: Localizer
    @EnvironmentObject var mainVM: MainViewModel
    @State private var fields: [MetaField] = []

    // Редактирование.
    @State private var isEditing = false
    @State private var editFields: [MetaEditField] = []
    @State private var editFileName = ""
    @State private var saveError = false

    private var canEditMetadata: Bool { MetadataWriter.isEditable(url: item.originalURL) }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().opacity(0.3)

            ScrollView {
                VStack(spacing: 12) {
                    if let thumbData = item.thumbnail, let nsImage = NSImage(data: thumbData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.top, 4)
                    }

                    if isEditing {
                        editForm
                    } else {
                        fieldsList
                    }
                    if !isEditing && !canEditMetadata {
                        Text(loc.tr("Формат WebP: метаданные доступны только для чтения."))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: item.originalURL) { reload() }
        .alert(loc.tr("Не удалось сохранить изменения"), isPresented: $saveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(loc.tr("Проверьте, что файл с таким именем ещё не существует."))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundStyle(Color(hex: "34D399"))
            Text(loc.tr("Метаданные"))
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if isEditing {
                Button(loc.tr("Отмена")) {
                    isEditing = false
                }
                .controlSize(.small)
                Button(loc.tr("Сохранить")) {
                    save()
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "34D399"))
            } else {
                Button {
                    beginEditing()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .help(loc.tr("Редактировать"))

                Button {
                    mainVM.clearSelection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(loc.tr("Закрыть"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Read-only list

    private var fieldsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                HStack(alignment: .top, spacing: 10) {
                    Text(loc.tr(field.label))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 110, alignment: .leading)
                    Text(field.value)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.85))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 7)

                if index < fields.count - 1 {
                    Divider().opacity(0.12)
                }
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    // MARK: - Edit form

    private var editForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Имя файла — доступно для любого формата.
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.tr("Имя файла"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    TextField("", text: $editFileName)
                        .font(.system(size: 12))
                        .textFieldStyle(.roundedBorder)
                    let ext = item.originalURL.pathExtension
                    if !ext.isEmpty {
                        Text(".\(ext)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if canEditMetadata {
                ForEach($editFields) { $field in
                    editField(title: loc.tr(field.labelKey), text: $field.value, multiline: field.multiline)
                }

                Text(loc.tr("Метаданные записываются в файл без перекодирования изображения."))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.6))
            } else {
                Text(loc.tr("Формат WebP: метаданные доступны только для чтения."))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    private func editField(title: String, text: Binding<String>, multiline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            if multiline {
                TextEditor(text: text)
                    .font(.system(size: 12))
                    .frame(height: 60)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
            } else {
                TextField("", text: text)
                    .font(.system(size: 12))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Actions

    private func reload() {
        fields = MetadataReader.read(url: item.originalURL, fileSize: item.fileSize)
    }

    private func beginEditing() {
        editFileName = item.originalURL.deletingPathExtension().lastPathComponent
        editFields = canEditMetadata ? MetadataWriter.loadFields(url: item.originalURL) : []
        isEditing = true
    }

    private func save() {
        var targetURL = item.originalURL
        var ok = true

        // 1. Переименование файла (для любого формата).
        let trimmed = editFileName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let dir = item.originalURL.deletingLastPathComponent()
            let ext = item.originalURL.pathExtension
            let newName = ext.isEmpty ? trimmed : "\(trimmed).\(ext)"
            let newURL = dir.appendingPathComponent(newName)
            if newURL != item.originalURL {
                if mainVM.renameFile(item: item, to: newURL) {
                    targetURL = newURL
                } else {
                    ok = false
                }
            }
        }

        // 2. Запись метаданных (только для поддерживаемых форматов).
        if ok && canEditMetadata {
            ok = MetadataWriter.write(url: targetURL, fields: editFields)
        }

        if ok {
            isEditing = false
            reload()
        } else {
            saveError = true
        }
    }
}
