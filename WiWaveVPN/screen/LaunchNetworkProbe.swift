import Foundation
import Network

/// 启动阶段：用系统路径监视判断当前网络类型（Wi‑Fi / 蜂窝等）。
enum LaunchNetworkProbe {

    enum PathKind: String {
        case wifi
        case cellular
        case wiredEthernet
        case other
        case unsatisfied
    }

    static func classifyCurrentPath() async -> PathKind {
        await withCheckedContinuation { cont in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                let kind: PathKind
                if path.status != .satisfied {
                    kind = .unsatisfied
                } else if path.usesInterfaceType(.wifi) {
                    kind = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    kind = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    kind = .wiredEthernet
                } else {
                    kind = .other
                }
                cont.resume(returning: kind)
            }
            monitor.start(queue: .global(qos: .utility))
        }
    }
}
