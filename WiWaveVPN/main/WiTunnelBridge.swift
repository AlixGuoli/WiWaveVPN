import Foundation

/// 主 app <-> target 的最小桥接层：
/// - 主 app 写配置
/// - target 读配置
/// - 双方通过 App Group UserDefaults 交互
final class WiTunnelBridge {
    static let shared = WiTunnelBridge()

    private init() {}

    /// 写入最终路由 JSON 到 App Group，供 target 读取。
    @discardableResult
    func pushRouteConfig(_ json: String) -> Bool {
        guard !json.isEmpty else {
            AppLogger.log(.connection, tag: "Bridge", "桥接写入失败 bridge write failed（empty json）")
            return false
        }
        guard let ud = UserDefaults(suiteName: FluxLatch.lane) else {
            AppLogger.log(.connection, tag: "Bridge", "桥接写入失败 bridge write failed（suite unavailable）")
            return false
        }

        let now = Date()
        ud.set(json, forKey: FluxLatch.payloadSlot)
        ud.set(now, forKey: FluxLatch.stampSlot)
        ud.synchronize()

        AppLogger.log(
            .connection,
            tag: "Bridge",
            "桥接写入成功 bridge write ok, bytes=\(json.utf8.count), ts=\(now)"
        )
        return true
    }

    /// 读取当前桥接配置（主 app 调试可用，target 也读同一 key）。
    func pullRouteConfig() -> String? {
        guard let ud = UserDefaults(suiteName: FluxLatch.lane) else {
            AppLogger.log(.connection, tag: "Bridge", "桥接读取失败 bridge read failed（suite unavailable）")
            return nil
        }
        return ud.string(forKey: FluxLatch.payloadSlot)
    }

    func lastPushedAt() -> Date? {
        guard let ud = UserDefaults(suiteName: FluxLatch.lane) else {
            return nil
        }
        return ud.object(forKey: FluxLatch.stampSlot) as? Date
    }

    /// 清空桥接配置（联调时可用）。
    func clearRouteConfig() {
        guard let ud = UserDefaults(suiteName: FluxLatch.lane) else { return }
        ud.removeObject(forKey: FluxLatch.payloadSlot)
        ud.removeObject(forKey: FluxLatch.stampSlot)
        ud.synchronize()
        AppLogger.log(.connection, tag: "Bridge", "桥接配置已清空 bridge config cleared")
    }
}
