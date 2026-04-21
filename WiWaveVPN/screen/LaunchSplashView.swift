import SwiftUI

/// 冷启动页：页面启动即开始 20 秒计时，超时直接放行。
struct LaunchSplashView: View {
    let onComplete: () -> Void

    @EnvironmentObject private var appLanguage: AppLanguageStore

    @State private var progressPercent: Int = 0
    private let splashTimeoutSeconds: Int = 20

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

                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(WiTheme.textTertiary.opacity(0.25))
                            .frame(height: 4)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [WiTheme.accent.opacity(0.9), WiTheme.glowTeal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: CGFloat(progressPercent) / 100.0 * 200.0, height: 4)
                    }
                    .frame(width: 200, alignment: .leading)

                    Text("\(progressPercent)%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WiTheme.textSecondary.opacity(0.9))
                }
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
        let progressTask = Task {
            await tickProgress(startedAt: began)
        }
        let race = await driveStartup(startedAt: began)

        progressTask.cancel()
        await MainActor.run {
            progressPercent = 100
        }

        switch race {
        case .completed(let elapsedMs):
            AppLogger.log(.connection, tag: "Launch", "bootstrap completed in \(elapsedMs)ms")
        case .timeout(let elapsedMs):
            AppLogger.log(.connection, tag: "Launch", "bootstrap timeout \(splashTimeoutSeconds)s, elapsed=\(elapsedMs)ms")
        }
    }

    private enum StartupResult {
        case completed(elapsedMs: Int)
        case timeout(elapsedMs: Int)
    }

    /// 页面启动即计时；网络可用后尝试拉取，若在剩余时间内未完成同样按超时放行。
    private func driveStartup(startedAt: Date) async -> StartupResult {
        let deadline = startedAt.addingTimeInterval(Double(splashTimeoutSeconds))

        while Date() < deadline {
            let path = await LaunchNetworkProbe.classifyCurrentPath()
            if path != .unsatisfied {
                AppLogger.log(.connection, tag: "Launch", "path ready=\(path.rawValue), start bootstrap")
                let remaining = max(0, deadline.timeIntervalSinceNow)
                let bootstrapFinished = await runBootstrapWithin(remainingSeconds: remaining)
                let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
                return bootstrapFinished ? .completed(elapsedMs: elapsedMs) : .timeout(elapsedMs: elapsedMs)
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
        return .timeout(elapsedMs: elapsedMs)
    }

    /// 在剩余时间内执行接口编排，超时则返回 false。
    private func runBootstrapWithin(remainingSeconds: TimeInterval) async -> Bool {
        guard remainingSeconds > 0 else { return false }
        return await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                _ = await QuillBootstrapFlow().run()
                return true
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(remainingSeconds * 1_000_000_000))
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }

    private func tickProgress(startedAt: Date) async {
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(startedAt)
            let ratio = min(1.0, max(0.0, elapsed / Double(splashTimeoutSeconds)))
            let percent = Int(ratio * 100.0)
            await MainActor.run {
                progressPercent = percent
            }
            if percent >= 100 {
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
}
