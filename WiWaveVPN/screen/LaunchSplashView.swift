import SwiftUI

/// 冷启动页：最短展示时间；视觉与主应用深色仪器风一致。
struct LaunchSplashView: View {
    let onComplete: () -> Void

    @EnvironmentObject private var appLanguage: AppLanguageStore

    private let minimumDisplaySeconds: Double = 2.0

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(WiTheme.glowTeal.opacity(0.35))
                        .frame(width: 140, height: 140)
                        .blur(radius: 28)

                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(WiTheme.borderSubtle.opacity(0.95), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.45), radius: 22, y: 10)
                }

                VStack(spacing: 8) {
                    Text(AppDisplayName.fromBundle)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(WiTheme.textPrimary)

                    Text(L10n.Launch.tagline(appLanguage))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WiTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer()

                ProgressView()
                    .tint(WiTheme.accent)
                    .scaleEffect(1.05)
                    .padding(.bottom, 36)
            }
        }
        .task {
            await prepareLaunchResources()
            await MainActor.run { onComplete() }
        }
    }

    private func prepareLaunchResources() async {
        let began = Date()
        let pathKind = await LaunchNetworkProbe.classifyCurrentPath()
        AppLogger.log(.connection, tag: "Launch", "path=\(pathKind.rawValue)")
        let elapsed = Date().timeIntervalSince(began)
        let remain = max(0, minimumDisplaySeconds - elapsed)
        if remain > 0 {
            try? await Task.sleep(nanoseconds: UInt64(remain * 1_000_000_000))
        }
    }
}
