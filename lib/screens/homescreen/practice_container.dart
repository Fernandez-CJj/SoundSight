import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../constants/constant.dart';

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
                'Start AR Practice',
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
                  'Use AR to visualize notes,\nimprove accuracy, and\nelevate your performance.',
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
                width: 128,
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.center_focus_weak, size: 17),
                  label: Text(
                    'Start Practice',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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
