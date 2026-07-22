import Foundation
import CoreGraphics

// libwebp может импортироваться под разными именами в зависимости от пакета.
// Импортируем то, что доступно.
#if canImport(libwebp)
import libwebp
#elseif canImport(WebP)
import WebP
#elseif canImport(CWebP)
import CWebP
#elseif canImport(libwebp_Xcode)
import libwebp_Xcode
#endif

/// Кодирование WebP через libwebp.
enum WebPEncoder {

    static var isAvailable: Bool {
        #if canImport(libwebp) || canImport(WebP) || canImport(CWebP) || canImport(libwebp_Xcode)
        return true
        #else
        return false
        #endif
    }

    /// Диагностика: какие webp-модули видит компилятор.
    static var diagnostics: String {
        var names: [String] = []
        #if canImport(libwebp)
        names.append("libwebp")
        #endif
        #if canImport(WebP)
        names.append("WebP")
        #endif
        #if canImport(CWebP)
        names.append("CWebP")
        #endif
        #if canImport(libwebp_Xcode)
        names.append("libwebp_Xcode")
        #endif
        return names.isEmpty ? "НЕТ (модуль не найден)" : names.joined(separator: ", ")
    }

    /// Кодирует CGImage в WebP. quality 0.0…1.0. Возвращает nil и печатает причину.
    static func encode(_ cgImage: CGImage, quality: CGFloat) -> Data? {
        #if canImport(libwebp) || canImport(WebP) || canImport(CWebP) || canImport(libwebp_Xcode)
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else {
            NSLog("[WebP] Некорректный размер: \(width)x\(height)")
            return nil
        }

        let bytesPerRow = width * 4
        var rgba = [UInt8](repeating: 0, count: height * bytesPerRow)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let ok: Bool = rgba.withUnsafeMutableBytes { buffer -> Bool in
            guard let base = buffer.baseAddress,
                  let ctx = CGContext(
                    data: base,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                return false
            }
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard ok else {
            NSLog("[WebP] Не удалось создать CGContext / нарисовать изображение")
            return nil
        }

        let qualityFactor = Float(max(0, min(1, quality)) * 100)

        var output: UnsafeMutablePointer<UInt8>? = nil
        let size = rgba.withUnsafeBufferPointer { ptr -> Int in
            WebPEncodeRGBA(ptr.baseAddress, Int32(width), Int32(height), Int32(bytesPerRow), qualityFactor, &output)
        }

        guard size > 0, let output else {
            NSLog("[WebP] WebPEncodeRGBA вернул размер 0 (кодирование не удалось)")
            return nil
        }
        defer { WebPFree(output) }
        NSLog("[WebP] Успешно закодировано: \(size) байт")
        return Data(bytes: output, count: size)
        #else
        NSLog("[WebP] Модуль libwebp не подключён (canImport == false)")
        return nil
        #endif
    }
}
