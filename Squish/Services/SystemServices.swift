import Foundation
import AppKit
@preconcurrency import UserNotifications
import ServiceManagement

/// Системные уведомления после батча.
enum NotificationManager {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func notifyBatchComplete(count: Int, saved: String) {
        let content = UNMutableNotificationContent()
        content.title = Localizer.translate("Сжатие завершено")
        content.body = "\(Localizer.translate("Обработано")): \(count) · \(Localizer.translate("Сэкономлено")): \(saved)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}

/// Запуск при входе в систему через SMAppService.
enum LoginItemManager {
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("LoginItem error: \(error.localizedDescription)")
        }
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}

/// Видимость иконки в Dock.
enum DockPolicy {
    static func setHidden(_ hidden: Bool) {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(hidden ? .accessory : .regular)
            if !hidden {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
