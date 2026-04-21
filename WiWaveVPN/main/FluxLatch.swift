import Foundation

/// 主 app / target 共享桥接键（使用抽象命名，避免复用旧项目标识）。
enum FluxLatch {
    static let lane = "group.com.glow.wiwave.vpn"
    static let payloadSlot = "fr_payload_box_v2"
    static let stampSlot = "fr_payload_mark_v2"
}
