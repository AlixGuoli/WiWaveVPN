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
        await probe.pingBootstrapAndLog()
        let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
        return .completed(elapsedMs: elapsedMs)
    }
}
