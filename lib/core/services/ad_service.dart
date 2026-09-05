import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdConfig {
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _banner = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-1478743894328528/6115880966',
  );
  static const _interstitial = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-1478743894328528/4378408839',
  );
  static const _rewarded = String.fromEnvironment(
    'ADMOB_REWARDED_ID',
    defaultValue: 'ca-app-pub-1478743894328528/6701319846',
  );
  static String get banner => kReleaseMode ? _banner : _testBanner;
  static String get interstitial =>
      kReleaseMode ? _interstitial : _testInterstitial;
  static String get rewarded => kReleaseMode ? _rewarded : _testRewarded;
  static bool get releaseConfigured =>
      !kReleaseMode ||
      (_banner.isNotEmpty && _interstitial.isNotEmpty && _rewarded.isNotEmpty);
}

class AdService {
  static final premium = ValueNotifier<bool>(false);
  static int _actions = 0;
  static InterstitialAd? _interstitial;
  static bool get adsAllowed => !premium.value;

  static void setPremium(bool value) {
    if (premium.value == value) return;
    premium.value = value;
    if (value) {
      _interstitial?.dispose();
      _interstitial = null;
      _actions = 0;
    } else {
      _loadInterstitial();
    }
  }

  static Future<void> initializeInBackground() async {
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => ConsentForm.loadAndShowConsentFormIfRequired((_) {}),
        (_) {},
      );
      await MobileAds.instance.initialize();
      _loadInterstitial();
    } catch (_) {}
  }

  static void _loadInterstitial() {
    if (!adsAllowed || !AdConfig.releaseConfigured) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  static void meaningfulAction() {
    if (!adsAllowed) return;
    _actions++;
    if (_actions >= 6 && _interstitial != null) {
      final ad = _interstitial!;
      _interstitial = null;
      _actions = 0;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          _loadInterstitial();
        },
      );
      ad.show();
    }
  }

  static void showRewarded({
    required void Function() onReward,
    required void Function() onUnavailable,
  }) {
    if (!adsAllowed || !AdConfig.releaseConfigured) {
      onUnavailable();
      return;
    }
    RewardedAd.load(
      adUnitId: AdConfig.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
          );
          ad.show(onUserEarnedReward: (_, _) => onReward());
        },
        onAdFailedToLoad: (_) => onUnavailable(),
      ),
    );
  }
}
