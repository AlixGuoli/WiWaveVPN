//
//  VelmRelay.swift
//  luu
//

import Foundation
import NetworkExtension
import os
import Dispatch
import Network

/// 扩展内连接编排：把 TLS 建连、预检、双向泵委托给细分类型。
final class VelmRelay {

    var connection: NWConnection?
    var queue: DispatchQueue?

    /// 本会话使用的对端描述（每次 `beginRelaySession` 刷新）。
    private(set) var profile: RelayPeerProfile = .wiWaveDefault()

    private var sniHost = ""
    private var dialHost = ""
    private var outboundHeaders: [String: String] = [:]

    var loadNetworkSettings: ((NEPacketTunnelNetworkSettings, @escaping (Error?) -> Void) -> Void)?
    let packetFlow: NEPacketTunnelFlow

    private var preflight = RelayPreflightReader()
    private let returnPath = RelayDownlinkDrain()

    init(packetFlow: NEPacketTunnelFlow) {
        self.packetFlow = packetFlow
    }

    func beginRelaySession() {
        preflight = RelayPreflightReader()
        returnPath.reset()
        os_log("relay.tls %{public}@", log: TunnelTrace.relay, type: .default, "begin")

        profile = RelayPeerProfile.wiWaveDefault()
        let resolved = profile.resolvingPeerLabels()
        sniHost = resolved.sniHost
        dialHost = resolved.dialHost
        outboundHeaders = resolved.httpFields

        os_log("relay.sni %{public}@", log: TunnelTrace.relay, type: .default, sniHost)

        let verifyLane = DispatchQueue(label: "\(Bundle.main.bundleIdentifier ?? "ext").tls.peer")
        let proto: NWParameters = profile.isUseTls
            ? RelayTlsSurface.parametersForPeer(host: sniHost, relaxedAnchor: true, verifyQueue: verifyLane)
            : .tcp

        guard let port = NWEndpoint.Port(profile.serverPort) else { return }

        os_log("relay.sni %{public}@", log: TunnelTrace.relay, type: .default, sniHost)

        connection = NWConnection(host: NWEndpoint.Host(dialHost), port: port, using: proto)
        os_log("relay.peer %{public}@", log: TunnelTrace.relay, type: .default, dialHost)

        queue = .global()
        connection?.stateUpdateHandler = { [weak self] st in
            self?.onNwState(st)
        }
        connection?.start(queue: queue!)
    }

    private func onNwState(_ state: NWConnection.State) {
        switch state {
        case .setup:
            os_log("conn %{public}@", log: TunnelTrace.relay, type: .default, "setup")
        case .waiting(_):
            os_log("conn %{public}@", log: TunnelTrace.relay, type: .default, "waiting")
        case .preparing:
            os_log("conn %{public}@", log: TunnelTrace.relay, type: .default, "preparing")
        case .ready:
            os_log("conn %{public}@", log: TunnelTrace.relay, type: .default, "ready")
            negotiateFirstExchange()
        case .failed:
            os_log("conn %{public}@", log: TunnelTrace.relay, type: .default, "failed")
        case .cancelled:
            os_log("conn %{public}@", log: TunnelTrace.relay, type: .default, "cancelled")
        @unknown default:
            os_log("conn %{public}@", log: TunnelTrace.relay, type: .default, "unknown")
        }
    }

    private func negotiateFirstExchange() {
        os_log("relay.negotiate %{public}@", log: TunnelTrace.relay, type: .default, "begin")
        guard let sealed = RelayCipher.sealHandshakeBlob(
            packageName: profile.package,
            version: profile.version,
            sdk: profile.handshakeSdkToken,
            country: profile.country,
            language: profile.language,
            keyString: profile.key
        ) else { return }

        let mask = UInt8(profile.cf_len_int)
        let body = RelayCipher.applyXorShell(payload: sealed, key: Data(profile.cf_key.utf8), maskWidth: mask)
        let advertisedLen = profile.isChunked ? 0 : body.count

        guard let head = RelayUplinkPump.openingPreamble(
            path: profile.path,
            fields: outboundHeaders,
            contentLength: advertisedLen,
            chunked: profile.isChunked
        ) else {
            os_log("post.build %{public}@", log: TunnelTrace.relay, type: .default, "nil-frame")
            return
        }

        connection?.send(content: head, completion: .contentProcessed({ [weak self] err in
            guard let self else { return }
            if err != nil {
                os_log("post.send %{public}@", log: TunnelTrace.relay, type: .error, "failed")
                return
            }
            os_log("post.send %{public}@", log: TunnelTrace.relay, type: .default, "ok")
            self.flushOpeningBody(body)
        }))
    }

    private func flushOpeningBody(_ body: Data) {
        let frame = RelayUplinkPump.singleChunkFrame(body, chunked: profile.isChunked)
        connection?.send(content: frame, completion: .contentProcessed({ [weak self] err in
            if err != nil { return }
            os_log("relay.negotiate %{public}@", log: TunnelTrace.relay, type: .default, "end")
            self?.pullNextPreflightSlice()
        }))
    }

    private func pullNextPreflightSlice() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            guard let self, let data, !data.isEmpty else { return }
            if let routeHint = self.preflight.ingest(data) {
                os_log("hdr.route %{public}@", log: TunnelTrace.relay, type: .default, routeHint)
                let priming = self.preflight.takeQueuedTail()
                self.applyTunnelFace(routeHint, priming: priming)
            } else {
                self.pullNextPreflightSlice()
            }
        }
    }

    private func applyTunnelFace(_ intranetIP: String, priming: Data) {
        let face = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.10.0.1")
        face.mtu = 1400
        face.dnsSettings = NEDNSSettings(servers: ["8.8.8.8"])
        face.ipv4Settings = {
            let v4 = NEIPv4Settings(addresses: [intranetIP], subnetMasks: ["255.255.0.0"])
            v4.includedRoutes = [NEIPv4Route.default()]
            return v4
        }()

        loadNetworkSettings?(face) { [weak self] err in
            guard let self, err == nil else { return }
            if !priming.isEmpty {
                let key = Data(self.profile.cf_key.utf8)
                self.returnPath.push(priming, modeChunked: self.profile.isChunked, xorKey: key, into: self.packetFlow)
            }
            self.armReturnPath()
            self.armForwardPath()
        }
    }

    private func armReturnPath() {
        connection?.receive(minimumIncompleteLength: 1024, maximumLength: 65535) { [weak self] data, _, _, _ in
            guard let self else { return }
            if let data, !data.isEmpty {
                self.returnPath.push(
                    data,
                    modeChunked: self.profile.isChunked,
                    xorKey: Data(self.profile.cf_key.utf8),
                    into: self.packetFlow
                )
            }
            self.armReturnPath()
        }
    }

    private func armForwardPath() {
        packetFlow.readPackets { [weak self] packets, _ in
            guard let self else { return }
            let key = Data(self.profile.cf_key.utf8)
            let mask = UInt8(self.profile.cf_len_int)
            let batches = RelayUplinkPump.wireBatch(
                packets: packets,
                path: self.profile.path,
                fields: self.outboundHeaders,
                chunked: self.profile.isChunked,
                xorKey: key,
                maskWidth: mask
            )
            for blob in batches {
                self.connection?.send(content: blob, completion: .contentProcessed { _ in })
            }
            self.armForwardPath()
        }
    }

    func endRelaySession() {
        connection?.cancel()
    }
}
