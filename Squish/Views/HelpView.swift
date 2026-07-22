import SwiftUI

struct HelpTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let text: String
}

struct HelpView: View {
    @EnvironmentObject var loc: Localizer
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private var tips: [HelpTip] {
        [
            HelpTip(icon: "square.and.arrow.down",
                    title: loc.tr("Добавление файлов"),
                    text: loc.tr("Перетащите изображения или папки в окно, либо нажмите иконку файла слева. Поддерживаются PNG, JPEG, WebP и HEIC.")),
            HelpTip(icon: "dial.medium",
                    title: loc.tr("Качество и формат"),
                    text: loc.tr("В панели справа выберите уровень качества (1–5) и формат на выходе. «Оригинал» сохраняет исходный формат; можно конвертировать в JPEG, PNG, HEIC или WebP.")),
            HelpTip(icon: "aspectratio",
                    title: loc.tr("Изменение размера"),
                    text: loc.tr("Задайте ширину и/или высоту в пикселях, чтобы уменьшить большие фото. 0 — не менять размер. Пропорции сохраняются автоматически.")),
            HelpTip(icon: "slider.horizontal.3",
                    title: loc.tr("Пресеты"),
                    text: loc.tr("Пресет — сохранённый набор настроек. Есть встроенные, можно создавать свои кнопкой «+», переименовывать и удалять в Настройках → Пресеты.")),
            HelpTip(icon: "rectangle.split.2x1",
                    title: loc.tr("Превью до/после"),
                    text: loc.tr("Дважды кликните по обработанному файлу, чтобы открыть сравнение до и после со слайдером и метриками экономии.")),
            HelpTip(icon: "checklist",
                    title: loc.tr("Выделение нескольких"),
                    text: loc.tr("Клик — выбрать один. ⌘-клик — добавить/убрать. ⇧-клик — выделить диапазон. Затем Delete удаляет выбранные. Иконка корзины очищает всё.")),
            HelpTip(icon: "folder",
                    title: loc.tr("Куда сохраняются"),
                    text: loc.tr("Выберите: рядом с оригиналом, спросить папку каждый раз или указать постоянную. Можно класть в подпапку и добавлять суффикс к имени."))
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(loc.tr("Как пользоваться"))
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            // Current tip
            let tip = tips[page]
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "34D399").opacity(0.15))
                        .frame(width: 76, height: 76)
                    Image(systemName: tip.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(Color(hex: "34D399"))
                }
                .padding(.top, 8)

                Text(tip.title)
                    .font(.system(size: 17, weight: .semibold))

                Text(tip.text)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 360)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .id(page)
            .transition(.opacity)

            // Page dots
            HStack(spacing: 6) {
                ForEach(tips.indices, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color(hex: "34D399") : Color.secondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.vertical, 12)

            Divider()

            // Nav buttons
            HStack {
                Button {
                    withAnimation { page = max(0, page - 1) }
                } label: {
                    Label(loc.tr("Назад"), systemImage: "chevron.left")
                }
                .disabled(page == 0)

                Spacer()

                Text("\(page + 1) / \(tips.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Spacer()

                if page == tips.count - 1 {
                    Button(loc.tr("Готово")) {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "34D399"))
                } else {
                    Button {
                        withAnimation { page = min(tips.count - 1, page + 1) }
                    } label: {
                        Label(loc.tr("Далее"), systemImage: "chevron.right")
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 440, height: 420)
    }
}
