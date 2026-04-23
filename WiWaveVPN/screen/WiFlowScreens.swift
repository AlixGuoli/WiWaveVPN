import SwiftUI

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

                        Spacer(minLength: max(56, (geo.size.height - 360) * 0.2))
                    }
                    .frame(minHeight: geo.size.height)
                    .padding(.horizontal, 24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
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

    @State private var reportAt = Date()

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
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
                    .frame(minHeight: geo.size.height)
                    .padding(.horizontal, 24)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            reportAt = Date()
        }
        .onDisappear {
            coil.clearVerdict()
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
