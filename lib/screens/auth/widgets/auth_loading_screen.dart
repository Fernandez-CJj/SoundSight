import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:soundsight/l10n/generated/app_localizations.dart';

/// Shown while the saved session and the user's destination are being checked.
class AuthLoadingScreen extends StatefulWidget {
  const AuthLoadingScreen({super.key});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const foreground = Color(0xFF171A20);
    const accent = Color(0xFFB47B36);
    const muted = Color(0xFF6F737B);
    const halo = Color(0xFFF2E8D8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 560;
            final logoSize = compact ? 104.0 : 136.0;

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final pulse =
                            (math.sin(_controller.value * 2 * math.pi) + 1) / 2;
                        return Transform.translate(
                          offset: Offset(0, -4 * pulse),
                          child: Container(
                            width: logoSize + 56,
                            height: logoSize + 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: halo.withValues(
                                alpha: 0.55 + 0.25 * pulse,
                              ),
                              border: Border.all(
                                color: accent.withValues(
                                  alpha: 0.16 + 0.18 * pulse,
                                ),
                              ),
                            ),
                            child: Container(
                              width: logoSize + 28,
                              height: logoSize + 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 28,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo_image_light.png',
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: compact ? 24 : 34),
                    Text(
                      'SoundSight',
                      style: TextStyle(
                        color: foreground,
                        fontSize: compact ? 29 : 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'See the music. Play with confidence',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(height: compact ? 32 : 48),
                    Semantics(
                      label: AppLocalizations.of(context).loading,
                      liveRegion: true,
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                final wave = math.sin(
                                  _controller.value * 2 * math.pi -
                                      index * math.pi / 3,
                                );
                                return Container(
                                  width: 4,
                                  height: 10 + 18 * (wave + 1) / 2,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).loading,
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
