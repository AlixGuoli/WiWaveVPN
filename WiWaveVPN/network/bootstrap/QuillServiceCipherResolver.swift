import Foundation

struct QuillServiceDraft {
    let endpointIP: String
    let configMap: [String: Any]
    let plainJSON: String
    let origin: QuillCipherOrigin
}

/// 服务密文解析器：解密 -> JSON 解析 -> 提取服务端 IP。
final class QuillServiceCipherResolver {
    private let rawKey = "f92mUj0K1uBnMlXGFQKrYP07Emgc4yFmWYS8WRgy4IY="
    private let decoder: QuillCipherDecoding

    init(decoder: QuillCipherDecoding = QuillCipherBox()) {
        self.decoder = decoder
    }

    func resolve(cipherText: String, origin: QuillCipherOrigin) -> QuillServiceDraft? {
        guard let plain = decoder.decode(cipherText, key: rawKey) else {
            AppLogger.log(.connection, tag: "Quill", "服务密文解密失败 service cipher decode failed")
            return nil
        }
        guard let data = plain.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let map = obj as? [String: Any] else {
            AppLogger.log(.connection, tag: "Quill", "服务配置解析失败 service profile parse failed")
            return nil
        }
        guard let ip = extractEndpointIP(from: map) else {
            AppLogger.log(.connection, tag: "Quill", "服务配置缺少 IP service profile missing ip")
            return nil
        }
        AppLogger.log(.connection, tag: "Quill", "服务配置解析完成 service profile resolved, ip=\(ip)")
        return QuillServiceDraft(endpointIP: ip, configMap: map, plainJSON: plain, origin: origin)
    }

    private func extractEndpointIP(from map: [String: Any]) -> String? {
        guard let outbounds = map["outbounds"] as? [[String: Any]] else { return nil }
        for outbound in outbounds {
            guard let settings = outbound["settings"] as? [String: Any],
                  let vnext = settings["vnext"] as? [[String: Any]] else { continue }
            for node in vnext {
                if let address = node["address"] as? String, !address.isEmpty {
                    return address
                }
            }
        }
        return nil
    }
}
