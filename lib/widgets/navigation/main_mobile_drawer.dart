import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';

class MainMobileDrawer extends StatelessWidget {
  const MainMobileDrawer({super.key});

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
              decoration: const BoxDecoration(color: AppColors.transparent),
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
              onTap: () {
                Navigator.pop(context);
                context.go('/');
              },
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
                  onTap: () {
                    Navigator.pop(context);
                    // Usually this would go to a stops list, for now we can just close
                  },
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
              onTap: () {
                Navigator.pop(context);
                context.go('/news');
              },
            ),
            ListTile(
              title: Text(
                AppTexts.map,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/map');
              },
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
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/tickets');
                  },
                ),
                ListTile(
                  title: Text(
                    '  ${AppTexts.addTicket}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/tickets/add');
                  },
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
