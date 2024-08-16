import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../router/router.gr.dart";
import "../utils/api_calls.dart";
import "../utils/api_models.dart";
import "../utils/errors.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";

enum _ValidationErrorType {
  tooMany,
  tooFew,
  missing,
}

@RoutePage()
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
      unawaited(
        showSnackBar(
          context,
          const SnackBar(content: Text("Для продолжения исправьте ошибки")),
        ),
      );
      return;
    }

    // final newRoles = _chosenRoles.toList(growable: false);
    final players = <Player>[];

    for (var i = 0; i < 10; i++) {
      if (_chosenRoles[i] != null) {
        final nickname = _chosenNicknames[i] ?? "Игрок ${i + 1}";
        players.add(
          Player(
            number: i + 1,
            nickname: nickname,
            role: _chosenRoles[i]!,
          ),
        );
      }
    }

    if (!context.mounted) {
      throw ContextNotMountedError();
    }
    // if (showRoles == null) {
    //   return;
    // }
    // setState(() {
    context.read<GameController>().players = players;
    // });

    if (context.mounted) {
      context.read<GameController>().startWithPlayers();
      await context.router.replace(const GameRoute());
    }
    // await openPage(context, const GameScreen());
  }

  void _onNicknameSelected(int index, String? value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _chosenNicknames[index] = value;
    });
  }

  String roleName(PlayerRole role, Orientation orientation) {
    var name = "";
    if (orientation == Orientation.landscape) {
      name = role.prettyName;
    } else {
      switch (role) {
        case PlayerRole.citizen:
          name = "👍";
        case PlayerRole.mafia:
          name = "👎";
        case PlayerRole.sheriff:
          name = "👌";
        case PlayerRole.don:
          name = "👑";
      }
    }
    return name;
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
        byRole[entry.key] = entry.value > 0
            ? _ValidationErrorType.tooFew
            : _ValidationErrorType.missing;
      }
    }

    _errorsByRole
      ..clear()
      ..addAll(byRole);
    _errorsByIndex
      ..clear()
      ..addAll(byIndex);
  }

  List<Widget> buildColumn(
    List<DropdownMenuEntry<String?>> nicknameEntries,
    Orientation orientation,
    int playerNumber,
  ) {
    final columns = <Widget>[];
    // final elementHeight = (MediaQuery.of(context).size.height / 10)*0.7;
    // ignore: cascade_invocations
    columns
      ..add(
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: DropdownMenu(
            expandedInsets: EdgeInsets.zero,
            // enableFilter: true,
            enableSearch: true,
            label: Text("Игрок ${playerNumber + 1}"),
            menuHeight: 256,
            inputDecorationTheme: const InputDecorationTheme(
              isDense: true,
              border: OutlineInputBorder(),
              errorStyle: TextStyle(fontSize: 0),
            ),
            // requestFocusOnTap: true,
            initialSelection: _chosenNicknames[playerNumber],
            dropdownMenuEntries: nicknameEntries,
            errorText: _errorsByIndex.contains(playerNumber)
                ? "Роль не выбрана"
                : null,
            onSelected: (value) => _onNicknameSelected(playerNumber, value),
          ),
        ),
      )
      ..add(
        TextButton(
          onPressed: () {
            setState(() {
              if (_chosenRoles[playerNumber] == null) {
                _chosenRoles[playerNumber] = PlayerRole.citizen;
              } else if (_chosenRoles[playerNumber] == PlayerRole.citizen) {
                _chosenRoles[playerNumber] = PlayerRole.mafia;
              } else if (_chosenRoles[playerNumber] == PlayerRole.mafia) {
                _chosenRoles[playerNumber] = PlayerRole.sheriff;
              } else if (_chosenRoles[playerNumber] == PlayerRole.sheriff) {
                _chosenRoles[playerNumber] = PlayerRole.don;
              } else if (_chosenRoles[playerNumber] == PlayerRole.don) {
                _chosenRoles[playerNumber] = PlayerRole.citizen;
              }
            });
          },
          child: Text(
            _chosenRoles[playerNumber] != null
                ? roleName(_chosenRoles[playerNumber]!, orientation)
                : "?",
            style: const TextStyle(
              fontSize: 38,
              color: Colors.red,
            ),
          ),
        ),
        // SizedBox(
        //   height: 48,
        //   // padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        //   child: SegmentedButton(
        //     segments: [
        //       for (final role in PlayerRole.values)
        //         ButtonSegment(
        //           label: Text(roleName(role, orientation)),
        //           value: role,
        //           icon: const Icon(null),
        //         ),
        //     ],
        //     style: ButtonStyle(
        //       padding: WidgetStateProperty.all(EdgeInsets.zero),
        //       iconSize: WidgetStateProperty.all(0),
        //       textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 24)),
        //     ),
        //     selected: _chosenRoles[playerNumber] != null
        //         ? {_chosenRoles[playerNumber]!}
        //         : {},
        //     emptySelectionAllowed: true,
        //     onSelectionChanged: (newSelection) {
        //       setState(() {
        //         if (newSelection.isEmpty) {
        //           _chosenRoles[playerNumber] = null;
        //         } else {
        //           _chosenRoles[playerNumber] =
        //               newSelection.first! as PlayerRole;
        //         }
        //       });
        //     },
        //   ),
        // ),
      );

    if (orientation == Orientation.landscape) {
      columns.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      );
    }

    return columns;
  }

  Widget _buildPlayerTable(
    List<DropdownMenuEntry<String?>> nicknameEntries,
    Orientation orientation,
  ) {
    final landscape = orientation == Orientation.landscape;
    final columnWidths = landscape
        ? const {
            0: FlexColumnWidth(5),
            1: FlexColumnWidth(4),
            2: FlexColumnWidth(1),
          }
        : const {
            0: FlexColumnWidth(8),
            1: FlexColumnWidth(4),
          };
    final tableHeader = landscape
        ? const TableRow(
            children: [
              Center(child: Text("Игрок")),
              Center(child: Text("Роль")),
              Center(child: Text("")),
            ],
          )
        : const TableRow(
            children: [
              Center(child: Text("Игрок")),
              Center(child: Text("Роль")),
            ],
          );
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Table(
            // defaultVerticalAlignment: TableCellVerticalAlignment.fill,
            columnWidths: columnWidths,
            children: [
              // tableHeader,
              for (var i = 0; i < 10; i++)
                TableRow(
                  children: buildColumn(nicknameEntries, orientation, i),
                ),
              if (orientation == Orientation.portrait)
                const TableRow(
                  children: [
                    SizedBox(
                      height: 90,
                    ),
                    SizedBox(
                      height: 90,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<DropdownMenuEntry<String?>> _buildNicknameEntries(
    List<PlayersModel> players,
  ) {
    final nicknameEntries = [
      const DropdownMenuEntry(
        value: null,
        label: "",
        labelWidget: Text(
          "(*без никнейма*)",
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      for (final nickname
          in players.map((p) => p.nickname).toList(growable: false)..sort())
        DropdownMenuEntry(
          value: nickname,
          label: nickname!,
          enabled: !_chosenNicknames.contains(nickname),
          labelWidget: Text(
            nickname,
            style: const TextStyle(
              letterSpacing: 0.5,
            ),
          ),
        ),
    ];
    return nicknameEntries;
  }

  void shufflePlayerRoles() {
    const roles = {
      PlayerRole.citizen: 6,
      PlayerRole.mafia: 2,
      PlayerRole.sheriff: 1,
      PlayerRole.don: 1,
    };
    final playerRoles = roles.entries
        .expand((entry) => List.filled(entry.value, entry.key))
        .toList(growable: false)
      ..shuffle();

    for (var i = 0; i < 10; i++) {
      _chosenRoles[i] = playerRoles[i];
    }
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
        title: const Text("Роли"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case "shuffle":
                  setState(shufflePlayerRoles);
                case "clear":
                  setState(() {
                    for (var i = 0; i < 10; i++) {
                      _chosenNicknames[i] = null;
                      _chosenRoles[i] = null;
                    }
                  });
                case "seating":
                  final seating = List<int>.generate(10, (index) => index + 1);
                  final seatingBuffer = StringBuffer();
                  var isShuffled = false;

                  while (!isShuffled) {
                    isShuffled = true;
                    for (var i = 0; i < 10; i++) {
                      if (seating[i] == i + 1) {
                        isShuffled = false;
                        seating.shuffle();
                        break;
                      }
                    }
                  }
                  for (var i = 0; i < 10; i++) {
                    _chosenNicknames[i] = null;
                    _chosenRoles[i] = null;
                  }
                  for (var i = 0; i < 10; i++) {
                    seatingBuffer.writeln("Игрок ${i + 1} -> ${seating[i]}");
                  }
                  showSimpleDialog(
                    context: context,
                    title: const Text("Рассадка"),
                    content: Text(seatingBuffer.toString()),
                  );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "shuffle",
                child: Text("Перемешать роли"),
              ),
              const PopupMenuItem(
                value: "seating",
                child: Text("Рассадка"),
              ),
              const PopupMenuItem(
                value: "clear",
                child: Text("Очистить"),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: () => showSimpleDialog(
              context: context,
              title: const Text("Помощь"),
              content: const Text(
                "Выберите роли для игроков и их никнеймы.\n"
                "После нажатия на галочку начнется игра.\n"
                "👍 - мирный житель\n👎 - мафия\n👌 - шериф\n👑 - дон",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _onFabPressed(context),
          ),
        ],
      ),
      body: FutureBuilder<List<PlayersModel>>(
        future: apiCalls.getPlayers(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final apiPlayers = snapshot.data!;
            return OrientationBuilder(
              builder: (context, orientation) => _buildPlayerTable(
                _buildNicknameEntries(apiPlayers),
                orientation,
              ),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
