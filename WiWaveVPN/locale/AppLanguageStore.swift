import Combine
import Foundation

/// 应用内语言（与系统语言设置独立，持久化在 UserDefaults）。
final class AppLanguageStore: ObservableObject {

    enum Preference: String, CaseIterable, Identifiable {
        case system
        case english
        case simplifiedChinese

        var id: String { rawValue }

        fileprivate var lprojName: String? {
            switch self {
            case .system: return nil
            case .english: return "en"
            case .simplifiedChinese: return "zh-Hans"
            }
        }
    }

    private static let udKey = "app.language.preference"

    @Published var preference: Preference {
        didSet { UserDefaults.standard.set(preference.rawValue, forKey: Self.udKey) }
    }

    /// 影响 `Text` 日期数字等环境；与 `tr(_:)` 使用同一套选择。
    var localeForSwiftUI: Locale {
        switch preference {
        case .system:
            return .current
        case .english:
            return Locale(identifier: "en")
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.udKey) ?? Preference.system.rawValue
        self.preference = Preference(rawValue: raw) ?? .system
    }

    func tr(_ key: String) -> String {
        guard let lang = preference.lprojName else {
            return String(localized: String.LocalizationValue(key))
        }
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return String(localized: String.LocalizationValue(key))
        }
        let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
        if value == key {
            return String(localized: String.LocalizationValue(key))
        }
        return value
    }
}
