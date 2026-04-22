import Foundation
import UIKit
import YandexMobileAds

/// 原版 Yandex Int 加载通道：按 key 队列顺序尝试、100 秒超时、关闭后自动预拉下一条。
final class FluxYandexIntChannel: NSObject {
    private let channelTag = "AdY"
    private let timeoutSeconds: TimeInterval = 100

    private var startedAt: Date?
    private var cachedAd: InterstitialAd?
    private var cursor = 0
    private var loading = false
    private var slotIDs: [String] = []
    private var showingAd: InterstitialAd?
    private var loader: InterstitialAdLoader?
    private var loadContinuation: CheckedContinuation<Bool, Never>?

    var onReady: (() -> Void)?
    var onMiss: (() -> Void)?
    var onTap: (() -> Void)?
    var onClosed: (() -> Void)?
    var onDisplayStateChanged: ((Bool) -> Void)?

    func hasPayload() -> Bool {
        cachedAd != nil
    }

    func requestNext(trigger: FluxAdTrigger? = nil) {
        if hasPayload() { return }
        if loading, let begin = startedAt, Date().timeIntervalSince(begin) <= timeoutSeconds { return }
        Task { [weak self] in
            await self?.runQueueLoad(trigger: trigger)
        }
    }

    func expose(from host: UIViewController, trigger: FluxAdTrigger? = nil) {
        guard let ad = cachedAd else {
            AppLogger.log(.system, tag: channelTag, "无可展示广告，忽略 present")
            return
        }
        ad.delegate = self
        ad.show(from: host)
        AppLogger.log(.system, tag: channelTag, "开始展示 Y Int trigger=\(trigger?.rawValue ?? "nil")")
    }

    func dropCurrent() {
        cachedAd = nil
        loader = nil
        AppLogger.log(.system, tag: channelTag, "清空当前缓存")
    }

    private func reloadSlotKeys() {
        slotIDs = QuillAdConfigCache.shared.slotIDs(for: .yandexInterstitial)
        if slotIDs.isEmpty {
            AppLogger.log(.system, tag: channelTag, "未配置 Yandex_Int_List")
        }
    }

    private func runQueueLoad(trigger: FluxAdTrigger?) async {
        reloadSlotKeys()
        cursor = 0
        guard cursor < slotIDs.count else { return }
        loading = true
        startedAt = Date()

        while cursor < slotIDs.count {
            if let begin = startedAt, Date().timeIntervalSince(begin) > timeoutSeconds {
                AppLogger.log(.system, tag: channelTag, "加载超时 \(Int(timeoutSeconds))s")
                loading = false
                finalizeMiss()
                return
            }
            if await tryCurrentSlot(trigger: trigger) { return }
            cursor += 1
        }
        finalizeMiss()
    }

    private func tryCurrentSlot(trigger: FluxAdTrigger?) async -> Bool {
        let adKey = slotIDs[cursor]
        AppLogger.log(.system, tag: channelTag, "开始加载 slot[\(cursor + 1)/\(slotIDs.count)] key=\(adKey), trigger=\(trigger?.rawValue ?? "nil")")
        return await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(returning: false)
                return
            }
            self.loadContinuation = continuation
            DispatchQueue.main.async {
                let slotLoader = InterstitialAdLoader()
                slotLoader.delegate = self
                self.loader = slotLoader
                let request = AdRequestConfiguration(adUnitID: adKey)
                slotLoader.loadAd(with: request)
            }
        }
    }

    private func markReady(_ ad: InterstitialAd) {
        cachedAd = ad
        loading = false
        startedAt = nil
        onReady?()
        loadContinuation?.resume(returning: true)
        loadContinuation = nil
    }

    private func finalizeMiss() {
        cachedAd = nil
        loading = false
        startedAt = nil
        onMiss?()
    }

    private func mediaWillShow() {
        onDisplayStateChanged?(true)
    }

    private func mediaDidDismiss() {
        onDisplayStateChanged?(false)
        showingAd = nil
        cachedAd = nil
        requestNext(trigger: .closeAd)
        onClosed?()
        onClosed = nil
    }
}

extension FluxYandexIntChannel: InterstitialAdLoaderDelegate {
    func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didLoad interstitialAd: InterstitialAd) {
        AppLogger.log(.system, tag: channelTag, "加载成功 key=\(interstitialAd.adInfo?.adUnitId ?? "-")")
        markReady(interstitialAd)
    }

    func interstitialAdLoader(_ adLoader: InterstitialAdLoader, didFailToLoadWithError error: AdRequestError) {
        AppLogger.log(.system, tag: channelTag, "加载失败 error=\(error.error.localizedDescription)")
        loadContinuation?.resume(returning: false)
        loadContinuation = nil
    }
}

extension FluxYandexIntChannel: InterstitialAdDelegate {
    func interstitialAdDidShow(_ ad: InterstitialAd) {
        AppLogger.log(.system, tag: channelTag, "广告已展示")
        mediaWillShow()
        showingAd = ad
        cachedAd = nil
    }

    func interstitialAdDidDismiss(_ ad: InterstitialAd) {
        AppLogger.log(.system, tag: channelTag, "广告已关闭")
        mediaDidDismiss()
    }

    func interstitialAdDidClick(_ ad: InterstitialAd) {
        AppLogger.log(.system, tag: channelTag, "广告被点击")
        onTap?()
    }

    func interstitialAd(_ ad: InterstitialAd, didFailToShowWithError error: Error) {
        AppLogger.log(.system, tag: channelTag, "展示失败 error=\(error.localizedDescription)")
        mediaDidDismiss()
    }
}
