import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// A two-option mode control whose selected color fills its entire segment.
class PracticeModeToggle<T> extends StatelessWidget {
  const PracticeModeToggle({
    super.key,
    required this.firstValue,
    required this.firstLabel,
    required this.secondValue,
    required this.secondLabel,
    required this.selectedValue,
    required this.colors,
    this.onChanged,
  });

  final T firstValue;
  final String firstLabel;
  final T secondValue;
  final String secondLabel;
  final T selectedValue;
  final AppThemeColors colors;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: colors.backgroundColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegment(firstValue, firstLabel),
              Container(width: 1, height: 38, color: colors.borderColor),
              _buildSegment(secondValue, secondLabel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(T value, String label) {
    final selected = selectedValue == value;
    final VoidCallback? select = onChanged == null || selected
        ? null
        : () => onChanged!(value);

    return Semantics(
      button: true,
      excludeSemantics: true,
      selected: selected,
      enabled: onChanged != null,
      label: label,
      onTap: select,
      child: Ink(
        color: selected ? colors.primaryColor : colors.backgroundColor,
        child: InkWell(
          excludeFromSemantics: true,
          onTap: select,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 86),
            child: SizedBox(
              height: 38,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? colors.backgroundColor
                          : colors.primaryColor,
                      fontSize: AppTextSizes.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
