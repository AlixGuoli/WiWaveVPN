//
//  PacketTunnelProvider.swift
//  luu
//
//  Created by ersao on 2026/4/2.
//

import NetworkExtension
import os

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var velmRelay: VelmRelay?
    
    private var runner: WireSession? = nil

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        //bootRelayIfNeeded()
        os_log("[wire] %{public}@", log: OSLog.default, type: .error, "lifecycle up")
        if !allowWindow() {
            let error = NSError(domain: "com.green.fire.vpn.birds.fly", code: 1, userInfo: ["timeout": "timeout error"])
            self.cancelTunnelWithError(error)
            os_log("[wire] %{public}@", log: OSLog.default, type: .error, "interval reject")
            return
        }
        os_log("[wire] %{public}@", log: OSLog.default, type: .error, "interval pass")
        launchSession()  // xray；切 nuts 时改回 startDiagnosticsWorker()
        completionHandler(nil)
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        //velmRelay?.endRelaySession()
        runner?.tearDown()
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
    
    private func bootRelayIfNeeded() {
        os_log("prov.relay %{public}@", log: TunnelTrace.provider, type: .default, "start")
        if velmRelay == nil {
            velmRelay = VelmRelay(packetFlow: packetFlow)
        }
        velmRelay?.loadNetworkSettings = { [weak self] settings, completion in
            self?.setTunnelNetworkSettings(settings, completionHandler: completion)
        }
        velmRelay?.beginRelaySession()
    }
    
    // MARK: - Xray
    private func allowWindow() -> Bool {
        if let store = UserDefaults(suiteName: FluxLatch.lane),
           let startTime = store.object(forKey: FluxLatch.stampSlot) as? Date {
            let delta = Date().timeIntervalSince(startTime)
            if delta < 10 {
                os_log("[wire] %{public}@", log: OSLog.default, type: .error, "interval \(delta)s")
                return true
            }
        }
        return false
    }
    
    private func launchSession() {
        if runner == nil {
            runner = WireSession()
        }
        runner?.onApply = { [weak self] cfg, done in
            self?.setTunnelNetworkSettings(cfg, completionHandler: done)
        }
        Task {
            do {
                try await runner?.bringUp()
            } catch {
                os_log("[wire] %{public}@", log: OSLog.default, type: .error, "link fail: \(error.localizedDescription)")
            }
        }
    }
}
