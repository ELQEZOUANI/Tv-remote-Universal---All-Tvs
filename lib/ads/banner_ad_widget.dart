import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/app_logger.dart';

/// A reusable widget that loads and displays an AdMob banner ad.
///
/// Automatically handles loading, error states, and disposal.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // Test Ad Unit IDs (replace with real IDs for production)
  static String get _adUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-2535194044471316/1446036465'; // iOS ad unit ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!_isSupportedPlatform) return;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner, // 320×50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          appLog('✅ Banner ad loaded successfully!');
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          appLog('❌ Banner ad failed to load: ${error.message}');
          ad.dispose();
          _bannerAd = null;
        },
        onAdOpened: (ad) => appLog('📺 Banner ad opened'),
        onAdClosed: (ad) => appLog('👋 Banner ad closed'),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // Return an empty container while loading / if failed
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
