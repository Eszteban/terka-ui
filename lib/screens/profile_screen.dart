import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../theme/app_tokens.dart';
import 'add_ticket_screen.dart';
import 'about_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'tickets_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeMode selectedThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const ProfileScreen({
    super.key,
    required this.selectedThemeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthApiService _authApiService = const AuthApiService();
  static const _desktopBreakpoint = 700.0;

  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await _authApiService.loadSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _session = session;
    });
  }

  Future<void> _openLogin() async {
    final isDesktop = MediaQuery.of(context).size.width > _desktopBreakpoint;
    final result = isDesktop
        ? await _showDesktopSurface<AuthSession>(
            child: const LoginScreen(),
            maxWidth: 560,
            maxHeight: 760,
          )
        : await Navigator.of(context).push<AuthSession>(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );

    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }

    setState(() {
      _session = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sikeres bejelentkezés: ${result.email}')),
    );
  }

  Future<void> _logout() async {
    await _authApiService.clearSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _session = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Kijelentkeztél.')));
  }

  Future<void> _openEditProfile() async {
    if (_session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A szerkesztéshez előbb jelentkezz be.')),
      );
      return;
    }

    final isDesktop = MediaQuery.of(context).size.width > _desktopBreakpoint;
    final changed = isDesktop
        ? await _showDesktopSurface<bool>(
            child: EditProfileScreen(session: _session!),
            maxWidth: 620,
            maxHeight: 840,
          )
        : await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(session: _session!),
            ),
          );

    if (changed == true) {
      await _loadSession();
    }
  }

  Future<void> _openTickets() async {
    if (_session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A jegyekhez előbb jelentkezz be.')),
      );
      return;
    }

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
    if (_session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jegy hozzáadásához előbb jelentkezz be.'),
        ),
      );
      return;
    }

    final isDesktop = MediaQuery.of(context).size.width > _desktopBreakpoint;
    if (isDesktop) {
      await _showDesktopSurface<void>(
        child: const AddTicketScreen(),
        maxWidth: 660,
        maxHeight: 860,
      );
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddTicketScreen()));
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
                Text('Megjelenés', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Világos'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Sötét'),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_suggest),
                      label: Text('Rendszer'),
                    ),
                  ],
                  selected: {widget.selectedThemeMode},
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      widget.onThemeModeChanged(selection.first);
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
                if (_session != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bejelentkezve: ${_session!.email}\nFelhasználónév: ${_session!.username}',
                      style: textTheme.titleSmall,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileActionButton(
                  icon: _session == null ? Icons.login : Icons.logout,
                  label: _session == null ? 'Bejelentkezés' : 'Kijelentkezés',
                  onTap: _session == null ? _openLogin : _logout,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileActionButton(
                  icon: Icons.edit,
                  label: 'Saját adatok szerkesztése',
                  onTap: _openEditProfile,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileActionButton(
                  icon: Icons.confirmation_num,
                  label: 'Jegyeim',
                  onTap: _openTickets,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProfileActionButton(
                  icon: Icons.add_card,
                  label: 'Jegy hozzáadása',
                  onTap: _openAddTicket,
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
                  label: 'Alkalmazás névjegye',
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
