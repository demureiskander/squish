import Foundation

struct CompressionResult: Equatable {
    let compressedURL: URL
    let originalSize: Int64
    let compressedSize: Int64

    var savedPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return Double(originalSize - compressedSize) / Double(originalSize) * 100.0
    }

    var formattedOriginalSize: String {
        ByteCountFormatter.string(fromByteCount: originalSize, countStyle: .file)
    }

    var formattedCompressedSize: String {
        ByteCountFormatter.string(fromByteCount: compressedSize, countStyle: .file)
    }

    var formattedSavings: String {
        String(format: "−%.0f%%", savedPercentage)
    }

    var savedBytes: Int64 {
        originalSize - compressedSize
    }
}
