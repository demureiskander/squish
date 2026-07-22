import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        }
    }
}

@MainActor
final class Localizer: ObservableObject {
    static let shared = Localizer()

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.russian.rawValue
        language = AppLanguage(rawValue: saved) ?? .russian
    }

    /// Перевод для использования во вью (реактивно обновляется при смене языка).
    func tr(_ ru: String) -> String {
        Self.translate(ru)
    }

    /// Статический перевод для кода вне вью (уведомления и т.п.).
    nonisolated static func translate(_ ru: String) -> String {
        let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "ru"
        guard lang == "en" else { return ru }
        return enTable[ru] ?? ru
    }

    // Русский оригинал → английский перевод.
    nonisolated static let enTable: [String: String] = [
        // DropZone
        "Перетащите изображения сюда": "Drop images here",
        "или нажмите для выбора": "or click to browse",
        "Поддерживаемые форматы": "Supported formats",

        // File list / grid
        "Удалить": "Delete",
        "Удалить выбранные": "Delete selected",
        "Показать в Finder": "Show in Finder",
        "Это изображение уже добавлено": "This image is already added",
        "Уже в очереди": "Already in queue",
        "Очистить все изображения?": "Clear all images?",
        "Все добавленные изображения будут убраны из очереди.": "All added images will be removed from the queue.",
        "Очистить": "Clear",
        "Имя": "Name",
        "Формат": "Format",
        "Оригинал": "Original",
        "Результат": "Result",
        "Экономия": "Saved",
        "Сжатие…": "Compressing…",
        "Сжатие...": "Compressing…",
        "Ожидание": "Pending",
        "Ошибка": "Error",

        // Compression panel
        "Пресеты": "Presets",
        "Качество": "Quality",
        "Насколько сильно сжимать. Ниже качество — меньше файл, но заметнее потери.":
            "How much to compress. Lower quality means a smaller file but more visible loss.",
        "Меньше файл": "Smaller file",
        "Выше качество": "Higher quality",
        "Куда сохранять": "Save to",
        "Исходная — рядом с оригиналом. Спросить — выбор папки при каждом сжатии. Указать — постоянная папка.":
            "Original — next to the source. Ask — pick a folder each time. Custom — a fixed folder.",
        "Исходная": "Original",
        "Спросить": "Ask",
        "Указать": "Custom",
        "Папка не выбрана": "No folder selected",
        "Обзор…": "Browse…",
        "В подпапку": "Subfolder",
        "Добавить суффикс": "Add suffix",
        "Формат на выходе": "Output format",
        "«Оригинал» — сохранить тот же формат. Или конвертировать в JPEG/PNG/HEIC. WebP появится в будущей версии.":
            "“Original” keeps the same format. Or convert to JPEG/PNG/HEIC. WebP is coming in a future version.",
        "Конвертировать в": "Convert to",
        "Размер": "Size",
        "Максимальные ширина и высота в пикселях. 0 — не менять. Пропорции сохраняются.":
            "Maximum width and height in pixels. 0 keeps it unchanged. Aspect ratio is preserved.",
        "Ширина": "Width",
        "Высота": "Height",
        "Опции": "Options",
        "Дополнительные параметры обработки.": "Additional processing options.",
        "Пропускать уже сжатые": "Skip already compressed",
        "Файлы с суффиксом не трогаются повторно": "Files with the suffix aren’t reprocessed",
        "Сохранять метаданные": "Preserve metadata",
        "EXIF, геолокация, дата съёмки": "EXIF, location, capture date",
        "Действие после": "After compressing",
        "Что скопировать в буфер обмена после сжатия каждого файла. Путь — путь к файлу. Файл — сам файл. MD — Markdown-ссылку.":
            "What to copy to the clipboard after each file. Path — the file path. File — the file itself. MD — a Markdown link.",
        "Ничего": "None",
        "Путь": "Path",
        "Файл": "File",
        "Сжать всё": "Compress All",
        "Остановить": "Stop",
        "Останавливается…": "Stopping…",
        "Обработка уже останавливается, подождите…": "Already stopping, please wait…",
        "Звук по завершении": "Sound on completion",
        "Версия": "Version",
        "Быстрое сжатие, конвертация и ресайз изображений для macOS.":
            "Fast image compression, conversion and resizing for macOS.",

        // Quality levels (short)
        "1 · Макс. сжатие": "1 · Max",
        "2 · Сильное": "2 · Strong",
        "3 · Баланс": "3 · Balanced",
        "4 · Высокое": "4 · High",
        "5 · Минимальное": "5 · Minimal",
        // Quality levels (full)
        "Максимальное сжатие": "Maximum compression",
        "Сильное сжатие": "Strong compression",
        "Баланс": "Balanced",
        "Высокое качество": "High quality",
        "Минимальное сжатие": "Minimal compression",

        // Main window
        "Добавить файлы (⌘O)": "Add files (⌘O)",
        "Статистика": "Stats",
        "Настройки (⌘,)": "Settings (⌘,)",
        "Панель настроек": "Settings panel",
        "Обработано": "Processed",
        "Сэкономлено": "Saved",

        // Settings
        "Управлять": "Manage",
        "Язык": "Language",
        "Уведомления": "Notifications",
        "Запуск при входе": "Launch at login",
        "Иконка в строке меню": "Menu bar icon",
        "Скрыть из Dock": "Hide from Dock",
        "Готово": "Done",

        // Preset management
        "Восстановить стандартные пресеты": "Restore default presets",
        "Новый пресет": "New preset",
        "Название": "Name",
        "Отмена": "Cancel",
        "Создать": "Create",
        "Переименовать": "Rename",
        "Настройки пресета": "Preset settings",
        "Нельзя удалить последний пресет": "Can’t delete the last preset",
        "Редактировать пресет": "Edit preset",
        "Сохранить": "Save",

        // Preview
        "Сжатое": "Compressed",
        "До": "Before",
        "После": "After",
        "Разрешение": "Resolution",

        // Menu / MenuBarExtra
        "Открыть файлы…": "Open Files…",
        "Открыть файлы...": "Open Files…",
        "Удалить выбранное": "Remove Selected",
        "Очистить всё": "Clear All",
        "Настройки…": "Settings…",
        "Выйти": "Quit",

        // Notifications
        "Сжатие завершено": "Compression complete",

        // Save picker
        "Сохранить сюда": "Save here",
        "Выберите папку для сжатых файлов": "Choose a folder for compressed files",

        // Sidebar / Help
        "Поддержать разработку": "Support development",
        "Поддержать": "Support",
        "Как пользоваться": "How to use",
        "Открыть": "Open",
        "Исходный код": "Source code",
        "Исходный код на GitHub": "Source code on GitHub",
        "Назад": "Back",
        "Далее": "Next",
        "Добавление файлов": "Adding files",
        "Перетащите изображения или папки в окно, либо нажмите иконку файла слева. Поддерживаются PNG, JPEG, WebP и HEIC.":
            "Drag images or folders into the window, or click the file icon on the left. PNG, JPEG, WebP and HEIC are supported.",
        "Качество и формат": "Quality & format",
        "В панели справа выберите уровень качества (1–5) и формат на выходе. «Оригинал» сохраняет исходный формат; можно конвертировать в JPEG, PNG, HEIC или WebP.":
            "In the right panel pick a quality level (1–5) and output format. “Original” keeps the source format; you can convert to JPEG, PNG, HEIC or WebP.",
        "Изменение размера": "Resizing",
        "Задайте ширину и/или высоту в пикселях, чтобы уменьшить большие фото. 0 — не менять размер. Пропорции сохраняются автоматически.":
            "Set width and/or height in pixels to shrink large photos. 0 keeps the original size. Aspect ratio is preserved automatically.",
        "Пресет — сохранённый набор настроек. Есть встроенные, можно создавать свои кнопкой «+», переименовывать и удалять в Настройках → Пресеты.":
            "A preset is a saved set of settings. There are built-in ones; create your own with the “+” button, rename and delete them in Settings → Presets.",
        "Превью до/после": "Before/after preview",
        "Дважды кликните по обработанному файлу, чтобы открыть сравнение до и после со слайдером и метриками экономии.":
            "Double-click a processed file to open the before/after comparison with a slider and savings metrics.",
        "Выделение нескольких": "Selecting multiple",
        "Клик — выбрать один. ⌘-клик — добавить/убрать. ⇧-клик — выделить диапазон. Затем Delete удаляет выбранные. Иконка корзины очищает всё.":
            "Click to select one. ⌘-click to add/remove. ⇧-click to select a range. Then Delete removes the selected. The trash icon clears everything.",
        "Куда сохраняются": "Where files are saved",
        "Выберите: рядом с оригиналом, спросить папку каждый раз или указать постоянную. Можно класть в подпапку и добавлять суффикс к имени.":
            "Choose: next to the original, ask each time, or a fixed folder. You can save into a subfolder and add a suffix to the name.",

        // Metadata panel
        "Метаданные": "Metadata",
        "Закрыть": "Close",
        "Имя файла": "File name",
        "Размер файла": "File size",
        "Плотность": "Density",
        "Цветовая модель": "Color model",
        "Глубина цвета": "Bit depth",
        "Прозрачность": "Alpha",
        "Да": "Yes",
        "Нет": "No",
        "Камера": "Camera",
        "Объектив": "Lens",
        "Дата съёмки": "Date taken",
        "Выдержка": "Shutter",
        "Диафрагма": "Aperture",
        "Фокусное расстояние": "Focal length",
        "Геолокация": "Location",
        "Мегапиксели": "Megapixels",
        "Соотношение": "Aspect ratio",
        "Ориентация": "Orientation",
        "Цветовой профиль": "Color profile",
        "Программа": "Software",
        "Описание": "Description",
        "Автор": "Author",
        "Авторские права": "Copyright",
        "Экспокоррекция": "Exposure bias",
        "Вспышка": "Flash",
        "Режим съёмки": "Exposure program",
        "Ключевые слова": "Keywords",
        "Город": "City",
        "Обычная": "Normal",
        "Ручной": "Manual",
        "Авто": "Auto",
        "Приоритет диафрагмы": "Aperture priority",
        "Приоритет выдержки": "Shutter priority",
        "Редактировать": "Edit",
        "Метаданные записываются в файл без перекодирования изображения.":
            "Metadata is written to the file without re-encoding the image.",
        "Не удалось сохранить метаданные": "Couldn’t save metadata",
        "Не удалось сохранить изменения": "Couldn’t save changes",
        "Проверьте, что файл с таким именем ещё не существует.":
            "Make sure a file with this name doesn’t already exist.",
        "Производитель": "Manufacturer",
        "Модель": "Model",
        "Формат WebP: метаданные доступны только для чтения.":
            "WebP format: metadata is read-only.",
        "ИИ-происхождение": "AI provenance",
        "Помечено как ИИ (IPTC)": "Marked as AI (IPTC)",
        "Метка ПО": "Software tag",
        "Не обнаружено": "Not detected",

        // Misc
        "фото": "photo"
    ]
}
