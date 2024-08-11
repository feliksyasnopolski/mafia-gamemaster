import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";

import "../router/router.gr.dart";

Future<void> openRoleChooserPage(BuildContext context) =>
    context.router.push(const RolesRoute());

Future<void> openMainPage(BuildContext context) =>
    context.router.replace(const MainRoute());

Future<void> openGamePage(BuildContext context) =>
    context.router.replace(const GameRoute());

Future<void> openGameLogPage(BuildContext context) =>
    context.router.push(const GameLogRoute());

Future<void> openSettingsPage(BuildContext context) =>
    context.router.push(const SettingsRoute());

Future<void> openLoginPage(BuildContext context) =>
    context.router.replace(const LoginRoute());
