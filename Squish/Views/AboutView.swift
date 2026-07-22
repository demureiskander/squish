import SwiftUI
import AppKit

struct AboutView: View {
    @EnvironmentObject var loc: Localizer

    private let repoURL = URL(string: "https://github.com/demureiskander/squish")!
    private let donateURL = URL(string: "https://web.tribute.tg/d/GLT")!

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 84, height: 84)

            Text("Squish")
                .font(.system(size: 22, weight: .bold))

            Text("\(loc.tr("Версия")) \(version)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Text(loc.tr("Быстрое сжатие, конвертация и ресайз изображений для macOS."))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 280)

            HStack(spacing: 10) {
                Button {
                    NSWorkspace.shared.open(repoURL)
                } label: {
                    HStack(spacing: 5) {
                        Image("GitHubLogo")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                        Text("GitHub")
                    }
                }

                Button {
                    NSWorkspace.shared.open(donateURL)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                        Text(loc.tr("Поддержать"))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "34D399"))
            }
            .padding(.top, 4)

            Text("GPL v3 · © 2026 demureiskander")
                .font(.system(size: 10))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(28)
        .frame(width: 360)
        .fixedSize()
    }
}
