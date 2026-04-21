import Foundation

/// 连接与服务状态上报（按旧逻辑字段，使用新命名实现）。
final class QuillPulseReporter {
    static let shared = QuillPulseReporter()

    private let vault: QuillDomainVaulting
    private let session: URLSession

    private init(
        vault: QuillDomainVaulting = QuillDomainVault.shared,
        session: URLSession = .shared
    ) {
        self.vault = vault
        self.session = session
    }

    static func makeSessionToken() -> String {
        String(UUID().uuidString.prefix(8))
    }

    func reportConnectStart(sessionId: String) {
        guard let message = buildConnectMessage(event: .start, sessionId: sessionId, ip: nil) else { return }
        submitConnectLog(message: message, event: .start)
    }

    func reportConnectSuccess(sessionId: String?) {
        let ip = QuillReportEndpointContext.shared.currentEndpoint
        guard let message = buildConnectMessage(event: .success, sessionId: sessionId, ip: ip) else { return }
        submitConnectLog(message: message, event: .success)
    }

    func reportConnectFailure(sessionId: String?) {
        let ip = QuillReportEndpointContext.shared.currentEndpoint
        guard let message = buildConnectMessage(event: .failure, sessionId: sessionId, ip: ip) else { return }
        submitConnectLog(message: message, event: .failure)
    }

    /// 服务状态：live=true -> isf=0；fallback/失败 -> isf=1
    func reportServiceStatus(isLive: Bool) {
        Task.detached { [weak self] in
            await self?.sendServiceStatus(isLive: isLive)
        }
    }

    private enum ConnectEvent: String {
        case start = "start_connect"
        case failure = "connect_failed"
        case success = "connect_success"
    }

    private func buildConnectMessage(event: ConnectEvent, sessionId: String?, ip: String?) -> String? {
        let ts = formattedTimestamp()
        let sid = sessionId ?? ""
        let identifier = "\(ts)-\(sid)"
        let endpoint = ip ?? "0.0.0.0"
        switch event {
        case .start:
            return "\(ConnectEvent.start.rawValue),\(identifier),0.0.0.0"
        case .failure:
            return "\(ConnectEvent.failure.rawValue),\(identifier),\(endpoint)"
        case .success:
            return "\(ConnectEvent.success.rawValue),0,\(identifier),\(endpoint)"
        }
    }

    private func submitConnectLog(message: String, event: ConnectEvent) {
        Task.detached { [weak self] in
            guard let self else { return }
            guard let base = self.vault.reportBaseURL(for: .connect), !base.isEmpty else {
                AppLogger.log(.connection, tag: "Report", "连接上报跳过 connect report skipped（missing connreport）")
                return
            }
            guard let url = self.buildConnectURL(base: base, message: message) else {
                AppLogger.log(.connection, tag: "Report", "连接上报跳过 connect report skipped（url build failed）")
                return
            }
            await self.performRequest(url: url, label: "connect/\(event.rawValue)")
        }
    }

    private func sendServiceStatus(isLive: Bool) async {
        guard let base = vault.reportBaseURL(for: .general), !base.isEmpty else {
            AppLogger.log(.connection, tag: "Report", "服务状态上报跳过 service status skipped（missing greport）")
            return
        }
        let isf = isLive ? "0" : "1"
        guard let url = buildServiceStatusURL(base: base, isf: isf) else {
            AppLogger.log(.connection, tag: "Report", "服务状态上报跳过 service status skipped（url build failed）")
            return
        }
        await performRequest(url: url, label: "service/isf=\(isf)")
    }

    private func buildConnectURL(base: String, message: String) -> URL? {
        guard var comp = URLComponents(string: base) else { return nil }
        let ctx = QuillContext.baseQuery()
        comp.queryItems = [
            URLQueryItem(name: "imei", value: ctx["uid"] ?? ""),
            URLQueryItem(name: "country", value: ctx["country"] ?? ""),
            URLQueryItem(name: "lang", value: ctx["language"] ?? ""),
            URLQueryItem(name: "mobile", value: "iPhone"),
            URLQueryItem(name: "pk", value: ctx["pk"] ?? ""),
            URLQueryItem(name: "version", value: ctx["version"] ?? ""),
            URLQueryItem(name: "info", value: message),
        ]
        return comp.url
    }

    private func buildServiceStatusURL(base: String, isf: String) -> URL? {
        guard var comp = URLComponents(string: base + "/report_total") else { return nil }
        let ctx = QuillContext.baseQuery()
        comp.queryItems = [
            URLQueryItem(name: "name", value: "getService"),
            URLQueryItem(name: "cty", value: ctx["country"] ?? ""),
            URLQueryItem(name: "pk", value: ctx["pk"] ?? ""),
            URLQueryItem(name: "v", value: ctx["version"] ?? ""),
            URLQueryItem(name: "asn", value: "0"),
            URLQueryItem(name: "isf", value: isf),
            URLQueryItem(name: "cnt", value: "1"),
        ]
        return comp.url
    }

    private func performRequest(url: URL, label: String) async {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let begin = Date()
        do {
            let (_, response) = try await session.data(for: req)
            let ms = Int(Date().timeIntervalSince(begin) * 1000)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            AppLogger.log(.connection, tag: "Report", "上报完成 report done, label=\(label), status=\(status), elapsed=\(ms)ms")
        } catch {
            let ms = Int(Date().timeIntervalSince(begin) * 1000)
            AppLogger.log(.connection, tag: "Report", "上报失败 report failed, label=\(label), elapsed=\(ms)ms")
        }
    }

    private func formattedTimestamp() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMddHHmmss"
        return fmt.string(from: Date())
    }
}
