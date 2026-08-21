import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/app_logger.dart';

class AppOpenAdManager {
  static bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Platform-aware test Ad Unit IDs for App Open Ad
  static String get _adUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-2535194044471316/5266017504'; // iOS ad unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  /// Set to true while (or shortly after) another full-screen ad (like an Interstitial) is active,
  /// to prevent App Open Ads from triggering on lifecycle resume.
  static bool isOtherAdShowing = false;

  /// Completer that resolves when the current ad load finishes (success or fail).
  Completer<void>? _loadCompleter;

  bool get isAdAvailable => _appOpenAd != null;

  /// A future that completes when the ad has loaded (or failed to load).
  /// Returns immediately if no load is in progress.
  Future<void> get loadingFuture =>
      _loadCompleter?.future ?? Future<void>.value();

  void loadAd() {
    if (!_isSupportedPlatform) return;

    // Don't start a new load if one is already in progress
    if (_loadCompleter != null && !_loadCompleter!.isCompleted) return;

    _loadCompleter = Completer<void>();

    appLog('\n=================================');
    appLog('🔍 ADMOB DEBUG: Checking Ad Unit ID');
    appLog('Ad Unit ID: $_adUnitId');
    appLog('=================================\n');

    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          appLog('✅ App Open ad loaded successfully!');
          _appOpenAd = ad;
          if (!_loadCompleter!.isCompleted) _loadCompleter!.complete();
        },
        onAdFailedToLoad: (error) {
          appLog('❌ App Open ad failed to load: ${error.message}');
          debugPrint('AppOpenAd failed to load: $error');
          if (!_loadCompleter!.isCompleted) _loadCompleter!.complete();
        },
      ),
    );
  }

  void showAdIfAvailable() {
    if (!_isSupportedPlatform) return;

    if (!isAdAvailable || _isShowingAd || isOtherAdShowing) {
      appLog(
        '⚠️ App Open ad not ready, already showing, or suppressed by another ad (Available: $isAdAvailable, Showing: $_isShowingAd, OtherAd: $isOtherAdShowing)',
      );
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        appLog('📺 App Open ad displayed on screen!');
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        appLog('❌ App Open ad failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        appLog('👋 App Open ad dismissed, preloading next ad.');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }
}
