import Foundation
import Combine

/// 首装引导与安全区入口标记（仅本地 UserDefaults）。
final class AppLaunchGate: ObservableObject {
    private let key = "wvv.launch.onboarding.completed"

    @Published private(set) var hasCompletedOnboarding: Bool

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: key)
    }

    func markOnboardingFinished() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: key)
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: key)
    }
}
