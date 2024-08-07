import "package:auto_route/auto_route.dart";

import "../utils/settings.dart";
import "router.gr.dart";

class LoginGuard extends AutoRouteGuard {
  @override
  Future<void> onNavigation(
      NavigationResolver resolver, StackRouter router) async {
    final settings = await getSettings();
    final isAuthenticated = settings.appToken.isNotEmpty;

    if (isAuthenticated || resolver.routeName == LoginRoute.name) {
      resolver.next();
    } else {
      await resolver.redirect(const LoginRoute());
    }
  }
}
