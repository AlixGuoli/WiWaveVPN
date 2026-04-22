import UIKit
import GameAnalytics
import YandexMobileAds

final class WiAppDelegate: NSObject, UIApplicationDelegate {
    private var didInitializeThirdParty = false

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        initializeThirdPartyStacksIfNeeded()
        return true
    }

    func initializeThirdPartyStacksIfNeeded() {
        guard !didInitializeThirdParty else { return }
        guard WiATTGate.shared.canInitializeThirdParty else {
            AppLogger.log(.system, tag: "Startup", "等待 ATT 结果后再初始化第三方 SDK（新用户）")
            return
        }
        didInitializeThirdParty = true
        AppLogger.log(.system, tag: "Startup", "应用启动：初始化第三方 SDK")
        activateSignalStack()
        activateAdMatrix()
    }

    /// 第三方统计初始化入口（避免复用旧项目同名方法）。
    private func activateSignalStack() {
        AppLogger.log(.system, tag: "GA", "开始激活统计引擎")
        let buildTag = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        GameAnalytics.setEnabledInfoLog(true)
        GameAnalytics.setEnabledVerboseLog(true)
        GameAnalytics.configureAutoDetectAppVersion(true)
        GameAnalytics.configureBuild(buildTag)
        GameAnalytics.initialize(
            withGameKey: "cea583d05769033774d849e2068f3bb0",
            gameSecret: "639372f367964d8d2ab310eb8149e8c5b157135c"
        )
        AppLogger.log(.system, tag: "GA", "统计引擎激活完成")
    }

    /// 广告 SDK 初始化入口（本版本仅启用 Yandex 聚合，不接 AdMob）。
    private func activateAdMatrix() {
        AppLogger.log(.system, tag: "Ads", "开始激活广告引擎（Yandex Mediation）")
        MobileAds.initializeSDK {
            AppLogger.log(.system, tag: "Ads", "广告引擎激活完成")
        }
    }
}
