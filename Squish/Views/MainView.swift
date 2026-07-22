import SwiftUI

struct MainView: View {
    @EnvironmentObject var mainVM: MainViewModel
    @EnvironmentObject var presetVM: PresetViewModel
    @EnvironmentObject var loc: Localizer
    @Environment(\.openSettings) private var openSettings
    @State private var showStats = false
    @State private var showInspector = true
    @State private var showClearConfirm = false
    @State private var donateHovering = false

    private let donateURL = URL(string: "https://web.tribute.tg/d/GLT")!

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                sidebar

                Divider()

                contentArea

                if showInspector && !mainVM.items.isEmpty {
                    Divider()
                        .transition(.opacity)
                    Group {
                        if let selected = mainVM.singleSelectedItem {
                            MetadataPanel(item: selected)
                                .environmentObject(loc)
                                .environmentObject(mainVM)
                        } else {
                            CompressionPanel()
                                .environmentObject(presetVM)
                                .environmentObject(mainVM)
                        }
                    }
                    .frame(width: 300)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showInspector)
            .animation(.easeInOut(duration: 0.25), value: mainVM.items.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: mainVM.singleSelectedItem?.id)

            Divider()

            statusBar
        }
        .overlay(alignment: .bottom) {
            if let toast = mainVM.toast {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color(hex: "f5a623"))
                    Text(toast)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color(hex: "f5a623").opacity(0.35)))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                .padding(.bottom, 44)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: mainVM.toast)
        .frame(minWidth: 780, minHeight: 520)
        .background(WindowAccessor(autosaveName: "SquishMainWindow"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if !mainVM.items.isEmpty {
                    Picker("", selection: $mainVM.viewMode) {
                        Image(systemName: "square.grid.2x2")
                            .tag(MainViewModel.ViewMode.grid)
                        Image(systemName: "list.bullet")
                            .tag(MainViewModel.ViewMode.list)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 84)
                }
            }

            ToolbarItem(placement: .automatic) {
                if !mainVM.items.isEmpty {
                    Button {
                        showInspector.toggle()
                    } label: {
                        Image(systemName: "sidebar.trailing")
                    }
                    .help(loc.tr("Панель настроек"))
                }
            }
        }
        .sheet(item: $mainVM.previewItem) { item in
            PreviewCompareView(item: item)
                .environmentObject(loc)
                .frame(minWidth: 600, minHeight: 400)
        }
        .alert(loc.tr("Очистить все изображения?"), isPresented: $showClearConfirm) {
            Button(loc.tr("Отмена"), role: .cancel) {}
            Button(loc.tr("Очистить"), role: .destructive) {
                mainVM.clearAll()
            }
        } message: {
            Text(loc.tr("Все добавленные изображения будут убраны из очереди."))
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 4) {
            sidebarButton(icon: "doc.badge.plus", tooltip: loc.tr("Добавить файлы (⌘O)")) {
                mainVM.addFilesFromPicker()
            }

            if !mainVM.items.isEmpty {
                sidebarButton(icon: "trash", tooltip: loc.tr("Очистить всё")) {
                    showClearConfirm = true
                }
            }

            Spacer()

            donateButton

            sidebarButton(icon: "info.circle", tooltip: loc.tr("Статистика")) {
                showStats.toggle()
            }
            .popover(isPresented: $showStats, arrowEdge: .trailing) {
                statsPopover
            }

            sidebarButton(icon: "gearshape", tooltip: loc.tr("Настройки (⌘,)")) {
                openSettings()
            }
        }
        .frame(width: 52)
        .padding(.vertical, 16)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.7))
    }

    private var donateButton: some View {
        Button {
            NSWorkspace.shared.open(donateURL)
        } label: {
            Image(systemName: "heart.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "34D399"), Color(hex: "2a9d6e")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 9)
                )
                .shadow(color: Color(hex: "34D399").opacity(donateHovering ? 0.6 : 0.35), radius: donateHovering ? 8 : 5)
                .scaleEffect(donateHovering ? 1.08 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(loc.tr("Поддержать разработку"))
        .onHover { donateHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: donateHovering)
    }

    private func sidebarButton(icon: String, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    // MARK: - Content Area

    private var contentArea: some View {
        Group {
            if mainVM.items.isEmpty {
                DropZoneView()
                    .environmentObject(mainVM)
            } else {
                switch mainVM.viewMode {
                case .grid:
                    FileGridView()
                        .environmentObject(mainVM)
                case .list:
                    FileListTableView()
                        .environmentObject(mainVM)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 16) {
            if mainVM.isProcessing {
                ProgressView(value: mainVM.processingProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 100)
                    .tint(Color(hex: "34D399"))
            }

            Text("\(loc.tr("Обработано")): \(mainVM.totalImagesProcessed)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("\u{00B7}")
                .foregroundStyle(.secondary.opacity(0.2))

            Text("\(loc.tr("Сэкономлено")): \(mainVM.formattedTotalSaved)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "34D399"))
        }
        .frame(height: 28)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Stats Popover

    private var statsPopover: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.tr("Обработано"))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text("\(mainVM.totalImagesProcessed)")
                    .font(.system(size: 18, weight: .bold))
            }
            Divider().frame(height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.tr("Сэкономлено"))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(mainVM.formattedTotalSaved)
                    .font(.system(size: 18, weight: .bold))
            }
        }
        .padding(16)
    }
}
