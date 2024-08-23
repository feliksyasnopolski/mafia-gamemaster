import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/log.dart";
import "../game/states.dart";
import "../utils/game_controller.dart";
import "../utils/log/map_items.dart";
import "../utils/ui.dart";

extension DescribeLogItem on BaseGameLogItem {
  List<String> get description {
    final result = <String>[];
    switch (this) {
      case StateChangeGameLogItem(
          oldState: final oldState,
          newState: final newState
        ):
        if (newState != null && oldState.day != newState.day) {
          result.add("День ${newState.day}");
        }
        switch (oldState) {
          case GameStateFirstKilled(
              thisNightKilledPlayerNumber: final killedPlayerNumber,
              bestMoves: final bestMoves
            ):
            result.add(
              "Первоубиенный #$killedPlayerNumber, его ЛХ: ${bestMoves.join(", ")}",
            );
          case GameStateSpeaking(
              currentPlayerNumber: final pn,
              accusations: final accusations
            ):
            if (accusations[pn] != null) {
              result.add(
                "Игрок #$pn выставил на голосование игрока #${accusations[pn]}",
              );
            }
          case GameStateVoting(
              currentPlayerNumber: final pn,
              currentPlayerVotes: final votes,
              lastPlayer: final lastPlayer,
            ):
            if (lastPlayer == pn) {
              result.add(
                "За игрока #$pn ушли оставшиеся голоса",
              );
            } else {
              result.add(
                "За игрока #$pn отдано голосов: ${votes ?? 0}",
              ); // FIXME: i18n
            }
          case GameStateDropTableVoting(votesForDropTable: final votes):
            result.add("За подъём стола отдано голосов: $votes"); // FIXME: i18n
          case GameStateFinish():
            throw AssertionError();
          default:
            break;
          // case GameState() ||
          //       GameStateWithPlayer() ||
          //       GameStateWithPlayers() ||
          //       GameStateNightKill() ||
          //       GameStateNightCheck() ||
          //       GameStateWithCurrentPlayer():
          //   break;
        }

      // result.add(oldState.prettyName());
      case PlayerCheckedGameLogItem(
          playerNumber: final playerNumber,
          checkedByRole: final checkedByRole,
        ):
        result
            .add("${checkedByRole.prettyName} проверил игрока #$playerNumber");
      case PlayerWarnedGameLogItem(playerNumber: final playerNumber):
        result.add("Выдан фол игроку #$playerNumber");
    }
    return result;
  }
}

@RoutePage()
class GameLogScreen extends StatelessWidget {
  const GameLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<GameController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Журнал игры"),
      ),
      body: controller.gameLog.isNotEmpty
          ? ListView(
              children: _buildLogItems(context),
              // children: controller.gameLog.reversed
              //     .map((item) => ListTile(
              //           title: Text(item.description.,
              //         ))
              //     .toList(
            )
          : Center(
              child: Text(
                "Ещё ничего не произошло",
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ),
    );
  }

  List<Widget> _buildLogItems(BuildContext context) {
    final controller = context.read<GameController>();
    final mapItems = controller.gameLog.mapItems;
    final result = <Widget>[];

    result.add(const SizedBox(height: 8));

    for (final day in mapItems.keys.toList()..sort()) {
      final cardWidgets = <Widget>[];
      cardWidgets.add(
        Center(
          heightFactor: 1,
          child: Text(
            "День $day",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).highlightColor,
            ),
          ),
        ),
      );
      for (final item in mapItems[day]!) {
        cardWidgets.add(
          ListTile(
            title: Text(item),
          ),
        );
      }

      result.add(
        Card(
          surfaceTintColor: Theme.of(context).highlightColor,
          borderOnForeground: true,
          child: Column(
            children: cardWidgets,
          ),
        ),
      );
    }

    return result;
  }
}
