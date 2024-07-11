import "package:flutter/material.dart";

import "../game/log.dart";
import "../screens/roles.dart";
import "../screens/game_log.dart";
import "../screens/roles.dart";
import "../screens/seat_randomizer.dart";
import "../screens/settings.dart";

Future<void> openPage(BuildContext context, Widget page) async {
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => page));
}

Future<void> openRoleChooserPage(BuildContext context) =>
    openPage(context, const RolesScreen());