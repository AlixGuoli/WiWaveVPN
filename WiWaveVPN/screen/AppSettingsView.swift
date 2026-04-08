import SwiftUI

/// 设置：语言、法律链接；「使用说明」进入独立帮助页。
struct AppSettingsView: View {
    @Binding var path: [WiRoute]
    @EnvironmentObject private var appLanguage: AppLanguageStore

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            VStack(spacing: 0) {
                TabTopChrome(title: L10n.Chrome.settings(appLanguage), flowStyle: true)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        settingsHero

                        settingsGroupHeader(L10n.Settings.languageSection(appLanguage))
                        settingsGroupedSurface {
                            settingsIconRow(icon: "globe") {
                                Picker(selection: languageBinding) {
                                    ForEach(AppLanguageStore.Preference.settingsMenuOrder, id: \.self) { opt in
                                        Text(languagePickerLabel(opt)).tag(opt)
                                    }
                                } label: {
                                    HStack {
                                        Text(languagePickerLabel(appLanguage.preference))
                                            .font(.body)
                                            .foregroundStyle(WiTheme.textPrimary)
                                        Spacer(minLength: 0)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(WiTheme.accent)
                                .accessibilityLabel(L10n.Settings.languageSection(appLanguage))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        settingsGroupHeader(L10n.Settings.legal(appLanguage))
                        settingsGroupedSurface {
                            settingsIconRow(icon: "hand.raised.fill") {
                                linkRow(title: L10n.Settings.privacyLink(appLanguage), url: AppLegalURLs.privacyPolicy)
                            }
                            rowDivider
                            settingsIconRow(icon: "doc.text.fill") {
                                linkRow(title: L10n.Settings.termsLink(appLanguage), url: AppLegalURLs.termsOfUse)
                            }
                        }

                        settingsGroupHeader(L10n.Chrome.help(appLanguage))
                            .padding(.top, 4)

                        settingsGroupedSurface {
                            Button {
                                path.append(.helpManual)
                            } label: {
                                HStack(alignment: .center, spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(WiTheme.bgElevated.opacity(0.75))
                                            .overlay(Circle().stroke(WiTheme.borderSubtle.opacity(0.9), lineWidth: 1))
                                        Image(systemName: "text.book.closed.fill")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(WiTheme.accent)
                                    }
                                    .frame(width: 38, height: 38)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L10n.Help.docTitle(appLanguage))
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(WiTheme.textPrimary)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(L10n.Settings.helpEntryBlurb(appLanguage))
                                            .font(.caption)
                                            .foregroundStyle(WiTheme.textTertiary)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: 8)

                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(WiTheme.textTertiary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        Text(L10n.Settings.footerPlaceholder(appLanguage))
                            .font(.caption)
                            .foregroundStyle(WiTheme.textTertiary.opacity(0.95))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(3)
                            .padding(.horizontal, 6)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 36)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .tint(WiTheme.accent)
    }

    private var settingsHero: some View {
        HStack(alignment: .center, spacing: 18) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WiTheme.borderSubtle.opacity(0.95), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 14, y: 7)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(AppDisplayName.fromBundle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(WiTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(L10n.Settings.version(appLanguage)) \(version)  ·  \(L10n.Settings.build(appLanguage)) \(build)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WiTheme.textTertiary)
                    .monospacedDigit()
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(WiTheme.bgTile)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [WiTheme.borderSubtle, WiTheme.accent.opacity(0.28), WiTheme.borderSubtle],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: WiTheme.glowTeal.opacity(0.45), radius: 16, y: 7)
    }

    private func settingsGroupHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(WiTheme.textTertiary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
    }

    private var languageBinding: Binding<AppLanguageStore.Preference> {
        Binding(
            get: { appLanguage.preference },
            set: { appLanguage.applyPreference($0) }
        )
    }

    /// 语言名称用各族原文显示，避免依赖大量 `Localizable` 键。
    private func languagePickerLabel(_ p: AppLanguageStore.Preference) -> String {
        switch p {
        case .system: return L10n.Settings.languageSystem(appLanguage)
        case .english: return "English"
        case .russian: return "Русский"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .spanish: return "Español"
        case .polish: return "Polski"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        }
    }

    private func settingsIconRow<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(WiTheme.bgElevated.opacity(0.75))
                    .overlay(Circle().stroke(WiTheme.borderSubtle.opacity(0.9), lineWidth: 1))
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WiTheme.accent)
            }
            .frame(width: 38, height: 38)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(WiTheme.borderSubtle.opacity(0.75))
            .frame(height: 1)
            .padding(.leading, 66)
    }

    private func settingsGroupedSurface<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(WiTheme.bgTile.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(WiTheme.borderSubtle.opacity(0.88), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.18), radius: 10, y: 4)
    }

    private func linkRow(title: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(WiTheme.accent)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(WiTheme.accent.opacity(0.85))
            }
        }
    }
}
