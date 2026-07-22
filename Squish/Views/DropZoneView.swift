import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var loc: Localizer
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // App icon
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(
                            colors: [Color(hex: "2a9d6e"), Color(hex: "34D399")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color(hex: "34D399").opacity(0.25), radius: 16, y: 4)

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text(loc.tr("Перетащите изображения сюда"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.75))

                    Text(loc.tr("или нажмите для выбора"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.5))
                }

                VStack(spacing: 6) {
                    Text(loc.tr("Поддерживаемые форматы"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary.opacity(0.4))

                    HStack(spacing: 12) {
                        ForEach(["PNG", "JPEG", "WebP", "HEIC"], id: \.self) { format in
                            Text(format)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary.opacity(0.6))
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color(hex: "34D399") : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .padding(16)
        )
        .background(isTargeted ? Color(hex: "34D399").opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.addFilesFromPicker()
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            viewModel.handleDrop(providers: providers)
            return true
        }
    }
}
