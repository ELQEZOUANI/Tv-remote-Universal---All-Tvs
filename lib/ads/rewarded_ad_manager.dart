import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/app_logger.dart';

/// Loads and presents a rewarded ad before the remote is unlocked.
///
/// Test ad unit IDs are used here so this flow is safe during development.
/// Replace them with production rewarded IDs before release.
class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  static bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get _adUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-2535194044471316/5074445816';
    }
    throw UnsupportedError('Unsupported platform');
  }

  void loadAd() {
    if (!_isSupportedPlatform || _rewardedAd != null || _isLoading) return;

    _isLoading = true;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          appLog('✅ Rewarded ad loaded successfully!');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          appLog('❌ Rewarded ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Shows the ad and calls [onRewarded] only after the user earns the reward.
  /// If the ad is unavailable or fails to show, [onUnavailable] is called so
  /// connection remains usable on unsupported/offline devices.
  void showAdThen({
    required VoidCallback onRewarded,
    required VoidCallback onUnavailable,
    VoidCallback? onDismissedWithoutReward,
  }) {
    if (!_isSupportedPlatform) {
      onUnavailable();
      return;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      loadAd();
      onUnavailable();
      return;
    }

    _rewardedAd = null;
    var earned = false;
    var completed = false;

    void finish() {
      if (completed) return;
      completed = true;
      ad.dispose();
      loadAd();
      if (earned) {
        onRewarded();
      } else {
        onDismissedWithoutReward?.call();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdFailedToShowFullScreenContent: (ad, error) {
        appLog('❌ Rewarded ad failed to show: $error');
        ad.dispose();
        loadAd();
        if (!completed) {
          completed = true;
          onUnavailable();
        }
      },
      onAdDismissedFullScreenContent: (_) {
        appLog('👋 Rewarded ad dismissed. earned=$earned');
        finish();
      },
    );

    ad.show(
      onUserEarnedReward: (_, reward) {
        earned = true;
        appLog('🎁 Reward earned: ${reward.amount} ${reward.type}');
      },
    );
  }
}
