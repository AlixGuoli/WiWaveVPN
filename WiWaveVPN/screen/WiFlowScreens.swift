import SwiftUI
import UIKit

private enum WiFlowLinks {
    static let appID = "6761802049"
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id\(appID)")!
    static let appStoreReviewURL = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!
    static let telegramURL = URL(string: "https://t.me/+lL7WwrUdUxY3YmJl")!
}

enum WiRoute: Hashable {
    case progress
    case verdict(WiVerdict)
    /// 与进度/结果共用同一条 path，避免再套一层 `NavigationStack` + `NavigationLink` 触发 `comparisonTypeMismatch`。
    case nodeList
    /// 设置 → 使用说明：必须走同一条 path，禁止在 Tab 内再嵌 `NavigationStack`（否则返回后切换 Tab 再 push 易崩溃）。
    case helpManual
    /// 设置 → 会员页（当前先静态 UI 预览）。
    case membership
}

struct WiProgressScreen: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: max(48, (geo.size.height - 360) * 0.22))

                        pillHeader(title: L10n.Flow.progressSection(appLanguage), tint: WiTheme.accent)

                        progressCard
                            .padding(.top, 20)
                            .padding(.horizontal, 8)

                        Text(L10n.Flow.progressSteps(appLanguage))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(WiTheme.textTertiary)
                            .tracking(0.2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 22)

                        RoundedRectangle(cornerRadius: 1, style: .continuous)
                            .fill(WiTheme.borderSubtle)
                            .frame(width: 120, height: 2)
                            .padding(.top, 24)

                        Spacer()
                        
                        WiRatingPromoCard()
                            .padding(.horizontal, -24)
                    }
                    .frame(minHeight: geo.size.height)
                    .padding(.horizontal, 24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(edges: .bottom)
    }

    private func pillHeader(title: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(tint.opacity(0.55))
                .frame(width: 3, height: 14)
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(WiTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var progressCard: some View {
        VStack(alignment: .center, spacing: 20) {
            ConnectScopeStrip(phase: .busy)

            Text(L10n.Flow.progressTitle(appLanguage))
                .font(.title2.weight(.bold))
                .foregroundStyle(WiTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(L10n.Flow.progressSubtitle(appLanguage))
                .font(.subheadline)
                .foregroundStyle(WiTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView()
                .tint(WiTheme.accent)
                .scaleEffect(1.1)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(WiTheme.bgTile)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(WiTheme.borderSubtle, lineWidth: 1)
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(WiTheme.accent)
                .frame(width: 3)
                .padding(.vertical, 22)
        }
    }
}

struct WiOutcomeScreen: View {
    let verdict: WiVerdict
    @EnvironmentObject private var appLanguage: AppLanguageStore
    @EnvironmentObject private var coil: WiSessionCoordinator
    @EnvironmentObject private var nodes: NodeSelectionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var reportAt = Date()
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if usesEnhancedSuccessLayout {
                            successTopBackBar
                                .padding(.horizontal, 8)
                                .padding(.top, 8)

                            Spacer(minLength: max(18, (geo.size.height - 520) * 0.06))

                            outcomeCard
                                .padding(.top, 10)
                                .padding(.horizontal, 8)

                            successActionCards
                                .padding(.top, 14)
                                .padding(.horizontal, 4)
                            
                            Spacer()

                            WiRatingPromoCard()
                                .padding(.horizontal, -24)

                            
                        } else {
                            Spacer(minLength: max(40, (geo.size.height - 520) * 0.16))

                            pillHeader(title: L10n.Flow.outcomeSection(appLanguage), tint: verdictBarColor)

                            outcomeCard
                                .padding(.top, 20)
                                .padding(.horizontal, 8)

                            flowDismissButton
                                .padding(.top, 24)
                                .padding(.horizontal, 8)

                            Spacer(minLength: max(48, (geo.size.height - 520) * 0.14))
                        }
                    }
                    .frame(minHeight: geo.size.height)
                    .padding(.horizontal, 24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            reportAt = Date()
        }
        .onDisappear {
            coil.clearVerdict()
        }
        .sheet(isPresented: $showShareSheet) {
            WiActivityShareSheet(activityItems: [WiFlowLinks.appStoreURL])
        }
    }

    private func pillHeader(title: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(tint.opacity(0.65))
                .frame(width: 3, height: 14)
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(WiTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var outcomeCard: some View {
        Group {
            if usesEnhancedSuccessLayout {
                modernSuccessHeaderCard
            } else {
                legacyOutcomeCard
            }
        }
    }

    private var legacyOutcomeCard: some View {
        VStack(alignment: .center, spacing: 0) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WiTheme.heroGradient(for: verdictPhase))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: verdictIcon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(WiTheme.textPrimary.opacity(0.96))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(WiTheme.borderSubtle, lineWidth: 1)
                )
                .shadow(color: verdictBarColor.opacity(0.2), radius: 14, y: 6)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(WiTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(verdictCode)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(WiTheme.textTertiary)
                    .tracking(0.35)
            }
            .padding(.top, 16)

            Text(summaryText)
                .font(.subheadline)
                .foregroundStyle(WiTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 400)
                .padding(.top, 12)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                outcomeDetailRow(
                    label: L10n.Flow.outcomeDetailExit(appLanguage),
                    value: outcomeExitValue
                )
                outcomeDivider
                outcomeDetailRow(
                    label: L10n.Flow.outcomeDetailMode(appLanguage),
                    value: nodes.selected.isAuto
                        ? L10n.Connect.homeModeAuto(appLanguage)
                        : L10n.Connect.homeModeManual(appLanguage)
                )
                outcomeDivider
                outcomeDetailRow(
                    label: L10n.Flow.outcomeDetailTime(appLanguage),
                    value: formattedReportTime
                )
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(WiTheme.bgTile)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(WiTheme.borderSubtle, lineWidth: 1)
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(verdictBarColor)
                .frame(width: 3)
                .padding(.vertical, 20)
        }
    }

    private var modernSuccessHeaderCard: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(successBadgeFill)
                .frame(width: 70, height: 70)
                .overlay {
                    statusHeaderIcon
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(successBadgeStroke, lineWidth: 1)
                )

            Text(successHeadline)
                .font(.system(size: 34, weight: .medium, design: .default))
                .foregroundStyle(WiTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var successTopBackBar: some View {
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

    private var statusHeaderIcon: some View {
        Group {
            if verdict == .unpluggedOK {
                Image("disconnect")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
            } else {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
    }

    private var successBadgeFill: LinearGradient {
        if verdict == .unpluggedOK {
            return LinearGradient(
                colors: [.clear, .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return WiTheme.heroGradient(for: .online)
    }

    private var successBadgeStroke: Color {
        verdict == .unpluggedOK ? .clear : WiTheme.borderSubtle
    }

    private var successActionCards: some View {
        VStack(spacing: 14) {
            successActionRow(
                icon: "share",
                title: L10n.Flow.successShareTitle(appLanguage),
                subtitle: L10n.Flow.successShareSubtitle(appLanguage),
                action: handleShareTap
            )
            successActionRow(
                icon: "follow",
                title: L10n.Flow.successFollowTitle(appLanguage),
                subtitle: L10n.Flow.successFollowSubtitle(appLanguage),
                action: handleFollowTap
            )
        }
    }

    private func successActionRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(WiTheme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(WiTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(WiTheme.bgTile.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(WiTheme.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func handleShareTap() {
        showShareSheet = true
    }

    private func handleFollowTap() {
        openURL(WiFlowLinks.telegramURL)
    }

    private var outcomeExitValue: String {
        let name = nodes.selected.name
        if let cc = nodes.selected.country, !cc.isEmpty {
            return "\(name)  ·  \(cc)"
        }
        return name
    }

    private var outcomeDivider: some View {
        Rectangle()
            .fill(WiTheme.borderSubtle.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }

    private func outcomeDetailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(WiTheme.textTertiary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WiTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 11)
    }

    private var formattedReportTime: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = appLanguage.localeForSwiftUI
        return f.string(from: reportAt)
    }

    private var summaryText: String {
        switch verdict {
        case .linkedOK: return L10n.Flow.outcomeSummaryOk(appLanguage)
        case .linkedFail: return L10n.Flow.outcomeSummaryFail(appLanguage)
        case .unpluggedOK: return L10n.Flow.outcomeSummaryUnplug(appLanguage)
        }
    }

    private var usesEnhancedSuccessLayout: Bool {
        verdict == .linkedOK || verdict == .unpluggedOK
    }

    private var successHeadline: String {
        switch verdict {
        case .linkedOK:
            return L10n.Flow.successHeadlineConnected(appLanguage)
        case .unpluggedOK:
            return L10n.Flow.successHeadlineDisconnected(appLanguage)
        case .linkedFail:
            return title
        }
    }

    private var flowDismissButton: some View {
        Button {
            dismiss()
        } label: {
            Text(L10n.Flow.dismiss(appLanguage))
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

    private var title: String {
        switch verdict {
        case .linkedOK: return L10n.Flow.outcomeOk(appLanguage)
        case .linkedFail: return L10n.Flow.outcomeFail(appLanguage)
        case .unpluggedOK: return L10n.Flow.outcomeUnplugged(appLanguage)
        }
    }

    private var verdictIcon: String {
        switch verdict {
        case .linkedOK: return "checkmark.shield.fill"
        case .linkedFail: return "xmark.octagon.fill"
        case .unpluggedOK: return "bolt.horizontal.circle"
        }
    }

    private var verdictPhase: WiPhase {
        switch verdict {
        case .linkedOK: return .online
        case .linkedFail: return .error
        case .unpluggedOK: return .offline
        }
    }

    private var verdictBarColor: Color {
        switch verdict {
        case .linkedOK: return WiTheme.success
        case .linkedFail: return WiTheme.error
        case .unpluggedOK: return WiTheme.textTertiary
        }
    }

    private var verdictCode: String {
        switch verdict {
        case .linkedOK: return L10n.Flow.outcomeCodeOk(appLanguage)
        case .linkedFail: return L10n.Flow.outcomeCodeFail(appLanguage)
        case .unpluggedOK: return L10n.Flow.outcomeCodeUnplug(appLanguage)
        }
    }

}

private struct WiActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct WiRatingPromoCard: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var appLanguage: AppLanguageStore
    @State private var filledCount = 4
    @State private var sweepHighlightIndex = 0
    @State private var tapFeedbackIndex = 0

    var body: some View {
        ZStack(alignment: .top) {
            Image("bgRate")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Flow.ratingTitle(appLanguage))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(WiTheme.textPrimary)
                    .padding(.top, 40)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openReview()
                    }

                Text(L10n.Flow.ratingSubtitle(appLanguage))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(WiTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openReview()
                    }

                HStack(alignment: .center, spacing: 26) {
                    ForEach(1...5, id: \.self) { index in
                        Button {
                            onStarTapped(index)
                        } label: {
                            Image(index <= filledCount ? "starYes" : "starNo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .scaleEffect(starScale(for: index))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openReview()
        }
        .task {
            await runSweepLoop()
        }
    }

    private func onStarTapped(_ index: Int) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.58)) {
            filledCount = index
            tapFeedbackIndex = index
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeOut(duration: 0.16)) {
                tapFeedbackIndex = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            openReview()
        }
    }

    private func starScale(for index: Int) -> CGFloat {
        var scale: CGFloat = 1.0
        if sweepHighlightIndex == index {
            scale *= 1.14
        }
        if tapFeedbackIndex == index {
            scale *= 1.16
        }
        return scale
    }

    private func runSweepLoop() async {
        while !Task.isCancelled {
            await runSingleSweep()
            try? await Task.sleep(nanoseconds: 1_700_000_000)
        }
    }

    @MainActor
    private func runSingleSweep() async {
        for index in 1...5 {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
                sweepHighlightIndex = index
            }
            try? await Task.sleep(nanoseconds: 80_000_000)
        }
        withAnimation(.easeOut(duration: 0.16)) {
            sweepHighlightIndex = 0
        }
    }

    private func openReview() {
        openURL(WiFlowLinks.appStoreReviewURL)
    }
}
