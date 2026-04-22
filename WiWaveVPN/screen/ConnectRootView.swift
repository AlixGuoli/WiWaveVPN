import SwiftUI
import Combine

/// 连接 Tab：偏仪器/控制台的科技感，克制、可读；标识为自绘波形，不依赖图片 Logo。
struct ConnectRootView: View {
    @Binding var path: [WiRoute]

    @EnvironmentObject private var appLanguage: AppLanguageStore
    @EnvironmentObject private var coil: WiSessionCoordinator
    @EnvironmentObject private var nodes: NodeSelectionStore

    /// 已连接时进入节点页前提示：需先断开。
    @State private var showRoutesLockedWhileOnline = false

    private var buildStamp: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "v\(v) · \(b)"
    }

    var body: some View {
        ZStack {
            WiTheme.FlowBackdrop()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        brandSection
                            .padding(.top, 6)

                        Group {
                            ConnectScopeStrip(phase: coil.phase)
                                .animation(.easeInOut(duration: 0.38), value: coil.phase)
                                .padding(.top, 22)

                            ConnectSimulatedThroughputRow(isOnline: coil.phase == .online)
                                .animation(.easeInOut(duration: 0.35), value: coil.phase == .online)
                                .padding(.top, 14)

                            Text(L10n.Connect.homeSpecLine(appLanguage))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(WiTheme.textTertiary)
                                .tracking(0.3)
                                .padding(.top, 16)
                        }

                        tunnelSection
                            .padding(.top, 28)

                        Group {
                            routeSection
                                .padding(.top, 16)

                            Text(L10n.Connect.homeScribble(appLanguage))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(WiTheme.textTertiary.opacity(0.85))
                                .padding(.top, 20)
                                .padding(.bottom, 28)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .alert(L10n.Connect.alertDisconnectTitle(appLanguage), isPresented: $coil.showUnplugConfirm) {
            Button(L10n.Connect.alertDisconnectConfirm(appLanguage), role: .destructive) { coil.confirmUnplug() }
            Button(L10n.Connect.alertDisconnectCancel(appLanguage), role: .cancel) { coil.cancelUnplug() }
        } message: {
            Text(L10n.Connect.alertDisconnectMessage(appLanguage))
        }
        .alert(L10n.Connect.alertRoutesLockedTitle(appLanguage), isPresented: $showRoutesLockedWhileOnline) {
            Button(L10n.Connect.alertRoutesLockedOK(appLanguage), role: .cancel) {}
        } message: {
            Text(L10n.Connect.alertRoutesLockedMessage(appLanguage))
        }
        .alert(L10n.Connect.alertNoNetworkTitle(appLanguage), isPresented: $coil.showNoNetworkAlert) {
            Button(L10n.Connect.alertNoNetworkOK(appLanguage), role: .cancel) {}
        } message: {
            Text(L10n.Connect.alertNoNetworkMessage(appLanguage))
        }
    }

    private func tryOpenNodeList() {
        if coil.phase == .online {
            showRoutesLockedWhileOnline = true
        } else {
            path.append(.nodeList)
        }
    }

    // MARK: - Top

    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 8) {
                StatusPulseDot(
                    color: WiTheme.statusTint(for: coil.phase),
                    pulsing: coil.phase == .busy || coil.phase == .online
                )
                Text(buildStamp)
                    .font(.system(.caption2, design: .monospaced).weight(.medium))
                    .foregroundStyle(WiTheme.textTertiary)
            }
            Spacer()
            Button {
                tryOpenNodeList()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 13, weight: .semibold))
                    Text(L10n.Connect.homeChangeRoute(appLanguage))
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(WiTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(WiTheme.accent.opacity(0.45), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(WiTheme.bgTile.opacity(0.92))
                        )
                )
            }
            .buttonStyle(ConnectPressCardButtonStyle(scale: 0.985))
            .accessibilityLabel(L10n.Connect.nodesA11y(appLanguage))
        }
    }

    // MARK: - Brand

    /// 上半区只做「标题与状态」，波形移到下方全宽示波条，避免占住传统 Logo 位。
    private var brandSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Connect.homeOverline(appLanguage))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(WiTheme.textTertiary)

            Text(AppDisplayName.fromBundle)
                .font(.system(size: 26, weight: .bold, design: .default))
                .foregroundStyle(WiTheme.textPrimary)

            Text(L10n.Connect.homeTagline(appLanguage))
                .font(.subheadline)
                .foregroundStyle(WiTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                statusPill
                modePill
            }
            .padding(.top, 2)
            .animation(.easeInOut(duration: 0.42), value: coil.phase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusPill: some View {
        let c = WiTheme.statusTint(for: coil.phase)
        return Text(phaseBadgeLabel)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(c)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .stroke(c.opacity(0.45), lineWidth: 1)
                    .background(Capsule().fill(c.opacity(0.12)))
            )
    }

    private var modePill: some View {
        Text(nodes.selected.isAuto ? L10n.Connect.homeModeAuto(appLanguage) : L10n.Connect.homeModeManual(appLanguage))
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(WiTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .stroke(WiTheme.borderSubtle, lineWidth: 1)
                    .background(Capsule().fill(WiTheme.bgElevated.opacity(0.55)))
            )
    }

    // MARK: - Tunnel

    private var tunnelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(WiTheme.accent.opacity(0.55))
                    .frame(width: 3, height: 14)
                Text(L10n.Connect.homeConsoleLabel(appLanguage))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(WiTheme.textSecondary)
                Spacer()
            }

            sessionControlCard
        }
    }

    private var sessionControlCard: some View {
        Button(action: { coil.tapHero() }) {
            HStack(alignment: .center, spacing: 16) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(WiTheme.heroGradient(for: coil.phase))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: heroSymbol)
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(WiTheme.textPrimary.opacity(0.95))
                            .id(heroSymbol)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(WiTheme.borderSubtle, lineWidth: 1)
                    )
                    .accessibilityHidden(true)
                    .animation(.spring(response: 0.38, dampingFraction: 0.78), value: coil.phase)

                VStack(alignment: .leading, spacing: 6) {
                    Text(heroTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(WiTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut(duration: 0.32), value: heroTitle)

                    Text(statusLine)
                        .font(.subheadline)
                        .foregroundStyle(WiTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut(duration: 0.32), value: statusLine)
                }

                Group {
                    if coil.phase == .busy {
                        ProgressView()
                            .tint(WiTheme.accent)
                            .scaleEffect(1.05)
                    } else {
                        Image(systemName: sessionTrailingGlyph)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(WiTheme.accent.opacity(0.9))
                            .id(sessionTrailingGlyph)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 28, alignment: .center)
                .animation(.spring(response: 0.34, dampingFraction: 0.8), value: coil.phase)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(WiTheme.bgTile)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(WiTheme.borderSubtle, lineWidth: 1)
                    )
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(WiTheme.statusTint(for: coil.phase))
                    .frame(width: 3)
                    .padding(.vertical, 16)
                    .animation(.easeInOut(duration: 0.4), value: coil.phase)
            }
        }
        .buttonStyle(ConnectPressCardButtonStyle())
        .disabled(coil.phase == .busy && !coil.showUnplugConfirm)
        .accessibilityLabel("\(heroTitle)，\(statusLine)")
    }

    // MARK: - Route

    private var routeSection: some View {
        Button {
            tryOpenNodeList()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(WiTheme.accent.opacity(0.45))
                        .frame(width: 3, height: 14)
                    Text(L10n.Connect.homeRouteCaption(appLanguage))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(WiTheme.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WiTheme.textTertiary)
                }

                Text(nodes.selected.name)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundStyle(WiTheme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Text(L10n.Connect.currentLine(appLanguage))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(WiTheme.textTertiary)

                Divider()
                    .background(WiTheme.borderSubtle)

                HStack {
                    Text(modeBadgeInline)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(WiTheme.textTertiary)
                    Spacer()
                    Text(L10n.Connect.homeRouteFoot(appLanguage))
                        .font(.caption2)
                        .foregroundStyle(WiTheme.textTertiary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(WiTheme.bgElevated.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(WiTheme.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ConnectPressCardButtonStyle(scale: 0.985))
    }

    private var modeBadgeInline: String {
        nodes.selected.isAuto ? L10n.Connect.homeModeAuto(appLanguage) : L10n.Connect.homeModeManual(appLanguage)
    }

    // MARK: - State

    private var phaseBadgeLabel: String {
        switch coil.phase {
        case .offline: return L10n.Connect.homeBadgeOffline(appLanguage)
        case .busy: return L10n.Connect.homeBadgeBusy(appLanguage)
        case .online: return L10n.Connect.homeBadgeOnline(appLanguage)
        case .error: return L10n.Connect.homeBadgeError(appLanguage)
        }
    }

    private var sessionTrailingGlyph: String {
        switch coil.phase {
        case .offline, .error: return "play.fill"
        case .busy: return "ellipsis"
        case .online: return "power"
        }
    }

    private var heroSymbol: String {
        switch coil.phase {
        case .offline: return "antenna.radiowaves.left.and.right"
        case .busy: return "arrow.triangle.2.circlepath"
        case .online: return "checkmark.shield.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    private var heroTitle: String {
        switch coil.phase {
        case .offline, .error: return L10n.Connect.heroConnect(appLanguage)
        case .online: return L10n.Connect.heroDisconnect(appLanguage)
        case .busy: return L10n.Connect.heroBusy(appLanguage)
        }
    }

    private var statusLine: String {
        switch coil.phase {
        case .offline: return L10n.Connect.statusOffline(appLanguage)
        case .busy: return L10n.Connect.statusBusy(appLanguage)
        case .online: return L10n.Connect.statusOnline(appLanguage)
        case .error: return L10n.Connect.statusError(appLanguage)
        }
    }
}

// MARK: - 链路示波与示意吞吐

struct ConnectScopeStrip: View {
    let phase: WiPhase

    @EnvironmentObject private var appLanguage: AppLanguageStore

    private var tint: Color {
        switch phase {
        case .offline: return WiTheme.accent.opacity(0.55)
        case .busy: return WiTheme.accent
        case .online: return WiTheme.success.opacity(0.88)
        case .error: return WiTheme.error.opacity(0.88)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(L10n.Connect.homeScopeLabel(appLanguage))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(0.6)
                    .foregroundStyle(WiTheme.textTertiary)
                Spacer()
                Circle()
                    .fill(WiTheme.statusTint(for: phase))
                    .frame(width: 6, height: 6)
            }

            ZStack(alignment: .bottom) {
                TimelineView(.animation(minimumInterval: scopeFrameInterval, paused: false)) { timeline in
                    ConnectWaveformGlyph(phase: phase, time: timeline.date.timeIntervalSinceReferenceDate, tint: tint)
                }
                .frame(height: 52)
                .clipShape(Rectangle())
                .drawingGroup()

                GeometryReader { geo in
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: 0))
                        p.addLine(to: CGPoint(x: geo.size.width, y: 0))
                    }
                    .stroke(WiTheme.textTertiary.opacity(0.35), lineWidth: 1)
                }
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .offset(y: 4)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(WiTheme.bgElevated.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(WiTheme.borderSubtle, lineWidth: 1)
            )

            scopeTicksRow
        }
    }

    private var scopeTicksRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { i in
                Rectangle()
                    .fill(WiTheme.textTertiary.opacity(i % 4 == 0 ? 0.35 : 0.15))
                    .frame(width: 1, height: i % 4 == 0 ? 6 : 3)
                if i < 8 {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    /// 略提高刷新率、busy 时更密，减轻「一格格跳」的观感。
    private var scopeFrameInterval: TimeInterval {
        switch phase {
        case .busy: return 1.0 / 45.0
        case .online: return 1.0 / 30.0
        case .offline, .error: return 1.0 / 24.0
        }
    }
}

/// 三层波形；`time` 用于水平漂移，读起来更像实时示波而非静态 Logo。
struct ConnectWaveformGlyph: View {
    let phase: WiPhase
    let time: TimeInterval
    var tint: Color

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 2
            let w = size.width - inset * 2
            let h = size.height - inset * 2

            let (ampFactor, cycles, scroll): (CGFloat, Double, Double) = {
                switch phase {
                case .offline: return (0.32, 1.35, 0.35)
                case .busy: return (1.0, 3.2, 5.0)
                case .online: return (0.58, 2.1, 1.8)
                case .error: return (0.82, 2.8, 2.4)
                }
            }()

            let timeDrift = time * scroll
            let steps = Int(max(96, min(220, w / 1.8)))

            for i in 0..<3 {
                var path = Path()
                let mid = h * (0.22 + CGFloat(i) * 0.26)
                let amp = h * 0.11 * ampFactor
                for s in 0...steps {
                    let t = CGFloat(s) / CGFloat(steps)
                    let x = inset + t * w
                    var ang = Double(t) * cycles * Double.pi * 2 + Double(i) * 0.55 + timeDrift
                    if phase == .error {
                        ang += sin(Double(s) * 0.09 + timeDrift * 3.8) * 0.65
                    }
                    var y = mid + CGFloat(sin(ang)) * amp
                    if phase == .offline {
                        y += CGFloat(sin(ang * 3.1 + timeDrift * 0.5)) * amp * 0.15
                    }
                    if s == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                let opacity = 0.95 - Double(i) * 0.2
                context.stroke(
                    path,
                    with: .color(tint.opacity(opacity)),
                    style: StrokeStyle(
                        lineWidth: i == 1 ? 1.25 : 0.95,
                        lineCap: .round,
                        lineJoin: .round,
                        miterLimit: 8
                    )
                )
            }
        }
    }
}

private struct ConnectSimulatedThroughputRow: View {
    let isOnline: Bool

    @EnvironmentObject private var appLanguage: AppLanguageStore
    /// 示意用：偏保守的「够用但不夸张」区间（多数时间在个位数～二十出头 Mbit/s），避免看起来像测速拉满。
    @State private var downMbps: Double = 12
    @State private var upMbps: Double = 2.6
    @State private var upRatio: Double = 0.2

    private let clock = Timer.publish(every: 0.9, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                telemetryColumn(
                    title: L10n.Connect.homeTelemetryDown(appLanguage),
                    valueText: rateText(isOnline ? downMbps : nil),
                    alignment: .leading
                )
                Spacer()
                telemetryColumn(
                    title: L10n.Connect.homeTelemetryUp(appLanguage),
                    valueText: rateText(isOnline ? upMbps : nil),
                    alignment: .trailing
                )
            }

            if isOnline {
                HStack {
                    Spacer()
                    Text(L10n.Connect.homeTelemetrySimulated(appLanguage))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(WiTheme.textTertiary.opacity(0.9))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(WiTheme.bgTile.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(WiTheme.borderSubtle, lineWidth: 1)
                )
        )
        .onReceive(clock) { _ in
            guard isOnline else { return }
            downMbps += Double.random(in: -0.95...1.05)
            downMbps = min(26, max(4.2, downMbps))

            upRatio += Double.random(in: -0.014...0.014)
            upRatio = min(0.34, max(0.11, upRatio))

            var up = downMbps * upRatio * Double.random(in: 0.93...1.07)
            up = min(8.5, max(1.0, up))
            if up > downMbps * 0.4 { up = downMbps * Double.random(in: 0.13...0.30) }
            upMbps = up
        }
        .onChange(of: isOnline) { online in
            if online {
                downMbps = Double.random(in: 9.5...19.5)
                upRatio = Double.random(in: 0.14...0.28)
                upMbps = min(8, max(1.0, downMbps * upRatio))
            }
        }
    }

    private func telemetryColumn(title: String, valueText: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(WiTheme.textTertiary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if alignment == .trailing {
                    Spacer(minLength: 0)
                }
                Text(valueText)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(WiTheme.textPrimary)
                Text(L10n.Connect.homeTelemetryUnit(appLanguage))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(WiTheme.textTertiary)
            }
            .frame(maxWidth: alignment == .trailing ? .infinity : nil, alignment: alignment == .trailing ? .trailing : .leading)
        }
    }

    private func rateText(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f", locale: Locale.current, value)
    }
}

private struct ConnectPressCardButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct StatusPulseDot: View {
    let color: Color
    var pulsing: Bool = false

    var body: some View {
        ZStack {
            if pulsing {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { timeline in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let s = 1 + 0.22 * sin(t * 2 * Double.pi / 1.9)
                    let o = 0.28 + 0.2 * cos(t * 2 * Double.pi / 1.9)
                    Circle()
                        .stroke(color.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 13, height: 13)
                        .scaleEffect(s)
                        .opacity(o)
                }
                .frame(width: 22, height: 22)
            }
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: 10, height: 10)
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
        }
    }
}

#Preview {
    ConnectRootView(path: .constant([]))
        .environmentObject(AppLanguageStore())
        .environmentObject(WiSessionCoordinator())
        .environmentObject(NodeSelectionStore())
}
