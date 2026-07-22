import Foundation
import SwiftUI

@MainActor
class PresetViewModel: ObservableObject {
    @Published var presets: [CompressionPreset] = []
    @Published var selectedPreset: CompressionPreset

    private let manager = PresetManager.shared

    init() {
        let loaded = PresetManager.shared.loadPresets()
        let list = loaded.isEmpty ? CompressionPreset.builtInPresets : loaded
        self.presets = list
        self.selectedPreset = list.first ?? CompressionPreset.builtInPresets[0]
    }

    func addPreset(name: String) {
        var preset = selectedPreset
        preset.id = UUID()
        preset.name = name
        preset.isBuiltIn = false
        presets.append(preset)
        selectedPreset = preset
        save()
    }

    func updatePreset(_ preset: CompressionPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
            if selectedPreset.id == preset.id {
                selectedPreset = preset
            }
            save()
        }
    }

    /// Переименовать пресет.
    func rename(_ preset: CompressionPreset, to newName: String) {
        var updated = preset
        updated.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !updated.name.isEmpty else { return }
        updatePreset(updated)
    }

    func deletePreset(_ preset: CompressionPreset) {
        presets.removeAll { $0.id == preset.id }
        if presets.isEmpty {
            presets = CompressionPreset.builtInPresets
        }
        if !presets.contains(where: { $0.id == selectedPreset.id }) {
            selectedPreset = presets.first ?? CompressionPreset.builtInPresets[0]
        }
        save()
    }

    /// Восстановить стандартные пресеты.
    func resetToDefaults() {
        presets = CompressionPreset.builtInPresets
        selectedPreset = presets[0]
        save()
    }

    func selectPreset(_ preset: CompressionPreset) {
        selectedPreset = preset
    }

    private func save() {
        manager.savePresets(presets)
    }
}
