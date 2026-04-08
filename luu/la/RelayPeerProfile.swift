//
//  RelayPeerProfile.swift
//  luu
//

import Foundation

/// 对端与握手相关参数（与连接/IO 状态分离）。
struct RelayPeerProfile {
    var domain: String
    var ip: String
    var serverPort: String

    var country: String
    var language: String
    var package: String
    var version: String
    var key: String

    var path: String
    var isChunked: Bool
    var isUseTls: Bool
    var cf: Bool
    var wildcard: Bool

    var cf_key: String
    var cf_len_int: Int

    /// 固定请求头（不含动态 `Host`）。
    var baseHTTPFields: [String: String]

    /// 写入握手 JSON 的 `SDK` 字段。
    var handshakeSdkToken: String

    /// 默认生产配置；`patching` 便于单测或多环境覆写。
    static func wiWaveDefault(patching: ((inout RelayPeerProfile) -> Void)? = nil) -> RelayPeerProfile {
        var profile = RelayPeerProfile(
            domain: "hp.com",
            ip: "64.176.43.209",
            serverPort: "49155",
            country: "sg",
            language: "en-SG",
            package: "com.glow.wiwave.vpn.luu",
            version: "1.0.0",
            key: "3e027e48ec6f5a9c705dfe17bed37201",
            path: "",
            isChunked: true,
            isUseTls: true,
            cf: false,
            wildcard: false,
            cf_key: "hfor1",
            cf_len_int: 32,
            baseHTTPFields: [
                "User-Agent": "WiWaveTunnel/1 CFNetwork Darwin",
                "Content-Type": "application/json",
            ],
            handshakeSdkToken: "7.0"
        )
        patching?(&profile)
        return profile
    }

    func resolvingPeerLabels() -> (sniHost: String, dialHost: String, httpFields: [String: String]) {
        let sni = wildcard ? "\(RelayTlsSurface.asciiNoiseLabel()).\(domain)" : domain
        let dial = ip.isEmpty ? sni : ip
        var fields = baseHTTPFields
        if !cf && !isUseTls {
            fields["Host"] = sni
        }
        return (sni, dial, fields)
    }
}
