import Foundation

protocol QuillTransporting {
    func get(url: URL, timeout: TimeInterval) async -> Result<String, QuillError>
}

struct QuillTransport: QuillTransporting {
    private let session: URLSession
    #if DEBUG
    /// Debug 手动开关：true=强制走 5 秒超时；false=正常请求。
    private let forceTimeoutForDebug = false
    #endif

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(url: URL, timeout: TimeInterval = 5) async -> Result<String, QuillError> {
        let seconds = max(1, Int(timeout.rounded()))
        let token = Int.random(in: 1000...9999)
        let startedAt = Date()
        let endpoint = endpointName(for: url)
        let domain = url.host ?? "-"
        AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] request start")
        AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] domain=\(domain)")
        AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] url=\(url.absoluteString)")
        let countdownTask = Task.detached(priority: .utility) {
            for i in stride(from: seconds, through: 1, by: -1) {
                if Task.isCancelled { break }
                AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] countdown \(i)s")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

#if DEBUG
        if forceTimeoutForDebug {
            AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] debug forced-timeout enabled")
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            countdownTask.cancel()
            let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
            AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] request end timeout, elapsed=\(elapsedMs)ms")
            return .failure(.timeout)
        }
#endif

        var req = URLRequest(url: url)
        req.timeoutInterval = timeout
        do {
            let (data, response) = try await session.data(for: req)
            countdownTask.cancel()
            guard let http = response as? HTTPURLResponse else {
                let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
                AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] request end failed, elapsed=\(elapsedMs)ms")
                return .failure(.nonHTTPResponse)
            }
            guard (200...300).contains(http.statusCode) else {
                let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
                AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] request end failed, elapsed=\(elapsedMs)ms")
                return .failure(.badStatus(http.statusCode))
            }
            guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
                let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
                AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] request end failed, elapsed=\(elapsedMs)ms")
                return .failure(.emptyBody)
            }
            let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
            AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] response body=\(text)")
            AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] request end success, elapsed=\(elapsedMs)ms")
            return .success(text)
        } catch let err as URLError where err.code == .timedOut {
            countdownTask.cancel()
            let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
            AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] request end timeout, elapsed=\(elapsedMs)ms")
            return .failure(.timeout)
        } catch {
            countdownTask.cancel()
            let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1000)
            AppLogger.log(.connection, tag: "Quill", "[\(token)][\(endpoint)] request end failed, elapsed=\(elapsedMs)ms")
            return .failure(.transport(error.localizedDescription))
        }
    }

    private func endpointName(for url: URL) -> String {
        let path = url.path
        if path.contains("/academy/config/curriculum") { return "getconf" }
        if path.contains("/academy/ads/sponsor") { return "adsettings" }
        if path.contains("/academy/category/subject") { return "category" }
        if path.contains("/academy/service/lesson") { return "service" }
        return "unknown"
    }
}
