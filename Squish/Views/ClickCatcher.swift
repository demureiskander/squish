import SwiftUI
import AppKit

/// Нативный обработчик клика — срабатывает мгновенно (на mouseDown),
/// сообщает число кликов и модификаторы. Правый клик пропускает вниз,
/// чтобы работало контекстное меню SwiftUI.
struct ClickCatcher: NSViewRepresentable {
    var onClick: (_ clickCount: Int, _ shift: Bool, _ command: Bool) -> Void
    /// Если задан — перетаскивание ячейки вытаскивает этот файл (в Finder/другие приложения).
    var fileURL: URL? = nil
    var dragImage: NSImage? = nil

    func makeNSView(context: Context) -> ClickView {
        let view = ClickView()
        view.onClick = onClick
        view.fileURL = fileURL
        view.dragImage = dragImage
        return view
    }

    func updateNSView(_ view: ClickView, context: Context) {
        view.onClick = onClick
        view.fileURL = fileURL
        view.dragImage = dragImage
    }

    final class ClickView: NSView, NSDraggingSource {
        var onClick: ((Int, Bool, Bool) -> Void)?
        var fileURL: URL?
        var dragImage: NSImage?
        private var downPoint: NSPoint?

        override func mouseDown(with event: NSEvent) {
            downPoint = convert(event.locationInWindow, from: nil)
            let shift = event.modifierFlags.contains(.shift)
            let command = event.modifierFlags.contains(.command)
            onClick?(event.clickCount, shift, command)
        }

        override func mouseDragged(with event: NSEvent) {
            guard let fileURL, let start = downPoint else { return }
            let point = convert(event.locationInWindow, from: nil)
            guard abs(point.x - start.x) + abs(point.y - start.y) > 6 else { return }
            downPoint = nil

            // Явно кладём файл как public.file-url — так его принимают Finder, чаты, письма.
            let pbItem = NSPasteboardItem()
            pbItem.setString(fileURL.absoluteString, forType: .fileURL)

            let dragItem = NSDraggingItem(pasteboardWriter: pbItem)
            let image = dragImage ?? NSWorkspace.shared.icon(forFile: fileURL.path)
            let frame = NSRect(x: point.x - 32, y: point.y - 32, width: 64, height: 64)
            dragItem.setDraggingFrame(frame, contents: image)

            let session = beginDraggingSession(with: [dragItem], event: event, source: self)
            session.draggingFormation = .none
        }

        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            .copy
        }

        // Пропускаем правый клик к нижележащему SwiftUI-view (контекстное меню).
        override func hitTest(_ point: NSPoint) -> NSView? {
            if let event = NSApp.currentEvent {
                switch event.type {
                case .rightMouseDown, .rightMouseUp, .rightMouseDragged:
                    return nil
                default:
                    break
                }
            }
            return super.hitTest(point)
        }
    }
}

/// Даёт окну постоянное имя для автосохранения его размера/позиции.
struct WindowAccessor: NSViewRepresentable {
    let autosaveName: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.setFrameAutosaveName(autosaveName)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Фоновый обработчик мыши для рамочного выделения и сброса по клику.
/// Ставится ПОЗАДИ ячеек, чтобы не конкурировать с их кликами.
struct MarqueeCatcher: NSViewRepresentable {
    var onChange: (CGRect) -> Void
    var onClick: () -> Void
    var onEnd: () -> Void

    func makeNSView(context: Context) -> MarqueeView {
        let view = MarqueeView()
        view.onChange = onChange
        view.onClick = onClick
        view.onEnd = onEnd
        return view
    }

    func updateNSView(_ view: MarqueeView, context: Context) {
        view.onChange = onChange
        view.onClick = onClick
        view.onEnd = onEnd
    }

    final class MarqueeView: NSView {
        var onChange: ((CGRect) -> Void)?
        var onClick: (() -> Void)?
        var onEnd: (() -> Void)?

        private var start: NSPoint?
        private var dragged = false

        override var isFlipped: Bool { true }

        override func mouseDown(with event: NSEvent) {
            start = convert(event.locationInWindow, from: nil)
            dragged = false
        }

        override func mouseDragged(with event: NSEvent) {
            guard let start else { return }
            let point = convert(event.locationInWindow, from: nil)
            if !dragged && (abs(point.x - start.x) + abs(point.y - start.y) > 6) {
                dragged = true
            }
            if dragged {
                let rect = CGRect(
                    x: min(start.x, point.x),
                    y: min(start.y, point.y),
                    width: abs(point.x - start.x),
                    height: abs(point.y - start.y)
                )
                onChange?(rect)
            }
        }

        override func mouseUp(with event: NSEvent) {
            if !dragged { onClick?() }
            onEnd?()
            start = nil
            dragged = false
        }

        // Правый клик — вниз (контекстное меню).
        override func hitTest(_ point: NSPoint) -> NSView? {
            if let event = NSApp.currentEvent {
                switch event.type {
                case .rightMouseDown, .rightMouseUp, .rightMouseDragged:
                    return nil
                default:
                    break
                }
            }
            return super.hitTest(point)
        }
    }
}
