import Foundation
import Observation
import RevenueCat

/// RevenueCatを使った本番用の課金状態ストア。
@Observable
final class RevenueCatEntitlementStore: EntitlementStore {
    private(set) var isPro = false

    init() {
        Task { @MainActor [weak self] in
            await self?.refresh()
        }
    }

    @MainActor
    func purchase() async -> EntitlementOutcome {
        do {
            guard let offering = try await Purchases.shared.offerings().current,
                  let package = offering.lifetime ?? offering.availablePackages.first
            else {
                return .failed
            }

            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                return .cancelled
            }

            update(from: result.customerInfo)
            return isPro ? .purchased : .failed
        } catch {
            return .failed
        }
    }

    @MainActor
    func restore() async -> EntitlementOutcome {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            update(from: customerInfo)
            return isPro ? .restored : .noPurchaseFound
        } catch {
            return .failed
        }
    }

    @MainActor
    private func refresh() async {
        guard let customerInfo = try? await Purchases.shared.customerInfo() else {
            return
        }
        update(from: customerInfo)
    }

    @MainActor
    private func update(from customerInfo: CustomerInfo) {
        isPro = customerInfo.entitlements[LOEntitlement.identifier]?.isActive == true
    }
}
