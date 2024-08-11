import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../utils/game_controller.dart";
import "orientation_dependent.dart";

class PlayerButton extends OrientationDependentWidget {
  final Player player;
  final bool isSelected;
  final bool isActive;
  final int warnCount;
  final VoidCallback? onTap;
  final List<Widget> longPressActions;
  final bool showRole;

  // final GlobalKey widgetKey;

  const PlayerButton({
    super.key,
    required this.player,
    required this.isSelected,
    this.isActive = false,
    required this.warnCount,
    this.onTap,
    this.longPressActions = const [],
    this.showRole = false,
  });

  Future<void> showPlayerMenu(BuildContext context, Offset position) async {
    final isAliveText = player.isAlive ? "Жив" : "Мёртв";
    final controller = context.read<GameController>();

    final screenSize = MediaQuery.of(context).size;
    final widgetPosition = RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      screenSize.width - position.dx,
      screenSize.height - position.dy,
    );
    final res = await showMenu<String>(
        context: context,
        position: widgetPosition,
        menuPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        items: const [
          PopupMenuItem<String>(
            value: "add_faul",
            height: 30,
            child: Text("Выдать фол"),
          ),
          PopupMenuItem<String>(
            value: "remove_faul",
            height: 30,
            child: Text("Убрать фол"),
          ),
          PopupMenuItem<String>(
            value: "kill_player",
            height: 30,
            child: Text("Удаление игрока"),
          ),
        ],);

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
    if (isSelected) {
      return Colors.green;
    }
    return null;
  }

  Color? _getBackgroundColor(BuildContext context) {
    if (!player.isAlive) {
      return Colors.red.withOpacity(0.25);
    }
    return null;
  }

  Color? _getForegroundColor(BuildContext context) {
    if (isSelected) {
      return Colors.green;
    }
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
    final borderColor = _getBorderColor(context);
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
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${player.number}",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    player.nickname,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _getRoleSuffix(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 20,
          child: Text(
            "!" * warnCount,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
      ],
    );
  }
}
