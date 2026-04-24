//
//  WiWaveVPNApp.swift
//  WiWaveVPN
//
//  Created by ersao on 2026/4/1.
//

import SwiftUI

@main
struct WiWaveVPNApp: App {
    @UIApplicationDelegateAdaptor(WiAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var coil = WiSessionCoordinator()
    @StateObject private var launchGate = AppLaunchGate()
    @StateObject private var appLanguage = AppLanguageStore()
    @StateObject private var nodes = NodeSelectionStore()
    @StateObject private var purchaseCenter = WiPurchaseCenter.shared
    @State private var backgroundFlag = false
    @State private var resumeOverlayActive = false
    @State private var isColdSplashVisible = true
    @State private var didAttemptLaunchAdPresent = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootContainerView(
                    onPrivacyAccepted: { completion in
                        resolveTrackingGateAfterPrivacy(completion: completion)
                    },
                    onExistingUserSplashFinish: {
                        presentLaunchAdAtSplashExit()
                    },
                    onColdSplashVisibilityChanged: { visible in
                        isColdSplashVisible = visible
                    }
                )
                .environmentObject(coil)
                .environmentObject(launchGate)
                .environmentObject(nodes)
                .environmentObject(appLanguage)
                .environmentObject(purchaseCenter)
                .environment(\.locale, appLanguage.localeForSwiftUI)
                .onAppear { coil.boot() }
                .onChange(of: scenePhase) { newPhase in
                    processScenePhaseChange(newPhase)
                }

                if resumeOverlayActive {
                    ForegroundResumeMaskView()
                        .environmentObject(appLanguage)
                        .background(Color(UIColor.systemBackground).opacity(1.0))
                        .ignoresSafeArea()
                        .onAppear {
                            AppLogger.log(.system, tag: "Ads", "后台覆盖页显示")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                presentReturnOverlayAd()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                resumeOverlayActive = false
                            }
                        }
                        .zIndex(9999)
                }
            }
        }
    }

    private func processScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            enforceMembershipPolicyOnActive()
            handleForegroundReturn()
        case .inactive:
            break
        case .background:
            AppLogger.log(.connection, tag: "App", "切后台")
            backgroundFlag = true
        @unknown default:
            break
        }
    }

    /// active 事件第一时间执行：刷新会员态，并按策略处理非会员的手动节点与在线状态。
    private func enforceMembershipPolicyOnActive() {
        Task {
            AppLogger.log(.system, tag: "IAP", "[前台] 会员策略检查开始 | step=refreshThenEnforce")
            await purchaseCenter.refreshSubscriptionState()
            let isMember = purchaseCenter.hasActiveSubscriptionNow
            guard !isMember else {
                AppLogger.log(.system, tag: "IAP", "[前台] 会员策略检查完成 | member=true, noAction")
                return
            }
            let switchedToAuto = nodes.forceAutoSelectionIfPossible()
            if switchedToAuto {
                AppLogger.log(.system, tag: "IAP", "[前台] 非会员策略：节点已强制切回 auto")
            }
            if switchedToAuto && coil.phase == .online {
                AppLogger.log(.system, tag: "IAP", "[前台] 非会员策略：当前在线且原手动节点，执行静默断开")
                coil.performSilentDisconnectForMembershipPolicy()
            }
        }
    }

    /// 仅在后台回前台时按旧规则检查配置过期并触发刷新。
    private func handleForegroundReturn() {
        guard backgroundFlag else { return }
        guard !isColdSplashVisible else {
            AppLogger.log(.system, tag: "Ads", "启动页阶段回前台，跳过 foreground 广告链路")
            backgroundFlag = false
            return
        }
        Task {
            AppLogger.log(.system, tag: "IAP", "[前台] 开始前台链路 | step=refreshSubscriptionFirst")
            await purchaseCenter.refreshSubscriptionState()
            QuillForegroundRefreshScheduler.shared.refreshIfNeeded()
            if FluxAdManager.shared.mediaVisible {
                AppLogger.log(.system, tag: "Ads", "已有广告展示中，回前台跳过 foreground 预加载与覆盖页")
                backgroundFlag = false
                return
            }
            FluxAdManager.shared.primeInt(trigger: .foreground)
            if shouldShowReturnOverlay() {
                AppLogger.log(.system, tag: "Ads", "显示后台覆盖页")
                resumeOverlayActive = true
            }
            backgroundFlag = false
        }
    }

    /// 启动页切主页时尝试展示：与旧项目时机一致，没缓存则直接进主页。
    private func presentLaunchAdAtSplashExit() {
        guard !didAttemptLaunchAdPresent else { return }
        didAttemptLaunchAdPresent = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let shown = FluxAdManager.shared.presentIntIfReady(trigger: .launch)
            AppLogger.log(.system, tag: "Ads", "启动页切主页展示结果 shown=\(shown)")
        }
    }

    private func shouldShowReturnOverlay() -> Bool {
        guard launchGate.hasCompletedOnboarding else {
            AppLogger.log(.system, tag: "Ads", "首装未完成，跳过后台覆盖页")
            return false
        }
        if coil.phase == .busy {
            AppLogger.log(.system, tag: "Ads", "当前连接流程忙碌，跳过后台覆盖页")
            return false
        }
        if FluxAdManager.shared.mediaVisible {
            AppLogger.log(.system, tag: "Ads", "已有广告在展示，跳过后台覆盖页")
            return false
        }
        guard FluxAdManager.shared.hasIntPayload() else {
            AppLogger.log(.system, tag: "Ads", "无可用广告缓存，跳过后台覆盖页")
            return false
        }
        return true
    }

    private func presentReturnOverlayAd() {
        guard launchGate.hasCompletedOnboarding else {
            AppLogger.log(.system, tag: "Ads", "首装未完成，跳过后台覆盖页广告展示")
            return
        }
        let shown = FluxAdManager.shared.presentIntIfReady(trigger: .foreground)
        if shown {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                resumeOverlayActive = false
            }
        } else {
            AppLogger.log(.system, tag: "Ads", "后台覆盖页无广告可展示，等待兜底关闭")
        }
    }

    private func resolveTrackingGateAfterPrivacy(completion: @escaping () -> Void) {
        WiATTGate.shared.resolveTrackingIfNeededForFreshUser {
            appDelegate.initializeThirdPartyStacksIfNeeded()
            completion()
        }
    }
}

