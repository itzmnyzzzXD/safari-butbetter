# Safari But Better

A native iPhone and iPad browser built with **SwiftUI** and **WKWebView**. The project includes a custom browser interface, private tabs, bookmarks, browsing history, configurable search providers, appearance settings, built-in tracker rules, and a GitHub Actions workflow that packages an **unsigned IPA** for use with an iOS signing tool.

## What is included

- Native SwiftUI browser UI with a custom start page and responsive iPhone/iPad layout.
- WebKit browsing with back, forward, reload, loading progress, and links that open in new tabs.
- Multiple regular tabs and isolated private tabs using a non-persistent WebKit data store.
- Bookmarks and browsing history, with private-tab visits excluded from history.
- DuckDuckGo, Google, Brave Search, and Bing search options.
- System, light, and dark appearances.
- Optional blocking rules for common analytics and advertising hosts.
- Optional HTTPS preference for addresses entered in the browser.
- A shared Xcode scheme and a GitHub Actions IPA build workflow.

## Build an unsigned IPA

1. Open the repository's **Actions** tab.
2. Select **Build unsigned iOS IPA**.
3. Choose **Run workflow** on the `main` branch, or let a push to `main` start the same workflow.
4. Open the completed run and download the `SafariButBetter-unsigned-IPA` artifact.
5. Extract the artifact ZIP. The `SafariButBetter-unsigned.ipa` inside can be imported into your signer.

The IPA is intentionally **unsigned**. It does not contain a signing certificate or provisioning profile. Your signing tool must sign it for the target device before installation.

## Build locally with Xcode

Open `SafariButBetter.xcodeproj`, select the `SafariButBetter` scheme, choose an iPhone or iPad simulator, and press **Run**. To build for a physical device, select your Apple development team in Signing & Capabilities. See [Docs/BUILDING.md](Docs/BUILDING.md) for command-line steps and IPA details.

## Requirements

- Xcode 16 or later
- iOS/iPadOS 17.0 or later
- A Mac for local Xcode builds; GitHub Actions builds on a macOS runner

## Privacy notes

Regular browsing uses the default WebKit website data store. Private tabs use a non-persistent data store and are not added to the app's browsing-history list. The optional tracker blocker uses a small, built-in list of common analytics/ad hosts; it is not a comprehensive tracker-detection system. HTTPS preference upgrades typed `http://` addresses to `https://` but cannot guarantee that every site supports HTTPS.
