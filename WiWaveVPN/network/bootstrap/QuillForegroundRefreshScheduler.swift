import Foundation

/// 复用旧项目规则：后台回前台时检查缓存阈值，基础配置 6 小时、广告配置 4 小时。
final class QuillForegroundRefreshScheduler {
    static let shared = QuillForegroundRefreshScheduler()

    private let probe: QuillProbe
    private let appCache: QuillAppConfigCache
    private let adCache: QuillAdConfigCache

    private init(
        probe: QuillProbe = QuillProbe(),
        appCache: QuillAppConfigCache = .shared,
        adCache: QuillAdConfigCache = .shared
    ) {
        self.probe = probe
        self.appCache = appCache
        self.adCache = adCache
    }

    func refreshIfNeeded(
        baseExpiry: TimeInterval = 6 * 3600,
        adsExpiry: TimeInterval = 4 * 3600
    ) {
        refreshConfigIfNeeded(
            lastSave: appCache.lastUpdateTime(),
            expiry: baseExpiry,
            configName: "基础配置(getconf)"
        ) { [probe] in
            await probe.pingGetconfAndLog()
        }

        refreshConfigIfNeeded(
            lastSave: adCache.lastUpdateTime(),
            expiry: adsExpiry,
            configName: "广告配置(adsettings)"
        ) { [probe] in
            await probe.pingAdsettingsAndLog()
        }
    }

    private func refreshConfigIfNeeded(
        lastSave: Date?,
        expiry: TimeInterval,
        configName: String,
        refreshAction: @escaping () async -> Void
    ) {
        let now = Date()
        if let ts = lastSave {
            if now.timeIntervalSince(ts) >= expiry {
                AppLogger.log(.connection, tag: "Quill", "[Foreground] \(configName) 超过阈值，触发刷新")
                Task { await refreshAction() }
            }
        } else {
            AppLogger.log(.connection, tag: "Quill", "[Foreground] \(configName) 无时间戳，首次拉取")
            Task { await refreshAction() }
        }
    }
}
