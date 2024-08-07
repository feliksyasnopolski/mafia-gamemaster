
import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "../router/router.gr.dart";
import "../utils/settings.dart";


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfo = context.watch<PackageInfo>();
    final settings = context.watch<SettingsModel>();

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Center(
              child: Text("MafiaArena", style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Настройки"),
            onTap: () {
              context.router.push(const SettingsRoute());
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text("Выход"),
            onTap: () {
              settings.setAppToken("");
              context.router.replace(const LoginRoute());
            },
          ),
        ],
      ),
    );
  }
}
