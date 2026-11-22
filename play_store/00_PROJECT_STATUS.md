# Project status (honest)

## Implemented
All features in README, release/CI tooling, privacy page, Play documents.

## Actually tested so far
- ✔ `tool/prepare_android.py` run against mock Flutter kts/manifest: CI mode, release-without-secrets (correctly fails), release-with-secrets (SDK 36 / minSdk 24 / signing / AdMob id / backup off applied; idempotent).
- ✔ Workflow YAML parses; asset generator runs; zip structure checked.
- ✘ **Not compiled, not analyzed, not run**: no Flutter/Dart SDK existed in the authoring environment. `flutter analyze`, `dart format`, `flutter test`, the APK and the AAB have NOT been run.
- ✘ **No release AAB has been built.** It needs your secrets and a CI run.
- ✘ Never run on a device: game feel, ad loading, consent form, share sheet, audio latency are unverified.

## Localization (added)
9 languages incl. Urdu/Arabic RTL. Translations were written by the AI, not by native speakers or professional translators: proofread before release. Not run on a device: RTL layout, Arabic/Urdu font fallback on real phones (Urdu uses the system Arabic-script font, not necessarily Nastaliq), text overflow in long languages. The l10n unit test checks key/placeholder completeness only (not run yet).
Also fixed in review: reflex early-tap guard no longer depends on text, XP bar now RTL-aware, no negative distractors in Logic Chain, share image waits for the score animation, challenge-code length validated.

## Second full review (manual read-through, no compiler)
Read every UI/game file after the localisation refactor: bracket balance OK, all `tr()` keys exist in all 8 language tables, no `const` widget contains a translated string, imports all used. Fixed: hall-of-fame list flicker (initialData), untranslated "d" suffix on best streak, `required` used as a variable name. Still NOT compiled/analyzed/run.

## Startup-crash investigation (release APK closes on launch)
NOT reproduced and NOT confirmed fixed: no device, Flutter SDK, network or crash log was available here.
Defects found by reading the project:
1. **Wrong application id.** The scaffold was generated with `--org com.midostudio.brainbattlepro --project-name brain_battle_pro`, which makes namespace/applicationId/MainActivity package `com.midostudio.brainbattlepro.brain_battle_pro`. My verification used a substring match and my mock test used a hand-written template, so it passed. Now: `--org com.midostudio --project-name brainbattlepro`, android/ regenerated on every run, and exact checks on namespace, applicationId, MainActivity package, launcher intent, AdMob APPLICATION_ID.
2. **Startup order.** main() awaited 7 native audio-player setups before runApp; a hang there means no splash at all. Now only SharedPreferences is awaited; audio (5 s timeout) and AdMob/UMP start after the first frame; failures are logged with the tag `BBP` and a storage failure shows a visible error screen.
Added to CI: aapt2 check of the built APK (package, launchable activity, AdMob id), widget tests that boot splash→home and run all five games, and an **Android emulator smoke test** that installs the release APK, launches it, runs 400 random inputs, fails on any FATAL EXCEPTION and uploads logcat + screenshots (`smoke-test-logcat-and-screens`).
Other suspects not ruled out (need the real stack trace): AdMob/UMP native init on that phone, R8 stripping, device-specific Impeller/Vulkan crash, 16 KB-page-size devices.
To get the real log from a phone: `pkg install android-tools`, pair via Developer options → Wireless debugging (`adb pair`, `adb connect`), then `adb logcat -d | grep -B3 -A30 "FATAL EXCEPTION"`.

### Third review (startup path)
Re-read main/ads/audio/splash/home end to end; no further native-crash cause found by reading. Hardened verification instead: the emulator smoke test is now its own job running on Android 10 (API 29), 14 (API 34) and 16 (API 36, the target SDK), requires the app to be the resumed foreground activity, and the test APK is built with R8 + `--obfuscate` exactly like the release. A crash specific to one Android version will therefore show up as one failing matrix entry with its logcat in `smoke-logs-apiNN`.

## Remaining manual work
Play Console account/app creation, forms in `play_store/`, AdMob units + UMP message, secrets, screenshots, privacy-policy hosting + email.

## Risks
1. First CI run will likely surface compile/analyze/format errors (code never compiled).
2. Latest-stable Flutter/AGP may change the generated Gradle template; the patcher fails loudly if it can't apply SDK 36/signing. Pin a Flutter version in the workflow once a build is green.
3. Dependency versions (`google_mobile_ads ^5`, `share_plus ^10`, `audioplayers ^6`) are unverified against compileSdk 36 — check the first build.
4. Data Safety answers follow Google's published SDK disclosure; re-verify against shipped SDK versions.
5. New personal Play accounts must complete closed testing (12 testers, 14 days) before production.
6. Rewarded/interstitial ads and UMP only work with real ids + published consent message; test on device.
7. Original-asset risk: icon/sounds are procedurally generated; replace with commissioned art/audio if you want a more "luxury" identity.
