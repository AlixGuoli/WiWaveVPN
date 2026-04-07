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

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        bootRelayIfNeeded()
        completionHandler(nil)
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        velmRelay?.endRelaySession()
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
}
