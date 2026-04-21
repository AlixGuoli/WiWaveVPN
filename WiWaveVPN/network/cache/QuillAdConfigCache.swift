import Foundation

enum QuillAdSlotGroup {
    case yandexInterstitial
    case emInterstitial
}

/// 广告配置缓存：保存原始响应，并扁平化常用广告位字段。
final class QuillAdConfigCache {
    static let shared = QuillAdConfigCache()

    private let rawKey = "Quill.AdConfig.RawJSON"
    private let updatedAtKey = "Quill.AdConfig.UpdatedAt"

    private let yandexIntKey = "Quill.AdConfig.YandexInt"
    private let emIntKey = "Quill.AdConfig.EMInt"

    private init() {}

    func keep(_ jsonText: String) {
        UserDefaults.standard.set(jsonText, forKey: rawKey)
        UserDefaults.standard.set(Date(), forKey: updatedAtKey)

        guard let data = jsonText.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let adConfig = obj["adConfig"] as? [String: Any],
              let mixed = adConfig["adMixed"] as? [[String: Any]] else {
            AppLogger.log(.connection, tag: "Quill", "adsettings 缓存失败：JSON 结构异常")
            return
        }

        var yandexValue: String?
        var emValue: String?

        for item in mixed {
            guard let name = item["name"] as? String,
                  let value = item["key"] as? String else { continue }
            switch name {
            case "Yandex_Int_List":
                yandexValue = value
                UserDefaults.standard.set(value, forKey: yandexIntKey)
            case "Yandex_EMInt_List":
                emValue = value
                UserDefaults.standard.set(value, forKey: emIntKey)
            default:
                continue
            }
        }

        AppLogger.log(
            .connection,
            tag: "Quill",
            "adsettings 已缓存 yandex=\(yandexValue ?? "nil"), em=\(emValue ?? "nil")"
        )
    }

    func slotIDs(for group: QuillAdSlotGroup) -> [String] {
        let key: String
        switch group {
        case .yandexInterstitial:
            key = yandexIntKey
        case .emInterstitial:
            key = emIntKey
        }
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        return raw.split(separator: ";").map { String($0) }.filter { !$0.isEmpty }
    }

    func lastUpdateTime() -> Date? {
        UserDefaults.standard.object(forKey: updatedAtKey) as? Date
    }
}
