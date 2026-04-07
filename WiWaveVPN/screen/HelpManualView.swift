import SwiftUI

/// 独立帮助页：从设置经根导航 `path` 推入，顶栏与 `WiNodeListView` 一致。
struct HelpManualScreen: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 14) {
                    Text(L10n.Chrome.help(appLanguage))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(WiTheme.textPrimary)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(WiTheme.accent)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(WiTheme.bgTile.opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(WiTheme.accent.opacity(0.45), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Help.closeScreenA11y(appLanguage))
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    HelpManualScrollContent()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 36)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

/// 帮助正文（由 `HelpManualScreen` 承载）。
struct HelpManualScrollContent: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpHero

            helpChapter(
                icon: "lock.shield.fill",
                title: L10n.Help.whyVpnTitle(appLanguage),
                body: L10n.Help.whyVpnBody(appLanguage),
                density: .comfortable
            )

            helpChapter(
                icon: "wrench.and.screwdriver.fill",
                title: L10n.Help.troubleTitle(appLanguage),
                body: L10n.Help.troubleBody(appLanguage),
                density: .comfortable
            )

            helpChapter(
                icon: "map.fill",
                title: L10n.Help.routesTitle(appLanguage),
                body: L10n.Help.routesBody(appLanguage),
                density: .comfortable
            )

            helpChapter(
                icon: "envelope.open.fill",
                title: L10n.Help.contactTitle(appLanguage),
                body: L10n.Help.contactBody(appLanguage),
                density: .compact,
                emphasized: true
            )
        }
        .frame(maxWidth: 660)
        .frame(maxWidth: .infinity)
    }

    private var helpHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "text.book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(WiTheme.accent)
                    .shadow(color: WiTheme.accent.opacity(0.35), radius: 8)

                Text(L10n.Help.docTitle(appLanguage))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(WiTheme.textPrimary)
            }

            Text(AppDisplayName.fromBundle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WiTheme.textTertiary)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [WiTheme.accent.opacity(0.15), WiTheme.accent.opacity(0.85), WiTheme.accent.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(WiTheme.bgTile)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [WiTheme.borderSubtle, WiTheme.accent.opacity(0.35), WiTheme.borderSubtle],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: WiTheme.glowTeal.opacity(0.5), radius: 18, y: 8)
    }

    private enum SectionDensity {
        case comfortable
        case compact
    }

    private func helpChapter(
        icon: String,
        title: String,
        body: String,
        density: SectionDensity,
        emphasized: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(WiTheme.bgElevated.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(WiTheme.borderSubtle, lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(WiTheme.accent)
            }
            .frame(width: 46, height: 46)
            .shadow(color: Color.black.opacity(0.2), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(WiTheme.textPrimary)

                Text(body)
                    .font(density == .comfortable ? .body : .callout)
                    .foregroundStyle(density == .comfortable ? WiTheme.textSecondary : WiTheme.textTertiary)
                    .lineSpacing(density == .comfortable ? 5 : 3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(WiTheme.bgElevated.opacity(emphasized ? 0.55 : 0.42))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        emphasized ? WiTheme.accent.opacity(0.22) : WiTheme.borderSubtle.opacity(0.65),
                                        lineWidth: 1
                                    )
                            )
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WiTheme.bgTile.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WiTheme.borderSubtle.opacity(0.55), lineWidth: 1)
                )
        )
    }
}
