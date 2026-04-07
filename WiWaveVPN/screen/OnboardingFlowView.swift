import AppTrackingTransparency
import Darwin
import SwiftUI

/// 首装引导：不可跳过；须同意隐私后再请求 ATT。
struct OnboardingFlowView: View {
    var onFlowFinished: () -> Void

    @EnvironmentObject private var appLanguage: AppLanguageStore

    @State private var page = 0
    @State private var agreedPrivacy = false
    @State private var isRequestingATT = false

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            VStack(spacing: 0) {
                pageDotsHeader

                TabView(selection: $page) {
                    welcomePage.tag(0)
                    expectPage.tag(1)
                    valuePage.tag(2)
                    privacyPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .tint(WiTheme.accent)
    }

    /// 与系统页码点区分：顶部自建细条进度，避免与深色背景对比不足。
    private var pageDotsHeader: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == page ? WiTheme.accent : WiTheme.textTertiary.opacity(0.45))
                    .frame(width: i == page ? 22 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.22), value: page)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var welcomePage: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 12)

            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(WiTheme.borderSubtle, lineWidth: 1)
                )
                .shadow(color: WiTheme.accent.opacity(0.15), radius: 20, y: 8)

            onboardCard {
                Text(L10n.Onboard.welcomeTitle(appLanguage))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(WiTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(L10n.Onboard.welcomeBody(appLanguage))
                    .font(.body)
                    .foregroundStyle(WiTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer(minLength: 12)

            onboardPrimaryButton(L10n.Onboard.next(appLanguage)) { page = 1 }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }

    private var expectPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 8)

            onboardCard {
                Text(L10n.Onboard.expectTitle(appLanguage))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(WiTheme.textPrimary)

                Text(L10n.Onboard.expectBody(appLanguage))
                    .font(.body)
                    .foregroundStyle(WiTheme.textSecondary)
                    .lineSpacing(4)

                Label(L10n.Onboard.expectSettingsHint(appLanguage), systemImage: "gearshape")
                    .font(.subheadline)
                    .foregroundStyle(WiTheme.accent.opacity(0.92))
            }

            Spacer(minLength: 8)

            onboardPrimaryButton(L10n.Onboard.next(appLanguage)) { page = 2 }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }

    private var valuePage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 8)

            onboardCard {
                Text(L10n.Onboard.valueTitle(appLanguage))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(WiTheme.textPrimary)

                VStack(alignment: .leading, spacing: 14) {
                    onboardBullet(L10n.Onboard.valueBullet1(appLanguage))
                    onboardBullet(L10n.Onboard.valueBullet2(appLanguage))
                    onboardBullet(L10n.Onboard.valueBullet3(appLanguage))
                }
            }

            Spacer(minLength: 8)

            onboardPrimaryButton(L10n.Onboard.next(appLanguage)) { page = 3 }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }

    private var privacyPage: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Onboard.privacyHeading(appLanguage))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(WiTheme.textPrimary)

                    Text(L10n.Onboard.privacyIntro(appLanguage))
                        .font(.subheadline)
                        .foregroundStyle(WiTheme.textSecondary)
                        .lineSpacing(4)

                    privacyDetailBlock(
                        icon: "iphone",
                        title: L10n.Onboard.privacyDeviceTitle(appLanguage),
                        body: L10n.Onboard.privacyDeviceBody(appLanguage)
                    )
                    privacyDetailBlock(
                        icon: "chart.line.uptrend.xyaxis",
                        title: L10n.Onboard.privacySessionTitle(appLanguage),
                        body: L10n.Onboard.privacySessionBody(appLanguage)
                    )
                    privacyDetailBlock(
                        icon: "arrow.up.arrow.down.circle",
                        title: L10n.Onboard.privacyUsageTitle(appLanguage),
                        body: L10n.Onboard.privacyUsageBody(appLanguage)
                    )
                    privacyDetailBlock(
                        icon: "square.stack.3d.up.fill",
                        title: L10n.Onboard.privacyThirdPartyTitle(appLanguage),
                        body: L10n.Onboard.privacyThirdPartyBody(appLanguage)
                    )

                    Text(L10n.Onboard.privacyPolicyFooter(appLanguage))
                        .font(.footnote)
                        .foregroundStyle(WiTheme.textTertiary)
                        .lineSpacing(3)

                    Link(destination: AppLegalURLs.privacyPolicy) {
                        HStack {
                            Text(L10n.Settings.privacyLink(appLanguage))
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "arrow.up.right.circle.fill")
                                .imageScale(.medium)
                        }
                        .foregroundStyle(WiTheme.accent)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(WiTheme.bgElevated.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(WiTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                    }

                    Toggle(isOn: $agreedPrivacy) {
                        Text(L10n.Onboard.privacyAgreeToggle(appLanguage))
                            .font(.footnote)
                            .foregroundStyle(WiTheme.textPrimary)
                            .lineSpacing(3)
                    }
                    .tint(WiTheme.accent)
                    .padding(.top, 4)

                    Text(L10n.Onboard.privacyPlaceholderNote(appLanguage))
                        .font(.caption2)
                        .foregroundStyle(WiTheme.textTertiary)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 20)
            }

            VStack(spacing: 12) {
                Button {
                    proceedAfterPrivacyAccepted()
                } label: {
                    Group {
                        if isRequestingATT {
                            ProgressView()
                                .tint(WiTheme.bgDeep)
                        } else {
                            Text(L10n.Onboard.privacyAgreeContinue(appLanguage))
                                .font(.body.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(WiTheme.bgDeep)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(WiTheme.accent)
                    )
                }
                .disabled(!agreedPrivacy || isRequestingATT)
                .opacity((!agreedPrivacy || isRequestingATT) ? 0.5 : 1)

                Button(role: .destructive) {
                    Self.terminateProcess()
                } label: {
                    Text(L10n.Onboard.privacyDeclineQuit(appLanguage))
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(WiTheme.error)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(WiTheme.borderSubtle, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(WiTheme.bgTile.opacity(0.6))
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [WiTheme.bgDeep.opacity(0), WiTheme.bgDeep.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private func privacyDetailBlock(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(WiTheme.accent)
                .frame(width: 30, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WiTheme.textPrimary)
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(WiTheme.textSecondary)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(WiTheme.bgTile.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(WiTheme.borderSubtle.opacity(0.85), lineWidth: 1)
                )
        )
    }

    private func onboardCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(WiTheme.bgTile.opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [WiTheme.borderSubtle, WiTheme.accent.opacity(0.22), WiTheme.borderSubtle],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 12, y: 5)
    }

    private func onboardBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(WiTheme.success)
            Text(text)
                .font(.body)
                .foregroundStyle(WiTheme.textPrimary)
                .lineSpacing(3)
        }
    }

    private func onboardPrimaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(WiTheme.bgDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(WiTheme.accent)
                        .shadow(color: WiTheme.accent.opacity(0.28), radius: 14, y: 5)
                )
        }
        .buttonStyle(.plain)
    }

    private func proceedAfterPrivacyAccepted() {
        guard agreedPrivacy, !isRequestingATT else { return }
        isRequestingATT = true
        ATTrackingManager.requestTrackingAuthorization { _ in
            DispatchQueue.main.async {
                isRequestingATT = false
                onFlowFinished()
            }
        }
    }

    private static func terminateProcess() {
        DispatchQueue.main.async {
            exit(0)
        }
    }
}
