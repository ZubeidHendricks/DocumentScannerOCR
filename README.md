# DocumentScannerOCR

Generated from niche `document-scanner` (Scanning, tier A, score 80).

**Utility:** Scan docs to PDF, OCR, sign, export
**Primary ASO keyword:** `document scanner`
**Also target:** `pdf scanner`, `scan to pdf`, `ocr scanner`, `scanner app`
**Paywall hook:** Unlimited scans, OCR, signature, no watermark

> iScanner-genre (your research). Saturated but huge intent; win on a vertical (receipts, IDs).

## Build it

```bash
brew install xcodegen        # once
cd DocumentScannerOCR
xcodegen generate
open DocumentScannerOCR.xcodeproj
```

The app runs immediately on a MockPurchaseProvider (real paywall UI, fake
purchases). To go live:

1. Replace `revenueCatKey` in `Sources/App.swift` with your RevenueCat key.
2. In App Store Connect create products `document-scanner_yearly` and `document-scanner_weekly`,
   map them into a RevenueCat offering, entitlement id `premium`.
3. Build the real feature in `Sources/ContentView.swift`.
4. **Guideline 4.3:** make the function, UI, screenshots and keywords genuinely
   distinct from any sibling app. Re-niche, never reskin.

Bundle id: `com.zubeid.documentscanner`

## Ship to TestFlight

This app ships with a Fastlane lane + GitHub Actions workflow. One-time account
setup (API key, signing) is documented in the kit's `Tools/appgen/DEPLOYMENT.md`.
Once your GitHub secrets are set, trigger the **TestFlight** workflow (or push a
`v*` tag), or run locally:

```bash
bundle install
bundle exec fastlane beta
```
