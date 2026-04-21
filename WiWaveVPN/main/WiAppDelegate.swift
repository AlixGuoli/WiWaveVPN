import UIKit
import GameAnalytics

final class WiAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        activateSignalStack()
        return true
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
}
