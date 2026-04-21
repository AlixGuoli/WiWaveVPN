import Foundation

enum QuillProbeResult {
    case success(bytes: Int, elapsedMs: Int)
    case failure(error: QuillError, elapsedMs: Int)
}

enum QuillRouteCatalog {
    static let getconf = QuillEndpoint(path: "/academy/config/curriculum")
    static let adsettings = QuillEndpoint(path: "/academy/ads/sponsor")
    static let category = QuillEndpoint(path: "/academy/category/subject")
    static let serviceProfile = QuillEndpoint(path: "/academy/service/lesson")
}

final class QuillProbe {
    private let gateway: QuillGateway
    private let vault: QuillDomainVaulting
    private let cache: QuillAppConfigCache
    private let adCache: QuillAdConfigCache

    init(
        gateway: QuillGateway = QuillGateway(),
        vault: QuillDomainVaulting = QuillDomainVault.shared,
        cache: QuillAppConfigCache = .shared,
        adCache: QuillAdConfigCache = .shared
    ) {
        self.gateway = gateway
        self.vault = vault
        self.cache = cache
        self.adCache = adCache
    }

    func pingGetconf() async -> QuillProbeResult {
        AppLogger.log(.connection, tag: "Quill", "开始探测 getconf / probe start")
        let start = Date()
        let result = await gateway.request(QuillRouteCatalog.getconf)
        let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
        switch result {
        case .success(let body):
            await processGetconfResponse(body)
            return .success(bytes: body.utf8.count, elapsedMs: elapsedMs)
        case .failure(let err):
            return .failure(error: err, elapsedMs: elapsedMs)
        }
    }

    func pingGetconfAndLog() async {
        switch await pingGetconf() {
        case .success(let bytes, let elapsedMs):
            AppLogger.log(.connection, tag: "Launch", "getconf ok in \(elapsedMs)ms, bytes=\(bytes)")
        case .failure(_, let elapsedMs):
            AppLogger.log(.connection, tag: "Launch", "getconf failed in \(elapsedMs)ms")
        }
    }

    func pingAdsettings() async -> QuillProbeResult {
        AppLogger.log(.connection, tag: "Quill", "开始探测 adsettings / probe start")
        let start = Date()
        let result = await gateway.request(QuillRouteCatalog.adsettings)
        let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
        switch result {
        case .success(let body):
            adCache.keep(body)
            return .success(bytes: body.utf8.count, elapsedMs: elapsedMs)
        case .failure(let err):
            return .failure(error: err, elapsedMs: elapsedMs)
        }
    }

    func pingAdsettingsAndLog() async {
        switch await pingAdsettings() {
        case .success(let bytes, let elapsedMs):
            AppLogger.log(.connection, tag: "Launch", "adsettings ok in \(elapsedMs)ms, bytes=\(bytes)")
        case .failure(_, let elapsedMs):
            AppLogger.log(.connection, tag: "Launch", "adsettings failed in \(elapsedMs)ms")
        }
    }

    func pingCategory() async -> QuillProbeResult {
        AppLogger.log(.connection, tag: "Quill", "开始探测 category / probe start")
        let start = Date()
        let result = await gateway.request(QuillRouteCatalog.category)
        let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
        switch result {
        case .success(let body):
            return .success(bytes: body.utf8.count, elapsedMs: elapsedMs)
        case .failure(let err):
            return .failure(error: err, elapsedMs: elapsedMs)
        }
    }

    func pingCategoryAndLog() async -> String? {
        let start = Date()
        let result = await gateway.request(QuillRouteCatalog.category)
        let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
        switch result {
        case .success(let body):
            AppLogger.log(.connection, tag: "Launch", "category ok in \(elapsedMs)ms, bytes=\(body.utf8.count)")
            return body
        case .failure:
            AppLogger.log(.connection, tag: "Launch", "category failed in \(elapsedMs)ms")
            return nil
        }
    }

    func pingServiceProfileAndLog(groupID: Int, vip: Int = 0) async -> String? {
        let params = [
            "group": String(groupID),
            "vip": String(vip),
        ]
        AppLogger.log(
            .connection,
            tag: "Quill",
            "开始探测 service profile / probe start, group=\(groupID), vip=\(vip)"
        )
        let start = Date()
        let result = await gateway.request(QuillEndpoint(path: QuillRouteCatalog.serviceProfile.path, extraQuery: params))
        let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
        switch result {
        case .success(let body):
            AppLogger.log(.connection, tag: "Launch", "service profile ok in \(elapsedMs)ms, bytes=\(body.utf8.count)")
            return body
        case .failure:
            AppLogger.log(.connection, tag: "Launch", "service profile failed in \(elapsedMs)ms")
            return nil
        }
    }

    func pingBootstrapAndLog() async {
        await pingGetconfAndLog()
        await pingAdsettingsAndLog()
    }

    private func processGetconfResponse(_ body: String) async {
        cache.keep(body)
        guard let remote = cache.remoteGitVersion() else {
            AppLogger.log(.connection, tag: "Quill", "getconf 未返回 git_version，跳过 git 刷新")
            return
        }

        let local = cache.localGitVersion()
        AppLogger.log(.connection, tag: "Quill", "git_version compare remote=\(remote), local=\(local)")
        guard remote > local else {
            AppLogger.log(.connection, tag: "Quill", "git_version 未提升，跳过 git 刷新")
            return
        }

        AppLogger.log(.connection, tag: "Quill", "git_version 提升，开始刷新 git 配置")
        let ok = await vault.refreshFromGitOnce()
        if ok {
            cache.saveLocalGitVersion(remote)
            AppLogger.log(.connection, tag: "Quill", "git 配置刷新成功")
        } else {
            AppLogger.log(.connection, tag: "Quill", "git 配置刷新失败")
        }
    }
}
