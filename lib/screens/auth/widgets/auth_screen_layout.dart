import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_colors.dart';

class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: AppColors.lightBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.lightBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                image: DecorationImage(
                  image: AssetImage('assets/images/background_image.png'),
                  opacity: 0.8,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
