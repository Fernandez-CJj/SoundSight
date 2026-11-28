import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class HelpContactSection extends StatelessWidget {
  const HelpContactSection({super.key, required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                header: true,
                child: Text(
                  l10n.helpCenterContactHeading,
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.display,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.helpCenterContactIntroduction,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.label,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ContactCard(
                title: l10n.helpCenterCustomerService,
                icon: Icons.headset_mic_outlined,
                colors: colors,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ContactCard(
                title: l10n.helpCenterFacebook,
                icon: Icons.facebook_rounded,
                colors: colors,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ContactCard(
                title: l10n.helpCenterGmail,
                icon: Icons.mail_outline_rounded,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.title,
    required this.icon,
    required this.colors,
  });

  final String title;
  final IconData icon;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        // Keep contact destinations unset until the team's details are provided.
        enabled: false,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: AppIconSizes.md, color: colors.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.primaryColor,
            fontSize: AppTextSizes.body,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            context.l10n.helpCenterContactPending,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: AppTextSizes.label,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
