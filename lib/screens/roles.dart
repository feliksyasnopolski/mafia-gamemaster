import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "../game/player.dart";

enum _ValidationErrorType {
  tooMany,
  tooFew,
  missing,
}

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  State<RolesScreen> createState() => _RolesScreenState();
}
class _RolesScreenState extends State<RolesScreen> {
  final _chosenNicknames = List<String?>.generate(10, (index) => null);
  final _chosenRoles = List<PlayerRole?>.filled(10, null);

  @override
  Widget build(BuildContext context) {
    final players = context.watch<GameController>().players;

    final nicknameEntries = [
      const DropdownMenuEntry(
        value: null,
        label: "",
        labelWidget: Text("(*без никнейма*)", style: TextStyle(fontStyle: FontStyle.italic)),
      ),
      for (final nickname in players.map((p) => p.nickname).toList(growable: false)..sort())
        DropdownMenuEntry(
          value: nickname,
          label: nickname,
          enabled: !_chosenNicknames.contains(nickname),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Раздача ролей"),
      ),
      body: SingleChildScrollView(
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(5),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: const [
                Center(child: Text("Игрок")),
                Center(child: Text("Роль")),
                Center(child: Text("")),
              ],
            ),
            for (var i=0; i<10; i++)
              TableRow(
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: DropdownMenu(
                        expandedInsets: EdgeInsets.zero,
                        enableFilter: true,
                        enableSearch: true,
                        label: Text("Игрок ${i + 1}"),
                        menuHeight: 256,
                        inputDecorationTheme: const InputDecorationTheme(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        // errorText: null,
                        requestFocusOnTap: true,
                        initialSelection: _chosenNicknames[i],
                        dropdownMenuEntries: nicknameEntries,
                        // onSelected: (value) => _onNicknameSelected(i, value),
                      ),
                    ),
                     Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: SegmentedButton(
                        segments: <ButtonSegment<PlayerRole>> [
                          for (final role in PlayerRole.values)
                            ButtonSegment(
                              label: Text(role.prettyName),
                              value: role,
                            ),
                        ],
                        selected: _chosenRoles[i] != null ? {_chosenRoles[i]!} : {},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            if (newSelection.isEmpty) {
                              _chosenRoles[i] = null;
                            } else {
                              print((newSelection.first! as PlayerRole).prettyName);
                              _chosenRoles[i] = newSelection.first! as PlayerRole;
                            }
                          });
                        },
                      )
                    ),
                     Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8)
                    ),
                ]
              )
          ],
        ),
      ),
    );
  }
}
