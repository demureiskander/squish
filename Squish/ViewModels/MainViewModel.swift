import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

@MainActor
class MainViewModel: ObservableObject {
    @Published var items: [ImageItem] = []
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    @Published var selectedIDs: Set<UUID> = []
    @Published var previewItem: ImageItem?
    @Published var viewMode: ViewMode = .grid

    // Дубликаты: всплывашка + кратковременная подсветка.
    @Published var toast: String?
    @Published var highlightedIDs: Set<UUID> = []

    // Счётчики сессии — обнуляются при каждом запуске приложения.
    @Published var totalImagesProcessed: Int = 0
    @Published var totalBytesSaved: Int64 = 0

    enum ViewMode: String {
        case grid
        case list
    }

    private var selectionAnchorID: UUID?
    private var compressionTask: Task<Void, Never>?
    @Published var isCancelling = false

    func cancelCompression() {
        guard isProcessing else { return }
        if isCancelling {
            showToast(Localizer.translate("Обработка уже останавливается, подождите…"))
            return
        }
        isCancelling = true
        compressionTask?.cancel()
    }

    /// Выбор элемента с модификаторами (как в Finder/Photoshop).
    /// ⌘ — добавить/убрать; ⇧ — диапазон от «якоря» до текущего; без модификаторов — только этот.
    func select(_ item: ImageItem, shift: Bool, command: Bool) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        if shift, let anchorID = selectionAnchorID,
           let anchorIndex = items.firstIndex(where: { $0.id == anchorID }) {
            let lower = min(anchorIndex, index)
            let upper = max(anchorIndex, index)
            let rangeIDs = items[lower...upper].map { $0.id }
            if command {
                selectedIDs.formUnion(rangeIDs)
            } else {
                selectedIDs = Set(rangeIDs)
            }
            // якорь не сдвигаем — можно расширять диапазон
        } else if command {
            if selectedIDs.contains(item.id) {
                selectedIDs.remove(item.id)
            } else {
                selectedIDs.insert(item.id)
            }
            selectionAnchorID = item.id
        } else {
            selectedIDs = [item.id]
            selectionAnchorID = item.id
        }
    }

    func openPreview(_ item: ImageItem) {
        guard item.status == .done else { return }
        previewItem = item
    }

    /// Переименовывает файл на диске и обновляет элемент. Возвращает успех.
    @discardableResult
    func renameFile(item: ImageItem, to newURL: URL) -> Bool {
        guard newURL != item.originalURL else { return true }
        guard !FileManager.default.fileExists(atPath: newURL.path) else { return false }
        do {
            try FileManager.default.moveItem(at: item.originalURL, to: newURL)
        } catch {
            return false
        }
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].originalURL = newURL
        }
        if previewItem?.id == item.id {
            previewItem?.originalURL = newURL
        }
        return true
    }

    /// Прямая установка выделения (для рамочного выделения мышью).
    func setSelection(_ ids: Set<UUID>) {
        selectedIDs = ids
    }

    func clearSelection() {
        selectedIDs = []
    }

    /// Единственная выбранная картинка (для панели метаданных).
    var singleSelectedItem: ImageItem? {
        guard selectedIDs.count == 1, let id = selectedIDs.first else { return nil }
        return items.first { $0.id == id }
    }

    var processedCount: Int {
        items.filter { $0.status == .done }.count
    }

    var totalSavedInSession: Int64 {
        items.compactMap { $0.result?.savedBytes }.reduce(0, +)
    }

    var formattedTotalSaved: String {
        ByteCountFormatter.string(fromByteCount: totalBytesSaved, countStyle: .file)
    }

    static let supportedTypes: [UTType] = [.jpeg, .png, .webP, .heic]

    func addFiles(urls: [URL]) {
        var duplicates: Set<UUID> = []
        ingest(urls: urls, duplicates: &duplicates)
        if !duplicates.isEmpty {
            flashDuplicates(duplicates)
        }
    }

    private func ingest(urls: [URL], duplicates: inout Set<UUID>) {
        let validExtensions = ["jpg", "jpeg", "png", "webp", "heic", "heif"]

        for url in urls {
            // Разворачиваем папки в отдельные файлы.
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
                    let nested = enumerator.compactMap { $0 as? URL }
                    ingest(urls: nested, duplicates: &duplicates)
                }
                continue
            }

            let ext = url.pathExtension.lowercased()
            guard validExtensions.contains(ext) else { continue }

            // Дубликат — уже в очереди.
            if let existing = items.first(where: { $0.originalURL == url }) {
                duplicates.insert(existing.id)
                continue
            }

            let item = ImageItem(url: url)
            let itemID = item.id
            Task {
                let thumbData = await ImageProcessor.shared.generateThumbnail(for: url)
                if let idx = items.firstIndex(where: { $0.id == itemID }) {
                    items[idx].thumbnail = thumbData
                }
            }
            items.append(item)
        }
    }

    private var toastToken = 0

    /// Показывает всплывашку внизу (и опционально подсвечивает элементы) на ~1.9 c.
    func showToast(_ message: String, highlight ids: Set<UUID> = []) {
        toast = message
        highlightedIDs = ids
        toastToken += 1
        let token = toastToken
        Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            if token == toastToken {
                highlightedIDs = []
                toast = nil
            }
        }
    }

    private func flashDuplicates(_ ids: Set<UUID>) {
        let n = ids.count
        let message = n == 1
            ? Localizer.translate("Это изображение уже добавлено")
            : "\(Localizer.translate("Уже в очереди")): \(n)"
        showToast(message, highlight: ids)
    }

    /// NSItemProvider потокобезопасен на практике, но не помечен Sendable —
    /// оборачиваем, чтобы безопасно передавать между изоляциями.
    private struct SendableProvider: @unchecked Sendable {
        let provider: NSItemProvider
    }

    /// Обрабатывает drop: собирает URL со ВСЕХ провайдеров и добавляет одним вызовом
    /// (чтобы подсветка дубликатов и обновление шли разом).
    func handleDrop(providers: [NSItemProvider]) {
        let wrapped = providers.map { SendableProvider(provider: $0) }
        Task { @MainActor in
            var urls: [URL] = []
            for item in wrapped {
                if let url = await Self.loadURL(from: item) {
                    urls.append(url)
                }
            }
            self.addFiles(urls: urls)
        }
    }

    private nonisolated static func loadURL(from wrapped: SendableProvider) async -> URL? {
        await withCheckedContinuation { (cont: CheckedContinuation<URL?, Never>) in
            wrapped.provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                if let data = data as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    cont.resume(returning: url)
                } else {
                    cont.resume(returning: nil)
                }
            }
        }
    }

    func addFilesFromPicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = Self.supportedTypes

        if panel.runModal() == .OK {
            var urls: [URL] = []
            for url in panel.urls {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
                        for case let fileURL as URL in enumerator {
                            urls.append(fileURL)
                        }
                    }
                } else {
                    urls.append(url)
                }
            }
            addFiles(urls: urls)
        }
    }

    func removeItem(_ item: ImageItem) {
        items.removeAll { $0.id == item.id }
        selectedIDs.remove(item.id)
        if previewItem?.id == item.id {
            previewItem = nil
        }
    }

    func removeSelected() {
        guard !selectedIDs.isEmpty else { return }
        let removed = selectedIDs
        items.removeAll { removed.contains($0.id) }
        selectedIDs.removeAll()
        if let p = previewItem, removed.contains(p.id) {
            previewItem = nil
        }
    }

    func clearAll() {
        items.removeAll()
        selectedIDs.removeAll()
        previewItem = nil
    }

    func compressAll(preset: CompressionPreset) {
        // Пересжимаем ВСЕ файлы в очереди (в т.ч. уже сжатые).
        // Пропускаем только если включён тоггл «Пропускать сжатые».
        let targetItems = items
        guard !targetItems.isEmpty else { return }

        // Режим «Спросить» — один раз спрашиваем папку для всей партии.
        var askDirectory: URL? = nil
        if preset.saveLocation == .ask {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.prompt = "Сохранить сюда"
            panel.message = "Выберите папку для сжатых файлов"
            guard panel.runModal() == .OK, let dir = panel.url else { return }
            askDirectory = dir
        }

        isProcessing = true
        processingProgress = 0
        let total = targetItems.count

        for i in items.indices {
            items[i].status = .pending
        }

        compressionTask = Task {
            var completed = 0
            var batchCount = 0
            var batchSaved: Int64 = 0

            for item in targetItems {
                if Task.isCancelled { break }

                if preset.skipOptimized && item.fileName.contains(preset.suffix) {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        items[idx].status = .pending
                    }
                    completed += 1
                    processingProgress = Double(completed) / Double(total)
                    continue
                }

                // Если файл уже был сжат ранее — вычитаем его прошлый вклад в счётчики,
                // чтобы повторное сжатие не задваивало статистику.
                var previousOutput: URL? = nil
                if let idx = items.firstIndex(where: { $0.id == item.id }),
                   let old = items[idx].result {
                    previousOutput = old.compressedURL
                    totalImagesProcessed = max(0, totalImagesProcessed - 1)
                    totalBytesSaved = max(0, totalBytesSaved - old.savedBytes)
                    items[idx].result = nil
                }

                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                    items[idx].status = .processing
                }

                do {
                    let outputURL = buildOutputURL(for: item, preset: preset, askDirectory: askDirectory, existingOutput: previousOutput)
                    try ensureDirectoryExists(for: outputURL)

                    let resultURL = try await ImageProcessor.shared.process(
                        imageAt: item.originalURL,
                        quality: preset.qualityLevel.qualityValue,
                        format: preset.format,
                        resizeWidth: preset.resizeWidth,
                        resizeHeight: preset.resizeHeight,
                        outputURL: outputURL,
                        preserveMetadata: preset.preserveMetadata
                    )

                    let compressedSize = (try? FileManager.default.attributesOfItem(atPath: resultURL.path)[.size] as? Int64) ?? 0

                    let compressionResult = CompressionResult(
                        compressedURL: resultURL,
                        originalSize: item.fileSize,
                        compressedSize: compressedSize
                    )

                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        items[idx].status = .done
                        items[idx].result = compressionResult
                        totalImagesProcessed += 1
                        totalBytesSaved += compressionResult.savedBytes
                        batchCount += 1
                        batchSaved += compressionResult.savedBytes
                    }

                    performPostAction(preset.postAction, result: compressionResult)
                } catch is CancellationError {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        items[idx].status = .pending
                    }
                    break
                } catch {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        items[idx].status = .error(error.localizedDescription)
                    }
                }

                if Task.isCancelled { break }
                completed += 1
                processingProgress = Double(completed) / Double(total)
            }

            let wasCancelled = Task.isCancelled
            isProcessing = false
            isCancelling = false
            compressionTask = nil

            // Прерванные/непройденные файлы возвращаем в «ожидание».
            for i in items.indices where items[i].status == .processing || items[i].status == .pending {
                items[i].status = .pending
            }

            if !wasCancelled && batchCount > 0 {
                if UserDefaults.standard.object(forKey: "playSound") as? Bool ?? true {
                    NSSound(named: "Glass")?.play()
                }
                if UserDefaults.standard.bool(forKey: "showNotifications") {
                    let savedStr = ByteCountFormatter.string(fromByteCount: batchSaved, countStyle: .file)
                    NotificationManager.notifyBatchComplete(count: batchCount, saved: savedStr)
                }
            }
        }
    }

    private func buildOutputURL(for item: ImageItem, preset: CompressionPreset, askDirectory: URL?, existingOutput: URL?) -> URL {
        let originalURL = item.originalURL
        let directory: URL

        switch preset.saveLocation {
        case .original:
            directory = originalURL.deletingLastPathComponent()
        case .ask:
            directory = askDirectory ?? originalURL.deletingLastPathComponent()
        case .custom:
            if preset.customOutputPath.isEmpty {
                directory = originalURL.deletingLastPathComponent()
            } else {
                directory = URL(fileURLWithPath: preset.customOutputPath)
            }
        }

        let finalDirectory: URL
        if preset.useSubfolder && !preset.subfolder.isEmpty {
            finalDirectory = directory.appendingPathComponent(preset.subfolder, isDirectory: true)
        } else {
            finalDirectory = directory
        }

        let baseName = originalURL.deletingPathExtension().lastPathComponent
        let suffix = preset.useSuffix ? preset.suffix : ""
        let format = preset.format == .original ? ImageFormat.from(url: originalURL) : preset.format
        let ext = format.fileExtension

        var effectiveBase = "\(baseName)\(suffix)"
        var outputURL = finalDirectory.appendingPathComponent("\(effectiveBase).\(ext)")

        // Защита от перезаписи оригинала: если путь совпал с исходным файлом,
        // принудительно добавляем суффикс.
        if outputURL.standardizedFileURL == originalURL.standardizedFileURL {
            effectiveBase = "\(baseName)\(suffix)-squished"
            outputURL = finalDirectory.appendingPathComponent("\(effectiveBase).\(ext)")
        }

        // Защита от коллизий: если файл уже существует и это НЕ наш собственный
        // прошлый результат (повторное сжатие того же элемента) — добавляем «(n)».
        let fm = FileManager.default
        var counter = 1
        while fm.fileExists(atPath: outputURL.path),
              outputURL.standardizedFileURL != existingOutput?.standardizedFileURL {
            outputURL = finalDirectory.appendingPathComponent("\(effectiveBase) (\(counter)).\(ext)")
            counter += 1
        }

        return outputURL
    }

    private func ensureDirectoryExists(for fileURL: URL) throws {
        let dir = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func performPostAction(_ action: PostAction, result: CompressionResult) {
        switch action {
        case .none:
            break
        case .copyPath:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.compressedURL.path, forType: .string)
        case .copyFile:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([result.compressedURL as NSURL])
        case .copyMarkdown:
            let md = "![image](\(result.compressedURL.lastPathComponent))"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(md, forType: .string)
        }
    }
}
