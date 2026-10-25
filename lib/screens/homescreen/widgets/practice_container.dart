import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/lessons/practice.dart';

class PracticeContainer extends StatelessWidget {
  const PracticeContainer({
    super.key,
    required this.practiceImage,
    required this.practiceTextColor,
    required this.practiceButtonColor,
    required this.practiceButtonTextColor,
    required this.borderColor,
  });

  final String practiceImage;
  final Color practiceTextColor;
  final Color practiceButtonColor;
  final Color practiceButtonTextColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          image: DecorationImage(
            image: AssetImage(practiceImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.startPractice,
                style: TextStyle(
                  color: practiceTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gap(AppSpacing.sm),
              SizedBox(
                width: 145,
                child: Text(
                  context.l10n.practiceBannerDescription,
                  style: TextStyle(
                    color: practiceTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ),
              Gap(AppSpacing.sm),
              SizedBox(
                width: 165,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const FundamentalsScreen()));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.center_focus_weak, size: 17),
                      const Gap(6),
                      Flexible(
                        child: Text(
                          context.l10n.startPractice,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: practiceButtonColor,
                    foregroundColor: practiceButtonTextColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
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
