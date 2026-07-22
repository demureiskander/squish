import SwiftUI
import AppKit

struct PreviewCompareView: View {
    let item: ImageItem
    @EnvironmentObject var loc: Localizer
    @Environment(\.dismiss) private var dismiss

    @State private var dividerPosition: CGFloat = 0.5
    @State private var originalResolution: String = ""
    @State private var originalImage: NSImage?
    @State private var compressedImage: NSImage?

    // Зум и панорамирование.
    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var lastPan: CGSize = .zero

    private let minZoom: CGFloat = 1
    private let maxZoom: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let aspect = imageAspect
                let fitted = fittedSize(container: geo.size, aspect: aspect)

                ZStack {
                    // Фон — клик мимо картинки закрывает превью.
                    Color(nsColor: .windowBackgroundColor)
                        .contentShape(Rectangle())
                        .onTapGesture { dismiss() }

                    // Масштабируемая пара изображений.
                    ZStack {
                        if let originalImage {
                            Image(nsImage: originalImage)
                                .resizable()
                                .interpolation(.high)
                        }
                        if let compressedImage {
                            Image(nsImage: compressedImage)
                                .resizable()
                                .interpolation(.high)
                                .clipShape(HorizontalClip(from: dividerPosition))
                        }

                        // Разделитель.
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2)
                            .position(x: fitted.width * dividerPosition, y: fitted.height / 2)

                        Circle()
                            .fill(.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                            .overlay {
                                Image(systemName: "arrow.left.and.right")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                            .position(x: fitted.width * dividerPosition, y: fitted.height / 2)
                            .gesture(
                                DragGesture(coordinateSpace: .named("img"))
                                    .onChanged { value in
                                        dividerPosition = max(0.02, min(0.98, value.location.x / fitted.width))
                                    }
                            )
                    }
                    .frame(width: fitted.width, height: fitted.height)
                    .coordinateSpace(name: "img")
                    .scaleEffect(zoom)
                    .offset(pan)
                    .gesture(panGesture)
                    .simultaneousGesture(zoomGesture)
                    .onTapGesture(count: 2) { resetZoom() }
                    .onTapGesture { /* поглощаем одиночный клик по картинке */ }

                    // Ярлыки — не масштабируются.
                    VStack {
                        HStack {
                            label(loc.tr("Оригинал"), color: .white.opacity(0.75))
                            Spacer()
                            label(loc.tr("Сжатое"), color: Color(hex: "34D399"))
                        }
                        Spacer()
                    }
                    .padding(12)

                    // Контролы зума.
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            zoomControls
                                .padding(12)
                        }
                    }
                }
                .clipped()
            }
            .background(Color(nsColor: .windowBackgroundColor))

            if let result = item.result {
                metricsBar(result)
            }
        }
        .task {
            originalImage = NSImage(contentsOf: item.originalURL)
            if let url = item.result?.compressedURL {
                compressedImage = NSImage(contentsOf: url)
            }
            if let res = await ImageProcessor.shared.imageResolution(at: item.originalURL) {
                originalResolution = "\(res.width) \u{00D7} \(res.height)"
            }
        }
    }

    // MARK: - Zoom controls

    private var zoomControls: some View {
        HStack(spacing: 2) {
            Button {
                setZoom(zoom - 0.5)
            } label: {
                Image(systemName: "minus")
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)

            Text("\(Int(zoom * 100))%")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .frame(width: 44)

            Button {
                setZoom(zoom + 0.5)
            } label: {
                Image(systemName: "plus")
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)

            Divider().frame(height: 16)

            Button {
                resetZoom()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(zoom == 1 && pan == .zero)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 4)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.1)))
    }

    // MARK: - Gestures

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = clampZoom(lastZoom * value.magnification)
            }
            .onEnded { _ in
                lastZoom = zoom
                if zoom == 1 { resetPan() }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoom > 1 else { return }
                pan = CGSize(
                    width: lastPan.width + value.translation.width,
                    height: lastPan.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastPan = pan
            }
    }

    private func clampZoom(_ z: CGFloat) -> CGFloat {
        min(max(z, minZoom), maxZoom)
    }

    private func setZoom(_ z: CGFloat) {
        withAnimation(.easeOut(duration: 0.15)) {
            zoom = clampZoom(z)
            lastZoom = zoom
            if zoom == 1 { pan = .zero; lastPan = .zero }
        }
    }

    private func resetZoom() {
        withAnimation(.easeOut(duration: 0.2)) {
            zoom = 1
            lastZoom = 1
            resetPan()
        }
    }

    private func resetPan() {
        pan = .zero
        lastPan = .zero
    }

    // MARK: - Helpers

    private var imageAspect: CGFloat {
        guard let size = originalImage?.size, size.height > 0 else { return 1 }
        return size.width / size.height
    }

    private func fittedSize(container: CGSize, aspect: CGFloat) -> CGSize {
        guard aspect > 0, container.width > 0, container.height > 0 else { return container }
        let containerAspect = container.width / container.height
        if aspect > containerAspect {
            return CGSize(width: container.width, height: container.width / aspect)
        } else {
            return CGSize(width: container.height * aspect, height: container.height)
        }
    }

    private func label(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func metricsBar(_ result: CompressionResult) -> some View {
        HStack(spacing: 32) {
            metricItem(label: loc.tr("До"), value: result.formattedOriginalSize, color: .primary.opacity(0.7))

            Image(systemName: "arrow.right")
                .font(.system(size: 14))
                .foregroundStyle(.secondary.opacity(0.3))

            metricItem(label: loc.tr("После"), value: result.formattedCompressedSize, color: Color(hex: "34D399"))

            Divider().frame(height: 16).opacity(0.3)

            metricItem(label: loc.tr("Экономия"), value: String(format: "%.0f%%", result.savedPercentage), color: Color(hex: "22c55e"))

            if !originalResolution.isEmpty {
                Divider().frame(height: 16).opacity(0.3)
                metricItem(label: loc.tr("Разрешение"), value: originalResolution, color: .primary.opacity(0.5))
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 44)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func metricItem(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary.opacity(0.5))
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

struct HorizontalClip: Shape {
    let from: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(
            x: rect.width * from,
            y: 0,
            width: rect.width * (1 - from),
            height: rect.height
        ))
        return path
    }
}
