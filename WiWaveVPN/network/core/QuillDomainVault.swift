import Foundation

protocol QuillDomainVaulting {
    func activeHosts() -> [String]
    func refreshFromGitOnce() async -> Bool
    func reportBaseURL(for kind: QuillReportKind) -> String?
}

enum QuillReportKind {
    case connect
    case general
}

/// 域名配置只做“读取 + 刷新 + 提供值”，不处理业务请求。
final class QuillDomainVault: QuillDomainVaulting {
    static let shared = QuillDomainVault()

    private let udCipherKey = "Quill.DomainCipher"
    private let localCipherName = "atlas"
    private let localCipherExtension = "seed"
    private let cipherKey: String
    private let decoder: QuillCipherDecoding
    private let session: URLSession

    init(
        cipherKey: String = "f92mUj0K1uBnMlXGFQKrYP07Emgc4yFmWYS8WRgy4IY=",
        decoder: QuillCipherDecoding = QuillCipherBox(),
        session: URLSession = .shared
    ) {
        self.cipherKey = cipherKey
        self.decoder = decoder
        self.session = session
    }

    func activeHosts() -> [String] {
        let json = activeJSON()
        let api = json?["api"] as? [String: Any]
        return api?["host"] as? [String] ?? []
    }

    func reportBaseURL(for kind: QuillReportKind) -> String? {
        let api = activeJSON()?["api"] as? [String: Any]
        switch kind {
        case .connect:
            return api?["connreport"] as? String
        case .general:
            return api?["greport"] as? String
        }
    }

    func refreshFromGitOnce() async -> Bool {
        guard let api = activeJSON()?["api"] as? [String: Any],
              let gitList = api["git"] as? [String],
              !gitList.isEmpty else {
            AppLogger.log(.connection, tag: "Quill", "跳过 git 刷新：缺少 git source")
            return false
        }
        AppLogger.log(.connection, tag: "Quill", "开始 git 刷新 sourceCount=\(gitList.count)")
        for (idx, raw) in gitList.enumerated() {
            guard let url = URL(string: raw) else { continue }
            AppLogger.log(.connection, tag: "Quill", "git[\(idx + 1)] 请求 git 源 url=\(raw)")
            var req = URLRequest(url: url)
            req.timeoutInterval = 5
            do {
                let (data, resp) = try await session.data(for: req)
                guard let http = resp as? HTTPURLResponse else {
                    AppLogger.log(.connection, tag: "Quill", "git[\(idx + 1)] 失败：响应异常")
                    continue
                }
                guard (200...300).contains(http.statusCode) else {
                    AppLogger.log(.connection, tag: "Quill", "git[\(idx + 1)] 失败 status=\(http.statusCode)")
                    continue
                }
                guard let cipher = String(data: data, encoding: .utf8),
                      decodeJSON(cipher, logDecodedJSON: false) != nil else {
                    AppLogger.log(.connection, tag: "Quill", "git[\(idx + 1)] 失败：解密或响应异常")
                    continue
                }
                AppLogger.log(.connection, tag: "Quill", "git[\(idx + 1)] 原始响应 body=\(cipher)")
                UserDefaults.standard.set(cipher, forKey: udCipherKey)
                AppLogger.log(.connection, tag: "Quill", "git[\(idx + 1)] 已保存到 UserDefaults")
                _ = decodeJSON(cipher, logDecodedJSON: true)
                return true
            } catch {
                AppLogger.log(.connection, tag: "Quill", "git[\(idx + 1)] 网络异常 error=\(error.localizedDescription)")
                continue
            }
        }
        AppLogger.log(.connection, tag: "Quill", "git 刷新失败：所有源均失败")
        return false
    }

    // MARK: - Internal

    private func activeJSON() -> [String: Any]? {
        if let fromUD = UserDefaults.standard.string(forKey: udCipherKey),
           let json = decodeJSON(fromUD, logDecodedJSON: false) {
            return json
        }
        if UserDefaults.standard.string(forKey: udCipherKey) != nil {
            AppLogger.log(.connection, tag: "Quill", "UD 配置不可用，回退本地")
        }
        guard let fromBundle = loadLocalCipher(),
              let json = decodeJSON(fromBundle, logDecodedJSON: true) else {
            AppLogger.log(.connection, tag: "Quill", "本地域名配置失败 source=local failed")
            return nil
        }
        AppLogger.log(.connection, tag: "Quill", "域名来源 source=local，写入 UD")
        UserDefaults.standard.set(fromBundle, forKey: udCipherKey)
        return json
    }

    private func decodeJSON(_ cipher: String, logDecodedJSON: Bool) -> [String: Any]? {
        guard let clear = decoder.decode(cipher, key: cipherKey),
              let data = clear.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let json = object as? [String: Any] else {
            AppLogger.log(.connection, tag: "Quill", "解密或 JSON 解析失败")
            return nil
        }
        if logDecodedJSON {
            AppLogger.log(.connection, tag: "Quill", "解密后 JSON decoded json=\(clear)")
        }
        return json
    }

    private func loadLocalCipher() -> String? {
        if let url = Bundle.main.url(forResource: localCipherName, withExtension: localCipherExtension, subdirectory: "network"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            AppLogger.log(.connection, tag: "Quill", "命中本地密文 /network")
            return text.split(whereSeparator: \.isNewline).first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let url = Bundle.main.url(forResource: localCipherName, withExtension: localCipherExtension),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            AppLogger.log(.connection, tag: "Quill", "命中本地密文 root")
            return text.split(whereSeparator: \.isNewline).first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        AppLogger.log(.connection, tag: "Quill", "未找到本地密文文件")
        return nil
    }
}
