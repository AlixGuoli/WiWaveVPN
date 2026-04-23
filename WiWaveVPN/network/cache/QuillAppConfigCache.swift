import Foundation

/// getconf 配置缓存：保存原始 JSON，同时扁平化关键字段。
final class QuillAppConfigCache {
    static let shared = QuillAppConfigCache()

    private let rawKey = "Quill.AppConfig.RawJSON"
    private let updatedAtKey = "Quill.AppConfig.UpdatedAt"
    private let localGitVersionKey = "Quill.AppConfig.LocalGitVersion"

    private let adsOffKey = "Quill.AppConfig.adsOff"
    private let adsTypeKey = "Quill.AppConfig.adsType"
    private let detectionServersKey = "Quill.AppConfig.detectionServers"
    private let remoteGitVersionKey = "Quill.AppConfig.remoteGitVersion"

    private init() {}

    func keep(_ jsonText: String) {
        UserDefaults.standard.set(jsonText, forKey: rawKey)
        UserDefaults.standard.set(Date(), forKey: updatedAtKey)

        guard let data = jsonText.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            AppLogger.log(.connection, tag: "Quill", "getconf 缓存失败：JSON 无法解析")
            return
        }

        if let value = extract(path: ["commonConf", "adsOff"], from: obj) as? Bool {
            UserDefaults.standard.set(value, forKey: adsOffKey)
        }
        if let value = extract(path: ["commonConf", "adsType"], from: obj) as? String {
            UserDefaults.standard.set(value, forKey: adsTypeKey)
        }
        if let cfg = extract(path: ["commonConf", "detectionConfig"], from: obj) as? [String: Any],
           let servers = cfg["detectionServers"] as? [String] {
            UserDefaults.standard.set(servers, forKey: detectionServersKey)
        }
        if let value = extract(path: ["commonConf", "git_version"], from: obj) as? Int {
            UserDefaults.standard.set(value, forKey: remoteGitVersionKey)
        }

        AppLogger.log(
            .connection,
            tag: "Quill",
            "getconf 已缓存 adsOff=\(isAdsOff()?.description ?? "nil"), adsType=\(adsType() ?? "nil"), servers=\(detectionServers() ?? []), serverCount=\(detectionServers()?.count ?? 0), git_version=\(remoteGitVersion()?.description ?? "nil")"
        )
    }

    func rawJSON() -> String? {
        UserDefaults.standard.string(forKey: rawKey)
    }

    func lastUpdateTime() -> Date? {
        UserDefaults.standard.object(forKey: updatedAtKey) as? Date
    }

    func isAdsOff() -> Bool? {
        // 测试服
        //return false
        if UserDefaults.standard.object(forKey: adsOffKey) != nil {
            return UserDefaults.standard.bool(forKey: adsOffKey)
        }
        return extractFromRaw(path: ["commonConf", "adsOff"]) as? Bool
    }

    func adsType() -> String? {
        // 测试服
        //return "e"
        if let value = UserDefaults.standard.string(forKey: adsTypeKey) {
            return value
        }
        return extractFromRaw(path: ["commonConf", "adsType"]) as? String
    }

    func detectionServers() -> [String]? {
        if let values = UserDefaults.standard.array(forKey: detectionServersKey) as? [String] {
            return values
        }
        guard let cfg = extractFromRaw(path: ["commonConf", "detectionConfig"]) as? [String: Any] else {
            return nil
        }
        return cfg["detectionServers"] as? [String]
    }

    func remoteGitVersion() -> Int? {
        if UserDefaults.standard.object(forKey: remoteGitVersionKey) != nil {
            return UserDefaults.standard.integer(forKey: remoteGitVersionKey)
        }
        return extractFromRaw(path: ["commonConf", "git_version"]) as? Int
    }

    func localGitVersion() -> Int {
        if UserDefaults.standard.object(forKey: localGitVersionKey) == nil {
            return 1
        }
        return UserDefaults.standard.integer(forKey: localGitVersionKey)
    }

    func saveLocalGitVersion(_ value: Int) {
        UserDefaults.standard.set(value, forKey: localGitVersionKey)
        AppLogger.log(.connection, tag: "Quill", "本地 git_version 已更新 local=\(value)")
    }

    private func extractFromRaw(path: [String]) -> Any? {
        guard let jsonText = UserDefaults.standard.string(forKey: rawKey),
              let data = jsonText.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return extract(path: path, from: obj)
    }

    private func extract(path: [String], from root: [String: Any]) -> Any? {
        var cursor: Any? = root
        for key in path {
            guard let dict = cursor as? [String: Any] else { return nil }
            cursor = dict[key]
        }
        return cursor
    }
}
