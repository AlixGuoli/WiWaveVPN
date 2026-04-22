import Foundation

enum QuillBootstrapOutcome {
    case completed(elapsedMs: Int)
}

/// 启动期接口编排：拉基础配置 + 广告配置。
final class QuillBootstrapFlow {
    private let probe: QuillProbe

    init(probe: QuillProbe = QuillProbe()) {
        self.probe = probe
    }

    func run() async -> QuillBootstrapOutcome {
        let startedAt = Date()
        await probe.pingGetconfAndLog()

        // 旧项目顺序：基础配置完成后，并行触发广告接口与广告预加载。
        Task { [probe] in
            await probe.pingAdsettingsAndLog()
        }
        await preloadLaunchAd()
        let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
        return .completed(elapsedMs: elapsedMs)
    }

    private func preloadLaunchAd() async {
        await withCheckedContinuation { continuation in
            var resumed = false
            FluxAdManager.shared.primeInt(trigger: .launch, onReady: {
                guard !resumed else { return }
                resumed = true
                AppLogger.log(.system, tag: "Ads", "启动阶段广告预加载完成")
                continuation.resume()
            }, onFailed: {
                guard !resumed else { return }
                resumed = true
                AppLogger.log(.system, tag: "Ads", "启动阶段广告预加载失败或无可用广告")
                continuation.resume()
            })
        }
    }
}
