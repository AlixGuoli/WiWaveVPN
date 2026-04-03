import Foundation
import NetworkExtension
import Combine

/// 主界面四种阶段
enum WiPhase {
    case offline
    case busy
    case online
    case error
}

/// 结果页枚举
enum WiVerdict: Hashable {
    case linkedOK
    case linkedFail
    case unpluggedOK
}

/// 主 App 连接会话：把系统 VPN 状态映射为界面阶段与导航所需标志。
final class WiSessionCoordinator: ObservableObject {

    @Published private(set) var phase: WiPhase = .offline
    @Published private(set) var verdict: WiVerdict?
    @Published private(set) var showProgressPage = false
    @Published var showUnplugConfirm = false

    @Published private(set) var circuitStatus: NEVPNStatus = .invalid {
        didSet {
            guard oldValue != circuitStatus else { return }
            syncCircuitToPhase(circuitStatus)
        }
    }

    private let tunnel = TunnelService.shared
    private let logTag = "WiSession"

    private var needsPostCheck = false
    private var userWantsDisconnect = false
    private var probeBusy = false

    init() {
        tunnel.observeStatusChanges { [weak self] status in
            DispatchQueue.main.async {
                self?.circuitStatus = status
            }
        }
        circuitStatus = tunnel.currentStatus()
        // 初始化期间不会触发 didSet，补一次映射以免冷启动 UI 与系统状态脱节。
        syncCircuitToPhase(circuitStatus)
    }

    func boot() {
        tunnel.restoreExistingConfiguration { [weak self] _, error in
            guard let self else { return }
            if let error = error {
                AppLogger.log(.connection, tag: self.logTag, "boot restore: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self.circuitStatus = self.tunnel.currentStatus()
            }
        }
    }

    func tapHero() {
        switch phase {
        case .offline, .error:
            startUserLink()
        case .online:
            showUnplugConfirm = true
        case .busy:
            break
        }
    }

    func confirmUnplug() {
        showUnplugConfirm = false
        userWantsDisconnect = true
        showProgressPage = true
        phase = .busy
        verdict = nil
        tunnel.stop()
    }

    func cancelUnplug() {
        showUnplugConfirm = false
        userWantsDisconnect = false
    }

    func clearVerdict() {
        verdict = nil
    }

    // MARK: - 系统 → 界面

    private func syncCircuitToPhase(_ status: NEVPNStatus) {
        AppLogger.log(.connection, tag: logTag, "circuit=\(status.rawValue)")
        switch status {
        case .connected:
            if needsPostCheck {
                runPostCheck()
            } else {
                phase = .online
            }
        case .disconnected:
            phase = .offline
            if userWantsDisconnect, verdict == nil {
                verdict = .unpluggedOK
                showProgressPage = false
                userWantsDisconnect = false
            }
            needsPostCheck = false
        case .invalid:
            phase = .offline
            needsPostCheck = false
        case .connecting, .disconnecting, .reasserting:
            phase = .busy
        @unknown default:
            phase = .error
            needsPostCheck = false
        }
    }

    // MARK: - 用户连接

    private func startUserLink() {
        verdict = nil
        tunnel.loadOrCreateConfiguration { [weak self] error in
            guard let self else { return }
            if let error = error {
                AppLogger.log(.connection, tag: self.logTag, "prepare: \(error.localizedDescription)")
                return
            }
            self.tunnel.activateConfiguration { [weak self] enableError in
                guard let self else { return }
                if let enableError = enableError {
                    AppLogger.log(.connection, tag: self.logTag, "activate: \(enableError.localizedDescription)")
                    DispatchQueue.main.async {
                        self.phase = .error
                        self.verdict = .linkedFail
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.needsPostCheck = true
                    self.showProgressPage = true
                    self.phase = .busy
                }
                self.tunnel.start { [weak self] startError in
                    guard let self else { return }
                    if let startError = startError {
                        AppLogger.log(.connection, tag: self.logTag, "start: \(startError.localizedDescription)")
                        DispatchQueue.main.async {
                            self.phase = .error
                            self.verdict = .linkedFail
                            self.showProgressPage = false
                            self.needsPostCheck = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - 占位探测（第二版换真探测）

    private func runPostCheck() {
        guard !probeBusy else {
            AppLogger.log(.connection, tag: logTag, "postCheck skip (busy)")
            return
        }
        probeBusy = true
        Task { @MainActor in
            AppLogger.log(.connection, tag: self.logTag, "postCheck sleep 4s")
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            self.probeBusy = false
            let ok = self.tunnel.currentStatus() == .connected
            AppLogger.log(.connection, tag: self.logTag, "postCheck done ok=\(ok)")
            if ok {
                self.phase = .online
                self.showProgressPage = false
                self.verdict = .linkedOK
            } else {
                self.tunnel.stop()
                self.phase = .error
                self.showProgressPage = false
                self.verdict = .linkedFail
            }
            self.needsPostCheck = false
        }
    }
}
