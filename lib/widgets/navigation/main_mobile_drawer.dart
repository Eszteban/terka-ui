import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class MainMobileDrawer extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onStationsTap;
  final VoidCallback onMapTap;

  const MainMobileDrawer({
    super.key,
    required this.onHomeTap,
    required this.onStationsTap,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: ColoredBox(
        color: AppColors.getSurface(context),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.none),
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Text(
                'Menü',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: AppFontSizes.drawerHeader,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: colorScheme.onSurface),
              title: Text(
                'Főoldal',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: onHomeTap,
            ),
            ExpansionTile(
              title: Text(
                'Listázások',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              iconColor: colorScheme.onSurface,
              collapsedIconColor: colorScheme.onSurface,
              children: [
                ListTile(
                  title: Text(
                    '  Megállók',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: onStationsTap,
                ),
                ListTile(
                  title: Text(
                    '  Vonalak',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            ListTile(
              title: Text(
                'MÁV Hírek',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text(
                'Térkép',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: onMapTap,
            ),
            ExpansionTile(
              title: Text(
                'Profil',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              iconColor: colorScheme.onSurface,
              collapsedIconColor: colorScheme.onSurface,
              children: [
                ListTile(
                  title: Text(
                    '  Admin felület',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  title: Text(
                    '  Kézi frissítés',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  title: Text(
                    '  Saját adatok szerkesztése',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  title: Text(
                    '  Jegyeim',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  title: Text(
                    '  Jegy hozzáadása',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            ListTile(
              title: Text(
                'Kijelentkezés',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text(
                'Bejelentkezés',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
