import Foundation

/// 固定策略：当前 host 轮询 -> 全失败则 Git 刷新 -> 新 host 再轮询一次。
final class QuillGateway {
    private let vault: QuillDomainVaulting
    private let transport: QuillTransporting

    init(vault: QuillDomainVaulting = QuillDomainVault.shared, transport: QuillTransporting = QuillTransport()) {
        self.vault = vault
        self.transport = transport
    }

    func request(_ endpoint: QuillEndpoint) async -> Result<String, QuillError> {
        AppLogger.log(.connection, tag: "Quill", "路由开始 route begin, api=\(endpointName(for: endpoint.path))")
        let firstRound = await tryHosts(vault.activeHosts(), endpoint: endpoint)
        if case .success = firstRound {
            return firstRound
        }

        AppLogger.log(.connection, tag: "Quill", "首轮失败，尝试 git 刷新域名")
        let refreshed = await vault.refreshFromGitOnce()
        guard refreshed else {
            AppLogger.log(.connection, tag: "Quill", "git 刷新失败，结束请求")
            return firstRound
        }
        AppLogger.log(.connection, tag: "Quill", "git 刷新成功，使用新 hosts 重试")
        return await tryHosts(vault.activeHosts(), endpoint: endpoint)
    }

    private func tryHosts(_ hosts: [String], endpoint: QuillEndpoint) async -> Result<String, QuillError> {
        guard !hosts.isEmpty else {
            AppLogger.log(.connection, tag: "Quill", "host 列表为空")
            return .failure(.noAvailableHost)
        }
        AppLogger.log(.connection, tag: "Quill", "当前 host 数量 hostCount=\(hosts.count)")
        var lastError: QuillError = .noAvailableHost

        for (idx, host) in hosts.enumerated() {
            guard let url = assembleURL(baseHost: host, endpoint: endpoint) else {
                AppLogger.log(.connection, tag: "Quill", "host[\(idx + 1)] URL 构建失败, host=\(host)")
                lastError = .invalidURL
                continue
            }
            let result = await transport.get(url: url, timeout: 5)
            switch result {
            case .success: return result
            case .failure(let e):
                AppLogger.log(.connection, tag: "Quill", "host[\(idx + 1)] 请求失败 request failed")
                lastError = e
            }
        }
        AppLogger.log(.connection, tag: "Quill", "所有 host 失败 all hosts failed")
        return .failure(lastError)
    }

    private func assembleURL(baseHost: String, endpoint: QuillEndpoint) -> URL? {
        let root = baseHost.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var components = URLComponents(string: root + endpoint.path) else {
            return nil
        }
        let query = QuillContext.merge(endpoint.extraQuery)
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }.sorted { $0.name < $1.name }
        return components.url
    }

    private func endpointName(for path: String) -> String {
        if path.contains("/academy/config/curriculum") { return "getconf" }
        if path.contains("/academy/ads/sponsor") { return "adsettings" }
        if path.contains("/academy/category/subject") { return "category" }
        if path.contains("/academy/service/lesson") { return "service" }
        return "unknown"
    }
}
