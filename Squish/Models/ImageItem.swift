import Foundation
import UniformTypeIdentifiers

enum ImageFormat: String, Codable, CaseIterable, Identifiable {
    case jpeg
    case png
    case webp
    case heic
    case original

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jpeg: return "JPEG"
        case .png: return "PNG"
        case .webp: return "WebP"
        case .heic: return "HEIC"
        case .original: return "Оригинал"
        }
    }

    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .webp: return .webP
        case .heic: return .heic
        case .original: return .image
        }
    }

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .webp: return "webp"
        case .heic: return "heic"
        case .original: return ""
        }
    }

    static func from(url: URL) -> ImageFormat {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg": return .jpeg
        case "png": return .png
        case "webp": return .webp
        case "heic", "heif": return .heic
        default: return .jpeg
        }
    }
}

enum ProcessingStatus: Equatable {
    case pending
    case processing
    case done
    case error(String)
}

struct ImageItem: Identifiable, Equatable {
    let id: UUID
    var originalURL: URL
    let fileSize: Int64
    let format: ImageFormat
    var status: ProcessingStatus
    var result: CompressionResult?
    var thumbnail: Data?

    init(url: URL) {
        self.id = UUID()
        self.originalURL = url
        self.format = ImageFormat.from(url: url)
        self.status = .pending
        self.result = nil

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        self.fileSize = fileSize
    }

    var fileName: String {
        originalURL.lastPathComponent
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
            && lhs.originalURL == rhs.originalURL
            && lhs.status == rhs.status
            && lhs.result == rhs.result
            && (lhs.thumbnail == nil) == (rhs.thumbnail == nil)
    }
}
