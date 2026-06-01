import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class TopNavbar extends StatelessWidget {
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
    this.mobileCurrentSectionTitle = 'Tervezés',
  });

  Widget _buildDesktopNavButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool selected,
  }) {
    if (selected) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isDesktop) {
      final navItems = <({String label, IconData icon, VoidCallback onTap})>[
        (label: 'Főoldal', icon: Icons.home, onTap: onHomeTap),
        (label: 'Hírek', icon: Icons.newspaper, onTap: onNewsTap),
        (label: 'Profil', icon: Icons.person, onTap: onProfileTap),
      ];

      return ColoredBox(
        color: colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Text(
                'TERKA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: List<Widget>.generate(navItems.length, (index) {
                    final item = navItems[index];
                    return _buildDesktopNavButton(
                      context: context,
                      label: item.label,
                      icon: item.icon,
                      onPressed: item.onTap,
                      selected: selectedDesktopTabIndex == index,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.touchTarget),
            const Spacer(),
            Text(
              'TERKA - $mobileCurrentSectionTitle',
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
