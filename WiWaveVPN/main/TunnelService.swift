import Foundation
import NetworkExtension

/// 负责与 NETunnelProviderManager 打交道的轻量服务。
final class TunnelService {
    static let shared = TunnelService()

    private let logTag = "TunnelService"

    private(set) var manager: NETunnelProviderManager?

    private init() {}

    // MARK: - 配置

    /// 冷启动时只加载系统里已有配置，不创建新配置（用于恢复 manager 后读真实 NEVPNStatus）。
    func restoreExistingConfiguration(completion: @escaping (_ hasConfig: Bool, _ error: Error?) -> Void) {
        AppLogger.log(.connection, tag: logTag, "restoreExistingConfiguration begin")

        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                AppLogger.log(.connection, tag: self?.logTag ?? "TS", "restore loadAllFromPreferences error: \(error.localizedDescription)")
                completion(false, error)
                return
            }

            guard let self else {
                completion(false, nil)
                return
            }

            guard let first = managers?.first else {
                AppLogger.log(.connection, tag: self.logTag, "no existing VPN configuration in preferences")
                completion(false, nil)
                return
            }

            self.manager = first
            AppLogger.log(.connection, tag: self.logTag, "restored manager from preferences")
            completion(true, nil)
        }
    }

    /// 加载或创建配置。
    func loadOrCreateConfiguration(completion: @escaping (Error?) -> Void) {
        AppLogger.log(.connection, tag: logTag, "loadOrCreateConfiguration begin")

        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                AppLogger.log(.connection, tag: self?.logTag ?? "TS", "loadAllFromPreferences error: \(error.localizedDescription)")
                completion(error)
                return
            }

            guard let self else {
                completion(nil)
                return
            }

            if let existing = managers?.first {
                self.manager = existing
                AppLogger.log(.connection, tag: self.logTag, "reuse existing configuration")
                completion(nil)
                return
            }

            let newManager = NETunnelProviderManager()
            let proto = NETunnelProviderProtocol()

            let displayName = AppDisplayName.fromBundle

            proto.serverAddress = displayName
            newManager.protocolConfiguration = proto
            newManager.localizedDescription = displayName

            newManager.saveToPreferences { error in
                if let error = error {
                    AppLogger.log(.connection, tag: self.logTag, "saveToPreferences(new) error: \(error.localizedDescription)")
                    completion(error)
                    return
                }

                newManager.loadFromPreferences { loadError in
                    if let loadError = loadError {
                        AppLogger.log(.connection, tag: self.logTag, "loadFromPreferences(new) error: \(loadError.localizedDescription)")
                    } else {
                        self.manager = newManager
                        AppLogger.log(.connection, tag: self.logTag, "created new configuration")
                    }
                    completion(loadError)
                }
            }
        }
    }

    /// 启用当前配置。
    func activateConfiguration(completion: @escaping (Error?) -> Void) {
        guard let manager else {
            completion(nil)
            return
        }

        manager.isEnabled = true
        manager.saveToPreferences { error in
            if let error = error {
                AppLogger.log(.connection, tag: "TunnelService", "saveToPreferences(enable) error: \(error.localizedDescription)")
                completion(error)
                return
            }

            manager.loadFromPreferences { loadError in
                if let loadError = loadError {
                    AppLogger.log(.connection, tag: "TunnelService", "loadFromPreferences(enable) error: \(loadError.localizedDescription)")
                }
                completion(loadError)
            }
        }
    }

    // MARK: - 状态 & 控制

    func currentStatus() -> NEVPNStatus {
        manager?.connection.status ?? .invalid
    }

    /// 系统为当前 VPN 会话记录的连通时刻（仅 status 为已连接时通常有值）；冷启动恢复 manager 后仍可读，适用于会话时长。
    func vpnConnectedDate() -> Date? {
        manager?.connection.connectedDate
    }

    func start(completion: @escaping (Error?) -> Void) {
        guard let manager else {
            completion(nil)
            return
        }

        let status = manager.connection.status
        AppLogger.log(.connection, tag: logTag, "start called, current status=\(status.rawValue)")

        guard status == .disconnected || status == .invalid else {
            completion(nil)
            return
        }

        do {
            try manager.connection.startVPNTunnel()
            AppLogger.log(.connection, tag: logTag, "startVPNTunnel invoked")
            completion(nil)
        } catch {
            AppLogger.log(.connection, tag: logTag, "startVPNTunnel error: \(error.localizedDescription)")
            completion(error)
        }
    }

    func stop() {
        guard let manager else { return }
        let status = manager.connection.status
        AppLogger.log(.connection, tag: logTag, "stop called, current status=\(status.rawValue)")
        switch status {
        case .connected, .connecting, .disconnecting, .reasserting:
            manager.connection.stopVPNTunnel()
        default:
            break
        }
    }

    // MARK: - 状态监听

    func observeStatusChanges(_ handler: @escaping (NEVPNStatus) -> Void) {
        NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let status = self?.currentStatus() ?? .invalid
            AppLogger.log(.connection, tag: self?.logTag ?? "TS", "NEVPNStatusDidChange -> \(status.rawValue)")
            handler(status)
        }
    }
}

