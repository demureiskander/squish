import SwiftUI

@main
struct SquishApp: App {
    @StateObject private var mainVM = MainViewModel()
    @StateObject private var presetVM = PresetViewModel()
    @StateObject private var loc = Localizer.shared
    @AppStorage("menuBarIcon") private var menuBarIcon = true
    @AppStorage("hideFromDock") private var hideFromDock = false

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(mainVM)
                .environmentObject(presetVM)
                .environmentObject(loc)
                .onAppear {
                    // Применяем сохранённые системные настройки при запуске.
                    DockPolicy.setHidden(hideFromDock)
                    // Диагностика WebP — смотри в консоли Xcode.
                    NSLog("[WebP] Доступность: \(WebPEncoder.isAvailable) · Модули: \(WebPEncoder.diagnostics)")
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 960, height: 620)
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutMenuButton()
            }

            CommandGroup(replacing: .newItem) {
                Button(loc.tr("Открыть файлы…")) {
                    mainVM.addFilesFromPicker()
                }
                .keyboardShortcut("o")

                Divider()

                Button(loc.tr("Сжать всё")) {
                    mainVM.compressAll(preset: presetVM.selectedPreset)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(mainVM.items.isEmpty || mainVM.isProcessing)

                Divider()

                Button(loc.tr("Удалить выбранное")) {
                    mainVM.removeSelected()
                }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(mainVM.selectedIDs.isEmpty)

                Button(loc.tr("Очистить всё")) {
                    mainVM.clearAll()
                }
                .disabled(mainVM.items.isEmpty)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(presetVM)
                .environmentObject(loc)
        }

        Window("Squish", id: "about") {
            AboutView()
                .environmentObject(loc)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        MenuBarExtra("Squish", systemImage: "square.on.square.dashed", isInserted: $menuBarIcon) {
            Button(loc.tr("Открыть файлы…")) {
                mainVM.addFilesFromPicker()
            }

            Button(loc.tr("Сжать всё")) {
                mainVM.compressAll(preset: presetVM.selectedPreset)
            }
            .disabled(mainVM.items.isEmpty || mainVM.isProcessing)

            Divider()

            Text("\(loc.tr("Обработано")): \(mainVM.totalImagesProcessed) · \(loc.tr("Сэкономлено")): \(mainVM.formattedTotalSaved)")

            Divider()

            SettingsLink {
                Text(loc.tr("Настройки…"))
            }

            Button(loc.tr("Выйти")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// MARK: - About menu button

struct AboutMenuButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("О программе Squish / About Squish") {
            openWindow(id: "about")
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
