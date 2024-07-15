import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../screens/game.dart";
import "../utils/api_calls.dart";
import "../utils/api_models.dart";
import "../utils/errors.dart";
import "../utils/game_controller.dart";
import "../utils/navigation.dart";
import "../utils/ui.dart";


enum _ValidationErrorType {
  tooMany,
  tooFew,
  missing,
}

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final _chosenNicknames = List<String?>.generate(10, (index) => null);
  final _chosenRoles = List<PlayerRole?>.filled(10, null);

  final _errorsByRole = <PlayerRole, _ValidationErrorType>{};
  final _errorsByIndex = <int>{};

  Future<void> _onFabPressed(BuildContext context) async {
    setState(_validate);
    if (_errorsByIndex.isNotEmpty || _errorsByRole.isNotEmpty) {
      unawaited(showSnackBar(context, const SnackBar(content: Text("Для продолжения исправьте ошибки"))));
      return;
    }

    // final newRoles = _chosenRoles.toList(growable: false);
    final players = <Player>[];
    
    for (var i = 0; i < 10; i++) {
      if (_chosenRoles[i] != null) {
        final nickname = _chosenNicknames[i] ?? "Игрок ${i + 1}";
        players.add(Player(
          number: i+1,
          nickname: nickname,
          role: _chosenRoles[i]!,
        ),);
      }
    }

    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    // if (showRoles == null) {
    //   return;
    // }
    setState(() {
      context.read<GameController>().players = players;
    });

    if (context.mounted)
    {
      context.read<GameController>().startWithPlayers();
    }
    await openPage(context, const GameScreen());
  }

  void _onNicknameSelected(int index, String? value) {
    setState(() {
      _chosenNicknames[index] = value;
    });
  }

    /// Validates roles. Must be called from `setState` to update errors.
  void _validate() {
    final byRole = <PlayerRole, _ValidationErrorType>{};
    final byIndex = <int>{};

    // check if no roles are selected for player
    for (var i = 0; i < 10; i++) {
      if (_chosenRoles[i] == null) {
        byIndex.add(i);
      }
    }

    // check if role is not chosen at least given amount of times
    final counter = <PlayerRole, int>{
      for (final role in PlayerRole.values) role: 0,
    };

    for (final rolesChoice in _chosenRoles) {
      if (rolesChoice != null) {
        counter.update(rolesChoice, (value) => value + 1);
      }
    }

    for (final entry in counter.entries) {
      final requiredCount = roles[entry.key]!;
      if (entry.value > requiredCount) {
        byRole[entry.key] = _ValidationErrorType.tooMany;
      }
    }

    for (final entry in counter.entries) {
      final minimumCount = roles[entry.key]!;
      if (entry.value < minimumCount) {
        byRole[entry.key] =
            entry.value > 0 ? _ValidationErrorType.tooFew : _ValidationErrorType.missing;
      }
    }

    _errorsByRole
      ..clear()
      ..addAll(byRole);
    _errorsByIndex
      ..clear()
      ..addAll(byIndex);
  }

  Widget _buildPlayerTable(List<DropdownMenuEntry<String?>> nicknameEntries) => SingleChildScrollView(
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FlexColumnWidth(5),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(1),
        },
        children: [
          const TableRow(
            children: [
              Center(child: Text("Игрок")),
              Center(child: Text("Роль")),
              Center(child: Text("")),
            ],
          ),
          for (var i = 0; i < 10; i++)
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
                      errorStyle: TextStyle(fontSize: 0),
                    ),
                    requestFocusOnTap: true,
                    initialSelection: _chosenNicknames[i],
                    dropdownMenuEntries: nicknameEntries,
                    errorText: _errorsByIndex.contains(i) ? "Роль не выбрана" : null,
                    onSelected: (value) => _onNicknameSelected(i, value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: SegmentedButton(
                    segments: [
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
                          _chosenRoles[i] = newSelection.first! as PlayerRole;
                        }
                      });
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                ),
              ],
            ),
        ],
      ),
    );

  List<DropdownMenuEntry<String?>> _buildNicknameEntries(List<PlayersModel> players) {
    final nicknameEntries = [
      const DropdownMenuEntry(
        value: null,
        label: "",
        labelWidget: Text("(*без никнейма*)", style: TextStyle(fontStyle: FontStyle.italic)),),

      for (final nickname in players.map((p) => p.nickname).toList(growable: false)..sort())
        DropdownMenuEntry(
          value: nickname,
          label: nickname!,
          enabled: !_chosenNicknames.contains(nickname),
        ),
    ];
    return nicknameEntries;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final apiCalls = ApiCalls();
    final players = game.players;

    if (game.isStarted) {
      for (var i = 0; i < 10; i++) {
        _chosenNicknames[i] ??= players[i].nickname;
        _chosenRoles[i] ??= players[i].role;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Раздача ролей"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: FutureBuilder<List<PlayersModel>>(
          future: apiCalls.getPlayers(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final apiPlayers = snapshot.data!;
              return _buildPlayerTable(_buildNicknameEntries(apiPlayers));
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
          tooltip: "Применить",
          onPressed: () => _onFabPressed(context),
          child: const Icon(Icons.check),
        ),
    );
  }
}
