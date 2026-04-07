//
//  RelayPreflightReader.swift
//  luu
//

import Foundation

/// 收取首段 HTTP 响应头，解析 `X-Access-From`（仅预检阶段使用）。
final class RelayPreflightReader {
    private var stash = Data()
    private static let delimiter = "\r\n\r\n".data(using: .utf8)!

    func reset() {
        stash = Data()
    }

    /// 拼满头后返回路由提示；`header` 之后的字节留在内部队列，请再调 `takeQueuedTail()`。
    func ingest(_ chunk: Data) -> String? {
        stash.append(chunk)
        guard let span = stash.range(of: Self.delimiter) else { return nil }
        let headData = stash.subdata(in: 0..<span.lowerBound)
        stash = stash.subdata(in: span.upperBound..<stash.endIndex)
        guard let text = String(data: headData, encoding: .utf8) else { return nil }
        var map = [String: String]()
        for line in text.split(separator: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                let k = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let v = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                map[k] = v
            }
        }
        return map["X-Access-From"]
    }

    func takeQueuedTail() -> Data {
        let t = stash
        stash = Data()
        return t
    }
}
