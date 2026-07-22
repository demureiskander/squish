import Foundation
import CoreImage
import ImageIO
import UniformTypeIdentifiers
import AppKit

enum ImageProcessorError: LocalizedError {
    case cannotCreateSource
    case cannotCreateImage
    case cannotCreateDestination
    case cannotFinalize
    case cannotResize
    case unsupportedFormat(String)

    var errorDescription: String? {
        switch self {
        case .cannotCreateSource: return "Не удалось прочитать изображение"
        case .cannotCreateImage: return "Не удалось декодировать изображение"
        case .cannotCreateDestination: return "Не удалось создать выходной файл"
        case .cannotFinalize: return "Не удалось сохранить изображение"
        case .cannotResize: return "Не удалось изменить размер"
        case .unsupportedFormat(let name): return "\(name) недоступен для записи (нужна Фаза 2)"
        }
    }
}

actor ImageProcessor {
    static let shared = ImageProcessor()

    /// Форматы, которые ImageIO умеет записывать на этой системе.
    private static let supportedOutputTypes: Set<String> = {
        let types = (CGImageDestinationCopyTypeIdentifiers() as? [String]) ?? []
        return Set(types)
    }()

    func process(
        imageAt url: URL,
        quality: CGFloat,
        format: ImageFormat,
        resizeWidth: Int,
        resizeHeight: Int,
        outputURL: URL,
        preserveMetadata: Bool
    ) throws -> URL {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ImageProcessorError.cannotCreateSource
        }

        guard var cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImageProcessorError.cannotCreateImage
        }

        try Task.checkCancellation()

        if resizeWidth > 0 || resizeHeight > 0 {
            cgImage = try resize(image: cgImage, targetWidth: resizeWidth, targetHeight: resizeHeight)
        }

        try Task.checkCancellation()

        let outputFormat = format == .original ? ImageFormat.from(url: url) : format
        let destUTType = outputFormat.utType

        // WebP пишем через libwebp (если пакет подключён).
        if outputFormat == .webp {
            guard WebPEncoder.isAvailable else {
                throw ImageProcessorError.unsupportedFormat(outputFormat.displayName)
            }
            guard let data = WebPEncoder.encode(cgImage, quality: quality) else {
                throw ImageProcessorError.cannotFinalize
            }
            try data.write(to: outputURL, options: .atomic)
            return outputURL
        }

        guard Self.supportedOutputTypes.contains(destUTType.identifier) else {
            throw ImageProcessorError.unsupportedFormat(outputFormat.displayName)
        }

        guard let dest = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            destUTType.identifier as CFString,
            1,
            nil
        ) else {
            throw ImageProcessorError.cannotCreateDestination
        }

        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        if preserveMetadata, let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) {
            let dict = properties as Dictionary
            for (key, value) in dict {
                options[key as! CFString] = value
            }
        }

        CGImageDestinationAddImage(dest, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw ImageProcessorError.cannotFinalize
        }

        return outputURL
    }

    private func resize(image: CGImage, targetWidth: Int, targetHeight: Int) throws -> CGImage {
        let originalWidth = image.width
        let originalHeight = image.height

        var newWidth: Int
        var newHeight: Int

        if targetWidth > 0 && targetHeight > 0 {
            let scaleW = CGFloat(targetWidth) / CGFloat(originalWidth)
            let scaleH = CGFloat(targetHeight) / CGFloat(originalHeight)
            let scale = min(scaleW, scaleH)
            newWidth = Int(CGFloat(originalWidth) * scale)
            newHeight = Int(CGFloat(originalHeight) * scale)
        } else if targetWidth > 0 {
            let scale = CGFloat(targetWidth) / CGFloat(originalWidth)
            newWidth = targetWidth
            newHeight = Int(CGFloat(originalHeight) * scale)
        } else {
            let scale = CGFloat(targetHeight) / CGFloat(originalHeight)
            newWidth = Int(CGFloat(originalWidth) * scale)
            newHeight = targetHeight
        }

        if newWidth >= originalWidth && newHeight >= originalHeight {
            return image
        }

        let context = CIContext()
        let ciImage = CIImage(cgImage: image)

        let scaleX = CGFloat(newWidth) / CGFloat(originalWidth)
        let scaleY = CGFloat(newHeight) / CGFloat(originalHeight)
        let scale = min(scaleX, scaleY)

        guard let filter = CIFilter(name: "CILanczosScaleTransform") else {
            throw ImageProcessorError.cannotResize
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)

        guard let outputImage = filter.outputImage,
              let resizedCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw ImageProcessorError.cannotResize
        }

        return resizedCGImage
    }

    func generateThumbnail(for url: URL, maxSize: CGFloat = 512) -> Data? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let rep = NSBitmapImageRep(cgImage: thumbnail)
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
    }

    func imageResolution(at url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        return (width, height)
    }
}
