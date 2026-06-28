import SwiftUI
import AppFactoryKit
import AppFactoryKitRevenueCat

// ─────────────────────────────────────────────────────────────────────────
// Doc Scanner — production configuration.
// RevenueCat public SDK keys are designed to ship inside the app (they are not
// secret), so this is safe to commit. Until a real key is set, the app runs on a
// mock provider so the paywall can be previewed without a store connection.
// ─────────────────────────────────────────────────────────────────────────

private let revenueCatKey = "appl_REPLACE_ME"

// App Store Connect product identifiers (alphanumerics, "." and "_" only — no hyphens).
private enum Product {
    static let yearly = "docscanner_pro_yearly"
    static let weekly = "docscanner_pro_weekly"
}

@MainActor
enum DocScannerFactory {
    static func make() -> AppFactory {
        let provider: PurchaseProvider = revenueCatKey == "appl_REPLACE_ME"
            ? MockPurchaseProvider()
            : RevenueCatPurchaseProvider(apiKey: revenueCatKey, entitlementID: "premium")

        let config = AppFactoryConfiguration(
            appName: "Doc Scanner",
            purchaseProvider: provider,
            onboarding: OnboardingConfiguration(
                slides: [
                    .init(systemImage: "doc.viewfinder",
                          title: "Scan Anything",
                          message: "Turn paper documents into crisp PDFs in seconds — edges are detected and straightened automatically."),
                    .init(systemImage: "text.viewfinder",
                          title: "Extract the Text",
                          message: "Pull editable, searchable text out of any scan with on-device OCR."),
                    .init(systemImage: "square.and.arrow.up",
                          title: "Share & Export",
                          message: "Export multi-page PDFs and send them anywhere.")
                ],
                presentsPaywallOnFinish: true,
                accent: .blue
            ),
            paywall: PaywallConfiguration(
                headline: "Unlock Doc Scanner Pro",
                subheadline: "Everything you need to scan, read and share documents.",
                benefits: [
                    .init(systemImage: "infinity", title: "Unlimited scans & pages"),
                    .init(systemImage: "text.viewfinder", title: "OCR text extraction", subtitle: "Copy and search the text in any scan"),
                    .init(systemImage: "doc.on.doc", title: "Multi-page PDF export"),
                    .init(systemImage: "nosign", title: "No watermarks, no ads")
                ],
                productIDs: [Product.yearly, Product.weekly],
                highlightedProductID: Product.yearly,
                ctaTitle: "Continue",
                dismissButtonDelay: 4,
                isDismissable: true,
                termsURL: URL(string: "https://zubeidhendricks.github.io/DocumentScannerOCR/terms.html"),
                privacyURL: URL(string: "https://zubeidhendricks.github.io/DocumentScannerOCR/privacy.html"),
                style: PaywallStyle(accent: .blue, heroSystemImage: "doc.viewfinder")
            )
        )
        return AppFactory(config)
    }
}

@main
struct DocScannerApp: App {
    @StateObject private var factory = DocScannerFactory.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appFactoryRoot(factory)
                .tint(.blue)
        }
    }
}
