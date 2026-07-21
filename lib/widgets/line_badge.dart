import 'package:flutter/material.dart';
import 'package:terka/theme/app_tokens.dart';

class LineBadge extends StatelessWidget {
  static const String spanFontFamily = 'MNR2007';
  static const double spanFontScale = 28 / 16;

  final String lineLabel;
  final Color routeColor;
  final Color routeTextColor;
  final bool useSpanFont;

  const LineBadge({
    super.key,
    required this.lineLabel,
    required this.routeColor,
    required this.routeTextColor,
    required this.useSpanFont,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: useSpanFont
          ? const EdgeInsets.symmetric(horizontal: AppSpacing.none, vertical: AppSpacing.none)
          : const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: routeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        lineLabel,
        style: TextStyle(
          color: routeTextColor,
          fontWeight: FontWeight.w700,
          fontSize: useSpanFont ? 12 * spanFontScale : null,
          fontFamily: useSpanFont ? spanFontFamily : null,
          leadingDistribution: useSpanFont
              ? TextLeadingDistribution.even
              : null,
          height: useSpanFont ? 1.0 : null,
        ),
      ),
    );
  }
}
