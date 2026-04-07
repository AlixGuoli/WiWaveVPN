import Foundation

/// 与主应用 Info 一致：优先 `CFBundleDisplayName`，否则 `CFBundleName`（与 Tunnel 管理器里 VPN 名称来源相同）。
enum AppDisplayName {
    static var fromBundle: String {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        return "App"
    }
}
