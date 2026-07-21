import 'package:flutter/material.dart';
import 'package:terka/theme/app_texts.dart';
import '../../../utils/stop_details_utils.dart';
import 'package:terka/theme/app_tokens.dart';

class StopLineSelector extends StatefulWidget {
  final List<Map<String, dynamic>> uniqueLines;
  final Set<String> selectedLines;
  final void Function(String line, bool selected) onLineSelected;
  final VoidCallback onClearSelection;

  const StopLineSelector({
    super.key,
    required this.uniqueLines,
    required this.selectedLines,
    required this.onLineSelected,
    required this.onClearSelection,
  });

  @override
  State<StopLineSelector> createState() => _StopLineSelectorState();
}

class _StopLineSelectorState extends State<StopLineSelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uniqueLines.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: AppColors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.none),
          leading: Icon(
            Icons.filter_list_rounded,
            color: primaryColor,
            size: 22,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppTexts.stopLineFilterTitle} (${widget.selectedLines.isEmpty ? (AppTexts.isHungarian ? 'mind' : 'all') : widget.selectedLines.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.white.withValues(alpha: 0.9) : AppColors.black.withValues(alpha: 0.87),
                ),
              ),
              if (widget.selectedLines.isNotEmpty)
                TextButton(
                  onPressed: widget.onClearSelection,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    AppTexts.stopLineFilterReset,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.none, AppSpacing.md, AppSpacing.md),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.uniqueLines.map((line) {
                          final shortName = line['shortName'].toString();
                          final isSelected = widget.selectedLines.contains(shortName);
                          final routeColor = StopDetailsUtils.hexColor(line['color']?.toString() ?? '0A84FF');
                          final routeTextColor = StopDetailsUtils.hexColor(line['textColor']?.toString() ?? 'FFFFFF');
                          final useSpanFont = line['useSpanFont'] == true;

                          return FilterChip(
                            label: Text(shortName),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? routeTextColor : (isDark ? AppColors.white.withValues(alpha: 0.70) : AppColors.black.withValues(alpha: 0.87)),
                              fontSize: useSpanFont ? 12 * (28 / 16) : 12,
                              fontFamily: useSpanFont ? 'MNR2007' : null,
                              leadingDistribution: useSpanFont ? TextLeadingDistribution.even : null,
                              height: useSpanFont ? 1.0 : null,
                            ),
                            selected: isSelected,
                            checkmarkColor: routeTextColor,
                            selectedColor: routeColor,
                            backgroundColor: routeColor.withValues(alpha: 0.15),
                            side: BorderSide(
                              color: isSelected ? routeColor : routeColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            padding: useSpanFont
                                ? const EdgeInsets.symmetric(horizontal: AppSpacing.none, vertical: AppSpacing.none)
                                : const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.none),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onSelected: (selected) {
                              widget.onLineSelected(shortName, selected);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
