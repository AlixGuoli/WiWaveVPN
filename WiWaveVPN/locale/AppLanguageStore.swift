import Combine
import Foundation

/// 应用内语言（持久化）；`system` 时按系统首选语言匹配本包支持的语言，否则回退 **`en`**。
final class AppLanguageStore: ObservableObject {

    enum Preference: String, CaseIterable, Identifiable {
        case system
        case english
        case russian
        case german
        case french
        case spanish
        case polish
        case japanese
        case korean

        var id: String { rawValue }

        fileprivate var fixedLprojName: String? {
            switch self {
            case .system: return nil
            case .english: return "en"
            case .russian: return "ru"
            case .german: return "de"
            case .french: return "fr"
            case .spanish: return "es"
            case .polish: return "pl"
            case .japanese: return "ja"
            case .korean: return "ko"
            }
        }

        static var settingsMenuOrder: [Preference] {
            [.system, .english, .russian, .german, .french, .spanish, .polish, .japanese, .korean]
        }
    }

    /// 可随系统/手动语言变化的界面刷新键（`system` 时用解析结果）。
    var contentRefreshIdentity: String {
        "\(preference.rawValue)|\(activeLprojTag())"
    }

    private static let udKey = "app.language.preference"

    /// 切换语言时短暂为 `true`，用于全屏遮罩（类似系统设置换语言）。
    @Published private(set) var isApplyingLanguage = false

    @Published var preference: Preference {
        didSet { UserDefaults.standard.set(preference.rawValue, forKey: Self.udKey) }
    }

    private var languageApplyWorkItem: DispatchWorkItem?

    /// 延迟写入 `preference`，先展示 `isApplyingLanguage` 遮罩，避免界面瞬间跳变。
    func applyPreference(_ newValue: Preference) {
        guard newValue != preference else { return }
        languageApplyWorkItem?.cancel()
        isApplyingLanguage = true
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.preference = newValue
            self.isApplyingLanguage = false
            self.languageApplyWorkItem = nil
        }
        languageApplyWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68, execute: work)
    }

    /// 与 `tr(_:)` 使用同一套解析结果，供 `Locale`、`\.id` 等使用。
    func activeLprojTag() -> String {
        if let fixed = preference.fixedLprojName {
            return fixed
        }
        return Self.resolveSystemLprojToBundleTag()
    }

    var localeForSwiftUI: Locale {
        Locale(identifier: activeLprojTag())
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.udKey) ?? Preference.system.rawValue
        self.preference = Preference(rawValue: raw) ?? .system
    }

    func tr(_ key: String) -> String {
        let tag = activeLprojTag()
        if let v = Self.localizedString(key: key, lprojTag: tag), v != key {
            return v
        }
        if tag != "en", let v = Self.localizedString(key: key, lprojTag: "en"), v != key {
            return v
        }
        return String(localized: String.LocalizationValue(key))
    }

    private static func localizedString(key: String, lprojTag: String) -> String? {
        guard let path = Bundle.main.path(forResource: lprojTag, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return nil
        }
        let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
        if value == key { return nil }
        return value
    }

    /// 与 `*.lproj` 目录名一致；不在列表的系统语言（含中文）跳过，按 `preferredLanguages` 下一项匹配，最终可落到 **`en`**。
    private static func resolveSystemLprojToBundleTag() -> String {
        for raw in Locale.preferredLanguages {
            let norm = raw.replacingOccurrences(of: "_", with: "-").lowercased()
            if norm.hasPrefix("zh") { continue }
            if norm.hasPrefix("de") { return "de" }
            if norm.hasPrefix("fr") { return "fr" }
            if norm.hasPrefix("es") { return "es" }
            if norm.hasPrefix("pl") { return "pl" }
            if norm.hasPrefix("ja") { return "ja" }
            if norm.hasPrefix("ko") { return "ko" }
            if norm.hasPrefix("ru") { return "ru" }
            if norm.hasPrefix("en") { return "en" }
        }
        return "en"
    }
}
