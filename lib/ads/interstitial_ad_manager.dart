import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_open_ad_manager.dart';
import '../core/app_logger.dart';

/// Manages loading and displaying full-screen Interstitial Ads.
class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  static bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get _adUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-2535194044471316/7756449475'; // iOS ad unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Preloads an Interstitial Ad into memory.
  void loadAd() {
    if (!_isSupportedPlatform) return;

    if (_interstitialAd != null || _isLoading) return;
    _isLoading = true;

    appLog('\n=================================');
    appLog('🔍 ADMOB DEBUG: Loading Interstitial Ad');
    appLog('Ad Unit ID: $_adUnitId');
    appLog('=================================\n');

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          appLog('✅ Interstitial ad loaded successfully!');
          _interstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          appLog('❌ Interstitial ad failed to load: ${error.message}');
          _interstitialAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// Displays the interstitial ad if ready, and invokes [onAdDismissed] when closed.
  /// If the ad is not ready, invokes [onAdDismissed] immediately and preloads for next time.
  void showAdThen({required VoidCallback onAdDismissed}) {
    if (!_isSupportedPlatform) {
      onAdDismissed();
      return;
    }

    if (_interstitialAd == null) {
      appLog(
        '⚠️ Interstitial ad not ready yet, proceeding with action directly.',
      );
      loadAd();
      onAdDismissed();
      return;
    }

    AppOpenAdManager.isOtherAdShowing = true;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        appLog('📺 Interstitial ad displayed on screen!');
        AppOpenAdManager.isOtherAdShowing = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        appLog('❌ Interstitial ad failed to show: $error');
        AppOpenAdManager.isOtherAdShowing = false;
        ad.dispose();
        _interstitialAd = null;
        loadAd();
        onAdDismissed();
      },
      onAdDismissedFullScreenContent: (ad) {
        appLog('👋 Interstitial ad dismissed by user.');
        ad.dispose();
        _interstitialAd = null;
        loadAd();
        onAdDismissed();

        // Suppress App Open Ad for 5s so lifecycle resume event doesn't trigger an App Open Ad
        Timer(const Duration(seconds: 5), () {
          AppOpenAdManager.isOtherAdShowing = false;
        });
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
