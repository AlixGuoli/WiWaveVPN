//
//  WiWaveVPNApp.swift
//  WiWaveVPN
//
//  Created by ersao on 2026/4/1.
//

import SwiftUI

@main
struct WiWaveVPNApp: App {
    @StateObject private var coil = WiSessionCoordinator()
    @StateObject private var launchGate = AppLaunchGate()
    @StateObject private var appLanguage = AppLanguageStore()
    @StateObject private var nodes = NodeSelectionStore()

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(coil)
                .environmentObject(launchGate)
                .environmentObject(nodes)
                .environmentObject(appLanguage)
                .environment(\.locale, appLanguage.localeForSwiftUI)
                .onAppear { coil.boot() }
        }
    }
}
