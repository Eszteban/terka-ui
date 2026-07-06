import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../controllers/navigation_cubit.dart';
import '../../theme/app_texts.dart';
import '../../theme/app_tokens.dart';

class MainMobileDrawer extends StatelessWidget {
  const MainMobileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final navCubit = context.read<NavigationCubit>();

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
              onTap: () {
                Navigator.pop(context);
                navCubit.navigateTo(MainSection.home);
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
                    navCubit.navigateTo(MainSection.stopDetails);
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
                navCubit.navigateTo(MainSection.news);
              },
            ),
            ListTile(
              title: Text(
                AppTexts.map,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                navCubit.navigateTo(MainSection.map);
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
                    navCubit.navigateTo(MainSection.tickets);
                  },
                ),
                ListTile(
                  title: Text(
                    '  ${AppTexts.addTicket}',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    navCubit.navigateTo(MainSection.addTicket);
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
