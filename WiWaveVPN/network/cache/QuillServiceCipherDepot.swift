import Foundation

enum QuillCipherOrigin {
    case live
    case fallback
}

/// 服务密文仓：管理“接口密文 / 本地回退密文”的来源与持久化。
final class QuillServiceCipherDepot {
    static let shared = QuillServiceCipherDepot()

    private let cipherStorageKey = "Quill.ServiceCipher.Raw"

    private(set) var activeCipher: String?
    private(set) var origin: QuillCipherOrigin = .fallback
    private(set) var activeDraft: QuillServiceDraft?
    private(set) var activeRouteJSON: String?

    private init() {}

    /// 接收接口返回的服务密文，先进入内存，不立即写盘。
    func absorbLiveCipher(_ cipher: String) {
        activeCipher = cipher
        origin = .live
        activeDraft = nil
        activeRouteJSON = nil
        AppLogger.log(.connection, tag: "Quill", "服务密文来源 source=live（接口）")
    }

    /// 接口失败时尝试从本地缓存回退。
    func reviveFallbackCipher() -> String? {
        guard let cached = UserDefaults.standard.string(forKey: cipherStorageKey),
              !cached.isEmpty else {
            AppLogger.log(.connection, tag: "Quill", "服务密文回退失败 fallback missing")
            return nil
        }
        activeCipher = cached
        origin = .fallback
        activeDraft = nil
        activeRouteJSON = nil
        AppLogger.log(.connection, tag: "Quill", "服务密文来源 source=fallback（本地缓存）")
        return cached
    }

    /// 连接成功后调用：仅当当前来源是 live 才写入本地缓存。
    func storeLiveCipherIfNeeded() {
        guard origin == .live, let cipher = activeCipher, !cipher.isEmpty else { return }
        UserDefaults.standard.set(cipher, forKey: cipherStorageKey)
        AppLogger.log(.connection, tag: "Quill", "服务密文已落盘 persisted to disk")
    }

    func clearActiveCipher() {
        activeCipher = nil
        origin = .fallback
        activeDraft = nil
        activeRouteJSON = nil
    }

    func holdDraft(_ draft: QuillServiceDraft) {
        activeDraft = draft
        AppLogger.log(.connection, tag: "Quill", "服务草稿已缓存 service draft cached")
    }

    func holdRouteJSON(_ json: String) {
        activeRouteJSON = json
        AppLogger.log(.connection, tag: "Quill", "路由草稿已缓存 route draft cached")
    }
}
