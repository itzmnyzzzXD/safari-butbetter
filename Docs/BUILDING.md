# Building Safari But Better

## Open in Xcode

1. Open `SafariButBetter.xcodeproj`.
2. Choose the shared `SafariButBetter` scheme.
3. Select an iPhone or iPad simulator and run, or select a connected device.
4. For a physical-device build, open **Signing & Capabilities**, select your Apple development team, and let Xcode manage signing.

The deployment target is iOS/iPadOS 17.0. The app uses SwiftUI for its interface and WebKit (`WKWebView`) for page rendering.

## Build from Terminal

For a simulator build:

```bash
xcodebuild \
  -project SafariButBetter.xcodeproj \
  -scheme SafariButBetter \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

For an unsigned device build:

```bash
xcodebuild \
  -project SafariButBetter.xcodeproj \
  -scheme SafariButBetter \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -sdk iphoneos \
  -derivedDataPath ./DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## GitHub Actions IPA

The workflow at `.github/workflows/build-ipa.yml` runs on pushes to `main` and on manual dispatch. It builds the Release app for a generic iOS device with code signing disabled, places the app bundle inside `Payload/`, validates the resulting ZIP, and uploads `SafariButBetter-unsigned.ipa` as the `SafariButBetter-unsigned-IPA` artifact.

To run it manually, open **Actions → Build unsigned iOS IPA → Run workflow**. Download the artifact from the completed workflow run. GitHub wraps the IPA in an artifact ZIP, so extract that outer ZIP first.

## Installing on a device

An unsigned IPA is not installable as-is on a normal iPhone or iPad. Import it into a compatible signing tool, sign it with a certificate and provisioning profile valid for the device, and then install the signed output.

## Notes

- `SafariButBetter` is the Xcode scheme and target name used by the workflow.
- The bundle identifier is `com.itzmnyzzz.safaribetter`; change it in the target build settings if you need a different identifier.
- The built-in content rules block selected known analytics/advertising hostnames. They are intentionally conservative and may need maintenance as the web changes.
- Private tabs use `WKWebsiteDataStore.nonPersistent()`. This isolates WebKit website data for those tabs, but it does not make a network connection anonymous or hide activity from websites, networks, or service providers.