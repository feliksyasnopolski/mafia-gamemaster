import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../utils/game_controller.dart";
import "custom_color_menuitem.dart";
import "orientation_dependent.dart";

class PlayerButton extends OrientationDependentWidget {
  final Player player;
  final bool isSelected;
  final bool isActive;
  final int warnCount;
  final VoidCallback? onTap;
  final List<Widget> longPressActions;
  final bool showRole;
  final List<Color> buttonColors;
  // final GlobalKey widgetKey;

  PlayerButton({
    super.key,
    required this.player,
    required this.isSelected,
    this.isActive = false,
    required this.warnCount,
    this.onTap,
    this.longPressActions = const [],
    this.showRole = false,
  }) : buttonColors = [
          Colors.deepOrange,
          Colors.green,
          Colors.blue,
          Colors.purple,
          Colors.brown,
          Colors.pink,
          Colors.teal,
          Colors.indigo,
          Colors.amber,
          Colors.cyan,
        ];

  Future<void> showPlayerMenu(BuildContext context, Offset position) async {
    final controller = context.read<GameController>();

    final screenSize = MediaQuery.of(context).size;
    final widgetPosition = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      screenSize.width - position.dx,
      screenSize.height - position.dy,
    );
    final showAddFaul =
        (controller.getPlayerWarnCount(player.number) < 4) && player.isAlive;
    final showRemoveFaul = controller.getPlayerWarnCount(player.number) > 0;
    final showKillPlayer = player.isAlive;
    final res = await showMenu<String>(
      context: context,
      position: widgetPosition,
      menuPadding: EdgeInsets.zero, //symmetric(horizontal: 8, vertical: 0),
      items: [
        CustomPopupMenuItem(
          enabled: false,
          height: 30,
          color: Colors.white24,
          child: Text(
            "Игрок ${player.number}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (showAddFaul)
          PopupMenuItem<String>(
            value: "add_faul",
            height: 30,
            enabled: showAddFaul,
            child: const Text("Выдать фол"),
          ),
        if (showRemoveFaul)
          PopupMenuItem<String>(
            value: "remove_faul",
            height: 30,
            enabled: showRemoveFaul,
            child: const Text("Убрать фол"),
          ),
        if (showKillPlayer)
          PopupMenuItem<String>(
            value: "kill_player",
            height: 30,
            enabled: showKillPlayer,
            child: const Text("Удаление игрока"),
          ),
      ],
    );

    if (res == "add_faul") {
      if (controller.getPlayerWarnCount(player.number) >= 3) {
        controller.killPlayer(player.number);
      } else {
        controller.warnPlayer(player.number);
      }
    } else if (res == "remove_faul") {
      controller.removePlayerWarn(player.number);
    } else if (res == "kill_player") {
      controller.killPlayer(player.number);
    }
  }

  Color? _getBorderColor(BuildContext context) {
    if (isActive) {
      return Theme.of(context).colorScheme.primary;
    }
    // if (isSelected) {
    //   return Colors.green;
    // }
    return null;
  }

  Color? _getBackgroundColor(BuildContext context) {
    if (!player.isAlive) {
      return Colors.red.withOpacity(0.25);
    }
    if (isActive) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.25);
    }
    // else if (isSelected) {
    //   return Colors.green.withOpacity(0.25);
    // }
    return null;
  }

  Color? _getForegroundColor(BuildContext context) {
    // if (isSelected) {
    //   return Colors.green;
    // }
    if (!player.isAlive) {
      return Colors.red;
    }
    return null;
  }

  String _getRoleSuffix() {
    if (!showRole) {
      return "";
    }
    if (player.role == PlayerRole.citizen) {
      return "";
    } else if (player.role == PlayerRole.mafia) {
      return "👎";
    } else if (player.role == PlayerRole.don) {
      return "👑";
    } else if (player.role == PlayerRole.sheriff) {
      return "👌";
    } else {
      throw AssertionError("Unknown role: ${player.role}");
    }
  }

  Widget accusedWidget(BuildContext context) {
    final controller = context.read<GameController>();
    var accusedBy = -1;
    if (controller.state.stage == GameStage.speaking) {
      final state = controller.state as GameStateSpeaking;
      Color? color;
      accusedBy = state.accusations.entries
          .firstWhere(
            (entry) => entry.value == player.number,
            orElse: () => const MapEntry(-1, -1),
          )
          .key;
      if (accusedBy != -1) {
        color = buttonColors[accusedBy - 1];
      }
      return Container(
        width: 18,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          // border: Border.all(
          //   color: color,
          //   width: 1,
          // ),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
      );
    } else if (controller.state.stage == GameStage.nightKill) {
      final state = controller.state as GameStateNightKill;
      if (state.thisNightKilledPlayerNumber == player.number) {
        return const SizedBox(
          width: 18,
          // height: 16,
          // decoration: BoxDecoration(
          //   // color: buttonColors[0],
          //   border: Border.all(
          //     color: Colors.white,
          //     width: 1,
          //   ),
          //   borderRadius: const BorderRadius.all(Radius.circular(4)),
          // ),
          child: Text(
            "🔫",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        );
      }
    } else if (controller.state.stage == GameStage.nightCheck) {
      final state = controller.state as GameStateNightCheck;
      if (state.thisNightKilledPlayerNumber == player.number) {
        return const SizedBox(
          width: 18,
          child: Text(
            "💀",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        );
      }
    }
    // 🔫
    return Container(
      width: 18,
      height: 16,
      decoration: const BoxDecoration(
        color: null,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    );
  }

  @override
  Widget buildLandscape(BuildContext context) {
    final borderColor = _getBorderColor(context);
    // final cardText =
    //     "${player.number}\n ${player.nickname}\n ${_getRoleSuffix()}";
    return Stack(
      children: [
        GestureDetector(
          onLongPressStart: (details) {
            showPlayerMenu(context, details.globalPosition);
          },
          child: ElevatedButton(
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              side: borderColor != null
                  ? WidgetStateProperty.all(
                      BorderSide(
                        color: borderColor,
                        width: 1,
                      ),
                    )
                  : null,
              backgroundColor:
                  WidgetStateProperty.all(_getBackgroundColor(context)),
              foregroundColor:
                  WidgetStateProperty.all(_getForegroundColor(context)),
              minimumSize: WidgetStateProperty.all(const Size.fromHeight(96)),
            ),
            onPressed: onTap,
            // onLongPress: () => _onLongPress(context),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    "${player.number}",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ), // Adjust text style as needed
                ),
                Center(
                  child: Text(
                    player.nickname,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ), // Adjust text style as needed
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    _getRoleSuffix(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Text(
            "!" * warnCount,
            style:
                const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildPortrait(BuildContext context) {
    final controller = context.read<GameController>();
    final borderColor = _getBorderColor(context);
    // final Int? accusedBy = controller.voteCandidates[player.number];

    return Stack(
      children: [
        GestureDetector(
          onLongPressStart: (details) {
            showPlayerMenu(context, details.globalPosition);
          },
          child: ElevatedButton(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 2),),
              shape: WidgetStateProperty.all(
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
              side: null,
              backgroundColor:
                  WidgetStateProperty.all(_getBackgroundColor(context)),
              foregroundColor:
                  WidgetStateProperty.all(_getForegroundColor(context)),
              minimumSize: WidgetStateProperty.all(const Size.fromHeight(96)),
            ),
            onPressed: onTap,
            // onLongPress: () => _onLongPress(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 2,
                    right: 4,
                    top: 7,
                    bottom: 7,
                  ),
                  child: Container(
                    width: 18,
                    decoration: BoxDecoration(
                      color: buttonColors[player.number - 1],
                      border: Border.all(
                        color: buttonColors[player.number - 1],
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
                Text(
                  "${player.number}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // ),
                // ),
                SizedBox(
                  width: (player.number < 10) ? 16 : 9,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    player.nickname,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 5,
          child: Row(
            children: [
              Text(
                _getRoleSuffix(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              accusedWidget(context),
              const SizedBox(
                width: 10,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  textAlign: TextAlign.right,
                  "!" * warnCount,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
