import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'providers/tv_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'views/splash_screen.dart';
import 'ads/app_open_ad_manager.dart';
import 'ads/interstitial_ad_manager.dart';
import 'ads/rewarded_ad_manager.dart';
import 'ads/app_lifecycle_reactor.dart';
import 'core/app_logger.dart';
import 'services/app_tracking_transparency_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final appOpenAdManager = AppOpenAdManager();
  final interstitialAdManager = InterstitialAdManager();
  final rewardedAdManager = RewardedAdManager();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TVProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AppOpenAdManager>.value(value: appOpenAdManager),
        Provider<InterstitialAdManager>.value(value: interstitialAdManager),
        Provider<RewardedAdManager>.value(value: rewardedAdManager),
      ],
      child: _AppStartup(
        appOpenAdManager: appOpenAdManager,
        interstitialAdManager: interstitialAdManager,
        rewardedAdManager: rewardedAdManager,
      ),
    ),
  );
}

/// Starts advertising only after iOS has resolved the ATT request.
class _AppStartup extends StatefulWidget {
  const _AppStartup({
    required this.appOpenAdManager,
    required this.interstitialAdManager,
    required this.rewardedAdManager,
  });

  final AppOpenAdManager appOpenAdManager;
  final InterstitialAdManager interstitialAdManager;
  final RewardedAdManager rewardedAdManager;

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeAds());
  }

  Future<void> _initializeAds() async {
    final trackingStatus =
        await AppTrackingTransparencyService.requestAuthorization();
    appLog('ATT authorization status: ${trackingStatus.name}');

    try {
      await MobileAds.instance.initialize();
      widget.appOpenAdManager.loadAd();
      widget.interstitialAdManager.loadAd();
      widget.rewardedAdManager.loadAd();
    } catch (error) {
      appLog('Unable to initialize ads: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycleReactor(
      appOpenAdManager: widget.appOpenAdManager,
      child: const UniversalRemoteApp(),
    );
  }
}

class UniversalRemoteApp extends StatelessWidget {
  const UniversalRemoteApp({super.key});

  static const _lightBg = AppTheme.lightBg;
  static const _lightText = AppTheme.lightTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    // Keep status-bar icons readable in both themes.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Tv remote Universal - All Tvs',
      theme: CupertinoThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primaryColor: AppTheme.primaryRed,
        scaffoldBackgroundColor: isDark ? AppTheme.midnight : _lightBg,
        barBackgroundColor: isDark
            ? AppTheme.midnight.withValues(alpha: 0.8)
            : _lightBg.withValues(alpha: 0.8),
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: '.SF Pro Display',
            color: isDark ? AppTheme.white : _lightText,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
