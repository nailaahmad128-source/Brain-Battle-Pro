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
