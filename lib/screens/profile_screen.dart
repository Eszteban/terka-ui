import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/app_texts.dart';
import 'add_ticket_screen.dart';
import 'about_screen.dart';
import 'tickets_screen.dart';
import 'manage_pass_types_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeMode selectedThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.selectedThemeMode,
    required this.onThemeModeChanged,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _desktopBreakpoint = 700.0;

  Future<void> _openTickets() async {
    final isDesktop = MediaQuery.of(context).size.width > _desktopBreakpoint;
    if (isDesktop) {
      await _showDesktopSurface<void>(
        child: const TicketsScreen(),
        maxWidth: 760,
        maxHeight: 760,
      );
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TicketsScreen()));
  }

  Future<void> _openAddTicket() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddTicketScreen()));
  }

  Future<void> _openManagePassTypes() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ManagePassTypesScreen()));
  }

  Future<void> _openAbout() async {
    final isDesktop = MediaQuery.of(context).size.width > _desktopBreakpoint;
    if (isDesktop) {
      await _showDesktopSurface<void>(
        child: const AboutScreen(),
        maxWidth: 760,
        maxHeight: 620,
      );
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
  }

  Future<T?> _showDesktopSurface<T>({
    required Widget child,
    double maxWidth = 720,
    double maxHeight = 760,
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;

    final bentoShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.4),
        width: 1,
      ),
    );
    final cardColor = isDark ? const Color(0xFF1A1615) : Colors.white;
    final cardElevation = isDark ? 0.0 : 2.0;
    final cardShadowColor = Colors.black.withValues(alpha: isDark ? 0.3 : 0.08);

    return ListView(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: cardElevation,
          shadowColor: cardShadowColor,
          shape: bentoShape,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTexts.profileLabelAppearance,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<ThemeMode>(
                  // MEGOLDÁS 1: Csökkentjük a belső paddingot, hogy több hely maradjon a szövegnek
                  style: SegmentedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode),
                      label: Text(
                        AppTexts.profileAppearanceVilagos,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow
                            .ellipsis, // Ha nagyon durván elfogyna a hely, inkább három pont legyen, mint csúnya törés
                      ),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode),
                      label: Text(
                        AppTexts.profileAppearanceSotet,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.settings_suggest),
                      // MEGOLDÁS 2: A FittedBox garantálja, hogy ha még a padding csökkentés után sem férne ki,
                      // akkor inkább picit lekicsinyíti a szöveget, de nem engedi kettéhasadni a szót.
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppTexts.profileAppearanceRendszer,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ],
                  selected: {widget.selectedThemeMode},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      widget.onThemeModeChanged(selection.first);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(AppTexts.profileLanguage, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment<AppLanguage>(
                      value: AppLanguage.hu,
                      icon: Icon(Icons.language),
                      label: Text('Magyar'),
                    ),
                    ButtonSegment<AppLanguage>(
                      value: AppLanguage.en,
                      icon: Icon(Icons.language),
                      label: Text('English'),
                    ),
                  ],
                  selected: {widget.selectedLanguage},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      widget.onLanguageChanged(selection.first);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        // Add spacing between the two main cards
        const SizedBox(height: AppSpacing.xl),
        Card(
          elevation: cardElevation,
          shadowColor: cardShadowColor,
          shape: bentoShape,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _ProfileActionButton(
                  icon: Icons.confirmation_num,
                  label: AppTexts.profileMyTickets,
                  onTap: _openTickets,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileActionButton(
                  icon: Icons.add_card,
                  label: AppTexts.profileAddTicket,
                  onTap: _openAddTicket,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileActionButton(
                  icon: Icons.card_membership,
                  label: AppTexts.profileManagePassTypes,
                  onTap: _openManagePassTypes,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          elevation: cardElevation,
          shadowColor: cardShadowColor,
          shape: bentoShape,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                _ProfileActionButton(
                  icon: Icons.info,
                  label: AppTexts.profileAboutApp,
                  onTap: _openAbout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon, size: AppFontSizes.title),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.touchTarget,
            AppSpacing.touchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
