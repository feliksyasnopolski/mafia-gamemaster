import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:auto_route/auto_route.dart";

import "router.gr.dart";
import "../utils/settings.dart";

class LoginGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final SettingsModel settings = await getSettings();
    final isAuthenticated = settings.appToken.isNotEmpty;

    if(isAuthenticated || resolver.routeName == LoginRoute.name) {
      resolver.next();
    } else {
      await resolver.redirect(const LoginRoute());
    }
  }
}