import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:soundsight/translations/generated/app_localizations.dart';
import 'package:soundsight/theme/app_colors.dart';

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
      duration: const Duration(milliseconds: 3000),
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
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
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
                              color: AppColors.lightSurface.withValues(
                                alpha: 0.55 + 0.25 * pulse,
                              ),
                              border: Border.all(color: AppColors.lightBorder),
                            ),
                            child: Container(
                              width: logoSize + 28,
                              height: logoSize + 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.lightSurface,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.lightPrimary.withValues(
                                      alpha: 0.06,
                                    ),
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
                        color: AppColors.lightPrimary,
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
                        color: AppColors.lightSecondaryText,
                        fontSize: 14,
                        letterSpacing: 0.1,
                      ),
                    ),
                    SizedBox(height: compact ? 32 : 48),
                    Semantics(
                      label: AppLocalizations.of(context).loading,
                      liveRegion: true,
                      child: ExcludeSemantics(
                        child: _PianoLoadingIndicator(animation: _controller),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).loading,
                      style: TextStyle(
                        color: AppColors.lightSecondaryText,
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

class _PianoLoadingIndicator extends StatelessWidget {
  const _PianoLoadingIndicator({required this.animation});

  final Animation<double> animation;

  static const _whiteNotes = [0, 2, 4, 5, 7, 9, 11];
  static const _blackNotes = [1, 3, 6, 8, 10];
  static const _blackKeyBoundaries = [1, 2, 4, 5, 6];
  static const _keyWidth = 15.0;
  static const _blackKeyWidth = 9.0;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return RepaintBoundary(
      child: Container(
        width: 113,
        height: 56,
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
        decoration: BoxDecoration(
          color: AppColors.lightPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            // Twelve notes per loop gives each key a 250 ms press and release.
            final progress = animation.value * 12;
            final activeNote = progress.floor().clamp(0, 11);
            final phase = progress - progress.floor();
            final press = disableAnimations
                ? 0.0
                : math.sin(math.pi * (phase / 0.85).clamp(0.0, 1.0));

            return Stack(
              children: [
                for (var index = 0; index < _whiteNotes.length; index++)
                  Positioned(
                    left: index * _keyWidth,
                    top: 0,
                    bottom: activeNote == _whiteNotes[index] ? 3 * press : 0,
                    width: _keyWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          AppColors.lightSurface,
                          AppColors.lightSecondaryText,
                          activeNote == _whiteNotes[index] ? 0.65 * press : 0,
                        ),
                        border: Border.all(
                          color: AppColors.lightPrimary,
                          width: 0.6,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                for (var index = 0; index < _blackNotes.length; index++)
                  Positioned(
                    left:
                        _blackKeyBoundaries[index] * _keyWidth -
                        _blackKeyWidth / 2,
                    top: activeNote == _blackNotes[index] ? 2 * press : 0,
                    width: _blackKeyWidth,
                    height: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          AppColors.lightPrimary,
                          AppColors.lightSecondaryText,
                          activeNote == _blackNotes[index] ? press : 0,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(2),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            offset: Offset(0, 2),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
