import Foundation
import UIKit

/// 广告管理层：负责 adsType 规则判定与 lane 调度（当前版本不含 AdMob）。
final class FluxAdManager {
    static let shared = FluxAdManager()

    private let appCache: QuillAppConfigCache
    private let yIntChannel: FluxYandexIntChannel
    private let emIntChannel: FluxEMIntChannel

    private(set) var mediaVisible = false

    init(
        appCache: QuillAppConfigCache = .shared,
        yIntChannel: FluxYandexIntChannel = FluxYandexIntChannel(),
        emIntChannel: FluxEMIntChannel = FluxEMIntChannel()
    ) {
        self.appCache = appCache
        self.yIntChannel = yIntChannel
        self.emIntChannel = emIntChannel

        self.yIntChannel.onDisplayStateChanged = { [weak self] visible in
            self?.mediaVisible = visible
        }
        self.emIntChannel.onDisplayStateChanged = { [weak self] visible in
            self?.mediaVisible = visible
        }
    }

    /// 按 getconf 的 adsType 决定当前模式：
    /// - 有 e：只走 EM（不回退 y）
    /// - 无 e 但有 y：走原版 Y Int
    /// - 无 e 且无 y：无广告
    func resolveMode() -> FluxAdMode {
        let flags = parseFlags(from: appCache.adsType())
        if flags.contains("e") { return .emInt }
        if flags.contains("y") { return .yandexInt }
        return .none
    }

    private var isAdsEnabled: Bool {
        if WiPurchaseCenter.hasActiveSubscriptionFast() {
            AppLogger.log(.system, tag: "AdMgr", "[总开关] 广告关闭 | reason=vipActive")
            return false
        }
        if !WiATTGate.shared.canLoadAds {
            AppLogger.log(.system, tag: "AdMgr", "广告加载拦截：等待 ATT 结果（新用户）")
            return false
        }
        if appCache.isAdsOff() == true {
            AppLogger.log(.system, tag: "AdMgr", "广告关闭：adsOff=true")
            return false
        }
        return true
    }

    func primeInt(trigger: FluxAdTrigger? = nil, onReady: (() -> Void)? = nil, onFailed: (() -> Void)? = nil) {
        guard isAdsEnabled else {
            onReady?()
            return
        }
        guard !mediaVisible else {
            AppLogger.log(.system, tag: "AdMgr", "已有广告在展示，跳过 preload trigger=\(trigger?.rawValue ?? "nil")")
            onReady?()
            return
        }
        switch resolveMode() {
        case .none:
            AppLogger.log(.system, tag: "AdMgr", "adsType 无可用通道，跳过预加载")
            onReady?()
        case .yandexInt:
            if yIntChannel.hasPayload() {
                onReady?()
                return
            }
            bindCallbacks(for: yIntChannel, onReady: onReady, onFailed: onFailed)
            yIntChannel.requestNext(trigger: trigger)
        case .emInt:
            if emIntChannel.hasPayload() {
                onReady?()
                return
            }
            bindCallbacks(for: emIntChannel, onReady: onReady, onFailed: onFailed)
            emIntChannel.requestNext(trigger: trigger)
        }
    }

    func hasIntPayload() -> Bool {
        guard isAdsEnabled else { return false }
        switch resolveMode() {
        case .none:
            return false
        case .yandexInt:
            return yIntChannel.hasPayload()
        case .emInt:
            return emIntChannel.hasPayload()
        }
    }

    @discardableResult
    func presentIntIfReady(from viewController: UIViewController? = nil, trigger: FluxAdTrigger) -> Bool {
        guard isAdsEnabled else { return false }
        guard !mediaVisible else {
            AppLogger.log(.system, tag: "AdMgr", "已有广告在展示，跳过 present")
            return false
        }
        guard let host = viewController ?? locateHostViewController() else {
            AppLogger.log(.system, tag: "AdMgr", "未找到可用宿主 VC")
            return false
        }

        switch resolveMode() {
        case .none:
            AppLogger.log(.system, tag: "AdMgr", "当前模式无广告，跳过展示")
            return false
        case .yandexInt:
            guard yIntChannel.hasPayload() else { return false }
            yIntChannel.expose(from: host, trigger: trigger)
            return true
        case .emInt:
            guard emIntChannel.hasPayload() else { return false }
            emIntChannel.expose(from: host, trigger: trigger)
            return true
        }
    }

    func clearAll() {
        yIntChannel.dropCurrent()
        emIntChannel.dropCurrent()
        mediaVisible = false
    }

    func hasAnyPayload() -> Bool {
        hasIntPayload()
    }

    private func parseFlags(from adsType: String?) -> Set<String> {
        guard let adsType else { return [] }
        let parts = adsType
            .lowercased()
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Set(parts)
    }

    private func bindCallbacks(for channel: FluxYandexIntChannel, onReady: (() -> Void)?, onFailed: (() -> Void)?) {
        channel.onReady = onReady
        channel.onMiss = onFailed
    }

    private func bindCallbacks(for channel: FluxEMIntChannel, onReady: (() -> Void)?, onFailed: (() -> Void)?) {
        channel.onReady = onReady
        channel.onMiss = onFailed
    }

    private func locateHostViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        guard let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
            return nil
        }
        var root = window.rootViewController
        while let presented = root?.presentedViewController {
            root = presented
        }
        if let nav = root as? UINavigationController {
            return nav.visibleViewController ?? nav
        }
        if let tab = root as? UITabBarController {
            return tab.selectedViewController ?? tab
        }
        return root
    }
}
