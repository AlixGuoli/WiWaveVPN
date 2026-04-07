//
//  RelayDownlinkDrain.swift
//  luu
//

import Foundation
import NetworkExtension

/// 将 socket → TUN 的字节流按 chunked / Content-Length 拆包并解 XOR 壳。
final class RelayDownlinkDrain {
    private var pending = Data()
    private var fieldScratch = [String: String]()
    private var scanningHeader = true
    private var bytesRemaining = 0
    private let headerBoundary: Data

    init() {
        headerBoundary = "\r\n\r\n".data(using: .ascii)!
    }

    func reset() {
        pending = Data()
        fieldScratch = [:]
        scanningHeader = true
        bytesRemaining = 0
    }

    func push(_ bytes: Data, modeChunked: Bool, xorKey: Data, into flow: NEPacketTunnelFlow) {
        pending.append(bytes)
        if modeChunked {
            drainChunked(xorKey: xorKey, flow: flow)
        } else {
            drainContentLength(xorKey: xorKey, flow: flow)
        }
    }

    private func drainChunked(xorKey: Data, flow: NEPacketTunnelFlow) {
        var cursor = pending.startIndex

        if pending.count >= 2 && pending[cursor] == 0x0D && pending[cursor + 1] == 0x0A {
            cursor += 2
        }

        while cursor < pending.count {
            guard let sizeRange = pending.range(of: Data("\r\n".utf8), options: [], in: cursor..<pending.count),
                  let sizeText = String(data: pending.subdata(in: cursor..<sizeRange.lowerBound), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let chunkSize = Int(sizeText, radix: 16) else {
                break
            }

            if chunkSize == 0 {
                let endIdx = sizeRange.upperBound + 2
                if endIdx <= pending.count {
                    pending.removeSubrange(pending.startIndex..<endIdx)
                }
                break
            }

            let bodyStart = sizeRange.upperBound
            let bodyEnd = bodyStart + chunkSize
            guard bodyEnd <= pending.count else { break }

            let rawChunk = pending.subdata(in: bodyStart..<bodyEnd)
            let ipPacket = RelayCipher.stripXorShell(data: rawChunk, key: xorKey)
            flow.writePackets([ipPacket], withProtocols: [AF_INET as NSNumber])

            cursor = bodyEnd
            if cursor + 2 > pending.count { break }

            if pending[cursor] == 0x0D && pending[cursor + 1] == 0x0A {
                cursor += 2
            } else {
                break
            }
        }

        pending.removeSubrange(pending.startIndex..<cursor)
    }

    private func drainContentLength(xorKey: Data, flow: NEPacketTunnelFlow) {
        if scanningHeader, let span = pending.range(of: headerBoundary) {
            let headerBlob = pending.subdata(in: 0..<span.lowerBound)
            if let headerText = String(data: headerBlob, encoding: .ascii) {
                for line in headerText.split(separator: "\r\n") {
                    let parts = line.components(separatedBy: ": ")
                    if parts.count >= 2 {
                        let k = parts[0]
                        let v = parts[1...].joined(separator: ": ")
                        fieldScratch[k] = v
                    }
                }
                if let lenText = fieldScratch["Content-Length"], let n = Int(lenText) {
                    bytesRemaining = n
                    scanningHeader = false
                }
                pending.removeSubrange(0..<span.upperBound)
            }
        }

        if !scanningHeader, bytesRemaining > 0, pending.count >= bytesRemaining {
            let body = pending.subdata(in: 0..<bytesRemaining)
            let ipPacket = RelayCipher.stripXorShell(data: body, key: xorKey)
            flow.writePackets([ipPacket], withProtocols: [AF_INET as NSNumber])

            pending.removeSubrange(0..<bytesRemaining)
            bytesRemaining = 0
            scanningHeader = true
            if !pending.isEmpty {
                drainContentLength(xorKey: xorKey, flow: flow)
            }
        }
    }
}
