import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var presetVM: PresetViewModel
    @EnvironmentObject var loc: Localizer
    @AppStorage("showNotifications") private var showNotifications = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("menuBarIcon") private var menuBarIcon = true
    @AppStorage("hideFromDock") private var hideFromDock = false
    @AppStorage("playSound") private var playSound = true
    @State private var showPresetManager = false
    @State private var showHelp = false

    private let repoURL = URL(string: "https://github.com/demureiskander/squish")!
    private let donateURL = URL(string: "https://web.tribute.tg/d/GLT")!

    var body: some View {
        VStack(spacing: 8) {
            // Language
            settingRow(icon: "globe", title: loc.tr("Язык")) {
                Picker("", selection: $loc.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
                .fixedSize()
                .controlSize(.small)
            }

            // Default Preset — открывает редактор пресетов
            settingRow(icon: "slider.horizontal.3", title: loc.tr("Пресеты")) {
                Button {
                    showPresetManager = true
                } label: {
                    HStack(spacing: 4) {
                        Text(loc.tr("Управлять"))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                    }
                }
                .controlSize(.small)
            }

            // Notifications
            toggleRow(icon: "bell", title: loc.tr("Уведомления"), isOn: $showNotifications)
                .onChange(of: showNotifications) { _, newValue in
                    if newValue { NotificationManager.requestAuthorization() }
                }

            // Sound
            toggleRow(icon: "speaker.wave.2", title: loc.tr("Звук по завершении"), isOn: $playSound)

            // Launch at Login
            toggleRow(icon: "clock", title: loc.tr("Запуск при входе"), isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    LoginItemManager.setEnabled(newValue)
                }

            // Menu Bar Icon
            toggleRow(icon: "menubar.rectangle", title: loc.tr("Иконка в строке меню"), isOn: $menuBarIcon)

            // Hide from Dock
            toggleRow(icon: "dock.rectangle", title: loc.tr("Скрыть из Dock"), isOn: $hideFromDock)
                .onChange(of: hideFromDock) { _, newValue in
                    DockPolicy.setHidden(newValue)
                }

            // How to use
            settingRow(icon: "questionmark.circle", title: loc.tr("Как пользоваться")) {
                Button {
                    showHelp = true
                } label: {
                    HStack(spacing: 4) {
                        Text(loc.tr("Открыть"))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                    }
                }
                .controlSize(.small)
            }

            // GitHub
            HStack {
                HStack(spacing: 10) {
                    Image("GitHubLogo")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    Text(loc.tr("Исходный код"))
                        .font(.system(size: 12))
                        .foregroundStyle(.primary.opacity(0.7))
                }
                Spacer()
                Button {
                    NSWorkspace.shared.open(repoURL)
                } label: {
                    HStack(spacing: 4) {
                        Text("GitHub")
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                    }
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)

            // Support development
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "34D399"))
                        .frame(width: 16)

                    Text(loc.tr("Поддержать разработку"))
                        .font(.system(size: 12))
                        .foregroundStyle(.primary.opacity(0.7))
                }
                Spacer()
                Button {
                    NSWorkspace.shared.open(donateURL)
                } label: {
                    HStack(spacing: 4) {
                        Text(loc.tr("Поддержать"))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                    }
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "34D399"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)

            // Version info
            Text("Squish v1.0.0 · GPL v3 · github.com/demureiskander/squish")
                .font(.system(size: 10))
                .foregroundStyle(.secondary.opacity(0.3))
                .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 420)
        .sheet(isPresented: $showPresetManager) {
            VStack(spacing: 0) {
                PresetListView()
                    .environmentObject(presetVM)
                    .environmentObject(loc)
                    .frame(minHeight: 360)

                Divider()

                HStack {
                    Spacer()
                    Button(loc.tr("Готово")) {
                        showPresetManager = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(12)
            }
            .frame(width: 460, height: 460)
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
                .environmentObject(loc)
        }
    }

    private func settingRow<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary.opacity(0.7))
            }
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        settingRow(icon: icon, title: title) {
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(Color(hex: "34D399"))
                .labelsHidden()
        }
    }
}
