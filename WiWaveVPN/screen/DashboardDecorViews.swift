import SwiftUI

// MARK: - 面板装饰模块（与主隧道逻辑隔离）

enum DashboardFakeMetrics {
    static func latencyMs(seed: Int) -> Int {
        let x = abs(seed &* 31 &+ 17)
        return 22 + (x % 76)
    }

    static func linkGrade(seed: Int) -> String {
        let grades = ["A+", "A", "A−", "B+", "B"]
        let idx = abs(seed &* 13 &+ 5) % grades.count
        return grades[idx]
    }
}

// MARK: 会话条（phase 只读；时长基于系统 `connectedDate`，非页面本地计时）

struct DashboardSessionStrip: View {
    let phase: WiPhase
    let phaseLabel: String
    /// 与 `NEVPNConnection.connectedDate` 对齐；由 `WiSessionCoordinator` 只读同步，杀进程重进仍连续计时。
    let tunnelConnectedSince: Date?

    @EnvironmentObject private var appLanguage: AppLanguageStore

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Dashboard.stripSessionTitle(appLanguage))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WiTheme.textTertiary)
                Text(phaseLabel)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(WiTheme.textPrimary)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 6) {
                Text(L10n.Dashboard.stripDurationCaption(appLanguage))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WiTheme.textTertiary)
                durationView
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .foregroundStyle(WiTheme.accent)
                    .monospacedDigit()
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WiTheme.bgTile.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WiTheme.borderSubtle, lineWidth: 1)
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(WiTheme.statusTint(for: phase))
                .frame(width: 3)
                .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private var durationView: some View {
        if phase == .online, let start = tunnelConnectedSince {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Self.formatDuration(from: start, to: context.date))
            }
        } else {
            Text(L10n.Dashboard.stripDurationIdle(appLanguage))
        }
    }

    private static func formatDuration(from start: Date, to now: Date) -> String {
        let sec = max(0, Int(now.timeIntervalSince(start)))
        let h = sec / 3600
        let m = (sec % 3600) / 60
        let s = sec % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: 线路摘要（展示指标；种子来自 serverNodeId）

struct DashboardRouteDigestCard: View {
    let nodeName: String
    let seed: Int

    @EnvironmentObject private var appLanguage: AppLanguageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "globe.asia.australia.fill")
                    .font(.title3)
                    .foregroundStyle(WiTheme.accent)
                Text(L10n.Dashboard.routeDigestTitle(appLanguage))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(WiTheme.textPrimary)
            }
            Text(nodeName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WiTheme.textSecondary)
                .lineLimit(2)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Dashboard.routeLatencyLabel(appLanguage))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WiTheme.textTertiary)
                    Text(L10n.Dashboard.routeLatencyValue(appLanguage, DashboardFakeMetrics.latencyMs(seed: seed)))
                        .font(.body.weight(.semibold).monospacedDigit())
                        .foregroundStyle(WiTheme.textPrimary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(L10n.Dashboard.routeGradeLabel(appLanguage))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WiTheme.textTertiary)
                    Text(DashboardFakeMetrics.linkGrade(seed: seed))
                        .font(.body.weight(.bold))
                        .foregroundStyle(WiTheme.success)
                }
            }
            .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WiTheme.bgTile.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WiTheme.borderSubtle.opacity(0.85), lineWidth: 1)
                )
        )
    }
}

// MARK: 波形

struct DashboardSparklineCard: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Dashboard.sparkTitle(appLanguage))
                .font(.headline.weight(.semibold))
                .foregroundStyle(WiTheme.textPrimary)

            TimelineView(.animation(minimumInterval: 0.06, paused: false)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<28, id: \.self) { i in
                        let phase = t * 1.85 + Double(i) * 0.31
                        let h = 10 + sin(phase) * 16 + sin(phase * 1.63 + 0.8) * 9
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [WiTheme.accent.opacity(0.35), WiTheme.accent.opacity(0.85)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 6, height: CGFloat(max(6, min(40, h))))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WiTheme.bgElevated.opacity(0.42))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WiTheme.borderSubtle.opacity(0.65), lineWidth: 1)
                )
        )
    }
}

// MARK: 快速检查（不触碰隧道状态）

struct DashboardFakeCheckCard: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore

    @State private var running = false
    @State private var showDone = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.Dashboard.checkTitle(appLanguage))
                .font(.headline.weight(.semibold))
                .foregroundStyle(WiTheme.textPrimary)

            Button {
                Task { await runFakeCheck() }
            } label: {
                HStack(spacing: 10) {
                    if running {
                        ProgressView()
                            .tint(WiTheme.bgDeep)
                    } else {
                        Image(systemName: "waveform.path.ecg")
                            .font(.body.weight(.semibold))
                    }
                    Text(running ? L10n.Dashboard.checkRunning(appLanguage) : L10n.Dashboard.checkButton(appLanguage))
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(WiTheme.bgDeep)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(WiTheme.accent.opacity(running ? 0.55 : 0.95))
                )
            }
            .buttonStyle(.plain)
            .disabled(running)

            if showDone {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(WiTheme.success)
                    Text(L10n.Dashboard.checkDone(appLanguage))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WiTheme.success)
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WiTheme.bgTile.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WiTheme.borderSubtle.opacity(0.85), lineWidth: 1)
                )
        )
        .animation(.easeOut(duration: 0.25), value: showDone)
    }

    @MainActor
    private func runFakeCheck() async {
        guard !running else { return }
        running = true
        showDone = false
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        running = false
        showDone = true
    }
}

// MARK: 安全摘要（静态文案）

struct DashboardSecurityCard: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.Dashboard.securityTitle(appLanguage))
                .font(.headline.weight(.semibold))
                .foregroundStyle(WiTheme.textPrimary)

            VStack(alignment: .leading, spacing: 10) {
                securityRow(L10n.Dashboard.securityItem1(appLanguage))
                securityRow(L10n.Dashboard.securityItem2(appLanguage))
                securityRow(L10n.Dashboard.securityItem3(appLanguage))
                securityRow(L10n.Dashboard.securityItem4(appLanguage))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WiTheme.bgTile.opacity(0.48))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(WiTheme.borderSubtle.opacity(0.72), lineWidth: 1)
                )
        )
    }

    private func securityRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.body)
                .foregroundStyle(WiTheme.success.opacity(0.92))
                .frame(width: 22, alignment: .center)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(WiTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: 技巧横滑

struct DashboardTipsCarousel: View {
    @EnvironmentObject private var appLanguage: AppLanguageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Dashboard.tipsSectionTitle(appLanguage))
                .font(.headline.weight(.semibold))
                .foregroundStyle(WiTheme.textPrimary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(tipItems, id: \.id) { item in
                        tipCard(title: item.title, body: item.body)
                            .id("\(item.id)-\(appLanguage.preference.rawValue)")
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
    }

    private var tipItems: [(id: Int, title: String, body: String)] {
        [
            (0, L10n.Dashboard.tip1Title(appLanguage), L10n.Dashboard.tip1Body(appLanguage)),
            (1, L10n.Dashboard.tip2Title(appLanguage), L10n.Dashboard.tip2Body(appLanguage)),
            (2, L10n.Dashboard.tip3Title(appLanguage), L10n.Dashboard.tip3Body(appLanguage)),
            (3, L10n.Dashboard.tip4Title(appLanguage), L10n.Dashboard.tip4Body(appLanguage)),
            (4, L10n.Dashboard.tip5Title(appLanguage), L10n.Dashboard.tip5Body(appLanguage)),
        ]
    }

    private func tipCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(WiTheme.textPrimary)
            Text(body)
                .font(.caption)
                .foregroundStyle(WiTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 260, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(WiTheme.bgElevated.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(WiTheme.borderSubtle.opacity(0.75), lineWidth: 1)
                )
        )
    }
}
