//
//  PacketTunnelProvider.swift
//  luu
//
//  Created by ersao on 2026/4/2.
//

import NetworkExtension
import os

class PacketTunnelProvider: NEPacketTunnelProvider {

    //private var velmRelay: VelmRelay?
    
    private var runner: OrbitCore? = nil

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        //bootRelayIfNeeded()
        os_log("[pt] %{public}@", log: OSLog.default, type: .error, "boot begin")
        if !withinBootWindow() {
            let error = NSError(domain: "com.glow.wiwave.vpn.luu", code: 1, userInfo: ["phase": "window reject"])
            self.cancelTunnelWithError(error)
            os_log("[pt] %{public}@", log: OSLog.default, type: .error, "boot reject")
            return
        }
        os_log("[pt] %{public}@", log: OSLog.default, type: .error, "boot pass")
        igniteCorePath()
        completionHandler(nil)
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        //velmRelay?.endRelaySession()
        runner?.halt()
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Add code here to handle the message.
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }
    
    override func wake() {
        // Add code here to wake up.
    }
    
    // MARK: - Legacy Relay
//    private func bootRelayIfNeeded() {
//        os_log("prov.relay %{public}@", log: TunnelTrace.provider, type: .default, "start")
//        if velmRelay == nil {
//            velmRelay = VelmRelay(packetFlow: packetFlow)
//        }
//        velmRelay?.loadNetworkSettings = { [weak self] settings, completion in
//            self?.setTunnelNetworkSettings(settings, completionHandler: completion)
//        }
//        velmRelay?.beginRelaySession()
//    }
    
    // MARK: - Core Path
    private func withinBootWindow() -> Bool {
        if let laneDefaults = UserDefaults(suiteName: FluxLatch.lane),
           let stampAt = laneDefaults.object(forKey: FluxLatch.stampSlot) as? Date {
            let elapsedSec = Date().timeIntervalSince(stampAt)
            if elapsedSec < 10 {
                os_log("[pt] %{public}@", log: OSLog.default, type: .error, "window %.2fs", elapsedSec)
                return true
            }
        }
        return false
    }
    
    private func igniteCorePath() {
        if runner == nil {
            runner = OrbitCore()
        }
        runner?.onCommit = { [weak self] laneCfg, done in
            self?.setTunnelNetworkSettings(laneCfg, completionHandler: done)
        }
        Task {
            do {
                try await runner?.boot()
            } catch {
                os_log("[pt] %{public}@", log: OSLog.default, type: .error, "core fail: \(error.localizedDescription)")
            }
        }
    }
}
