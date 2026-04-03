import Foundation

enum LogChannel: String {
    case system = "SYS"
    case connection = "CONN"
}

enum AppLogger {
    private static let prefix = "[WiWaveVPN]"

    static func log(_ channel: LogChannel = .system, tag: String, _ message: String) {
        let line = "\(prefix)[\(channel.rawValue)][\(tag)] \(message)"
        print(line)
    }
}

