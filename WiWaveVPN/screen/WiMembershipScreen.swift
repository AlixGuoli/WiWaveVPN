import SwiftUI

/// 会员页（静态 UI 预览版）：先对齐视觉，不接内购逻辑。
struct WiMembershipScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appLanguage: AppLanguageStore
    @EnvironmentObject private var purchaseCenter: WiPurchaseCenter
    @State private var selectedPlan: MembershipPlan = .monthly
    @State private var hasAgreedTerms = true

    private let membershipTermsURL = URL(string: "https://tunnelnova.xyz/m.html")!

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            RadialGradient(
                colors: [WiTheme.accent.opacity(0.16), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        headerBlock
                        benefitsCard
                        plansBlock
                        agreementRow
                            .padding(.horizontal, 2)
                        policyText
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                }

                actionButton
                    .padding(.horizontal, 20)

                restoreButton
                    .padding(.top, 9)
                    .padding(.bottom, 16)
            }

            if purchaseCenter.isBusy {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                    Text(L10n.Membership.processing(appLanguage))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            await purchaseCenter.prepare()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image("back")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
    }

    private var headerBlock: some View {
        VStack(spacing: 14) {
            Image("vip")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .shadow(color: WiTheme.accent.opacity(0.2), radius: 14, y: 6)

            Text(purchaseCenter.hasActiveSubscriptionNow
                 ? L10n.Membership.headerActive(appLanguage)
                 : L10n.Membership.headerGetPremium(appLanguage))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(WiTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(headerSubtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WiTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private var headerSubtitle: String {
        if purchaseCenter.hasActiveSubscriptionNow, let expiry = purchaseCenter.activeExpiration {
            return L10n.Membership.headerExpires(appLanguage, formatExpiryToSecond(expiry))
        }
        return L10n.Membership.headerDefaultSubtitle(appLanguage)
    }

    private func formatExpiryToSecond(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = appLanguage.localeForSwiftUI
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private var benefitsCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                benefitCell(
                    icon: "vipSpeed",
                    title: L10n.Membership.benefitSpeedTitle(appLanguage),
                    subtitle: L10n.Membership.benefitSpeedSubtitle(appLanguage)
                )
                dividerVertical
                benefitCell(
                    icon: "vipNode",
                    title: L10n.Membership.benefitNodesTitle(appLanguage),
                    subtitle: L10n.Membership.benefitNodesSubtitle(appLanguage)
                )
            }
            dividerHorizontalSplit
            HStack(alignment: .top, spacing: 0) {
                benefitCell(
                    icon: "vipPriority",
                    title: L10n.Membership.benefitPriorityTitle(appLanguage),
                    subtitle: L10n.Membership.benefitPrioritySubtitle(appLanguage)
                )
                dividerVertical
                benefitCell(
                    icon: "vipAd",
                    title: L10n.Membership.benefitAdFreeTitle(appLanguage),
                    subtitle: L10n.Membership.benefitAdFreeSubtitle(appLanguage)
                )
            }
        }
        .padding(.horizontal, -10)
    }

    private var dividerHorizontal: some View {
        Rectangle()
            .fill(WiTheme.borderSubtle.opacity(0.8))
            .frame(height: 1)
            .padding(.horizontal, 14)
    }

    private var dividerVertical: some View {
        Rectangle()
            .fill(WiTheme.borderSubtle.opacity(0.8))
            .frame(width: 1)
            .padding(.vertical, 18)
    }

    private var dividerHorizontalSplit: some View {
        HStack(spacing: 18) {
            Rectangle()
                .fill(WiTheme.borderSubtle.opacity(0.8))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(WiTheme.borderSubtle.opacity(0.8))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
    }

    private func benefitCell(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WiTheme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Text(subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(WiTheme.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
    }

    private var plansBlock: some View {
        VStack(spacing: 12) {
            ForEach(MembershipPlan.allCases, id: \.self) { plan in
                Button {
                    selectedPlan = plan
                } label: {
                    HStack(spacing: 10) {
                        Text(plan.title(appLanguage))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(WiTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(purchaseCenter.compareDisplayPrice(for: plan.productID, multiplier: plan.compareMultiplier) ?? plan.oldPrice)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(WiTheme.textTertiary)
                            .strikethrough(true, color: WiTheme.textTertiary)
                            .lineLimit(1)

                        Text(purchaseCenter.displayPrice(for: plan.productID) ?? plan.newPrice)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(WiTheme.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(WiTheme.bgTile.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(
                                        selectedPlan == plan ? WiTheme.accent : WiTheme.borderSubtle,
                                        lineWidth: selectedPlan == plan ? 2 : 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionButton: some View {
        Button {
            Task {
                _ = await purchaseCenter.purchase(productID: selectedPlan.productID)
            }
        } label: {
            Text(purchaseCenter.isPurchasing ? L10n.Membership.processing(appLanguage) : L10n.Membership.actionAgreePay(appLanguage))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.78))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(WiTheme.accent)
                )
        }
        .buttonStyle(.plain)
        .opacity(hasAgreedTerms && !purchaseCenter.isBusy ? 1.0 : 0.45)
        .disabled(!hasAgreedTerms || purchaseCenter.isBusy)
    }

    private var agreementRow: some View {
        HStack(alignment: .top, spacing: 6) {
            Button {
                hasAgreedTerms.toggle()
            } label: {
                Image(systemName: hasAgreedTerms ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(hasAgreedTerms ? WiTheme.accent : WiTheme.textTertiary)
            }
            .buttonStyle(.plain)

            Text(agreementAttributedText)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(WiTheme.textSecondary)
                .tint(WiTheme.accent)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private var restoreButton: some View {
        Button {
            Task {
                _ = await purchaseCenter.restorePurchases()
            }
        } label: {
            Text(purchaseCenter.isRestoring ? L10n.Membership.actionRestoring(appLanguage) : L10n.Membership.actionRestore(appLanguage))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WiTheme.textPrimary.opacity(0.88))
        }
        .buttonStyle(.plain)
        .disabled(purchaseCenter.isBusy)
    }

    private var policyText: some View {
        Text(L10n.Membership.policyText(appLanguage))
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(WiTheme.textTertiary)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
            .padding(.top, 2)
    }

    private var agreementAttributedText: AttributedString {
        let t1 = L10n.Membership.agreementAutoTitle(appLanguage)
        let t2 = L10n.Membership.agreementMemberTitle(appLanguage)
        let format = L10n.Membership.agreementFormat(appLanguage)
        let plain = String(format: format, locale: appLanguage.localeForSwiftUI, t1, t2)

        var attr = AttributedString(plain)
        if let r1 = attr.range(of: t1) {
            attr[r1].link = membershipTermsURL
        }
        if let r2 = attr.range(of: t2) {
            attr[r2].link = membershipTermsURL
        }
        return attr
    }
}

private enum MembershipPlan: CaseIterable {
    case weekly
    case monthly
    case annual

    var productID: String {
        switch self {
        case .weekly: return "com.glow.wiwave.vpn.weekly"
        case .monthly: return "com.glow.wiwave.vpn.monthly"
        case .annual: return "com.glow.wiwave.vpn.annual"
        }
    }

    func title(_ appLanguage: AppLanguageStore) -> String {
        switch self {
        case .weekly: return L10n.Membership.planWeekly(appLanguage)
        case .monthly: return L10n.Membership.planMonthly(appLanguage)
        case .annual: return L10n.Membership.planAnnual(appLanguage)
        }
    }

    var oldPrice: String {
        "--"
    }

    var newPrice: String {
        "--"
    }

    /// 仅用于 UI 划线对比价展示倍率（真实成交价来自 StoreKit）。
    var compareMultiplier: Decimal {
        switch self {
        case .weekly: return Decimal(string: "1.50")!
        case .monthly: return Decimal(string: "1.25")!
        case .annual: return Decimal(string: "1.20")!
        }
    }
}
