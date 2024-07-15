import "package:flutter/material.dart";

import "../screens/roles.dart";

Future<void> openPage(BuildContext context, Widget page) async {
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => page));
}

Future<void> openRoleChooserPage(BuildContext context) =>
    openPage(context, const RolesScreen());
