# Privacy & Data Safety preparation

Privacy policy sources: in-app `lib/ui/privacy_page.dart` · public page `website/privacy.html` (same content — keep them in sync).
Play Console needs a **public URL** for the policy (host `website/privacy.html`, e.g. GitHub Pages: Settings → Pages → deploy from `/website` via a copy of the folder, or any host). Replace `CONTACT_EMAIL_HERE` in the HTML and set the `PRIVACY_EMAIL` repo variable.

## Dependency audit (pubspec.yaml)
| Package | Network? | Data collected / shared | Permissions added |
|---|---|---|---|
| google_mobile_ads (Google Mobile Ads SDK + UMP) | **Yes** | **Yes — see table below** | INTERNET, ACCESS_NETWORK_STATE, `AD_ID` (merged) |
| shared_preferences | No | Local only (private app storage) | none |
| audioplayers | No (bundled asset files only) | none | none* |
| share_plus | No | none; hands a file/text to the user-chosen app via Android share sheet (FileProvider) | none |
| path_provider | No | none (temp dir for the share image) | none |
| flutter_launcher_icons / flutter_lints / flutter_test | dev-only, not shipped | — | — |
\*Verify in the CI "Audit merged permissions" log (it prints the final list and fails on sensitive ones). Re-audit after every dependency update.

## Data Safety form — recommended answers
Source: Google's "Google Mobile Ads SDK – Play data disclosure" page (it lists: IP address, user product interactions, diagnostic information, device/account identifiers such as Android ad ID and app-set ID; collected & shared automatically for advertising, analytics and fraud prevention; ad-ID collection is optional; encrypted in transit with TLS). **Re-read it and the UMP SDK page (developers.google.com/admob/ump/android/play-data-disclosure) for the SDK versions you ship — it changes.**

**Does the app collect or share user data? → Yes** (only via the ads SDK; the app itself sends nothing to Mido Studio).

| Play data type | Collected | Shared | Purposes | Required/optional |
|---|---|---|---|---|
| Location → Approximate location (IP address may reveal general location) | Yes | Yes (Google) | Advertising/marketing, Analytics, Fraud prevention | Optional* |
| App activity → App interactions | Yes | Yes (Google) | Advertising/marketing, Analytics, Fraud prevention | Optional* |
| App info & performance → Diagnostics | Yes | Yes (Google) | Analytics, Fraud prevention | Optional* |
| Device or other IDs → Advertising ID / app-set ID | Yes | Yes (Google) | Advertising/marketing, Analytics, Fraud prevention | Optional* |
*Google states users can control collection and opt out of personalised ads. Choose the option you are comfortable defending; "Required" is the safer choice if unsure.

**Not collected** (nothing leaves the device): name, email, user IDs, address, phone, race, political/religious views, sexual orientation, financial info, health/fitness, messages, photos/videos, audio, files, calendar, contacts, web history, installed apps. Scores/XP/settings/display name stay in local private storage — Play does not count data that never leaves the device.

**Security practices:** Data encrypted in transit: Yes (ads SDK uses TLS). Users can request deletion: the app holds no server-side user data; local data is erased with *Settings → Reset all progress* or uninstall — answer according to Play's wording at filing time. Independent security review: No. Committed to Play Families policy: No (13+).

## Consent (UMP)
- App requests consent info on every launch and shows Google's consent form when required (EEA/UK etc.). "Ad privacy choices" appears in Settings only when Google says it is required.
- **You must create and publish a consent message in AdMob → Privacy & messaging**; without it the form cannot show.
- No ads are requested if consent does not allow it.

## Account/data deletion
No accounts → no account-deletion requirement. If accounts are ever added: implement in-app deletion and a public web deletion page before release.
