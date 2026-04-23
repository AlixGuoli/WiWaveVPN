import Foundation
import StoreKit
import Combine

@MainActor
final class WiPurchaseCenter: ObservableObject {
    static let shared = WiPurchaseCenter()
    nonisolated static func hasActiveSubscriptionFast() -> Bool {
        WiPurchaseSnapshot.hasActiveSubscription()
    }

    @Published private(set) var productMap: [String: Product] = [:]
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published private(set) var hasActiveSubscription = false
    @Published private(set) var activeProductID: String?
    @Published private(set) var activeExpiration: Date?
    @Published private(set) var lastErrorMessage: String?

    var isBusy: Bool {
        isLoadingProducts || isPurchasing || isRestoring
    }

    private let productIDs: Set<String> = [
        "com.glow.wiwave.vpn.weekly",
        "com.glow.wiwave.vpn.monthly",
        "com.glow.wiwave.vpn.annual",
    ]
    private var updatesTask: Task<Void, Never>?

    init() {
        restoreSubscriptionSnapshotFromCache()
        AppLogger.log(.system, tag: "IAP", "[启动] 内购中心已初始化 | cacheActive=\(hasActiveSubscription)")
        updatesTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshSubscriptionState()
            await self.observeTransactionUpdates()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func prepare() async {
        AppLogger.log(.system, tag: "IAP", "[页面] 会员页准备完成前置任务 | tasks=loadProducts+refreshState")
        await loadProductsIfNeeded()
        await refreshSubscriptionState()
    }

    func loadProductsIfNeeded() async {
        guard productMap.isEmpty else { return }
        await loadProducts()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let products = try await Product.products(for: Array(productIDs))
            var map: [String: Product] = [:]
            for product in products {
                map[product.id] = product
            }
            productMap = map
            AppLogger.log(.system, tag: "IAP", "[商品] 加载成功 | count=\(products.count)")
        } catch {
            lastErrorMessage = error.localizedDescription
            AppLogger.log(.system, tag: "IAP", "[商品] 加载失败 | err=\(error.localizedDescription)")
        }
    }

    func displayPrice(for productID: String) -> String? {
        productMap[productID]?.displayPrice
    }

    func compareDisplayPrice(for productID: String, multiplier: Decimal) -> String? {
        guard let product = productMap[productID] else { return nil }
        let base = NSDecimalNumber(decimal: product.price)
        let scaled = base.multiplying(by: NSDecimalNumber(decimal: multiplier)).decimalValue
        return scaled.formatted(product.priceFormatStyle)
    }

    @discardableResult
    func purchase(productID: String) async -> Bool {
        guard !isPurchasing else { return false }
        if productMap[productID] == nil {
            await loadProducts()
        }
        guard let product = productMap[productID] else {
            lastErrorMessage = "Product not available."
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verify(verification)
                await transaction.finish()
                await refreshSubscriptionState()
                AppLogger.log(.system, tag: "IAP", "[购买] 成功 | productID=\(productID)")
                return true
            case .userCancelled:
                AppLogger.log(.system, tag: "IAP", "[购买] 用户取消")
                return false
            case .pending:
                AppLogger.log(.system, tag: "IAP", "[购买] 待处理（pending）")
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = error.localizedDescription
            AppLogger.log(.system, tag: "IAP", "[购买] 失败 | err=\(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        guard !isRestoring else { return false }
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await refreshSubscriptionState()
            AppLogger.log(.system, tag: "IAP", "[恢复] 完成 | active=\(hasActiveSubscription)")
            return true
        } catch {
            lastErrorMessage = error.localizedDescription
            AppLogger.log(.system, tag: "IAP", "[恢复] 失败 | err=\(error.localizedDescription)")
            return false
        }
    }

    func refreshSubscriptionState() async {
        let oldActive = hasActiveSubscription
        let oldProductID = activeProductID ?? "nil"
        AppLogger.log(.system, tag: "IAP", "[状态] 刷新开始 | oldActive=\(oldActive), oldProduct=\(oldProductID)")
        let (expiry, productID) = await latestEntitlement()
        let now = Date()
        if let expiry, expiry > now {
            hasActiveSubscription = true
            activeExpiration = expiry
            activeProductID = productID
            WiPurchaseSnapshot.write(expiration: expiry, productID: productID)
            AppLogger.log(.system, tag: "IAP", "[状态] 订阅有效 | active=true, product=\(productID ?? "nil"), expiry=\(expiry)")
        } else {
            hasActiveSubscription = false
            activeExpiration = nil
            activeProductID = nil
            WiPurchaseSnapshot.clear()
            AppLogger.log(.system, tag: "IAP", "[状态] 订阅无效 | active=false, cache=cleared")
        }
    }

    private func restoreSubscriptionSnapshotFromCache() {
        if let snapshot = WiPurchaseSnapshot.read(), snapshot.expiration > Date() {
            hasActiveSubscription = true
            activeExpiration = snapshot.expiration
            activeProductID = snapshot.productID
            AppLogger.log(.system, tag: "IAP", "[缓存] 命中有效订阅 | active=true, product=\(snapshot.productID ?? "nil"), expiry=\(snapshot.expiration)")
        } else {
            hasActiveSubscription = false
            activeExpiration = nil
            activeProductID = nil
            WiPurchaseSnapshot.clear()
            AppLogger.log(.system, tag: "IAP", "[缓存] 无有效订阅 | active=false")
        }
    }

    private func observeTransactionUpdates() async {
        for await update in Transaction.updates {
            if Task.isCancelled { break }
            do {
                let transaction = try verify(update)
                await transaction.finish()
                await refreshSubscriptionState()
                AppLogger.log(.system, tag: "IAP", "[交易] 更新已处理 | productID=\(transaction.productID)")
            } catch {
                AppLogger.log(.system, tag: "IAP", "[交易] 更新处理失败 | err=\(error.localizedDescription)")
            }
        }
    }

    private func latestEntitlement() async -> (Date?, String?) {
        var latestExpiration: Date?
        var latestProductID: String?
        for await entitlement in Transaction.currentEntitlements {
            do {
                let transaction = try verify(entitlement)
                guard productIDs.contains(transaction.productID) else { continue }
                let expiration = transaction.expirationDate ?? .distantFuture
                if latestExpiration == nil || expiration > latestExpiration! {
                    latestExpiration = expiration
                    latestProductID = transaction.productID
                }
            } catch {
                continue
            }
        }
        return (latestExpiration, latestProductID)
    }

    private func verify<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw WiPurchaseError.unverified
        }
    }
}

enum WiPurchaseError: Error {
    case unverified
}

struct WiPurchaseSnapshot {
    private static let flagKey = "WiPurchaseCenter.Subscription.Active"
    private static let expiryKey = "WiPurchaseCenter.Subscription.Expiry"
    private static let productKey = "WiPurchaseCenter.Subscription.ProductID"

    static func write(expiration: Date, productID: String?) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: flagKey)
        defaults.set(expiration.timeIntervalSince1970, forKey: expiryKey)
        defaults.set(productID, forKey: productKey)
    }

    static func clear() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: flagKey)
        defaults.removeObject(forKey: expiryKey)
        defaults.removeObject(forKey: productKey)
    }

    static func read() -> (expiration: Date, productID: String?)? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: flagKey) else { return nil }
        let ts = defaults.double(forKey: expiryKey)
        guard ts > 0 else { return nil }
        let exp = Date(timeIntervalSince1970: ts)
        let pid = defaults.string(forKey: productKey)
        return (exp, pid)
    }

    static func hasActiveSubscription() -> Bool {
        guard let snapshot = read() else { return false }
        return snapshot.expiration > Date()
    }
}
