import 'package:flutter/material.dart';
import '../../theme/app_texts.dart';
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
                AppTexts.menu,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: AppFontSizes.drawerHeader,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: colorScheme.onSurface),
              title: Text(
                AppTexts.home,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: onHomeTap,
            ),
            ExpansionTile(
              title: Text(
                AppTexts.lists,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              iconColor: colorScheme.onSurface,
              collapsedIconColor: colorScheme.onSurface,
              children: [
                ListTile(
                  title: Text(
                    '  ${AppTexts.stops}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: onStationsTap,
                ),
                ListTile(
                  title: Text(
                    '  ${AppTexts.lines}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            ListTile(
              title: Text(
                AppTexts.mavNews,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text(
                AppTexts.map,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: onMapTap,
            ),
            ExpansionTile(
              title: Text(
                AppTexts.profile,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              iconColor: colorScheme.onSurface,
              collapsedIconColor: colorScheme.onSurface,
              children: [
                ListTile(
                  title: Text(
                    '  ${AppTexts.myTickets}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  title: Text(
                    '  ${AppTexts.addTicket}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            ListTile(
              title: Text(
                AppTexts.logout,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text(
                AppTexts.login,
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
