import Foundation

/// 上报端点上下文：根据服务配置来源决定是否给 IP 加前缀。
final class QuillReportEndpointContext {
    static let shared = QuillReportEndpointContext()

    private(set) var currentEndpoint: String?

    private init() {}

    func apply(endpointIP: String, origin: QuillCipherOrigin) {
        let final = origin == .live ? endpointIP : "f\(endpointIP)"
        currentEndpoint = final
        if final == endpointIP {
            AppLogger.log(.connection, tag: "Report", "上报端点更新 endpoint updated, source=live, ip=\(final)")
        } else {
            AppLogger.log(.connection, tag: "Report", "上报端点更新 endpoint updated, source=fallback, ip=\(endpointIP)->\(final)")
        }
    }

    func clear() {
        currentEndpoint = nil
    }
}
