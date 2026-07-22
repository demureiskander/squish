import Foundation
import ImageIO

private extension Data {
    /// Есть ли в данных ASCII-подстрока (для поиска маркеров в файле).
    func containsASCII(_ string: String) -> Bool {
        guard let needle = string.data(using: .ascii) else { return false }
        return range(of: needle) != nil
    }
}

struct MetaField: Identifiable {
    let id = UUID()
    let label: String   // русский ключ (переводится во вью)
    let value: String
}

/// Читает метаданные изображения через ImageIO.
enum MetadataReader {
    static func read(url: URL, fileSize: Int64) -> [MetaField] {
        var fields: [MetaField] = []

        fields.append(MetaField(label: "Имя файла", value: url.lastPathComponent))
        fields.append(MetaField(label: "Размер файла",
                                value: ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))
        fields.append(MetaField(label: "ИИ-происхождение", value: aiProvenance(url: url)))

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return fields
        }

        if let type = CGImageSourceGetType(source) as String?,
           let ext = url.pathExtension.isEmpty ? nil : url.pathExtension.uppercased() {
            _ = type
            fields.append(MetaField(label: "Формат", value: ext))
        }

        if let w = props[kCGImagePropertyPixelWidth] as? Int,
           let h = props[kCGImagePropertyPixelHeight] as? Int {
            fields.append(MetaField(label: "Разрешение", value: "\(w) × \(h) px"))
        }

        if let dpi = props[kCGImagePropertyDPIWidth] as? Double, dpi > 0 {
            fields.append(MetaField(label: "Плотность", value: "\(Int(dpi)) DPI"))
        }

        if let model = props[kCGImagePropertyColorModel] as? String {
            fields.append(MetaField(label: "Цветовая модель", value: model))
        }

        if let depth = props[kCGImagePropertyDepth] as? Int {
            fields.append(MetaField(label: "Глубина цвета", value: "\(depth) bit"))
        }

        if let alpha = props[kCGImagePropertyHasAlpha] as? Bool {
            fields.append(MetaField(label: "Прозрачность", value: alpha ? "Да" : "Нет"))
        }

        if let w = props[kCGImagePropertyPixelWidth] as? Double,
           let h = props[kCGImagePropertyPixelHeight] as? Double, w > 0, h > 0 {
            let mp = (w * h) / 1_000_000
            fields.append(MetaField(label: "Мегапиксели", value: String(format: "%.1f Мп", mp)))
            fields.append(MetaField(label: "Соотношение", value: aspectRatio(w, h)))
        }

        if let orientation = props[kCGImagePropertyOrientation] as? Int {
            fields.append(MetaField(label: "Ориентация", value: orientationName(orientation)))
        }

        if let profile = props[kCGImagePropertyProfileName] as? String {
            fields.append(MetaField(label: "Цветовой профиль", value: profile))
        }

        // TIFF — камера и авторство
        if let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            let make = tiff[kCGImagePropertyTIFFMake] as? String ?? ""
            let model = tiff[kCGImagePropertyTIFFModel] as? String ?? ""
            let camera = [make, model].filter { !$0.isEmpty }.joined(separator: " ")
            if !camera.isEmpty {
                fields.append(MetaField(label: "Камера", value: camera))
            }
            if let software = tiff[kCGImagePropertyTIFFSoftware] as? String, !software.isEmpty {
                fields.append(MetaField(label: "Программа", value: software))
            }
            if let desc = tiff[kCGImagePropertyTIFFImageDescription] as? String, !desc.isEmpty {
                fields.append(MetaField(label: "Описание", value: desc))
            }
            if let artist = tiff[kCGImagePropertyTIFFArtist] as? String, !artist.isEmpty {
                fields.append(MetaField(label: "Автор", value: artist))
            }
            if let copyright = tiff[kCGImagePropertyTIFFCopyright] as? String, !copyright.isEmpty {
                fields.append(MetaField(label: "Авторские права", value: copyright))
            }
        }

        // EXIF — параметры съёмки
        if let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            if let lens = exif[kCGImagePropertyExifLensModel] as? String, !lens.isEmpty {
                fields.append(MetaField(label: "Объектив", value: lens))
            }
            if let date = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                fields.append(MetaField(label: "Дата съёмки", value: date))
            }
            if let exposure = exif[kCGImagePropertyExifExposureTime] as? Double, exposure > 0 {
                let value = exposure < 1 ? "1/\(Int((1 / exposure).rounded())) с" : "\(exposure) с"
                fields.append(MetaField(label: "Выдержка", value: value))
            }
            if let iso = (exif[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first {
                fields.append(MetaField(label: "ISO", value: "\(iso)"))
            }
            if let fnum = exif[kCGImagePropertyExifFNumber] as? Double {
                fields.append(MetaField(label: "Диафрагма", value: String(format: "ƒ/%.1f", fnum)))
            }
            if let focal = exif[kCGImagePropertyExifFocalLength] as? Double {
                fields.append(MetaField(label: "Фокусное расстояние", value: "\(Int(focal)) мм"))
            }
            if let bias = exif[kCGImagePropertyExifExposureBiasValue] as? Double, bias != 0 {
                fields.append(MetaField(label: "Экспокоррекция", value: String(format: "%+.1f EV", bias)))
            }
            if let flash = exif[kCGImagePropertyExifFlash] as? Int {
                fields.append(MetaField(label: "Вспышка", value: (flash & 1) == 1 ? "Да" : "Нет"))
            }
            if let program = exif[kCGImagePropertyExifExposureProgram] as? Int {
                fields.append(MetaField(label: "Режим съёмки", value: exposureProgram(program)))
            }
        }

        // IPTC
        if let iptc = props[kCGImagePropertyIPTCDictionary] as? [CFString: Any] {
            if let caption = iptc[kCGImagePropertyIPTCCaptionAbstract] as? String, !caption.isEmpty,
               !fields.contains(where: { $0.label == "Описание" }) {
                fields.append(MetaField(label: "Описание", value: caption))
            }
            if let keywords = iptc[kCGImagePropertyIPTCKeywords] as? [String], !keywords.isEmpty {
                fields.append(MetaField(label: "Ключевые слова", value: keywords.joined(separator: ", ")))
            }
            if let city = iptc[kCGImagePropertyIPTCCity] as? String, !city.isEmpty {
                fields.append(MetaField(label: "Город", value: city))
            }
        }

        // GPS
        if let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any],
           let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
           let lon = gps[kCGImagePropertyGPSLongitude] as? Double {
            let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String ?? "N"
            let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String ?? "E"
            fields.append(MetaField(label: "Геолокация",
                                    value: String(format: "%.4f°%@ %.4f°%@", lat, latRef, lon, lonRef)))
        }

        return fields
    }

    /// Ищет признаки того, что изображение сгенерировано ИИ.
    private static func aiProvenance(url: URL) -> String {
        var signals: [String] = []

        // Скан файла на C2PA / IPTC-метку.
        if let data = try? Data(contentsOf: url, options: .mappedIfSafe) {
            if data.containsASCII("c2pa.") || data.containsASCII("jumbf") {
                signals.append("Content Credentials (C2PA)")
            }
            if data.containsASCII("trainedAlgorithmicMedia") || data.containsASCII("compositeWithTrainedAlgorithmicMedia") {
                signals.append(Localizer.translate("Помечено как ИИ (IPTC)"))
            }
        }

        // Метки ПО в EXIF/TIFF.
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
            let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
            let haystack = [
                tiff?[kCGImagePropertyTIFFSoftware] as? String,
                tiff?[kCGImagePropertyTIFFImageDescription] as? String,
                exif?[kCGImagePropertyExifUserComment] as? String
            ].compactMap { $0 }.joined(separator: " ").lowercased()

            let tools: [(needle: String, name: String)] = [
                ("dall", "DALL·E"), ("openai", "OpenAI"), ("midjourney", "Midjourney"),
                ("stable diffusion", "Stable Diffusion"), ("firefly", "Adobe Firefly"),
                ("imagen", "Imagen"), ("gemini", "Gemini"), ("grok", "Grok")
            ]
            for tool in tools where haystack.contains(tool.needle) {
                signals.append("\(Localizer.translate("Метка ПО")): \(tool.name)")
                break
            }
        }

        if signals.isEmpty {
            return Localizer.translate("Не обнаружено")
        }
        return signals.joined(separator: "; ")
    }

    private static func aspectRatio(_ w: Double, _ h: Double) -> String {
        func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
        let wi = Int(w), hi = Int(h)
        let g = max(1, gcd(wi, hi))
        let rw = wi / g, rh = hi / g
        if rw <= 40 && rh <= 40 { return "\(rw):\(rh)" }
        return String(format: "%.2f:1", w / h)
    }

    private static func orientationName(_ o: Int) -> String {
        switch o {
        case 1: return "Обычная"
        case 3: return "180°"
        case 6: return "90° CW"
        case 8: return "90° CCW"
        default: return "\(o)"
        }
    }

    private static func exposureProgram(_ p: Int) -> String {
        switch p {
        case 1: return "Ручной"
        case 2: return "Авто"
        case 3: return "Приоритет диафрагмы"
        case 4: return "Приоритет выдержки"
        default: return "\(p)"
        }
    }
}
