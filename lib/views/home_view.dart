import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, BoxShadow, Divider, LinearGradient, Icons;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ads/interstitial_ad_manager.dart';
import '../ads/rewarded_ad_manager.dart';
import '../providers/tv_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../remote_engine.dart';

import '../widgets/premium_widgets.dart';
import 'remote_view.dart';

void _startScanWithAd(BuildContext context, TVProvider pv) {
  final interstitialAdManager = context.read<InterstitialAdManager>();
  interstitialAdManager.showAdThen(
    onAdDismissed: () {
      pv.startScan();
    },
  );
}

void _openSearchPageWithAd(BuildContext context) {
  final navigator = Navigator.of(context);
  final interstitialAdManager = context.read<InterstitialAdManager>();
  interstitialAdManager.showAdThen(
    onAdDismissed: () {
      if (!context.mounted) return;
      navigator.push(
        CupertinoPageRoute<void>(builder: (_) => const _DeviceSearchPage()),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Design-token helpers (theme-aware)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  _T._();

  // ── Backgrounds ──
  static Color bg(bool d) => d ? AppTheme.deepBg : AppTheme.lightBg;
  static Color card(bool d) => d ? AppTheme.charcoal : AppTheme.lightCard;
  static Color divider(bool d) =>
      d ? const Color(0xFF4A2028) : AppTheme.lightDivider;

  // ── Text ──
  static Color title(bool d) => d ? AppTheme.white : AppTheme.lightTitle;
  static Color sub(bool d) => d ? AppTheme.grey : AppTheme.lightSub;

  // ── Brand ──
  static Color accent(bool d) => d ? AppTheme.primaryRed : AppTheme.lightAccent;
  static Color accentDeep(bool d) =>
      d ? AppTheme.crimson : AppTheme.lightAccentD;
  static Color accentBg(bool d) =>
      d ? AppTheme.primaryRed.withValues(alpha: 0.12) : AppTheme.lightAccentBg;
  static Color accentBorder(bool d) =>
      d ? AppTheme.primaryRed.withValues(alpha: 0.25) : const Color(0xFFF3B8C4);
  static Color inputBg(bool d) =>
      d ? AppTheme.surface : const Color(0xFFFFF9FA);

  static List<BoxShadow> cardShadow(bool d) =>
      d ? AppTheme.darkCardShadow() : AppTheme.cardShadow();
  static List<BoxShadow> luxuryShadow(bool d) =>
      d ? AppTheme.glowShadow() : AppTheme.luxuryShadow();
}

// ─────────────────────────────────────────────────────────────────────────────
//  HomeView
// ─────────────────────────────────────────────────────────────────────────────
class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  late AnimationController _radarCtrl;

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<TVProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;

    return CupertinoPageScaffold(
      backgroundColor: _T.bg(isDark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NewDashboardBackground(isDark: isDark),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _NewDashboardHeader(index: _navIndex, isDark: isDark, pv: pv),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 180),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.985, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_navIndex),
                        child: _navIndex == 1
                            ? _NewRecentPage(pv: pv, isDark: isDark)
                            : _navIndex == 2
                            ? _NewSettingsPage(isDark: isDark)
                            : _NewHomePage(
                                pv: pv,
                                radarCtrl: _radarCtrl,
                                isDark: isDark,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 68,
            child: _NewBottomDock(
              index: _navIndex,
              isDark: isDark,
              onTap: (i) {
                if (i == 2 && _navIndex != 2) {
                  context.read<InterstitialAdManager>().showAdThen(
                    onAdDismissed: () {
                      setState(() => _navIndex = i);
                    },
                  );
                } else {
                  setState(() => _navIndex = i);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Premium Top Bar
// ─────────────────────────────────────────────────────────────────────────────
// Retained temporarily for migration compatibility with older screen snapshots.
// ignore: unused_element
class _PremiumTopBar extends StatelessWidget {
  final bool isDark;
  final TVProvider pv;

  const _PremiumTopBar({required this.isDark, required this.pv});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Row(
        children: [
          // Logo mark + wordmark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              boxShadow: AppTheme.glowShadow(intensity: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/images/icon_red.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tv remote Universal - All Tvs',
                  style: TextStyle(
                    color: _T.title(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                Text(
                  'Universal Control',
                  style: TextStyle(
                    color: _T.sub(isDark),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          GlowIconButton(
            icon: CupertinoIcons.tv_music_note,
            isDark: isDark,
            accent: true,
            onTap: () {
              if (pv.activeDevice != null && pv.isConnected) {
                Navigator.of(
                  context,
                ).push(CupertinoPageRoute(builder: (_) => const RemoteView()));
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Device Section  (Scan card + device list)
// ─────────────────────────────────────────────────────────────────────────────
// ignore: unused_element
class _DeviceSection extends StatelessWidget {
  final TVProvider pv;
  final AnimationController radarCtrl;
  final bool isDark;

  const _DeviceSection({
    required this.pv,
    required this.radarCtrl,
    required this.isDark,
  });

  void _showPairDialog(BuildContext ctx, TVDevice device) {
    showCupertinoDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _PairingDialog(device: device, isDark: isDark),
    );
  }

  void _showManualDialog(BuildContext ctx) {
    String ip = '';
    showCupertinoDialog(
      context: ctx,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Manual IP'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              const Text(
                "Enter the TV's local IP address.",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                autofocus: true,
                keyboardType: TextInputType.url,
                placeholder: '192.168.1.x',
                onChanged: (v) => ip = v,
                decoration: BoxDecoration(
                  color: _T.inputBg(isDark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _T.divider(isDark)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Connect'),
            onPressed: () {
              ctx.read<TVProvider>().probeManualIp(ip);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section header ────────────────────────────────────────────────
        _SectionHeader(
          label: 'AVAILABLE DEVICES',
          isDark: isDark,
          trailing: pv.scanning
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoActivityIndicator(
                      color: _T.accent(isDark),
                      radius: 7,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scanning',
                      style: TextStyle(
                        color: _T.accent(isDark).withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : PremiumTap(
                  onTap: () => _startScanWithAd(context, pv),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.refresh,
                        size: 13,
                        color: _T.accent(isDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rescan',
                        style: TextStyle(
                          color: _T.accent(isDark),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        // ── Connecting banner ─────────────────────────────────────────────
        if (pv.isConnecting) _ConnectingBanner(isDark: isDark),

        const SizedBox(height: 4),

        if (pv.devices.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Scan / Radar CTA ────────────────────────────────
              ScanDeviceCard(
                scanning: pv.scanning,
                isDark: isDark,
                radarCtrl: radarCtrl,
                onTap: () => _startScanWithAd(context, pv),
              ),

              const SizedBox(height: 20),

              // ── Quick Tips ─────────────────────────────────────
              _QuickTipsCard(isDark: isDark),
            ],
          )
        else
          // ── Device list ───────────────────────────────────────────────
          _DeviceListCard(
            pv: pv,
            isDark: isDark,
            onDeviceTap: (dev) => _showPairDialog(context, dev),
            onManual: () => _showManualDialog(context),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section header strip
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  final Widget? trailing;

  const _SectionHeader({
    required this.label,
    required this.isDark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_T.accent(isDark), _T.accentDeep(isDark)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: _T.sub(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Connecting Banner
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectingBanner extends StatelessWidget {
  final bool isDark;
  const _ConnectingBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_T.accent(isDark), _T.accentDeep(isDark)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.glowShadow(intensity: 0.8),
      ),
      child: const Row(
        children: [
          CupertinoActivityIndicator(color: Colors.white, radius: 9),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connecting to TV…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Accept the pairing prompt on your TV screen.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Quick Tips Card
// ─────────────────────────────────────────────────────────────────────────────
class _QuickTipsCard extends StatelessWidget {
  final bool isDark;
  const _QuickTipsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: _T.card(isDark),
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: const Color(0xFF4A2028), width: 0.8)
            : null,
        boxShadow: _T.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK TIPS',
            style: TextStyle(
              color: _T.sub(isDark),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ScanTip(
            icon: Icons.wifi,
            iconColor: _T.accent(isDark),
            title: 'Same Wi-Fi Network',
            subtitle: 'Ensure phone and TV are on the same Wi-Fi.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          ScanTip(
            icon: Icons.tv,
            iconColor: const Color(0xFF5B6AF0),
            title: 'Turn on your TV',
            subtitle: 'Make sure the TV is fully powered on, not in standby.',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          ScanTip(
            icon: Icons.security,
            iconColor: const Color(0xFFFFAB00),
            title: 'Disable VPN',
            subtitle: 'Turn off any active VPNs on your device.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Device List Card
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceListCard extends StatelessWidget {
  final TVProvider pv;
  final bool isDark;
  final void Function(TVDevice) onDeviceTap;
  final VoidCallback onManual;

  const _DeviceListCard({
    required this.pv,
    required this.isDark,
    required this.onDeviceTap,
    required this.onManual,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.card(isDark),
        borderRadius: BorderRadius.circular(28),
        border: isDark
            ? Border.all(color: const Color(0xFF4A2028), width: 0.8)
            : null,
        boxShadow: _T.luxuryShadow(isDark),
      ),
      child: Column(
        children: [
          ...pv.devices.asMap().entries.map((e) {
            final i = e.key;
            final dev = e.value;
            final active = pv.activeDevice?.ip == dev.ip;
            return Column(
              children: [
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, color: _T.divider(isDark)),
                  ),
                _DeviceRow(
                  device: dev,
                  active: active,
                  connected: active && pv.isConnected,
                  isDark: isDark,
                  onTap: () => onDeviceTap(dev),
                  onWake: () => pv.wakeDevice(dev),
                ),
              ],
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: _T.divider(isDark)),
          ),
          PremiumTap(
            onTap: onManual,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _T.accentBg(isDark),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _T.accentBorder(isDark)),
                    ),
                    child: Icon(
                      CupertinoIcons.add,
                      color: _T.accent(isDark),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add device manually',
                          style: TextStyle(
                            color: _T.accent(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enter IP address',
                          style: TextStyle(color: _T.sub(isDark), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: _T.accentBorder(isDark),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: _T.divider(isDark)),
          ),
          PremiumTap(
            onTap: () => _startScanWithAd(context, pv),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _T.accentBg(isDark),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _T.accentBorder(isDark)),
                    ),
                    child: Icon(
                      CupertinoIcons.search,
                      color: _T.accent(isDark),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search again for devices',
                          style: TextStyle(
                            color: _T.accent(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rescan Wi-Fi network for TVs',
                          style: TextStyle(color: _T.sub(isDark), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: _T.accentBorder(isDark),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Device Row
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceRow extends StatefulWidget {
  final TVDevice device;
  final bool active, connected, isDark;
  final VoidCallback onTap, onWake;

  const _DeviceRow({
    required this.device,
    required this.active,
    required this.connected,
    required this.isDark,
    required this.onTap,
    required this.onWake,
  });

  @override
  State<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends State<_DeviceRow> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: _p
              ? _T.accentBg(d)
              : widget.active
              ? _T.accentBg(d)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: widget.active
              ? Border.all(color: _T.accentBorder(d), width: 1.2)
              : null,
        ),
        child: Row(
          children: [
            // TV icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: widget.active
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_T.accent(d), _T.accentDeep(d)],
                      )
                    : null,
                color: widget.active ? null : _T.bg(d),
                borderRadius: BorderRadius.circular(18),
                boxShadow: widget.active
                    ? [
                        BoxShadow(
                          color: _T.accent(d).withValues(alpha: 0.30),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                CupertinoIcons.tv_fill,
                color: widget.active ? Colors.white : _T.sub(d),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.device.name,
                    style: TextStyle(
                      color: widget.active ? _T.accent(d) : _T.title(d),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.connected
                              ? AppTheme.connected
                              : _T.divider(d),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.connected ? 'Connected' : widget.device.ip,
                        style: TextStyle(
                          color: widget.connected
                              ? AppTheme.connected
                              : _T.sub(d),
                          fontSize: 12,
                          fontWeight: widget.connected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.connected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_T.accent(d), _T.accentDeep(d)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: AppTheme.glowShadow(intensity: 0.5),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: widget.onWake,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _T.bg(d),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _T.divider(d)),
                  ),
                  child: Icon(
                    CupertinoIcons.bolt_fill,
                    color: _T.sub(d),
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pairing Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _PairingDialog extends StatefulWidget {
  final TVDevice device;
  final bool isDark;
  const _PairingDialog({required this.device, required this.isDark});

  @override
  State<_PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<_PairingDialog> {
  String _phase = 'confirm';
  String _code = '';

  Future<void> _startConnect() async {
    setState(() => _phase = 'connecting');
    final pv = context.read<TVProvider>();
    pv.prepareService(widget.device);

    if (pv.needsPairing) {
      final ok = await pv.startPairing(widget.device);
      if (!mounted) return;
      if (ok) {
        setState(() => _phase = 'entering_code');
      } else {
        setState(() => _phase = 'error');
      }
      return;
    }

    final ok = await pv.connectTo(widget.device);
    if (!mounted) return;
    setState(() => _phase = ok ? 'success' : 'error');
  }

  Future<void> _submitCode() async {
    if (_code.isEmpty) return;
    setState(() => _phase = 'connecting');
    final pv = context.read<TVProvider>();
    final ok = await pv.submitPairingCode(_code);
    if (!mounted) return;

    if (ok) {
      // Token saved, now actually connect on the normal port
      final connected = await pv.connectTo(widget.device);
      if (!mounted) return;
      setState(() => _phase = connected ? 'success' : 'error');
    } else {
      setState(() => _phase = 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(_title()),
      content: Padding(padding: const EdgeInsets.only(top: 12), child: _body()),
      actions: _actions(),
    );
  }

  String _title() {
    switch (_phase) {
      case 'connecting':
        return 'Pairing…';
      case 'entering_code':
        return 'Enter Code';
      case 'success':
        return 'Connected!';
      case 'error':
        return 'Connection Failed';
      default:
        return 'Connect to TV';
    }
  }

  Widget _body() {
    switch (_phase) {
      case 'connecting':
        return const Column(
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: 12),
            Text(
              'Connecting to your TV…',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 'entering_code':
        return Column(
          children: [
            const Text(
              'Please enter the code shown on your TV screen.',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              autofocus: true,
              keyboardType: TextInputType.visiblePassword,
              placeholder: 'Enter code',
              textAlign: TextAlign.center,
              onChanged: (v) => _code = v,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
                fontSize: 20,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case 'success':
        return Text(
          '"${widget.device.name}" is ready to control.',
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        );
      case 'error':
        return Column(
          children: [
            Text(
              'Could not connect to "${widget.device.name}".',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Please check the following:\n'
                '• TV is turned on and not in standby\n'
                '• Devices are on the same Wi-Fi\n'
                '• Accepted pairing prompt on TV\n'
                '• VPN is disabled on this device',
                style: TextStyle(fontSize: 13, height: 1.4),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        );
      default:
        return Text(
          'Your TV will show a pairing prompt.\nPlease accept it on "${widget.device.name}".',
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        );
    }
  }

  List<CupertinoDialogAction> _actions() {
    if (_phase == 'connecting') return [];
    if (_phase == 'entering_code') {
      return [
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _submitCode,
          child: const Text('Submit'),
        ),
      ];
    }
    if (_phase == 'success') {
      return [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: Text(
            context.read<TVProvider>().isRemoteUnlocked(widget.device)
                ? 'Open Remote'
                : 'Watch ad to unlock',
          ),
          onPressed: () {
            final navigator = Navigator.of(context);
            final rewardedAds = context.read<RewardedAdManager>();
            final pv = context.read<TVProvider>();

            void openRemote() {
              if (!context.mounted) return;
              Navigator.pop(context);
              navigator.push(
                CupertinoPageRoute(builder: (_) => const RemoteView()),
              );
            }

            if (pv.isRemoteUnlocked(widget.device)) {
              openRemote();
              return;
            }

            void unlockAndOpen() {
              // Persist before opening the remote so a quick app restart does
              // not ask for the reward again after it has already been earned.
              unawaited(() async {
                try {
                  await pv.markRemoteUnlocked(widget.device);
                } catch (_) {
                  // The ad reward still unlocks this session if persistence
                  // is temporarily unavailable.
                }
                openRemote();
              }());
            }

            rewardedAds.showAdThen(
              onRewarded: unlockAndOpen,
              // Unsupported platforms and unavailable ads must not block a
              // successfully connected TV.
              onUnavailable: unlockAndOpen,
              onDismissedWithoutReward: () {
                if (!context.mounted) return;
                _showUnlockMessage(context);
              },
            );
          },
        ),
      ];
    }
    if (_phase == 'error') {
      return [
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _startConnect,
          child: const Text('Try Again'),
        ),
      ];
    }
    return [
      CupertinoDialogAction(
        isDestructiveAction: true,
        child: const Text('Cancel'),
        onPressed: () => Navigator.pop(context),
      ),
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: _startConnect,
        child: const Text('Connect'),
      ),
    ];
  }

  void _showUnlockMessage(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Remote still locked'),
        content: Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Watch the full reward video to unlock your remote.'),
        ),
        actions: [CupertinoDialogAction(child: Text('OK'))],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Recent Devices View
// ─────────────────────────────────────────────────────────────────────────────
// ignore: unused_element
class _RecentView extends StatelessWidget {
  final TVProvider pv;
  final bool isDark;
  const _RecentView({required this.pv, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final recent = pv.recentDevices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(label: 'RECENTLY CONNECTED', isDark: isDark),
        if (recent.isEmpty)
          // ── Premium empty state ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: _T.card(isDark),
              borderRadius: BorderRadius.circular(28),
              border: isDark
                  ? Border.all(color: const Color(0xFF4A2028), width: 0.8)
                  : null,
              boxShadow: _T.cardShadow(isDark),
            ),
            child: EmptyRecentState(isDark: isDark),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _T.card(isDark),
              borderRadius: BorderRadius.circular(28),
              border: isDark
                  ? Border.all(color: const Color(0xFF4A2028), width: 0.8)
                  : null,
              boxShadow: _T.cardShadow(isDark),
            ),
            child: Column(
              children: [
                ...recent.asMap().entries.map((e) {
                  final i = e.key;
                  final dev = e.value;
                  final isActive = pv.activeDevice?.ip == dev.ip;
                  return Column(
                    children: [
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: _T.divider(isDark)),
                        ),
                      PremiumTap(
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) =>
                                _PairingDialog(device: dev, isDark: isDark),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: isActive
                                      ? LinearGradient(
                                          colors: [
                                            _T.accent(isDark),
                                            _T.accentDeep(isDark),
                                          ],
                                        )
                                      : null,
                                  color: isActive ? null : _T.bg(isDark),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isActive
                                      ? AppTheme.glowShadow(intensity: 0.5)
                                      : null,
                                ),
                                child: Icon(
                                  CupertinoIcons.tv_fill,
                                  color: isActive
                                      ? Colors.white
                                      : _T.sub(isDark),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dev.name,
                                      style: TextStyle(
                                        color: _T.title(isDark),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      dev.ip,
                                      style: TextStyle(
                                        color: _T.sub(isDark),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive && pv.isConnected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _T.accentBg(isDark),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: _T.accentBorder(isDark),
                                    ),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      color: _T.accent(isDark),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  color: _T.divider(isDark),
                                  size: 15,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Settings View
// ─────────────────────────────────────────────────────────────────────────────
// ignore: unused_element
class _SettingsView extends StatelessWidget {
  final bool isDark;
  const _SettingsView({required this.isDark});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Premium branding header card ────────────────────────────────
        _BrandingHeader(isDark: isDark),
        const SizedBox(height: 28),

        // ── Support section ─────────────────────────────────────────────
        _SectionHeader(label: 'SUPPORT', isDark: isDark),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.05,
          padding: EdgeInsets.zero,
          children: [
            PremiumSquareTile(
              icon: CupertinoIcons.star_fill,
              iconColor: const Color(0xFFFFB800),
              iconBg: isDark
                  ? const Color(0xFFFFB800).withValues(alpha: 0.14)
                  : const Color(0xFFFFF8E1),
              title: 'Rate the App',
              subtitle: 'Enjoying it? Leave a review!',
              isDark: isDark,
              onTap: () => _launch(
                'https://apps.apple.com/app/id6803202067?action=write-review',
              ),
            ),
            PremiumSquareTile(
              icon: CupertinoIcons.share_solid,
              iconColor: const Color(0xFF7B8FFF),
              iconBg: isDark
                  ? const Color(0xFF7B8FFF).withValues(alpha: 0.14)
                  : const Color(0xFFEEF0FD),
              title: 'Share with Friends',
              subtitle: 'Spread the word',
              isDark: isDark,
              onTap: () => _launch('https://apps.apple.com/app/id6803202067'),
            ),
            PremiumSquareTile(
              icon: CupertinoIcons.envelope_fill,
              iconColor: _T.accent(isDark),
              iconBg: _T.accentBg(isDark),
              title: 'Contact Us',
              subtitle: 'Get help or send feedback',
              isDark: isDark,
              onTap: () => _launch('mailto:zaykarda@yahoo.com'),
            ),
            PremiumSquareTile(
              icon: CupertinoIcons.doc_text_fill,
              iconColor: isDark
                  ? const Color(0xFFA0A9C0)
                  : const Color(0xFF8E8E93),
              iconBg: isDark
                  ? const Color(0xFF4A2028)
                  : const Color(0xFFF2F2F7),
              title: 'Privacy Policy',
              subtitle: 'Terms of use and privacy information',
              isDark: isDark,
              onTap: () => _launch(
                'https://tv-remote-universal.blogspot.com/2026/08/tv-remote-universal-all-tvs.html',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Branding Header (Settings top)
// ─────────────────────────────────────────────────────────────────────────────
class _BrandingHeader extends StatelessWidget {
  final bool isDark;
  const _BrandingHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppTheme.primaryRed.withValues(alpha: 0.18)
                  : AppTheme.lightAccent.withValues(alpha: 0.20),
              width: 0.8,
            ),
            boxShadow: _T.cardShadow(isDark),
          ),
          child: Column(
            children: [
              // Glowing icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glowShadow(intensity: 0.8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/icon_red.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tv remote Universal - All Tvs',
                style: TextStyle(
                  color: _T.title(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _T.accentBg(isDark),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _T.accentBorder(isDark)),
                ),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: _T.accent(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Dashboard 2.0 — editorial red/white layout
// ═════════════════════════════════════════════════════════════════════════════

class _NewDashboardBackground extends StatelessWidget {
  final bool isDark;

  const _NewDashboardBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? const Color(0xFF0B0708) : const Color(0xFFFFFAFB),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -110,
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                color: _T
                    .accent(isDark)
                    .withValues(alpha: isDark ? 0.13 : 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 128,
            right: 0,
            child: Container(width: 76, height: 5, color: _T.accent(isDark)),
          ),
          Positioned(
            bottom: 160,
            left: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _T.accent(isDark).withValues(alpha: 0.10),
                  width: 32,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewDashboardHeader extends StatelessWidget {
  final int index;
  final bool isDark;
  final TVProvider pv;

  const _NewDashboardHeader({
    required this.index,
    required this.isDark,
    required this.pv,
  });

  @override
  Widget build(BuildContext context) {
    const titles = ['Control center', 'Connection log', 'Your space'];
    const numbers = ['01', '02', '03'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 44,
            height: 62,
            color: _T.accent(isDark),
            alignment: Alignment.center,
            child: Text(
              numbers[index],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TV / UNIVERSAL CONTROL',
                  style: TextStyle(
                    color: _T.accent(isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  titles[index],
                  style: TextStyle(
                    color: _T.title(isDark),
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: pv.isConnected
                ? () => Navigator.of(
                    context,
                  ).push(CupertinoPageRoute(builder: (_) => const RemoteView()))
                : null,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: pv.isConnected ? _T.accent(isDark) : _T.card(isDark),
                border: Border.all(color: _T.divider(isDark)),
              ),
              child: Icon(
                CupertinoIcons.tv,
                color: pv.isConnected ? Colors.white : _T.sub(isDark),
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewHomePage extends StatelessWidget {
  final TVProvider pv;
  final AnimationController radarCtrl;
  final bool isDark;

  const _NewHomePage({
    required this.pv,
    required this.radarCtrl,
    required this.isDark,
  });

  void _showPairDialog(BuildContext context, TVDevice device) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PairingDialog(device: device, isDark: isDark),
    );
  }

  void _showManualDialog(BuildContext context) {
    String ip = '';
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Connect by IP'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: CupertinoTextField(
            autofocus: true,
            keyboardType: TextInputType.url,
            placeholder: '192.168.1.100',
            onChanged: (value) => ip = value.trim(),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (ip.isNotEmpty) pv.probeManualIp(ip);
              Navigator.pop(dialogContext);
            },
            child: const Text('Find TV'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your phone is now\nthe remote.',
          style: TextStyle(
            color: _T.title(isDark),
            fontSize: 34,
            height: 1.02,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Discover a screen on the same Wi-Fi and start controlling it instantly.',
          style: TextStyle(color: _T.sub(isDark), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        _NewScanConsole(
          pv: pv,
          radarCtrl: radarCtrl,
          isDark: isDark,
          onScan: () => _openSearchPageWithAd(context),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _NewInfoStrip(
                icon: CupertinoIcons.wifi,
                label: 'NETWORK',
                value: pv.wifiName?.replaceAll('"', '') ?? 'Local Wi-Fi',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NewInfoStrip(
                icon: CupertinoIcons.tv,
                label: 'FOUND',
                value: '${pv.devices.length} screens',
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _NewSectionTitle(
          number: 'A',
          title: pv.devices.isEmpty ? 'Before you scan' : 'Screens nearby',
          isDark: isDark,
          action: GestureDetector(
            onTap: () => _showManualDialog(context),
            child: Text(
              'USE IP',
              style: TextStyle(
                color: _T.accent(isDark),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (pv.isConnecting)
          _NewInlineStatus(
            text: 'Waiting for confirmation on your TV…',
            isDark: isDark,
          ),
        if (pv.devices.isEmpty)
          _NewChecklist(isDark: isDark, timedOut: pv.scanTimedOut)
        else
          ...pv.devices.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NewDeviceRow(
                index: entry.key + 1,
                device: entry.value,
                isDark: isDark,
                isActive: pv.activeDevice?.ip == entry.value.ip,
                isConnected:
                    pv.activeDevice?.ip == entry.value.ip && pv.isConnected,
                onTap: () => _showPairDialog(context, entry.value),
              ),
            ),
          ),
      ],
    );
  }
}

class _NewScanConsole extends StatelessWidget {
  final TVProvider pv;
  final AnimationController radarCtrl;
  final bool isDark;
  final VoidCallback onScan;

  const _NewScanConsole({
    required this.pv,
    required this.radarCtrl,
    required this.isDark,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.accent(isDark),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(48),
          bottomLeft: Radius.circular(48),
        ),
        boxShadow: [
          BoxShadow(
            color: _T.accent(isDark).withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -52,
            right: -36,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 28,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: Colors.white.withValues(alpha: 0.14),
                      child: Text(
                        pv.scanning ? 'SCANNING NOW' : 'READY TO DISCOVER',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    RotationTransition(
                      turns: radarCtrl,
                      child: const Icon(
                        CupertinoIcons.dot_radiowaves_left_right,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  pv.scanning ? 'Looking around…' : 'Find your TV',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pv.scanning
                      ? 'Checking the local network for supported screens.'
                      : 'Samsung, LG, Roku, Android TV and more.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: pv.scanning ? null : onScan,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: pv.scanning
                        ? CupertinoActivityIndicator(
                            color: _T.accent(false),
                            radius: 10,
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.search,
                                color: _T.accent(false),
                                size: 18,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                'START NETWORK SCAN',
                                style: TextStyle(
                                  color: _T.accent(false),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewInfoStrip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _NewInfoStrip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      color: _T.card(isDark),
      child: Row(
        children: [
          Icon(icon, color: _T.accent(isDark), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _T.sub(isDark),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _T.title(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewSectionTitle extends StatelessWidget {
  final String number;
  final String title;
  final bool isDark;
  final Widget? action;

  const _NewSectionTitle({
    required this.number,
    required this.title,
    required this.isDark,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          number,
          style: TextStyle(
            color: _T.accent(isDark),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Container(width: 26, height: 1, color: _T.accent(isDark)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: _T.title(isDark),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _NewInlineStatus extends StatelessWidget {
  final String text;
  final bool isDark;

  const _NewInlineStatus({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CupertinoActivityIndicator(color: _T.accent(isDark), radius: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: _T.sub(isDark), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewChecklist extends StatelessWidget {
  final bool isDark;
  final bool timedOut;

  const _NewChecklist({required this.isDark, required this.timedOut});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: CupertinoIcons.wifi,
        title: 'Same network',
        detail: 'Phone and TV share Wi-Fi',
      ),
      (
        icon: CupertinoIcons.power,
        title: 'TV awake',
        detail: 'Not sleeping or on standby',
      ),
      (
        icon: CupertinoIcons.shield,
        title: 'VPN off',
        detail: 'Local devices are visible',
      ),
    ];

    return Column(
      children: [
        if (timedOut)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            color: _T.accentBg(isDark),
            child: Text(
              'No screen answered yet. Check these three things and scan again.',
              style: TextStyle(
                color: _T.accent(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ...items.asMap().entries.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            color: _T.card(isDark),
            child: Row(
              children: [
                Text(
                  '0${entry.key + 1}',
                  style: TextStyle(
                    color: _T.accent(isDark),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(entry.value.icon, color: _T.title(isDark), size: 18),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value.title,
                        style: TextStyle(
                          color: _T.title(isDark),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.value.detail,
                        style: TextStyle(color: _T.sub(isDark), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: _T.accent(isDark).withValues(alpha: 0.65),
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NewDeviceRow extends StatelessWidget {
  final int index;
  final TVDevice device;
  final bool isDark;
  final bool isActive;
  final bool isConnected;
  final VoidCallback onTap;

  const _NewDeviceRow({
    required this.index,
    required this.device,
    required this.isDark,
    required this.isActive,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78,
        color: _T.card(isDark),
        child: Row(
          children: [
            Container(
              width: 5,
              height: double.infinity,
              color: isActive ? _T.accent(isDark) : _T.divider(isDark),
            ),
            SizedBox(
              width: 54,
              child: Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: _T.accent(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _T.title(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected ? 'LIVE • ${device.brandLabel}' : device.ip,
                    style: TextStyle(
                      color: isConnected ? AppTheme.connected : _T.sub(isDark),
                      fontSize: 11,
                      fontWeight: isConnected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 74,
              height: double.infinity,
              color: isActive ? _T.accentBg(isDark) : Colors.transparent,
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.arrow_right,
                color: _T.accent(isDark),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewRecentPage extends StatelessWidget {
  final TVProvider pv;
  final bool isDark;

  const _NewRecentPage({required this.pv, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final devices = pv.recentDevices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 100,
              height: 112,
              color: _T.accent(isDark),
              alignment: Alignment.center,
              child: Text(
                devices.length.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAVED\nSCREENS',
                    style: TextStyle(
                      color: _T.title(isDark),
                      fontSize: 24,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your fastest route back to a TV.',
                    style: TextStyle(color: _T.sub(isDark), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _NewSectionTitle(
          number: 'B',
          title: devices.isEmpty ? 'How history works' : 'Tap to reconnect',
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        if (devices.isEmpty)
          const _NewEmptyTimeline()
        else
          ...devices.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NewDeviceRow(
                index: entry.key + 1,
                device: entry.value,
                isDark: isDark,
                isActive: pv.activeDevice?.ip == entry.value.ip,
                isConnected:
                    pv.activeDevice?.ip == entry.value.ip && pv.isConnected,
                onTap: () => showCupertinoDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      _PairingDialog(device: entry.value, isDark: isDark),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NewEmptyTimeline extends StatelessWidget {
  const _NewEmptyTimeline();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    const steps = [
      ('01', 'Scan', 'Find a TV on your network'),
      ('02', 'Pair', 'Approve the prompt on your screen'),
      ('03', 'Return', 'It will be waiting here next time'),
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final isLast = entry.key == steps.length - 1;
        final step = entry.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 42,
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    color: _T.accent(isDark),
                    alignment: Alignment.center,
                    child: Text(
                      step.$1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(width: 1, height: 54, color: _T.divider(isDark)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.$2,
                      style: TextStyle(
                        color: _T.title(isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.$3,
                      style: TextStyle(color: _T.sub(isDark), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _NewSettingsPage extends StatelessWidget {
  final bool isDark;

  const _NewSettingsPage({required this.isDark});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 150,
          color: _T.card(isDark),
          child: Row(
            children: [
              Container(
                width: 112,
                color: _T.accent(isDark),
                alignment: Alignment.center,
                child: const Text(
                  'TV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'TV REMOTE\nUNIVERSAL\nALL TVS',
                        style: TextStyle(
                          color: _T.title(isDark),
                          fontSize: 21,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'VERSION 1.0.0 / BUILD 4',
                        style: TextStyle(
                          color: _T.sub(isDark),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _NewSectionTitle(number: 'C', title: 'Preferences', isDark: isDark),
        const SizedBox(height: 14),
        _NewSettingRow(
          index: '01',
          icon: isDark
              ? CupertinoIcons.moon_stars_fill
              : CupertinoIcons.sun_max_fill,
          title: 'Appearance',
          subtitle: isDark ? 'Dark mode' : 'Light mode',
          isDark: isDark,
          trailing: CupertinoSwitch(
            value: isDark,
            activeTrackColor: _T.accent(isDark),
            onChanged: (_) => context.read<ThemeProvider>().toggle(),
          ),
          onTap: () => context.read<ThemeProvider>().toggle(),
        ),
        const SizedBox(height: 30),
        _NewSectionTitle(number: 'D', title: 'Support', isDark: isDark),
        const SizedBox(height: 14),
        _NewSettingRow(
          index: '02',
          icon: CupertinoIcons.star_fill,
          title: 'Rate the app',
          subtitle: 'Tell others what you think',
          isDark: isDark,
          onTap: () => _launch(
            'https://apps.apple.com/app/id6803202067?action=write-review',
          ),
        ),
        _NewSettingRow(
          index: '03',
          icon: CupertinoIcons.share_solid,
          title: 'Share with friends',
          subtitle: 'Send the App Store link',
          isDark: isDark,
          onTap: () => _launch('https://apps.apple.com/app/id6803202067'),
        ),
        _NewSettingRow(
          index: '04',
          icon: CupertinoIcons.envelope_fill,
          title: 'Contact support',
          subtitle: 'Questions, issues or feedback',
          isDark: isDark,
          onTap: () => _launch('mailto:zaykarda@yahoo.com'),
        ),
        _NewSettingRow(
          index: '05',
          icon: CupertinoIcons.doc_text_fill,
          title: 'Privacy policy',
          subtitle: 'Read terms and privacy details',
          isDark: isDark,
          onTap: () => _launch(
            'https://tv-remote-universal.blogspot.com/2026/08/tv-remote-universal-all-tvs.html',
          ),
        ),
      ],
    );
  }
}

class _NewSettingRow extends StatelessWidget {
  final String index;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;

  const _NewSettingRow({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        margin: const EdgeInsets.only(bottom: 1),
        color: _T.card(isDark),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Center(
                child: Text(
                  index,
                  style: TextStyle(
                    color: _T.accent(isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              color: _T.accentBg(isDark),
              child: Icon(icon, color: _T.accent(isDark), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _T.title(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: _T.sub(isDark), fontSize: 11),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child:
                  trailing ??
                  Icon(
                    CupertinoIcons.arrow_up_right,
                    color: _T.accent(isDark),
                    size: 17,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewBottomDock extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final bool isDark;

  const _NewBottomDock({
    required this.index,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (CupertinoIcons.house_fill, 'HOME'),
      (CupertinoIcons.clock_fill, 'RECENT'),
      (CupertinoIcons.gear_alt_fill, 'SETTINGS'),
    ];

    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF130A0C) : Colors.white,
        border: Border(top: BorderSide(color: _T.divider(isDark))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (itemIndex) {
          final active = index == itemIndex;
          final item = items[itemIndex];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(itemIndex);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: active ? 42 : 32,
                    height: 34,
                    color: active ? _T.accent(isDark) : Colors.transparent,
                    alignment: Alignment.center,
                    child: Icon(
                      item.$1,
                      color: active ? Colors.white : _T.sub(isDark),
                      size: active ? 18 : 17,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: active ? _T.accent(isDark) : _T.sub(isDark),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dedicated TV search route
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceSearchPage extends StatefulWidget {
  const _DeviceSearchPage();

  @override
  State<_DeviceSearchPage> createState() => _DeviceSearchPageState();
}

class _DeviceSearchPageState extends State<_DeviceSearchPage>
    with SingleTickerProviderStateMixin {
  late final TVProvider _provider;
  late final AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _provider = context.read<TVProvider>();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_provider.startScan());
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _closeSearch() async {
    if (_provider.scanning) await _provider.stopScan();
    if (mounted) Navigator.pop(context);
  }

  void _showPairDialog(TVDevice device, bool isDark) {
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PairingDialog(device: device, isDark: isDark),
    );
  }

  void _showManualDialog() {
    String ip = '';
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Connect by IP'),
        content: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: CupertinoTextField(
            autofocus: true,
            keyboardType: TextInputType.url,
            placeholder: '192.168.1.100',
            onChanged: (value) => ip = value.trim(),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              if (ip.isNotEmpty) unawaited(_provider.probeManualIp(ip));
            },
            child: const Text('Find TV'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TVProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final devices = provider.devices;

    return CupertinoPageScaffold(
      backgroundColor: _T.bg(isDark),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NewDashboardBackground(isDark: isDark),
          SafeArea(
            child: Column(
              children: [
                _SearchPageHeader(
                  isDark: isDark,
                  scanning: provider.scanning,
                  onBack: () => unawaited(_closeSearch()),
                  onScanAction: provider.scanning
                      ? () => unawaited(provider.stopScan())
                      : () => unawaited(provider.startScan()),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 34),
                    children: [
                      _SearchProgressCard(
                        provider: provider,
                        isDark: isDark,
                        animation: _radarController,
                      ),
                      const SizedBox(height: 26),
                      _NewSectionTitle(
                        number: '01',
                        title: devices.isEmpty
                            ? 'Searching for screens'
                            : '${devices.length} screen${devices.length == 1 ? '' : 's'} found',
                        isDark: isDark,
                        action: GestureDetector(
                          onTap: _showManualDialog,
                          child: Text(
                            'USE IP',
                            style: TextStyle(
                              color: _T.accent(isDark),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (devices.isEmpty)
                        _SearchEmptyState(
                          status: provider.discoveryStatus,
                          scanning: provider.scanning,
                          isDark: isDark,
                          onRetry: () => unawaited(provider.startScan()),
                          onManual: _showManualDialog,
                        )
                      else
                        ...devices.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _NewDeviceRow(
                              index: entry.key + 1,
                              device: entry.value,
                              isDark: isDark,
                              isActive:
                                  provider.activeDevice?.ip == entry.value.ip,
                              isConnected:
                                  provider.activeDevice?.ip == entry.value.ip &&
                                  provider.isConnected,
                              onTap: () => _showPairDialog(entry.value, isDark),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPageHeader extends StatelessWidget {
  final bool isDark;
  final bool scanning;
  final VoidCallback onBack;
  final VoidCallback onScanAction;

  const _SearchPageHeader({
    required this.isDark,
    required this.scanning,
    required this.onBack,
    required this.onScanAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: Container(
              width: 46,
              height: 46,
              color: _T.accent(isDark),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.arrow_left,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TV SEARCH',
                  style: TextStyle(
                    color: _T.accent(isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nearby screens',
                  style: TextStyle(
                    color: _T.title(isDark),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onScanAction,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: _T.card(isDark),
              alignment: Alignment.center,
              child: Text(
                scanning ? 'STOP' : 'RESCAN',
                style: TextStyle(
                  color: _T.accent(isDark),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchProgressCard extends StatelessWidget {
  final TVProvider provider;
  final bool isDark;
  final Animation<double> animation;

  const _SearchProgressCard({
    required this.provider,
    required this.isDark,
    required this.animation,
  });

  String get _statusLabel {
    switch (provider.discoveryStatus) {
      case DiscoveryStatus.requestingPermission:
        return 'REQUESTING ACCESS';
      case DiscoveryStatus.triggeringNetwork:
        return 'OPENING LOCAL NETWORK';
      case DiscoveryStatus.scanning:
        return 'LISTENING FOR TVS';
      case DiscoveryStatus.probing:
        return 'CHECKING NEARBY ADDRESSES';
      case DiscoveryStatus.networkError:
        return 'WI-FI UNAVAILABLE';
      case DiscoveryStatus.permissionDenied:
        return 'ACCESS REQUIRED';
      case DiscoveryStatus.finished:
        return 'SEARCH COMPLETE';
      case DiscoveryStatus.idle:
        return provider.scanning ? 'PREPARING SEARCH' : 'READY TO SEARCH';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      color: _T.accent(isDark),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (index) {
                    final progress = (animation.value + index / 3) % 1;
                    final diameter = 74 + (progress * 190);
                    return Container(
                      width: diameter,
                      height: diameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: (1 - progress) * 0.28,
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                provider.scanning
                    ? CupertinoIcons.dot_radiowaves_left_right
                    : CupertinoIcons.tv,
                color: _T.accent(false),
                size: 28,
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Row(
              children: [
                if (provider.scanning) ...[
                  const CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: 8,
                  ),
                  const SizedBox(width: 9),
                ],
                Expanded(
                  child: Text(
                    _statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Text(
                  '${provider.devices.length.toString().padLeft(2, '0')} FOUND',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final DiscoveryStatus status;
  final bool scanning;
  final bool isDark;
  final VoidCallback onRetry;
  final VoidCallback onManual;

  const _SearchEmptyState({
    required this.status,
    required this.scanning,
    required this.isDark,
    required this.onRetry,
    required this.onManual,
  });

  (String, String, IconData) get _content {
    if (scanning) {
      return (
        'Searching your Wi-Fi',
        'TVs will appear here as soon as they answer. This can take up to 25 seconds.',
        CupertinoIcons.search,
      );
    }
    if (status == DiscoveryStatus.networkError) {
      return (
        'Wi-Fi is unavailable',
        'Connect this phone to the same Wi-Fi network as your TV, then try again.',
        CupertinoIcons.wifi_slash,
      );
    }
    if (status == DiscoveryStatus.permissionDenied) {
      return (
        'Local network access is off',
        'Enable Local Network access for Tv remote Universal - All Tvs in device Settings.',
        CupertinoIcons.lock_shield,
      );
    }
    if (status == DiscoveryStatus.finished) {
      return (
        'No TVs found',
        'Confirm the TV is awake, VPN is off, and both devices use the same Wi-Fi.',
        CupertinoIcons.tv,
      );
    }
    return (
      'Preparing the search',
      'The app is getting local-network discovery ready.',
      CupertinoIcons.time,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    return Container(
      padding: const EdgeInsets.all(22),
      color: _T.card(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            color: _T.accentBg(isDark),
            child: Icon(content.$3, color: _T.accent(isDark), size: 21),
          ),
          const SizedBox(height: 18),
          Text(
            content.$1,
            style: TextStyle(
              color: _T.title(isDark),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            content.$2,
            style: TextStyle(color: _T.sub(isDark), fontSize: 13, height: 1.45),
          ),
          if (!scanning) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      height: 48,
                      color: _T.accent(isDark),
                      alignment: Alignment.center,
                      child: const Text(
                        'SEARCH AGAIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onManual,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: _T.accentBg(isDark),
                    alignment: Alignment.center,
                    child: Text(
                      'USE IP',
                      style: TextStyle(
                        color: _T.accent(isDark),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
