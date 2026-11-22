import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services.dart';

/// AdMob integration.
///
/// * Debug builds, or builds made with `--dart-define=ADS_TEST_MODE=true`
///   (the CI test APK), use Google's official TEST ad units.
/// * Any other build uses ONLY the ids injected with
///   `--dart-define=ADMOB_BANNER / ADMOB_INTERSTITIAL / ADMOB_REWARDED`.
///   If an id is missing, ads are simply disabled: test ids are never
///   used in a production build.
///
/// Ads are never shown during gameplay: banners live on menu/result screens
/// (with spacing from tappable controls), interstitials only appear between
/// games (every 3rd game, >= 2 min apart, never before the 3rd game, only
/// after the player taps "Play again"/"Home"), rewarded ads are opt-in.
class AdService {
  AdService._();
  static final instance = AdService._();

  static const _testMode = bool.fromEnvironment('ADS_TEST_MODE');
  static const _bannerProd = String.fromEnvironment('ADMOB_BANNER');
  static const _interProd = String.fromEnvironment('ADMOB_INTERSTITIAL');
  static const _rewardedProd = String.fromEnvironment('ADMOB_REWARDED');

  static String? _resolve(String prod, String test) {
    if (_testMode || kDebugMode) return test;
    return prod.isEmpty ? null : prod;
  }

  static String? get bannerId =>
      _resolve(_bannerProd, 'ca-app-pub-3940256099942544/6300978111');
  static String? get interstitialId =>
      _resolve(_interProd, 'ca-app-pub-3940256099942544/1033173712');
  static String? get rewardedId =>
      _resolve(_rewardedProd, 'ca-app-pub-3940256099942544/5224354917');
  static bool get enabled =>
      bannerId != null && interstitialId != null && rewardedId != null;

  final ready = ValueNotifier<bool>(false);
  final rewardedReady = ValueNotifier<bool>(false);
  final privacyOptionsRequired = ValueNotifier<bool>(false);
  InterstitialAd? _inter;
  RewardedAd? _rewarded;
  int _finished = 0;
  DateTime _last = DateTime.now();

  Future<void> init() async {
    if (!Platform.isAndroid || !enabled) return;
    try {
      final c = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
          if (!c.isCompleted) c.complete();
        },
        (_) {
          if (!c.isCompleted) c.complete();
        },
      );
      await c.future;
      privacyOptionsRequired.value =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg));
      await MobileAds.instance.initialize();
      ready.value = true;
      _loadInterstitial();
      _loadRewarded();
    } catch (_) {}
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _inter = ad,
        onAdFailedToLoad: (_) => _inter = null,
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: rewardedId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          rewardedReady.value = true;
        },
        onAdFailedToLoad: (_) {
          _rewarded = null;
          rewardedReady.value = false;
        },
      ),
    );
  }

  void gameFinished() => _finished++;

  /// Calls [then] right away, or after an interstitial if one is due.
  void showInterstitialIfDue(VoidCallback then) {
    final ad = _inter;
    final due = ad != null &&
        _finished >= 3 &&
        Svc.store.totalGames >= 3 &&
        DateTime.now().difference(_last).inSeconds >= 120;
    if (!due) {
      then();
      return;
    }
    _inter = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _finished = 0;
        _last = DateTime.now();
        _loadInterstitial();
        then();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadInterstitial();
        then();
      },
    );
    ad.show();
  }

  /// Opt-in rewarded ad ("Watch to double your XP"). Returns false if not ready.
  bool showRewarded(VoidCallback onReward) {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    rewardedReady.value = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => onReward());
    return true;
  }
}

class BannerSlot extends StatelessWidget {
  const BannerSlot({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: AdService.instance.ready,
        builder: (_, r, __) => r ? const _Banner() : const SizedBox.shrink(),
      );
}

class _Banner extends StatefulWidget {
  const _Banner();
  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  BannerAd? _ad;
  bool _loaded = false, _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load(MediaQuery.of(context).size.width.truncate());
  }

  Future<void> _load(int width) async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    final ad = BannerAd(
      adUnitId: AdService.bannerId!,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (a, _) => a.dispose(),
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
