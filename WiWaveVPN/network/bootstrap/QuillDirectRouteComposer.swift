import Foundation

/// 直连路由编排：基于服务配置草稿生成“可下发给 target”的最终 JSON。
final class QuillDirectRouteComposer {
    private let vault: QuillDomainVaulting

    init(vault: QuillDomainVaulting = QuillDomainVault.shared) {
        self.vault = vault
    }

    func compose(from draft: QuillServiceDraft) -> String? {
        AppLogger.log(.connection, tag: "Quill", "直连编排开始 direct-route begin, source=\(originLabel(draft.origin)), ip=\(draft.endpointIP)")
        var config = draft.configMap
        config = applyInboundPatch(config)
        config = applyDirectRoutingPatch(config)
        guard let json = serializeSingleLine(config) else {
            AppLogger.log(.connection, tag: "Quill", "直连编排失败 direct-route compose failed")
            return nil
        }
        AppLogger.log(.connection, tag: "Quill", "直连编排完成 direct-route composed, bytes=\(json.utf8.count)")
        AppLogger.log(.connection, tag: "Quill", "直连最终配置 final route json=\(json)")
        return json
    }

    private func applyInboundPatch(_ config: [String: Any]) -> [String: Any] {
        var next = config
        guard var inbounds = next["inbounds"] as? [[String: Any]], !inbounds.isEmpty else {
            AppLogger.log(.connection, tag: "Quill", "未找到 inbounds，跳过 inbound patch")
            return next
        }
        var first = inbounds[0]
        first["listen"] = "[::1]"
        first["port"] = "8080"
        inbounds[0] = first
        next["inbounds"] = inbounds
        AppLogger.log(.connection, tag: "Quill", "inbound patch 完成 listen=[::1], port=8080")
        return next
    }

    private func applyDirectRoutingPatch(_ config: [String: Any]) -> [String: Any] {
        var next = config
        let domains = gatherDirectDomains()
        let rules = buildDirectRules(domains)

        if var routing = next["routing"] as? [String: Any] {
            routing["rules"] = rules
            next["routing"] = routing
        } else {
            next["routing"] = [
                "domainStrategy": "AsIs",
                "rules": rules,
            ]
        }
        AppLogger.log(.connection, tag: "Quill", "routing patch 完成 ruleCount=\(rules.count), domainCount=\(domains.count)")
        return next
    }

    private func gatherDirectDomains() -> [String] {
        let fixedDomains = [
            "yastatic",
            "yandex",
            "yandex.ru",
            "yandexadexchange.net",
            "ads.adfox.ru",
            "appmetrica.yandex.ru",
            "gameanalytics",
            "mradx.net",
            "target.my.com",
            "vk.ru",
            "vk.me",
            "vk.com",
            "mail.ru",
        ]
        AppLogger.log(.connection, tag: "Quill", "固定直连域名 fixed direct domains=\(fixedDomains)")

        var dynamicDomains: [String] = []
        if let host = vault.reportBaseURL(for: .connect).flatMap({ URL(string: $0)?.host }) {
            dynamicDomains.append(host)
        }
        if let host = vault.reportBaseURL(for: .general).flatMap({ URL(string: $0)?.host }) {
            dynamicDomains.append(host)
        }
        let apiHosts = vault.activeHosts().compactMap { URL(string: $0)?.host }
        dynamicDomains.append(contentsOf: apiHosts)
        AppLogger.log(.connection, tag: "Quill", "动态直连域名 dynamic direct domains=\(dynamicDomains)")

        var merged = fixedDomains

        merged.append(contentsOf: dynamicDomains)

        // 去重且过滤空值
        var seen = Set<String>()
        return merged
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }

    private func buildDirectRules(_ domains: [String]) -> [[String: Any]] {
        var rules: [[String: Any]] = [
            [
                "type": "field",
                "domain": ["raw.githubusercontent.com"],
                "outboundTag": "direct",
            ],
        ]
        if !domains.isEmpty {
            rules.append([
                "type": "field",
                "domain": domains,
                "outboundTag": "direct",
            ])
        }
        AppLogger.log(.connection, tag: "Quill", "直连规则构建 direct rules built, ruleCount=\(rules.count)")
        return rules
    }

    private func serializeSingleLine(_ config: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: config, options: []),
              let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return text
    }

    private func originLabel(_ origin: QuillCipherOrigin) -> String {
        switch origin {
        case .live:
            return "live"
        case .fallback:
            return "fallback"
        }
    }
}
