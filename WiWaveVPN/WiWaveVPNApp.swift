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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coil)
                .onAppear { coil.boot() }
        }
    }
}
