# Doc Scanner — Release Runbook

Production-hardened: app icon, `PrivacyInfo.xcprivacy`, App Store metadata
(`fastlane/metadata`), hosted privacy/terms (`docs/`), and Fastlane lanes.

## What I still need from you (4 things)

| # | Value | Where to get it |
|---|-------|-----------------|
| 1 | **RevenueCat public SDK key** (`appl_…`) | app.revenuecat.com → your project → **Project Settings → API Keys** → *Public app-specific API key* for the iOS app. (The integrations URL you sent doesn't show it — it's under API Keys.) |
| 2 | **Apple Team ID** (10 chars) | developer.apple.com → Account → **Membership details** |
| 3 | **Apple Issuer ID** (UUID) | App Store Connect → Users and Access → **Integrations** (top of the API Keys list) |
| 4 | **Which .p8 key** to use | One of `~/Downloads/AuthKey_*.p8`. The filename’s code is the Key ID. |

Once I have these I:
1. paste the RevenueCat key into `Sources/App.swift` (`revenueCatKey`),
2. create the App Store record + subscription products,
3. archive + upload + submit for review.

## You also need to do (Apple-side, can't be automated)

- Create the **subscription products** in App Store Connect (or approve `produce` doing it):
  `docscanner_pro_yearly` and `docscanner_pro_weekly`, then add them to a RevenueCat
  **offering** with entitlement id `premium`.
- Enable **GitHub Pages** for this repo (Settings → Pages → main `/docs`) so the
  privacy/terms URLs resolve.
- Final **App Review** is Apple's call (~1–3 days).

## Commands (run on this Mac)

```bash
cd ~/AppFactoryPortfolio/DocumentScannerOCR
export ASC_KEY_ID=AL746SW9U2                     # the .p8 you choose
export ASC_ISSUER_ID=<your-issuer-id>
export ASC_KEY_PATH=~/Downloads/AuthKey_AL746SW9U2.p8
export DEVELOPMENT_TEAM=<your-team-id>

bundle install
bundle exec fastlane create_app     # one-time: registers bundle id + app record
bundle exec fastlane beta           # upload a TestFlight build
bundle exec fastlane release        # upload + submit for App Store review
```

## Status

- ✅ Builds clean on iOS 17 simulator, runs, icon + privacy manifest in bundle
- ✅ Metadata within Apple limits (name 22, subtitle 28, keywords 96)
- ⏳ Screenshots: 1 captured (`fastlane/screenshots/en-US`). For the listing, final
  6.9" screenshots (1320×2868) should be captured — easy follow-up.
- ⏳ Blocked only on the 4 credentials above.
