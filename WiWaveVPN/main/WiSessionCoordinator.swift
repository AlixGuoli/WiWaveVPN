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
    /// 与系统 VPN 会话对齐的连通时间（只读供 UI）；断开时为 nil。
    @Published private(set) var tunnelConnectedSince: Date?
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
    private let selectedNodeIDKey = "WiWaveVPN.SelectedServerNodeID"
    private let reporter = QuillPulseReporter.shared
    private var connectSessionID: String?

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
                AppLogger.log(.connection, tag: self.logTag, "启动恢复失败 boot restore failed: \(error.localizedDescription)")
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
        if phase == .online {
            // 旧项目一致：先出断开结果页，再给广告一个短窗口（有缓存时 3s）后再真正断开。
            verdict = .unpluggedOK
            showProgressPage = false
            if FluxAdManager.shared.hasAnyPayload() {
                AppLogger.log(.system, tag: "Ads", "断开流程：检测到广告缓存，延迟 3 秒后断开")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    guard let self, self.userWantsDisconnect else { return }
                    self.phase = .busy
                    self.tunnel.stop()
                }
            } else {
                AppLogger.log(.system, tag: "Ads", "断开流程：无广告缓存，立即断开")
                phase = .busy
                tunnel.stop()
            }
        } else {
            phase = .busy
            verdict = nil
            tunnel.stop()
        }
    }

    func cancelUnplug() {
        showUnplugConfirm = false
        userWantsDisconnect = false
    }

    func clearVerdict() {
        verdict = nil
    }

    /// 进度页兜底超时：仅关闭页面，不影响底层连接流程。
    func handleProgressPageTimeout() {
        AppLogger.log(.connection, tag: logTag, "进度页兜底超时（30s），仅关闭页面，不中断连接")
        showProgressPage = false
    }

    // MARK: - 系统 → 界面

    private func syncCircuitToPhase(_ status: NEVPNStatus) {
        AppLogger.log(.connection, tag: logTag, "circuit=\(status.rawValue)")
        switch status {
        case .connected:
            tunnelConnectedSince = tunnel.vpnConnectedDate()
            if needsPostCheck {
                runPostCheck()
            } else {
                phase = .online
            }
        case .disconnected:
            phase = .offline
            tunnelConnectedSince = nil
            if userWantsDisconnect, verdict == nil {
                verdict = .unpluggedOK
                showProgressPage = false
                userWantsDisconnect = false
            }
            needsPostCheck = false
        case .invalid:
            phase = .offline
            tunnelConnectedSince = nil
            needsPostCheck = false
        case .connecting, .disconnecting, .reasserting:
            phase = .busy
        @unknown default:
            phase = .error
            tunnelConnectedSince = nil
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
                Task { [weak self] in
                    guard let self else { return }
                    self.connectSessionID = nil
                    let groupID = self.currentSelectedServerNodeID()
                    let hasServiceCipher = await QuillServicePreludeFlow().prepare(groupID: groupID, vip: 0)
                    guard hasServiceCipher else {
                        self.reporter.reportServiceStatus(isLive: false)
                        await MainActor.run {
                            self.phase = .error
                            self.verdict = .linkedFail
                            self.showProgressPage = false
                            self.needsPostCheck = false
                        }
                        return
                    }
                    self.reporter.reportServiceStatus(isLive: QuillServiceCipherDepot.shared.origin == .live)
                    guard let routeJSON = QuillServiceCipherDepot.shared.activeRouteJSON, !routeJSON.isEmpty else {
                        AppLogger.log(.connection, tag: self.logTag, "路由配置缺失 route json missing，终止连接")
                        await MainActor.run {
                            self.phase = .error
                            self.verdict = .linkedFail
                            self.showProgressPage = false
                            self.needsPostCheck = false
                        }
                        return
                    }
                    let pushed = WiTunnelBridge.shared.pushRouteConfig(routeJSON)
                    guard pushed else {
                        AppLogger.log(.connection, tag: self.logTag, "桥接下发失败 bridge push failed，终止连接")
                        await MainActor.run {
                            self.phase = .error
                            self.verdict = .linkedFail
                            self.showProgressPage = false
                            self.needsPostCheck = false
                        }
                        return
                    }
                    let sid = QuillPulseReporter.makeSessionToken()
                    self.connectSessionID = sid
                    self.reporter.reportConnectStart(sessionId: sid)
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
    }

    private func currentSelectedServerNodeID() -> Int {
        if UserDefaults.standard.object(forKey: selectedNodeIDKey) == nil {
            return -1
        }
        return UserDefaults.standard.integer(forKey: selectedNodeIDKey)
    }

    // MARK: - 连接后真实探测

    private func runPostCheck() {
        guard !probeBusy else {
            AppLogger.log(.connection, tag: logTag, "探测跳过 postCheck skip（busy）")
            return
        }
        probeBusy = true
        Task { @MainActor in
            AppLogger.log(.connection, tag: self.logTag, "探测开始 postCheck begin（real probe）")
            let ok = await self.probeConnectivity(timeout: 10)
            self.probeBusy = false
            AppLogger.log(.connection, tag: self.logTag, "探测完成 postCheck done, ok=\(ok)")
            if ok {
                self.phase = .online
                self.tunnelConnectedSince = self.tunnel.vpnConnectedDate()
                self.showProgressPage = false
                self.verdict = .linkedOK
                QuillServiceCipherDepot.shared.storeLiveCipherIfNeeded()
                AppLogger.log(.connection, tag: self.logTag, "连接成功后已处理密文缓存 live cipher persisted if needed")
                self.reporter.reportConnectSuccess(sessionId: self.connectSessionID)
            } else {
                self.reporter.reportConnectFailure(sessionId: self.connectSessionID)
                self.tunnel.stop()
                self.phase = .error
                self.showProgressPage = false
                self.verdict = .linkedFail
            }
            self.needsPostCheck = false
        }
    }

    /// 并行探测：任一成功即返回成功；其余请求不取消、自然结束并忽略结果。
    private func probeConnectivity(timeout: TimeInterval) async -> Bool {
        var targets = QuillAppConfigCache.shared.detectionServers() ?? []
        targets = targets.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if targets.isEmpty {
            targets = [
                "https://www.google.com/generate_204",
                "http://cp.cloudflare.com/generate_204",
            ]
            AppLogger.log(.connection, tag: logTag, "探测目标回退 probe targets fallback in use")
        }
        let urls = targets.compactMap(URL.init(string:))
        guard !urls.isEmpty else {
            AppLogger.log(.connection, tag: logTag, "探测目标无效 probe targets invalid")
            return false
        }
        AppLogger.log(.connection, tag: logTag, "探测目标数量 probe targets count=\(urls.count)")

        let stateQueue = DispatchQueue(label: "com.wiwave.probe.state")
        var resolved = false
        var completed = 0
        let total = urls.count

        return await withCheckedContinuation { continuation in
            for url in urls {
                var req = URLRequest(url: url)
                req.timeoutInterval = timeout
                URLSession.shared.dataTask(with: req) { _, response, error in
                    stateQueue.sync {
                        if resolved { return }
                        if error == nil, let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                            resolved = true
                            AppLogger.log(.connection, tag: self.logTag, "探测成功 probe success, url=\(url.absoluteString)")
                            continuation.resume(returning: true)
                            return
                        }
                        completed += 1
                        if completed >= total {
                            resolved = true
                            AppLogger.log(.connection, tag: self.logTag, "探测全失败 probe all failed")
                            continuation.resume(returning: false)
                        }
                    }
                }.resume()
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                stateQueue.sync {
                    if !resolved {
                        resolved = true
                        AppLogger.log(.connection, tag: self.logTag, "探测超时 probe timeout \(Int(timeout))s")
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
}
