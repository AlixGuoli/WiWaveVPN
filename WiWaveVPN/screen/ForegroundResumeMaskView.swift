import SwiftUI

/// 回前台时的短暂过渡遮罩，用于承接前台广告展示时机。
struct ForegroundResumeMaskView: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(WiTheme.borderSubtle, lineWidth: 1)
                    )

                ProgressView()
                    .tint(WiTheme.accent)
                    .controlSize(.large)

                Text(L10n.Launch.tagline(appLanguage))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(WiTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
    }
}
