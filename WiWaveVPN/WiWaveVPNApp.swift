//
//  WiWaveVPNApp.swift
//  WiWaveVPN
//
//  Created by ersao on 2026/4/1.
//

import SwiftUI
import AppTrackingTransparency

@main
struct WiWaveVPNApp: App {
    @UIApplicationDelegateAdaptor(WiAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var coil = WiSessionCoordinator()
    @StateObject private var launchGate = AppLaunchGate()
    @StateObject private var appLanguage = AppLanguageStore()
    @StateObject private var nodes = NodeSelectionStore()
    @State private var backgroundFlag = false
    @State private var didResolveATTGate = false

    var body: some Scene {
        WindowGroup {
            RootContainerView(
                onPrivacyAccepted: { completion in
                    resolveATTGateAndBootstrap(trigger: "onboarding_agree", completion: completion)
                },
                onExistingUserLaunch: {
                    resolveATTGateAndBootstrap(trigger: "existing_user_launch")
                }
            )
                .environmentObject(coil)
                .environmentObject(launchGate)
                .environmentObject(nodes)
                .environmentObject(appLanguage)
                .environment(\.locale, appLanguage.localeForSwiftUI)
                .onAppear { coil.boot() }
                .onChange(of: scenePhase) { newPhase in
                    processScenePhaseChange(newPhase)
                }
        }
    }

    private func processScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
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

    /// 仅在后台回前台时按旧规则检查配置过期并触发刷新。
    private func handleForegroundReturn() {
        guard backgroundFlag else { return }
        QuillForegroundRefreshScheduler.shared.refreshIfNeeded()
        backgroundFlag = false
    }

    /// ATT 是初始化前置闸门：隐私同意后调用；无论授权结果如何都继续初始化。
    private func resolveATTGateAndBootstrap(trigger: String, completion: (() -> Void)? = nil) {
        guard !didResolveATTGate else {
            appDelegate.activateThirdPartyStackIfNeeded(trigger: "\(trigger)_reenter")
            completion?()
            return
        }

        didResolveATTGate = true

        let finalize: (_ attStatus: String) -> Void = { attStatus in
            AppLogger.log(.system, tag: "ATT", "ATT resolved status=\(attStatus), trigger=\(trigger)")
            appDelegate.activateThirdPartyStackIfNeeded(trigger: trigger)
            completion?()
        }

        guard #available(iOS 14, *) else {
            finalize("unavailable")
            return
        }

        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                let label: String
                switch status {
                case .authorized: label = "authorized"
                case .denied: label = "denied"
                case .restricted: label = "restricted"
                case .notDetermined: label = "notDetermined"
                @unknown default: label = "unknown"
                }
                finalize(label)
            }
        }
    }
}
