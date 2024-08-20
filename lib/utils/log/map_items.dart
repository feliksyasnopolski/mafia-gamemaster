import "package:provider/provider.dart";
import "package:flutter/material.dart";
import "../../game/log.dart";
import "../../game/states.dart";
import "../game_controller.dart";
import "../ui.dart";

extension MapItems on Iterable<BaseGameLogItem> {
  Map<int, List<String>> get mapItems {
    var currentDay = 0;
    final result = Map<int, List<String>>();

    for (final item in this) {
      switch (item) {
        case StateChangeGameLogItem(
            oldState: final oldState,
            newState: final newState
          ):
          if (newState != null && oldState.day != newState?.day) {
            currentDay = newState!.day;
          }
          switch (oldState) {
            case GameStateFirstKilled(
                thisNightKilledPlayerNumber: final killedPlayerNumber,
                bestMoves: final bestMoves
              ):
              result.putIfAbsent(currentDay, () => []).add(
                    "Первоубиенный #$killedPlayerNumber, его ЛХ: ${bestMoves.join(", ")}",
                  );

            case GameStateSpeaking(
                currentPlayerNumber: final pn,
                accusations: final accusations
              ):
              if (accusations[pn] != null) {
                result
                    .putIfAbsent(currentDay, () => [])
                    .add("Игрок #$pn выставил #${accusations[pn]}");
              }

            case GameStateVoting(
                currentPlayerNumber: final pn,
                currentPlayerVotes: final votes,
                lastPlayer: final lastPlayer
              ):
              if (lastPlayer == pn) {
                result
                    .putIfAbsent(currentDay, () => [])
                    .add("За игрока #$pn ушли оставшиеся голоса");
              } else {
                result
                    .putIfAbsent(currentDay, () => [])
                    .add("За игрока #$pn отдано голосов: ${votes ?? 0}");
              }

            case GameStateDropTableVoting(votesForDropTable: final votes):
              result
                  .putIfAbsent(currentDay, () => [])
                  .add("За подъём стола отдано голосов: $votes");

            default:
              break;
          }
        case PlayerWarnedGameLogItem(playerNumber: final playerNumber):
          result
              .putIfAbsent(currentDay, () => [])
              .add("Игрок #$playerNumber получил предупреждение");
        case PlayerCheckedGameLogItem(
            playerNumber: final playerNumber,
            checkedByRole: final checkedByRole
          ):
          result.putIfAbsent(currentDay, () => []).add(
              "${checkedByRole.prettyName} проверил игрока #$playerNumber ");
      }
    }

    return result;
  }
}
