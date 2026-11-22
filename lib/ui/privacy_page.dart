import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import 'widgets.dart';

const kPolicyUpdated = 'November 16, 2026';

const _sections = <(String, String)>[
  (
    'Who we are',
    'Brain Battle Pro is published by Mido Studio ("we"). This policy explains what the app does with data.'
  ),
  (
    'Data that stays on your device',
    'Your XP, level, streak, achievements, best scores, settings (sound, haptics) and the display name you choose are stored only on your device, in the app\'s private storage. We do not run servers, there are no accounts, and we never receive this data. App backups are turned off so this data is not copied to cloud backups. You can erase it any time with Settings → Reset all progress, or by uninstalling the app.'
  ),
  (
    'Advertising (Google AdMob)',
    'The app is free and shows ads served by Google AdMob using the Google Mobile Ads SDK. To show and measure ads, prevent fraud and provide analytics, Google may collect and use: your IP address (which can indicate your general location), your Android advertising ID and app-set ID, how you interact with the app and ads (for example app launches and taps), and diagnostic information such as performance data. This data is sent to Google over encrypted connections. We do not receive it and we do not sell your data.\n\nWhere required by law (for example in the EEA and UK) a Google consent form asks for your choice before ads are requested. You can change it later under Settings → Ad privacy choices when that option is shown. You can also reset or delete your advertising ID, or opt out of ad personalization, in your Android settings. Google\'s privacy policy: policies.google.com/privacy'
  ),
  (
    'Ads and gameplay',
    'Ads are never shown while you are playing. Banners appear on menu and result screens; a full-screen ad may appear between games, and you can optionally watch a rewarded ad for bonus XP.'
  ),
  (
    'Sharing and challenge codes',
    'When you tap Share, the score-card image (which shows your display name, score and level) and a text message are handed to the app you choose in Android\'s share sheet. We do not control what that app does with them. A challenge code only contains a game number and a random puzzle number; it contains no personal data.'
  ),
  (
    'Permissions',
    'The app needs internet access only for ads. It does not use your camera, microphone, contacts, location, photos or files.'
  ),
  (
    'Children',
    'Brain Battle Pro is not directed to children under 13 and does not knowingly collect personal information from them.'
  ),
  (
    'Your choices and data deletion',
    'We hold no personal data about you, so there is nothing for us to delete on a server. Local data can be erased with Settings → Reset all progress or by uninstalling. For data held by Google for advertising, use Google\'s ad settings and your Android advertising ID controls.'
  ),
  (
    'Changes',
    'If this policy changes, the new version will be published in the app and on our website with a new date.'
  ),
];

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text(context.tr('Privacy Policy'),
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Text(context.tr('Last updated: {d}', {'d': kPolicyUpdated}),
                        style: const TextStyle(color: C.muted, fontSize: 12)),
                    const SizedBox(height: 12),
                    GlassCard(
                      border: C.cyan.withValues(alpha: 0.4),
                      child: Text(
                          context.tr(
                              'Summary: your game data stays on your device and there are no accounts. Ads come from Google AdMob, which may use your advertising ID and device information. The full policy below is in English.'),
                          style: const TextStyle(height: 1.5, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    for (final s in _sections)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.$1,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: C.cyan)),
                              const SizedBox(height: 6),
                              Text(s.$2,
                                  style: const TextStyle(
                                      height: 1.45, color: C.text)),
                            ],
                          ),
                        ),
                      ),
                    if (AppConfig.privacyEmail.isNotEmpty)
                      GlassCard(
                        child: Text('Contact: ${AppConfig.privacyEmail}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );
}
