class AppConfig {
  static const appName = 'Brain Battle Pro';
  static const studio = 'Mido Studio';
  static const version = '1.0.0';
  static const storeUrl =
      'https://play.google.com/store/apps/details?id=com.midostudio.brainbattlepro';
  // Injected at build time: --dart-define=PRIVACY_EMAIL=you@example.com
  static const privacyEmail = String.fromEnvironment('PRIVACY_EMAIL');
}
