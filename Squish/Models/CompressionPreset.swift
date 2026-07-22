import Foundation

enum QualityLevel: Int, Codable, CaseIterable, Identifiable {
    case maximum = 1
    case strong = 2
    case balanced = 3
    case high = 4
    case minimal = 5

    var id: Int { rawValue }

    var qualityValue: CGFloat {
        switch self {
        case .maximum: return 0.30
        case .strong: return 0.50
        case .balanced: return 0.70
        case .high: return 0.85
        case .minimal: return 0.95
        }
    }

    var displayName: String {
        switch self {
        case .maximum: return "Максимальное сжатие"
        case .strong: return "Сильное сжатие"
        case .balanced: return "Баланс"
        case .high: return "Высокое качество"
        case .minimal: return "Минимальное сжатие"
        }
    }

    var shortName: String {
        switch self {
        case .maximum: return "1 · Макс. сжатие"
        case .strong: return "2 · Сильное"
        case .balanced: return "3 · Баланс"
        case .high: return "4 · Высокое"
        case .minimal: return "5 · Минимальное"
        }
    }
}

enum SaveLocation: String, Codable, CaseIterable, Identifiable {
    case original
    case ask
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .original: return "Исходная папка"
        case .ask: return "Спрашивать"
        case .custom: return "Указанная папка"
        }
    }
}

enum PostAction: String, Codable, CaseIterable, Identifiable {
    case none
    case copyPath
    case copyFile
    case copyMarkdown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Ничего"
        case .copyPath: return "Скопировать путь"
        case .copyFile: return "Скопировать файл"
        case .copyMarkdown: return "Скопировать Markdown"
        }
    }
}

struct CompressionPreset: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var qualityLevel: QualityLevel
    var format: ImageFormat
    var resizeWidth: Int
    var resizeHeight: Int
    var isBuiltIn: Bool
    var saveLocation: SaveLocation
    var subfolder: String
    var useSubfolder: Bool
    var suffix: String
    var useSuffix: Bool
    var skipOptimized: Bool
    var preserveMetadata: Bool
    var postAction: PostAction
    var customOutputPath: String

    static let builtInPresets: [CompressionPreset] = [
        CompressionPreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Для веба",
            qualityLevel: .balanced,
            format: .jpeg,
            resizeWidth: 1920,
            resizeHeight: 0,
            isBuiltIn: true,
            saveLocation: .original,
            subfolder: "squished",
            useSubfolder: true,
            suffix: "-squished",
            useSuffix: false,
            skipOptimized: false,
            preserveMetadata: false,
            postAction: .none,
            customOutputPath: ""
        ),
        CompressionPreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Высокое качество",
            qualityLevel: .high,
            format: .jpeg,
            resizeWidth: 0,
            resizeHeight: 0,
            isBuiltIn: true,
            saveLocation: .original,
            subfolder: "squished",
            useSubfolder: true,
            suffix: "-squished",
            useSuffix: false,
            skipOptimized: false,
            preserveMetadata: true,
            postAction: .none,
            customOutputPath: ""
        ),
        CompressionPreset(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "Агрессивное",
            qualityLevel: .maximum,
            format: .jpeg,
            resizeWidth: 0,
            resizeHeight: 0,
            isBuiltIn: true,
            saveLocation: .original,
            subfolder: "squished",
            useSubfolder: true,
            suffix: "-squished",
            useSuffix: false,
            skipOptimized: false,
            preserveMetadata: false,
            postAction: .none,
            customOutputPath: ""
        )
    ]
}
