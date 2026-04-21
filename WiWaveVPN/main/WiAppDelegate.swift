import UIKit
import GameAnalytics
import YandexMobileAds

final class WiAppDelegate: NSObject, UIApplicationDelegate {
    private var hasActivatedThirdPartyStack = false

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppLogger.log(.system, tag: "Startup", "等待 ATT 回调后再初始化第三方 SDK")
        return true
    }

    /// 在 ATT 回调后调用；无论授权结果如何都初始化，但整个生命周期仅执行一次。
    func activateThirdPartyStackIfNeeded(trigger: String) {
        guard !hasActivatedThirdPartyStack else {
            AppLogger.log(.system, tag: "Startup", "第三方 SDK 已初始化，跳过重复触发 trigger=\(trigger)")
            return
        }
        hasActivatedThirdPartyStack = true
        AppLogger.log(.system, tag: "Startup", "开始初始化第三方 SDK trigger=\(trigger)")
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
