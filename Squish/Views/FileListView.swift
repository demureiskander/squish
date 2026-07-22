import SwiftUI
import UniformTypeIdentifiers

struct CellFramesKey: PreferenceKey {
    static let defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct FileGridView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var loc: Localizer
    @State private var isTargeted = false
    @State private var cellFrames: [UUID: CGRect] = [:]
    @State private var marqueeRect: CGRect?

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.items) { item in
                    FileGridCell(
                        item: item,
                        isSelected: viewModel.selectedIDs.contains(item.id),
                        isHighlighted: viewModel.highlightedIDs.contains(item.id)
                    )
                        .animation(.easeInOut(duration: 0.25), value: viewModel.highlightedIDs)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: CellFramesKey.self,
                                    value: [item.id: proxy.frame(in: .named("grid"))]
                                )
                            }
                        )
                        .overlay(
                            ClickCatcher(
                                onClick: { clickCount, shift, command in
                                    if clickCount >= 2 {
                                        viewModel.openPreview(item)
                                    } else {
                                        viewModel.select(item, shift: shift, command: command)
                                    }
                                },
                                fileURL: item.status == .done ? item.result?.compressedURL : nil,
                                dragImage: item.thumbnail.flatMap { NSImage(data: $0) }
                            )
                        )
                        .contextMenu {
                            if viewModel.selectedIDs.count > 1 && viewModel.selectedIDs.contains(item.id) {
                                Button(loc.tr("Удалить выбранные") + " (\(viewModel.selectedIDs.count))") {
                                    viewModel.removeSelected()
                                }
                            } else {
                                Button(loc.tr("Удалить")) {
                                    viewModel.removeItem(item)
                                }
                            }
                            if item.status == .done, let result = item.result {
                                Button(loc.tr("Показать в Finder")) {
                                    NSWorkspace.shared.activateFileViewerSelecting([result.compressedURL])
                                }
                            }
                        }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
            .coordinateSpace(name: "grid")
            .background(
                MarqueeCatcher(
                    onChange: { rect in
                        marqueeRect = rect
                        let ids = cellFrames.compactMap { id, frame in
                            frame.intersects(rect) ? id : nil
                        }
                        viewModel.setSelection(Set(ids))
                    },
                    onClick: { viewModel.clearSelection() },
                    onEnd: { marqueeRect = nil }
                )
            )
            .onPreferenceChange(CellFramesKey.self) { cellFrames = $0 }
            .overlay {
                if let rect = marqueeRect {
                    Rectangle()
                        .fill(Color(hex: "34D399").opacity(0.12))
                        .overlay(Rectangle().strokeBorder(Color(hex: "34D399"), lineWidth: 1))
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .allowsHitTesting(false)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            viewModel.handleDrop(providers: providers)
            return true
        }
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(hex: "34D399"), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .background(Color(hex: "34D399").opacity(0.05))
                    .padding(8)
            }
        }
    }
}

struct FileGridCell: View {
    let item: ImageItem
    var isSelected: Bool = false
    var isHighlighted: Bool = false
    @EnvironmentObject var loc: Localizer

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack {
                if let thumbData = item.thumbnail, let nsImage = NSImage(data: thumbData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 120)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundStyle(.secondary.opacity(0.3))
                        }
                }

                // Status overlay
                switch item.status {
                case .done:
                    if let result = item.result {
                        VStack {
                            HStack {
                                Spacer()
                                Text(result.formattedSavings)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "22c55e"))
                                    .cornerRadius(4)
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                case .processing:
                    Color.black.opacity(0.4)
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color(hex: "34D399"))
                case .error:
                    Color.red.opacity(0.15)
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                default:
                    EmptyView()
                }
            }
            .frame(height: 120)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.fileName)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack {
                    if item.status == .done, let result = item.result {
                        Text(item.formattedSize)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.4))
                            .strikethrough()
                        Spacer()
                        Text(result.formattedCompressedSize)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "34D399"))
                    } else if case .processing = item.status {
                        Text(item.formattedSize)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.4))
                        Spacer()
                        Text(loc.tr("Сжатие…"))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.35))
                    } else {
                        Text(item.formattedSize)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary.opacity(0.4))
                        Spacer()
                        if case .error(let msg) = item.status {
                            Text(loc.tr("Ошибка"))
                                .font(.system(size: 10))
                                .foregroundStyle(.red.opacity(0.7))
                                .help(msg)
                        } else {
                            Text(loc.tr("Ожидание"))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary.opacity(0.3))
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isHighlighted ? Color(hex: "f5a623") : Color(hex: "34D399"),
                    lineWidth: (isHighlighted || isSelected) ? 2.5 : 0
                )
        }
    }
}

struct FileListTableView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var loc: Localizer
    @State private var isTargeted = false

    private let thumbCol: CGFloat = 40
    private let formatCol: CGFloat = 55
    private let sizeCol: CGFloat = 70
    private let resultCol: CGFloat = 70
    private let savedCol: CGFloat = 65

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Color.clear.frame(width: thumbCol, height: 1)
                Text(loc.tr("Имя"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(loc.tr("Формат"))
                    .frame(width: formatCol, alignment: .trailing)
                Text(loc.tr("Оригинал"))
                    .frame(width: sizeCol, alignment: .trailing)
                Text(loc.tr("Результат"))
                    .frame(width: resultCol, alignment: .trailing)
                Text(loc.tr("Экономия"))
                    .frame(width: savedCol, alignment: .trailing)
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary.opacity(0.4))
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))

            Divider().opacity(0.3)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.items) { item in
                        listRow(item)
                            .background(
                                viewModel.highlightedIDs.contains(item.id)
                                    ? Color(hex: "f5a623").opacity(0.22)
                                    : (viewModel.selectedIDs.contains(item.id)
                                        ? Color(hex: "34D399").opacity(0.15)
                                        : Color.clear)
                            )
                            .overlay(
                                ClickCatcher(
                                    onClick: { clickCount, shift, command in
                                        if clickCount >= 2 {
                                            viewModel.openPreview(item)
                                        } else {
                                            viewModel.select(item, shift: shift, command: command)
                                        }
                                    },
                                    fileURL: item.status == .done ? item.result?.compressedURL : nil,
                                    dragImage: item.thumbnail.flatMap { NSImage(data: $0) }
                                )
                            )
                            .contextMenu {
                                if viewModel.selectedIDs.count > 1 && viewModel.selectedIDs.contains(item.id) {
                                    Button(loc.tr("Удалить выбранные") + " (\(viewModel.selectedIDs.count))") {
                                        viewModel.removeSelected()
                                    }
                                } else {
                                    Button(loc.tr("Удалить")) {
                                        viewModel.removeItem(item)
                                    }
                                }
                            }
                        Divider().opacity(0.15)
                    }
                }
            }
        }
        .background(
            ClickCatcher { _, _, _ in
                viewModel.clearSelection()
            }
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            viewModel.handleDrop(providers: providers)
            return true
        }
    }

    private func listRow(_ item: ImageItem) -> some View {
        HStack(spacing: 8) {
            Group {
                if let thumbData = item.thumbnail, let nsImage = NSImage(data: thumbData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 28, height: 28)
                }
            }
            .frame(width: thumbCol)

            Text(item.fileName)
                .font(.system(size: 12))
                .foregroundStyle(.primary.opacity(0.8))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.format.displayName)
                .font(.system(size: 10))
                .foregroundStyle(.secondary.opacity(0.5))
                .frame(width: formatCol, alignment: .trailing)

            if item.status == .done, let result = item.result {
                Text(item.formattedSize)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .strikethrough()
                    .frame(width: sizeCol, alignment: .trailing)

                Text(result.formattedCompressedSize)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "34D399"))
                    .frame(width: resultCol, alignment: .trailing)

                Text(result.formattedSavings)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "22c55e"))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(hex: "22c55e").opacity(0.12))
                    .cornerRadius(3)
                    .frame(width: savedCol, alignment: .trailing)
            } else {
                Text(item.formattedSize)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .frame(width: sizeCol, alignment: .trailing)

                Text("—")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary.opacity(0.3))
                    .frame(width: resultCol, alignment: .trailing)

                Group {
                    if case .processing = item.status {
                        ProgressView()
                            .controlSize(.mini)
                    } else if case .error = item.status {
                        Text(loc.tr("Ошибка"))
                            .foregroundStyle(.red.opacity(0.6))
                    } else {
                        Text(loc.tr("Ожидание"))
                            .foregroundStyle(.secondary.opacity(0.3))
                    }
                }
                .font(.system(size: 10))
                .frame(width: savedCol, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
