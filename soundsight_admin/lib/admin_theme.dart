import 'dart:math' as math;

import 'package:flutter/material.dart';

class AdminPalette {
  const AdminPalette({
    required this.background,
    required this.surface,
    required this.foreground,
    required this.muted,
    required this.border,
    required this.danger,
    required this.logo,
  });

  final Color background;
  final Color surface;
  final Color foreground;
  final Color muted;
  final Color border;
  final Color danger;
  final String logo;

  static AdminPalette of(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const AdminPalette(
        background: Color(0xFF121212),
        surface: Color(0xFF1E1E1E),
        foreground: Color(0xFFFAFAFA),
        muted: Color(0xFFA3A3A3),
        border: Color(0xFF2A2A2A),
        danger: Color(0xFFF87171),
        logo: 'assets/images/logo_image_dark.png',
      );
    }
    return const AdminPalette(
      background: Color(0xFFF3F3F3),
      surface: Colors.white,
      foreground: Color(0xFF111111),
      muted: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),
      danger: Color(0xFFDC2626),
      logo: 'assets/images/logo_image_light.png',
    );
  }
}

ThemeData adminTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final foreground = dark ? const Color(0xFFFAFAFA) : const Color(0xFF111111);
  final surface = dark ? const Color(0xFF1E1E1E) : Colors.white;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF121212) : const Color(0xFFF3F3F3),
    colorScheme: ColorScheme.fromSeed(
      seedColor: foreground,
      brightness: brightness,
      primary: foreground,
      surface: surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF3F3F3),
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: dark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(136, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(136, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(120, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

class AdminDialogFrame extends StatelessWidget {
  const AdminDialogFrame({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.subtitle,
    this.maxWidth = 720,
    this.preferredHeight = 620,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final double preferredHeight;

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    final screen = MediaQuery.sizeOf(context);
    final width = math.min(maxWidth, screen.width - 32);
    final height = math.min(
      preferredHeight,
      screen.height - MediaQuery.viewInsetsOf(context).bottom - 32,
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(subtitle!, style: TextStyle(color: colors.muted)),
                    ],
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: colors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: child,
              ),
            ),
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

class AdminMessage extends StatelessWidget {
  const AdminMessage({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AdminPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: colors.muted),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String adminDate(DateTime? date) {
  if (date == null) return 'Not available';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
