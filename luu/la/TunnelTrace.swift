import os
import Foundation

/// Extension 内统一日志子系统（subsystem 用真实 bundle id，避免固定品牌串）。
enum TunnelTrace {
    static let relay = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "tunnel", category: "relay")
    static let provider = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "tunnel", category: "provider")
}
