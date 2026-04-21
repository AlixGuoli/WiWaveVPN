import Foundation

struct QuillContext {
    private static let uidKey = "Quill.Context.UID"

    static func baseQuery() -> [String: String] {
        [
            "uid": stableUID(),
            "country": (Locale.current.region?.identifier ?? "US").lowercased(),
            "language": Locale.preferredLanguages.first ?? "en",
            
            "pk": Bundle.main.bundleIdentifier ?? "com.glow.wiwave.vpn",
            // 测试服
            //"pk": "com.bluelink.nexus.key.vpn",
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
        ]
    }

    static func merge(_ extra: [String: String]) -> [String: String] {
        baseQuery().merging(extra) { _, rhs in rhs }
    }

    private static func stableUID() -> String {
        if let v = UserDefaults.standard.string(forKey: uidKey), !v.isEmpty {
            return v
        }
        let generated = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        UserDefaults.standard.set(generated, forKey: uidKey)
        return generated
    }
}
