import Foundation
import ImageIO

/// Одно редактируемое поле метаданных.
struct MetaEditField: Identifiable {
    let id = UUID()
    let labelKey: String        // русский ключ (переводится во вью)
    let dictionary: CFString    // напр. kCGImagePropertyTIFFDictionary
    let property: CFString      // напр. kCGImagePropertyTIFFImageDescription
    let isArray: Bool
    let multiline: Bool
    var value: String
}

enum MetadataWriter {
    /// Форматы, в которые ImageIO умеет записывать метаданные без перекодирования.
    static func isEditable(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "heic", "heif", "tiff", "tif"].contains(ext)
    }

    /// Описания всех редактируемых текстовых полей.
    private static var templates: [(labelKey: String, dict: CFString, prop: CFString, isArray: Bool, multiline: Bool)] {
        [
        ("Описание", kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFImageDescription, false, true),
        ("Автор", kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFArtist, false, false),
        ("Авторские права", kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFCopyright, false, false),
        ("Программа", kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFSoftware, false, false),
        ("Производитель", kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFMake, false, false),
        ("Модель", kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFModel, false, false),
        ("Объектив", kCGImagePropertyExifDictionary, kCGImagePropertyExifLensModel, false, false),
        ("Дата съёмки", kCGImagePropertyExifDictionary, kCGImagePropertyExifDateTimeOriginal, false, false),
        ("Ключевые слова", kCGImagePropertyIPTCDictionary, kCGImagePropertyIPTCKeywords, true, false),
        ("Город", kCGImagePropertyIPTCDictionary, kCGImagePropertyIPTCCity, false, false)
        ]
    }

    /// Загружает текущие значения редактируемых полей.
    static func loadFields(url: URL) -> [MetaEditField] {
        let props = (CGImageSourceCreateWithURL(url as CFURL, nil)
            .flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) }) as? [CFString: Any] ?? [:]

        return templates.map { template in
            var value = ""
            if let dict = props[template.dict] as? [CFString: Any], let raw = dict[template.prop] {
                if template.isArray, let arr = raw as? [String] {
                    value = arr.joined(separator: ", ")
                } else if let str = raw as? String {
                    value = str
                } else {
                    value = "\(raw)"
                }
            }
            return MetaEditField(
                labelKey: template.labelKey,
                dictionary: template.dict,
                property: template.prop,
                isArray: template.isArray,
                multiline: template.multiline,
                value: value
            )
        }
    }

    /// Записывает изменённые поля обратно в файл без перекодирования изображения.
    @discardableResult
    static func write(url: URL, fields: [MetaEditField]) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let uti = CGImageSourceGetType(source) else {
            return false
        }

        let metadata: CGMutableImageMetadata
        if let existing = CGImageSourceCopyMetadataAtIndex(source, 0, nil),
           let mutable = CGImageMetadataCreateMutableCopy(existing) {
            metadata = mutable
        } else {
            metadata = CGImageMetadataCreateMutable()
        }

        for field in fields {
            let value: CFTypeRef
            if field.isArray {
                let items = field.value
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                value = items as CFArray
            } else {
                value = field.value as CFString
            }
            CGImageMetadataSetValueMatchingImageProperty(metadata, field.dictionary, field.property, value)
        }

        let tmpURL = url.deletingLastPathComponent()
            .appendingPathComponent(".squish-\(UUID().uuidString).\(url.pathExtension)")

        guard let dest = CGImageDestinationCreateWithURL(tmpURL as CFURL, uti, 1, nil) else {
            return false
        }

        let options: [CFString: Any] = [kCGImageDestinationMetadata: metadata]
        var error: Unmanaged<CFError>?
        let ok = CGImageDestinationCopyImageSource(dest, source, options as CFDictionary, &error)

        guard ok else {
            try? FileManager.default.removeItem(at: tmpURL)
            return false
        }

        do {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmpURL)
            return true
        } catch {
            try? FileManager.default.removeItem(at: tmpURL)
            return false
        }
    }
}
