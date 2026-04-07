//
//  RelayUplinkPump.swift
//  luu
//

import Foundation

/// TUN 包 → HTTP 载体（chunk 或定长正文）的编码。
enum RelayUplinkPump {

    static func openingPreamble(
        path: String,
        fields: [String: String],
        contentLength: Int,
        chunked: Bool
    ) -> Data? {
        var lines = "POST \(path) HTTP/1.1\r\n"
        for (k, v) in fields {
            lines += "\(k): \(v)\r\n"
        }
        if chunked {
            lines += "Transfer-Encoding: chunked\r\n"
        } else {
            lines += "Content-Length: \(contentLength)\r\n"
        }
        lines += "\r\n"
        return lines.data(using: .utf8)
    }

    /// 每个 TUN 包对应一条待发 TCP 负载（与原实现逐包 `send` 一致）。
    static func wireBatch(
        packets: [Data],
        path: String,
        fields: [String: String],
        chunked: Bool,
        xorKey: Data,
        maskWidth: UInt8
    ) -> [Data] {
        var out: [Data] = []
        for pkt in packets {
            let enc = RelayCipher.applyXorShell(payload: pkt, key: xorKey, maskWidth: maskWidth)
            let n = enc.count
            if chunked {
                var blob = Data()
                let hex = String(n, radix: 16)
                blob.append("\(hex)\r\n".data(using: .utf8)!)
                blob.append(enc)
                blob.append("\r\n".data(using: .utf8)!)
                out.append(blob)
            } else {
                var head = "POST \(path) HTTP/1.1\r\n"
                for (k, v) in fields {
                    head += "\(k): \(v)\r\n"
                }
                head += "Content-Length: \(n)\r\n\r\n"
                var blob = head.data(using: .utf8)!
                blob.append(enc)
                out.append(blob)
            }
        }
        return out
    }

    static func singleChunkFrame(_ body: Data, chunked: Bool) -> Data {
        if chunked {
            var blob = Data()
            let hex = String(body.count, radix: 16)
            blob.append("\(hex)\r\n".data(using: .utf8)!)
            blob.append(body)
            blob.append("\r\n".data(using: .utf8)!)
            return blob
        }
        return body
    }
}
