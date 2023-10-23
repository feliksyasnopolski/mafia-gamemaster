import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "confirmation_dialog.dart";
import "orientation_dependent.dart";
import "player_button.dart";

enum PlayerActions {
  warn("Выдать фол"),
  removeWarn("Убрать фол"),
  kill("Убить"),
  revive("Воскресить"),
  ;

  final String text;

  const PlayerActions(this.text);
}

class PlayerButtons extends OrientationDependentWidget {
  final bool showRoles;

  const PlayerButtons({
    super.key,
    this.showRoles = false,
  });

  void _onPlayerButtonTap(BuildContext context, int playerNumber) {
    final controller = context.read<GameController>();
    final player = controller.getPlayerByNumber(playerNumber);
    if (controller.state case GameStateNightCheck(activePlayerNumber: final pn)) {
      final p = controller.getPlayerByNumber(pn);
      if (!p.isAlive) {
        return; // It's useless to allow dead players check others
      }
      final result = controller.checkPlayer(playerNumber);
      final String msg;
      if (p.role == PlayerRole.don) {
        if (result) {
          msg = "ШЕРИФ";
        } else {
          msg = "НЕ шериф";
        }
      } else if (p.role == PlayerRole.sheriff) {
        if (player.role.isMafia) {
          msg = "МАФИЯ 👎";
        } else {
          msg = "НЕ мафия 👍";
        }
      } else {
        throw AssertionError();
      }
      showSimpleDialog(
        context: context,
        title: const Text("Результат проверки"),
        content: Text("Игрок ${player.number} — $msg"),
      );
    } else {
      controller.togglePlayerSelected(player.number);
    }
  }

  Future<void> _onWarnPlayerTap(BuildContext context, int playerNumber) async {
    final controller = context.read<GameController>();
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: const Text("Выдать фол"),
        content: Text("Вы уверены, что хотите выдать фол игроку #$playerNumber?"),
      ),
    );
    debugPrint("$res");
    if (res ?? false) {
      controller.warnPlayer(playerNumber);
      if (context.mounted) {
        unawaited(
          showSnackBar(
            context,
            SnackBar(content: Text("Выдан фол игроку $playerNumber")),
          ),
        );
      }
    }
  }

  Future<void> _onPlayerActionsTap(BuildContext context, Player player) async {
    final controller = context.read<GameController>();
    final res = await showChoiceDialog(
      context: context,
      items: PlayerActions.values,
      itemToString: (i) => i.text,
      title: Text("Действия для игрока ${player.number}"),
      selectedIndex: null,
    );
    if (res == null) {
      return;
    }
    if (!context.mounted) {
      throw StateError("Context is not mounted");
    }
    switch (res) {
      case PlayerActions.warn:
        await _onWarnPlayerTap(context, player.number);
      case PlayerActions.removeWarn:
        controller.removePlayerWarn(player.number);
      case PlayerActions.kill:
        if (player.isAlive) {
          controller.killPlayer(player.number);
        }
      case PlayerActions.revive:
        if (!player.isAlive) {
          controller.revivePlayer(player.number);
        }
    }
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildPlayerButton(BuildContext context, int playerNumber, BaseGameState gameState) {
    final controller = context.watch<GameController>();
    final isActive = switch (gameState) {
      GameState() || GameStateFinish() => false,
      GameStateWithPlayer(currentPlayerNumber: final p) ||
      GameStateSpeaking(currentPlayerNumber: final p) ||
      GameStateWithCurrentPlayer(currentPlayerNumber: final p) ||
      GameStateVoting(currentPlayerNumber: final p) ||
      GameStateNightCheck(activePlayerNumber: final p) =>
        p == playerNumber,
      GameStateWithPlayers(playerNumbers: final ps) ||
      GameStateNightKill(mafiaTeam: final ps) ||
      GameStateDropTableVoting(playerNumbers: final ps) =>
        ps.contains(playerNumber),
    };
    final isSelected = switch (gameState) {
      GameStateSpeaking(accusations: final accusations) => accusations.containsValue(playerNumber),
      GameStateNightKill(thisNightKilledPlayerNumber: final thisNightKilledPlayer) ||
      GameStateNightCheck(thisNightKilledPlayerNumber: final thisNightKilledPlayer) =>
        thisNightKilledPlayer == playerNumber,
      _ => false,
    };
    final player = controller.getPlayerByNumber(playerNumber);
    return PlayerButton(
      player: player,
      isSelected: isSelected,
      isActive: isActive,
      warnCount: controller.getPlayerWarnCount(playerNumber),
      onTap: player.isAlive || gameState.stage == GameStage.nightCheck
          ? () => _onPlayerButtonTap(context, playerNumber)
          : null,
      longPressActions: [
        TextButton(
          onPressed: () => _onPlayerActionsTap(context, player),
          child: const Text("Действия"),
        ),
      ],
      showRole: showRoles,
    );
  }

  @override
  Widget buildPortrait(BuildContext context) {
    final controller = context.watch<GameController>();
    const itemsPerRow = 5;
    final totalPlayers = controller.totalPlayersCount;
    final size = (MediaQuery.of(context).size.width / itemsPerRow).floorToDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalPlayers; i += itemsPerRow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var j = i; j < i + itemsPerRow && j < totalPlayers; j++)
                SizedBox(
                  width: size,
                  height: size,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child:
                        _buildPlayerButton(context, controller.players[j].number, controller.state),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget buildLandscape(BuildContext context) {
    final controller = context.watch<GameController>();
    const itemsPerRow = 5;
    final totalPlayers = controller.totalPlayersCount;
    final size = (MediaQuery.of(context).size.height / itemsPerRow).floorToDouble() - 18;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < totalPlayers; i += itemsPerRow)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var j = i; j < i + itemsPerRow && j < totalPlayers; j++)
                SizedBox(
                  width: size + 24,
                  height: size,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildPlayerButton(
                      context,
                      controller.players[i.isEven ? i + itemsPerRow + i - j - 1 : j].number,
                      controller.state,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}