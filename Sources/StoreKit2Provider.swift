import Foundation
import StoreKit
import AppFactoryKit

/// Native StoreKit 2 payment backend — no third-party SDK, no API key. Reads
/// products straight from App Store Connect and checks entitlements on-device.
/// Conforms to AppFactoryKit's PurchaseProvider seam, so the paywall/onboarding/
/// funnel are unchanged.
final class StoreKit2PurchaseProvider: PurchaseProvider, @unchecked Sendable {
    private let productIDs: Set<String>

    init(productIDs: [String]) { self.productIDs = Set(productIDs) }

    var isSubscribed: Bool {
        get async {
            for await result in Transaction.currentEntitlements {
                if case .verified(let t) = result,
                   productIDs.contains(t.productID),
                   t.revocationDate == nil {
                    return true
                }
            }
            return false
        }
    }

    func fetchProducts(ids: [String]) async throws -> [SubscriptionProduct] {
        let products = try await Product.products(for: ids)
        let byID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        // Preserve the requested display order.
        return ids.compactMap { byID[$0] }.map(Self.map)
    }

    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult {
        let products = try await Product.products(for: [product.id])
        guard let sk = products.first else { throw PurchaseError.productNotFound(product.id) }
        let result = try await sk.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                await transaction.finish()
                return .success
            }
            return .pending
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .pending
        }
    }

    func restorePurchases() async throws -> Bool {
        try? await AppStore.sync()
        return await isSubscribed
    }

    // MARK: - Mapping StoreKit → AppFactoryKit

    private static func map(_ p: Product) -> SubscriptionProduct {
        let period: AppFactoryKit.SubscriptionPeriod
        if let unit = p.subscription?.subscriptionPeriod.unit {
            switch unit {
            case .day, .week: period = .week
            case .month: period = .month
            case .year: period = .year
            @unknown default: period = .month
            }
        } else {
            period = .lifetime
        }

        var intro: IntroOffer?
        if let offer = p.subscription?.introductoryOffer {
            let days: Int
            switch offer.period.unit {
            case .day: days = offer.period.value
            case .week: days = offer.period.value * 7
            case .month: days = offer.period.value * 30
            case .year: days = offer.period.value * 365
            @unknown default: days = offer.period.value
            }
            switch offer.paymentMode {
            case .freeTrial: intro = IntroOffer(kind: .freeTrial, periodDays: days)
            case .payAsYouGo: intro = IntroOffer(kind: .payAsYouGo, periodDays: days, priceText: offer.displayPrice)
            case .payUpFront: intro = IntroOffer(kind: .payUpFront, periodDays: days, priceText: offer.displayPrice)
            default: intro = nil
            }
        }

        return SubscriptionProduct(
            id: p.id,
            displayTitle: p.displayName,
            localizedPrice: p.displayPrice,
            priceValue: p.price,
            currencyCode: p.priceFormatStyle.currencyCode,
            period: period,
            introOffer: intro
        )
    }
}
