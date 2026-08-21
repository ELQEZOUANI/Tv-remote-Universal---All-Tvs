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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final appOpenAdManager = AppOpenAdManager();
  appOpenAdManager.loadAd();

  final interstitialAdManager = InterstitialAdManager();
  interstitialAdManager.loadAd();

  final rewardedAdManager = RewardedAdManager();
  rewardedAdManager.loadAd();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TVProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AppOpenAdManager>.value(value: appOpenAdManager),
        Provider<InterstitialAdManager>.value(value: interstitialAdManager),
        Provider<RewardedAdManager>.value(value: rewardedAdManager),
      ],
      child: AppLifecycleReactor(
        appOpenAdManager: appOpenAdManager,
        child: const UniversalRemoteApp(),
      ),
    ),
  );
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
