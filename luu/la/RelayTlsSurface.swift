//
//  RelayTlsSurface.swift
//  luu
//

import Dispatch
import Network

enum RelayTlsSurface {

    static func parametersForPeer(host: String, relaxedAnchor: Bool, verifyQueue: DispatchQueue) -> NWParameters {
        let options = NWProtocolTLS.Options()
        sec_protocol_options_set_tls_server_name(options.securityProtocolOptions, host)
        sec_protocol_options_set_verify_block(
            options.securityProtocolOptions,
            { (_meta, sec_trust, sec_protocol_verify_complete) in
                let trust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
                var err: CFError?
                let ok = SecTrustEvaluateWithError(trust, &err)
                sec_protocol_verify_complete(ok || relaxedAnchor)
            },
            verifyQueue
        )
        return NWParameters(tls: options)
    }

    static func asciiNoiseLabel(length: Int = 5) -> String {
        let pool = "abcdefghijklmnopqrstuvwxyz"
        return String((0..<length).compactMap { _ in pool.randomElement() })
    }
}
