import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';

class TopNavbar extends StatefulWidget {
  final bool isDesktop;
  final VoidCallback onHomeTap;
  final VoidCallback onNewsTap;
  final VoidCallback onProfileTap;
  final int selectedDesktopTabIndex;
  final String mobileCurrentSectionTitle;

  const TopNavbar({
    super.key,
    required this.isDesktop,
    required this.onHomeTap,
    required this.onNewsTap,
    required this.onProfileTap,
    this.selectedDesktopTabIndex = 0,
    this.mobileCurrentSectionTitle = '',
  });

  @override
  State<TopNavbar> createState() => _TopNavbarState();
}

class _TopNavbarState extends State<TopNavbar> {
  int _eggCounter = 0;
  bool _showFox = false;

  void _onLogoTap() {
    if (_showFox) return;
    _eggCounter++;
    if (_eggCounter >= 10) {
      setState(() {
        _showFox = true;
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showFox = false;
            _eggCounter = 0;
          });
        }
      });
    }
  }

  Widget _buildDesktopNavButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool selected,
  }) {
    if (selected) {
      return FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.none),
          minimumSize: const Size(0, 40),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      tooltip: label,
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topPadding = MediaQuery.of(context).viewPadding.top;

    if (widget.isDesktop) {
      final navItems = <({String label, IconData icon, VoidCallback onTap})>[
        (label: AppTexts.home, icon: Icons.home, onTap: widget.onHomeTap),
        (label: AppTexts.mavNews, icon: Icons.newspaper, onTap: widget.onNewsTap),
        (label: AppTexts.profile, icon: Icons.person, onTap: widget.onProfileTap),
      ];

      final isDark = theme.brightness == Brightness.dark;
      final pillColor = isDark 
          ? colorScheme.surface.withValues(alpha: 0.6)
          : colorScheme.surface.withValues(alpha: 0.7);

      return Padding(
        padding: EdgeInsets.only(
          top: topPadding + 16,
          left: AppSpacing.lg,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: AppSpacing.xs),
                    _showFox
                        ? Image.asset(
                            'assets/pics/spinning_fox.gif',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          )
                        : GestureDetector(
                            onTap: _onLogoTap,
                            child: Image.asset(
                              'assets/icons/terka_logo_monochrome.png',
                              width: 24,
                              height: 24,
                              color: colorScheme.primary,
                            ),
                          ),
                    const SizedBox(width: AppSpacing.lg),
                    Container(
                      width: 1,
                      height: 24,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...List<Widget>.generate(navItems.length, (index) {
                      final item = navItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        child: _buildDesktopNavButton(
                          context: context,
                          label: item.label,
                          icon: item.icon,
                          onPressed: item.onTap,
                          selected: widget.selectedDesktopTabIndex == index,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: AppColors.getSurface(context),
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding + AppSpacing.lg,
          bottom: AppSpacing.lg,
          left: AppSpacing.md,
          right: AppSpacing.md,
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.touchTarget),
            const Spacer(),
            Text(
              'TERKA - ${widget.mobileCurrentSectionTitle}',
              style: TextStyle(
                fontSize: AppFontSizes.title,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            const SizedBox(width: AppSpacing.touchTarget),
          ],
        ),
      ),
    );
  }
}
