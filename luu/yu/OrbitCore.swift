//
//  OrbitCore.swift
//  WiWaveVPN
//
//  Created by ersao on 2026/4/20.
//

import Foundation
import NetworkExtension
import os

class OrbitCore {

    private static let edgeHost = "254.1.1.1"
    private static let mtuNumber: NSNumber = 9000
    private static let laneHost = "198.18.0.1"
    private static let laneMask = "255.255.0.0"
    private static let resolverA = "8.8.8.8"
    private static let resolverB = "114.114.114.114"

    func boot() async throws {
        try await bootInner()
    }

    func halt() {
        haltInner()
    }

    var onCommit: ((NEPacketTunnelNetworkSettings, @escaping (Error?) -> Void) -> Void)?

    private func makeSettings() -> NEPacketTunnelNetworkSettings {
        let laneCfg = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: Self.edgeHost)
        laneCfg.mtu = Self.mtuNumber
        laneCfg.ipv4Settings = makeIPv4()
        laneCfg.dnsSettings = makeDNS()
        return laneCfg
    }

    private func makeIPv4() -> NEIPv4Settings {
        let laneV4 = NEIPv4Settings(addresses: [Self.laneHost], subnetMasks: [Self.laneMask])
        laneV4.includedRoutes = [NEIPv4Route.default()]
        return laneV4
    }

    private func makeDNS() -> NEDNSSettings {
        NEDNSSettings(servers: [Self.resolverA, Self.resolverB])
    }

    private func commit(_ laneCfg: NEPacketTunnelNetworkSettings) {
        onCommit?(laneCfg) { fault in
            if fault != nil {
                os_log("[oc] %{public}@", log: OSLog.default, type: .error, "apply fail: \(fault?.localizedDescription ?? "?")")
            }
        }
    }

    private func bootInner() async throws {
        try await applyLaneInner()
        try runLaneInner()
    }

    private func haltInner() {
        CGoStopBluelink()
    }

    private func applyLaneInner() async throws {
        let draft = makeSettings()
        commit(draft)
    }

    private func runLaneInner() throws {
        try runRelayInner()
        try runKernelInner()
    }

    private func runRelayInner() throws {
        let relayPath = NodeCapsule.composeRelayPath()
        DispatchQueue.global(qos: .userInitiated).async {
            RelayPort.engage(path: relayPath)
        }
    }

    private func runKernelInner() throws {
        let laneDirective = NodeCapsule.composeDirective()
        let encodedSeed = Data(laneDirective.utf8).base64EncodedString()
        guard let bridgePtr = strdup(encodedSeed) else {
            throw NSError(domain: "oc", code: 1, userInfo: [NSLocalizedDescriptionKey: "alloc fail"])
        }
        defer { free(bridgePtr) }
        CGoRunBluelink(UnsafeMutablePointer(mutating: bridgePtr))
    }
}
