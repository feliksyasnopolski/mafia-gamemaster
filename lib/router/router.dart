import 'package:auto_route/auto_route.dart';

import "router.gr.dart";
import "login_guard.dart";

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {

  @override
  RouteType get defaultRouteType => RouteType.material();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: MainRoute.page, initial: true),
    AutoRoute(page: GameLogRoute.page),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: SettingsRoute.page),
    AutoRoute(page: GameRoute.page),
    AutoRoute(page: RolesRoute.page),
  ];

  @override
  List<AutoRouteGuard> get guards => [
    LoginGuard(),
    // optionally add root guards here
  ];
}