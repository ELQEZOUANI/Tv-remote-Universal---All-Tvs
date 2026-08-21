import 'dart:ui';
import 'package:flutter/cupertino.dart';

/// Universal Remote Control – Premium Design System
class AppTheme {
  AppTheme._();

  // ── Core Dark Palette (Deep Burgundy) ───────────────────────────────────
  static const Color deepBg = Color(0xFF0E0507);
  static const Color midnight = Color(0xFF16070A);
  static const Color charcoal = Color(0xFF211015);
  static const Color surface = Color(0xFF2D151B);
  static const Color surfaceLight = Color(0xFF3A1D25);

  // ── Accent / Brand ────────────────────────────────────────────────────────
  static const Color primaryRed = Color(0xFFFF334D);
  static const Color crimson = Color(0xFFD90429);
  static const Color redMuted = Color(0xFFB80D2D);

  // ── Semantics ─────────────────────────────────────────────────────────────
  static const Color amber = Color(0xFFFFAB00);
  static const Color redAccent = Color(0xFFFF334D);
  static const Color connected = Color(0xFF34D399); // green status dot

  // ── Text / Neutral ────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteL60 = Color(0x99FFFFFF); // 60 % opacity
  static const Color whiteL30 = Color(0x4DFFFFFF); // 30 % opacity
  static const Color grey = Color(0xFFB8A4A8);
  static const Color greyDark = Color(0xFF786268);

  // ── Light Theme surface palette ───────────────────────────────────────────
  static const Color lightBg = Color(0xFFFFF7F8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFFE5092A);
  static const Color lightAccentD = Color(0xFFB80D2D);
  static const Color lightAccentBg = Color(0xFFFFEEF1);
  static const Color lightTitle = Color(0xFF27171A);
  static const Color lightSub = Color(0xFF775F65);
  static const Color lightDivider = Color(0xFFF1DDE1);

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// Primary brand gradient — vivid red → deep crimson.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryRed, crimson],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle dark card background gradient
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2A1319), Color(0xFF1B0A0E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Full-page background gradient (dark)
  static const LinearGradient bgGradient = LinearGradient(
    colors: [deepBg, Color(0xFF16070A), Color(0xFF240D13)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Power / destructive gradient
  static const LinearGradient powerGradient = LinearGradient(
    colors: [Color(0xFFFF334D), Color(0xFFA80724)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glow Shadows ─────────────────────────────────────────────────────────
  /// Ambient red glow — use on primary action surfaces.
  static List<BoxShadow> glowShadow({double intensity = 1.0}) => [
    BoxShadow(
      color: primaryRed.withValues(alpha: 0.28 * intensity),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: crimson.withValues(alpha: 0.14 * intensity),
      blurRadius: 48,
      spreadRadius: 0,
      offset: const Offset(0, 16),
    ),
  ];

  /// Subtle card elevation shadow (dark)
  static List<BoxShadow> darkCardShadow() => const [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 32,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  /// Luxury card shadow for light theme
  static List<BoxShadow> luxuryShadow() => const [
    BoxShadow(
      color: Color(0x1AD90429),
      blurRadius: 32,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadow() => const [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x07000000),
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  // ── Glassmorphism ─────────────────────────────────────────────────────────
  static BoxDecoration glass({
    double opacity = 0.08,
    double radius = 24,
    Color? border,
    Color? tint,
  }) => BoxDecoration(
    color: (tint ?? CupertinoColors.white).withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: border ?? CupertinoColors.white.withValues(alpha: 0.1),
      width: 0.8,
    ),
  );

  static Widget glassCard({
    required Widget child,
    double opacity = 0.08,
    double blur = 20,
    double radius = 24,
    EdgeInsets padding = const EdgeInsets.all(16),
    Color? border,
  }) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        padding: padding,
        decoration: glass(opacity: opacity, radius: radius, border: border),
        child: child,
      ),
    ),
  );

  // ── Neumorphic (kept for remote_view) ────────────────────────────────────
  static List<BoxShadow> neuShadow({bool pressed = false}) => pressed
      ? [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.6),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xFF401A22).withValues(alpha: 0.15),
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
        ]
      : [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.7),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: const Color(0xFF401A22).withValues(alpha: 0.2),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ];

  static BoxDecoration neuBox({
    bool pressed = false,
    double radius = 20,
    Color? color,
  }) => BoxDecoration(
    color: color ?? charcoal,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: neuShadow(pressed: pressed),
  );
}
