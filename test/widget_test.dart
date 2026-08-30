import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tvremote/main.dart';
import 'package:tvremote/providers/tv_provider.dart';
import 'package:tvremote/providers/theme_provider.dart';
import 'package:tvremote/ads/app_open_ad_manager.dart';
import 'package:tvremote/ads/interstitial_ad_manager.dart';
import 'package:tvremote/views/remote_view.dart';

void main() {
  test('Light theme is enabled by default', () {
    expect(ThemeProvider().isDark, isFalse);
  });

  testWidgets('App shows splash and then renders dashboard', (
    WidgetTester tester,
  ) async {
    final adManager = AppOpenAdManager();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TVProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<AppOpenAdManager>.value(value: adManager),
          Provider<InterstitialAdManager>.value(value: InterstitialAdManager()),
        ],
        child: const UniversalRemoteApp(),
      ),
    );
    await tester.pump();
    expect(find.text('TV Remote'), findsOneWidget);

    // The splash has a repeating glow animation, so pump exact durations
    // instead of pumpAndSettle (which would never settle).
    await tester.pump(const Duration(milliseconds: 5400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Control center'), findsOneWidget);

    await tester.ensureVisible(find.text('START NETWORK SCAN'));
    await tester.tap(find.text('START NETWORK SCAN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('TV SEARCH'), findsOneWidget);
  });

  testWidgets('Remote preserves its D-pad, touchpad, and number-pad modes', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(440, 956));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TVProvider(),
        child: const CupertinoApp(home: RemoteView()),
      ),
    );

    expect(find.text('PRIMARY CONTROL'), findsOneWidget);
    expect(find.text('D-PAD'), findsOneWidget);

    await tester.tap(find.text('Touchpad'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Swipe to navigate'), findsOneWidget);

    await tester.ensureVisible(find.text('Open number pad'));
    await tester.tap(find.text('Open number pad'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('NUMBER PAD'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
