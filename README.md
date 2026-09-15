Mostly copied the [Charles Translator Android](https://github.com/ufal/charles-translator-android), just converting it to native iOS UX.

Xcode 27.0 (27A266a) is now out of beta, so TestFlight distribution is possible. Everything in this repo that a build needs is in place; what remains is account-side setup that only a signed-in Xcode can do.

## Requirements

- Xcode 27.0 or later
- iOS 26.0 or later on the test device (`IPHONEOS_DEPLOYMENT_TARGET = 26.0`)

## Building and testing

```
xcodebuild test -project CharlesTranslator.xcodeproj -scheme CharlesTranslator \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## TestFlight distribution

### One-time setup

1. **Sign in to Xcode.** Settings > Accounts, add the Apple ID that belongs to team `8YW3ZU8MFU`, then Manage Certificates and create an Apple Development and an Apple Distribution certificate. Without this the archive fails with *"No profiles for 'cz.cuni.mff.ufal.translator.ios' were found"* — signing is automatic, so Xcode generates the profiles itself once an account exists.
2. **Register the app** in App Store Connect with bundle ID `cz.cuni.mff.ufal.translator.ios`, matching what the project already builds.
3. **Fill in App Privacy** in App Store Connect. It should mirror `CharlesTranslator/Resources/PrivacyInfo.xcprivacy`: "Other User Content" collected, not linked to identity, not used for tracking, app-functionality purpose. That covers the input text and translation sent to UFAL MFF UK when the user agrees on the consent sheet.
4. **Export compliance** is already answered in the app: `ITSAppUsesNonExemptEncryption = false` in `Info.plist`, correct for an app that only uses HTTPS.

### Each build

```
Scripts/testflight.sh 2      # 2 = the build number for this upload
```

The script archives, exports an `.ipa` into `build/export/`, and uploads it if `ASC_KEY_ID` and `ASC_ISSUER_ID` are exported (App Store Connect API key, with `AuthKey_$ASC_KEY_ID.p8` under `~/.appstoreconnect/private_keys/`). Without those variables it stops after the export, and the `.ipa` can be uploaded by hand from Xcode's Organizer.

App Store Connect refuses a build number it has already accepted for the same marketing version, so pass the next integer every time. `MARKETING_VERSION` (currently `1.0`) and `CURRENT_PROJECT_VERSION` in the project are the single source of truth — `Info.plist` references them through `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)`.

## Localization

The app is fully localized in English, Czech, Ukrainian, Russian, and Slovak via
`CharlesTranslator/Resources/Localizable.xcstrings`, reusing the Android app's approved
wording wherever the screens match. Strings that diverge for iOS platform/HIG reasons are
logged in [`Documentation/LocalizationNotes.md`](Documentation/LocalizationNotes.md) for
human review.

Regenerate the catalog after editing source strings:

```sh
python3 Scripts/generate_localizations.py
```
