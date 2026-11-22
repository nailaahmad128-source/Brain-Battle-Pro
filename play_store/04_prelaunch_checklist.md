# Pre-launch & publishing checklist

## One-time setup
- [ ] Play Console developer account verified (new personal accounts: **closed test with ≥12 testers for 14 days** before production access)
- [ ] Create app in Play Console, package **com.midostudio.brainbattlepro** (cannot be changed later; confirm it differs from your other apps)
- [ ] Opt in to **Play App Signing** at first upload (Google holds the app signing key; your keystore is only the *upload key*)
- [ ] AdMob: create app + banner/interstitial/rewarded units, publish a UMP consent message, link to the Play listing after publishing
- [ ] GitHub secrets/variables set (README §3) · keystore backed up offline
- [ ] Host the privacy policy; fill in contact email; enter URL in Play Console
- [ ] Complete App content: Privacy policy, Ads, App access, Content rating, Target audience, Data safety, Advertising ID
- [ ] Store listing: text (01_listing.md), icon, feature graphic, ≥2 phone screenshots

## Before each release
- [ ] CI green on `main` (format, analyze, tests)
- [ ] Install the TEST APK artifact on a real phone: play all 5 games, share a card, enter a challenge code, toggle sound/haptics, open Privacy Policy, reset progress, rotate/background the app, play with airplane mode on
- [ ] Bump `version:` in pubspec.yaml (versionName). versionCode is set from the CI run number (+`VERSION_CODE_OFFSET`)
- [ ] Run workflow **Android CI & Release** with *release = true* (or push tag `vX.Y.Z`) → download `brain-battle-pro-release-aab`
- [ ] Upload AAB (Closed testing first) + keep `mapping.txt` and `symbols` (de-obfuscation)
- [ ] Check Play Console pre-launch report; fix crashes/ANRs
- [ ] Release notes, rollout (start staged, e.g. 20%)
