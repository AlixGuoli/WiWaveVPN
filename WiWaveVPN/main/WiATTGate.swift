import Foundation
import AppTrackingTransparency

/// ATT 门控：老用户维持现有流程；新用户在 ATT 有结果后放行初始化/广告加载。
final class WiATTGate {
    static let shared = WiATTGate()

    private let onboardingKey = "wvv.launch.onboarding.completed"
    private let attResolvedKey = "wvv.att.resolved"

    private init() {}

    /// 老用户：已完成过引导；新用户：未完成引导。
    private var isLegacyUser: Bool {
        UserDefaults.standard.bool(forKey: onboardingKey)
    }

    private var hasResolvedATT: Bool {
        UserDefaults.standard.bool(forKey: attResolvedKey)
    }

    /// 第三方 SDK 初始化是否可放行。
    var canInitializeThirdParty: Bool {
        isLegacyUser || hasResolvedATT
    }

    /// 广告加载是否可放行。
    var canLoadAds: Bool {
        isLegacyUser || hasResolvedATT
    }

    /// 仅新用户在隐私同意后调用：拿到 ATT 结果（同意/拒绝均可）后放行。
    func resolveTrackingIfNeededForFreshUser(completion: @escaping () -> Void) {
        guard !isLegacyUser else {
            completion()
            return
        }

        guard !hasResolvedATT else {
            completion()
            return
        }

        guard #available(iOS 14, *) else {
            markATTResolved(reason: "ios<14")
            completion()
            return
        }

        DispatchQueue.main.async {
            let current = ATTrackingManager.trackingAuthorizationStatus
            if current == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { status in
                    self.markATTResolved(reason: "request:\(status.rawValue)")
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            } else {
                self.markATTResolved(reason: "cached:\(current.rawValue)")
                completion()
            }
        }
    }

    private func markATTResolved(reason: String) {
        if !UserDefaults.standard.bool(forKey: attResolvedKey) {
            UserDefaults.standard.set(true, forKey: attResolvedKey)
            AppLogger.log(.system, tag: "ATT", "ATT 结果已记录，reason=\(reason)")
        }
    }
}
