import "package:flutter/material.dart";

import "../game/player.dart";
import "../utils/ui.dart";

class PlayerButton extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final bool isActive;
  final int warnCount;
  final VoidCallback? onTap;
  final List<Widget> longPressActions;
  final bool showRole;

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

  void _onLongPress(BuildContext context) {
    final isAliveText = player.isAlive ? "Жив" : "Мёртв";
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(player.nickname.isEmpty
            ? "Игрок ${player.number}"
            : player.nickname,),
        content: Text(
          "Состояние: $isAliveText\n"
          "Роль: ${player.role.prettyName}\n"
          "Фолов: $warnCount",
        ),
        actions: [
          ...longPressActions,
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Закрыть"),
          ),
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    final borderColor = _getBorderColor(context);
    final cardText =
        "${player.number}\n ${player.nickname}\n ${_getRoleSuffix()}";
    return Stack(
      children: [
        ElevatedButton(
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
            minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
          ),
          onPressed: onTap,
          onLongPress: () => _onLongPress(context),
          child: Stack(
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text("${player.number}", 
                  style: const TextStyle(
                    color: Colors.white,

                  ),
                ), // Adjust text style as needed
              ),
              Center(
                  child: Text("${player.nickname} ${_getRoleSuffix()}", 
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ), // Adjust text style as needed
              ),
            ],
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Text(
            "!" * warnCount,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
