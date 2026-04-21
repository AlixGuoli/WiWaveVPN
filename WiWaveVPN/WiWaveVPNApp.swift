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
    @State private var backgroundFlag = false

    var body: some Scene {
        WindowGroup {
            RootContainerView()
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
}
