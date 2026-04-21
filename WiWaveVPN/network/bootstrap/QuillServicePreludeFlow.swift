import Foundation

/// 连接前服务预取：接口优先，失败再回退本地服务密文。
final class QuillServicePreludeFlow {
    private let probe: QuillProbe
    private let depot: QuillServiceCipherDepot
    private let resolver: QuillServiceCipherResolver
    private let composer: QuillDirectRouteComposer

    init(
        probe: QuillProbe = QuillProbe(),
        depot: QuillServiceCipherDepot = .shared,
        resolver: QuillServiceCipherResolver = QuillServiceCipherResolver(),
        composer: QuillDirectRouteComposer = QuillDirectRouteComposer()
    ) {
        self.probe = probe
        self.depot = depot
        self.resolver = resolver
        self.composer = composer
    }

    /// 返回 true 表示“已有可用服务密文”（来自接口或本地回退）。
    func prepare(groupID: Int, vip: Int) async -> Bool {
        AppLogger.log(.connection, tag: "Quill", "服务预取开始 service prelude begin, group=\(groupID), vip=\(vip)")
        let sourceLabel: String
        if let liveCipher = await probe.pingServiceProfileAndLog(groupID: groupID, vip: vip),
           !liveCipher.isEmpty {
            depot.absorbLiveCipher(liveCipher)
            sourceLabel = "live"
        }
        else {
            if let fallback = depot.reviveFallbackCipher(), !fallback.isEmpty {
                sourceLabel = "fallback"
            } else if depot.activeCipher == nil {
                AppLogger.log(.connection, tag: "Quill", "服务预取失败 service prelude failed（live/fallback 均不可用）")
                return false
            } else {
                sourceLabel = "fallback"
            }
        }

        guard let cipher = depot.activeCipher,
              let draft = resolver.resolve(cipherText: cipher, origin: depot.origin) else {
            AppLogger.log(.connection, tag: "Quill", "服务预取失败 service prelude failed（解密/解析失败）")
            return false
        }
        guard let routeJSON = composer.compose(from: draft) else {
            AppLogger.log(.connection, tag: "Quill", "服务预取失败 service prelude failed（直连编排失败）")
            return false
        }
        depot.holdDraft(draft)
        depot.holdRouteJSON(routeJSON)
        QuillReportEndpointContext.shared.apply(endpointIP: draft.endpointIP, origin: draft.origin)
        AppLogger.log(.connection, tag: "Quill", "服务预取完成 service prelude ready, source=\(sourceLabel), ip=\(draft.endpointIP)")
        return true
    }
}
