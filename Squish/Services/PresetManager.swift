import Foundation

final class PresetManager: Sendable {
    static let shared = PresetManager()

    private var presetsURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let squishDir = appSupport.appendingPathComponent("Squish", isDirectory: true)
        if !FileManager.default.fileExists(atPath: squishDir.path) {
            try? FileManager.default.createDirectory(at: squishDir, withIntermediateDirectories: true)
        }
        return squishDir.appendingPathComponent("presets.json")
    }

    func loadPresets() -> [CompressionPreset] {
        // Первый запуск — засеваем стандартные пресеты на диск.
        guard FileManager.default.fileExists(atPath: presetsURL.path),
              let data = try? Data(contentsOf: presetsURL),
              let presets = try? JSONDecoder().decode([CompressionPreset].self, from: data) else {
            savePresets(CompressionPreset.builtInPresets)
            return CompressionPreset.builtInPresets
        }
        return presets
    }

    func savePresets(_ presets: [CompressionPreset]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(presets) {
            try? data.write(to: presetsURL, options: .atomic)
        }
    }
}
