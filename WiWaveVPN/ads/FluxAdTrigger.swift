import Foundation

/// 广告触发时机（仅用于日志与调度标记）。
enum FluxAdTrigger: String {
    case launch = "launch"
    case foreground = "foreground"
    case connect = "connect"
    case disconnect = "disconnect"
    case closeAd = "closead"
    case manual = "manual"
}

enum FluxAdMode: String {
    case none
    case yandexInt
    case emInt
}
