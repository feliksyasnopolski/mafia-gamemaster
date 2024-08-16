import "package:flutter/material.dart";

import "../game/player.dart";
import "../game/states.dart";

extension PlayerRolePrettyString on PlayerRole {
  String get prettyName {
    switch (this) {
      case PlayerRole.citizen:
        return "Мирный";
      case PlayerRole.mafia:
        return "Мафия";
      case PlayerRole.don:
        return "Дон";
      case PlayerRole.sheriff:
        return "Шериф";
    }
  }

  String get jsonName {
    switch (this) {
      case PlayerRole.citizen:
        return "citizen";
      case PlayerRole.mafia:
        return "mafia";
      case PlayerRole.don:
        return "godfather";
      case PlayerRole.sheriff:
        return "sheriff";
    }
  }
}

extension GameStatePrettyString on BaseGameState {
  Map<String, dynamic> stateName({bool isLandscape = true}) {
    final result = <String, dynamic>{};
    switch (this) {
      case GameState(stage: GameStage.prepare):
        result["state"] = "prepare";
      case GameStateWithPlayers(stage: GameStage.night0):
        result["state"] = "agreement";
      case GameStateWithPlayer(stage: GameStage.night0SheriffCheck):
        result["state"] = "sheriffWakeUp";
      case GameStateSpeaking(
          stage: GameStage.speaking,
          currentPlayerNumber: final playerNumber
        ):
        result["state"] = "speaking";
        result["playerNumber"] = playerNumber;
      case GameStateWithPlayers(stage: GameStage.preVoting):
        result["state"] = "preVoting";
      case GameStateVoting(
          stage: GameStage.voting,
          currentPlayerNumber: final playerNumber
        ):
        result["state"] = "voting";
        result["playerNumber"] = playerNumber;
      case GameStateWithCurrentPlayer(
          stage: GameStage.excuse,
          currentPlayerNumber: final playerNumber,
        ):
        result["state"] = "excuse";
        result["playerNumber"] = playerNumber;
      case GameStateWithPlayers(stage: GameStage.preFinalVoting):
        result["state"] = "preFinalVoting";
      case GameStateVoting(
          stage: GameStage.finalVoting,
          currentPlayerNumber: final playerNumber
        ):
        result["state"] = "finalVoting";
        result["playerNumber"] = playerNumber;
      case GameStateDropTableVoting():
        result["state"] = "dropTableVoting";
      case GameStateWithCurrentPlayer(
          stage: GameStage.dayLastWords,
          currentPlayerNumber: final playerNumber,
        ):
        result["state"] = "lastWords";
        result["playerNumber"] = playerNumber;
      case GameStateNightKill():
        result["state"] = "nightKill";
      case GameStateNightCheck(
          stage: GameStage.nightCheck,
          activePlayerRole: final playerRole
        ):
        if (playerRole == PlayerRole.don) {
          result["state"] = "nightCheckDon";
        } else {
          result["state"] = "nightCheckSheriff";
        }
      case GameStateWithPlayer(
          stage: GameStage.nightLastWords,
          currentPlayerNumber: final playerNumber,
        ):
        result["state"] = "lastWords";
        result["playerNumber"] = playerNumber;
      case GameStateFirstKilled(
          stage: GameStage.nightFirstKilled,
          thisNightKilledPlayerNumber: final playerNumber,
        ):
        result["state"] = "firstKilled";
        result["playerNumber"] = playerNumber;
      case GameStateFinish():
        result["state"] = "finish";
      default:
        throw AssertionError("Unknown game state: $this");
    }

    return result;
  }

  String prettyName({bool isLandscape = true}) {
    switch (stateName()["state"]) {
      case "prepare":
        return isLandscape ? "Ожидание игроков..." : "ожидание";
      case "agreement":
        return isLandscape ? "Договорка мафии" : "договорка";
      case "sheriffWakeUp":
        return isLandscape ? "Шериф осматривает стол" : "осмотр шерифа";
      case "speaking":
        return isLandscape
            ? "Речь игрока ${stateName()["playerNumber"]}"
            : "речь #${stateName()["playerNumber"]}";
      case "preVoting":
        return isLandscape ? "Голосование" : "голосование";
      case "voting":
        return isLandscape
            ? "Голосование против игрока ${stateName()["playerNumber"]}"
            : "голосование против #${stateName()["playerNumber"]}";
      case "excuse":
        return isLandscape
            ? "Повторная речь игрока ${stateName()["playerNumber"]}"
            : "повторная речь #${stateName()["playerNumber"]}";
      case "preFinalVoting":
        return isLandscape ? "Повторное голосование" : "повторное голосование";
      case "finalVoting":
        return isLandscape
            ? "Повторное голосование против игрока ${stateName()["playerNumber"]}"
            : "повторное против #${stateName()["playerNumber"]}";
      case "dropTableVoting":
        return isLandscape
            ? "Голосование за подъём стола"
            : "голосование за подъём";
      case "lastWords":
        return isLandscape
            ? "Последние слова игрока ${stateName()["playerNumber"]}"
            : "прощальная #${stateName()["playerNumber"]}";
      case "nightKill":
        return isLandscape ? "Ночь, ход Мафии" : "ночь, ход мафии";
      case "nightCheckDon":
        return isLandscape ? "Ночь, ход Дона" : "ночь, ход дона";
      case "nightCheckSheriff":
        return isLandscape ? "Ночь, ход Шерифа" : "ход шерифа";
      case "firstKilled":
        return isLandscape
            ? "Первоубиенный игрок ${stateName()["playerNumber"]} оставляет ЛХ"
            : "ЛХ игрока #${stateName()["playerNumber"]}";
      case "finish":
        return isLandscape ? "Игра окончена" : "конец игры";
      default:
        throw AssertionError("Unknown game state: $this");
    }
  }

  // String stateName({bool isLandscape = true}) {

  //   switch (this) {
  //     case GameState(stage: GameStage.prepare):
  //       return isLandscape ? "Ожидание игроков..." : "ожидание";
  //     case GameStateWithPlayers(stage: GameStage.night0):
  //       return isLandscape ? "Договорка мафии" : "договорка";
  //     case GameStateWithPlayer(stage: GameStage.night0SheriffCheck):
  //       return isLandscape ? "Шериф осматривает стол" : "осмотр шерифа";
  //     case GameStateSpeaking(
  //         stage: GameStage.speaking,
  //         currentPlayerNumber: final playerNumber
  //       ):
  //       return isLandscape
  //           ? "Речь игрока $playerNumber"
  //           : "речь #$playerNumber";
  //     case GameStateWithPlayers(stage: GameStage.preVoting):
  //       return isLandscape ? "Голосование" : "голосование";
  //     case GameStateVoting(
  //         stage: GameStage.voting,
  //         currentPlayerNumber: final playerNumber
  //       ):
  //       return isLandscape
  //           ? "Голосование против игрока $playerNumber"
  //           : "голосование против #$playerNumber";
  //     case GameStateWithCurrentPlayer(
  //         stage: GameStage.excuse,
  //         currentPlayerNumber: final playerNumber,
  //       ):
  //       return isLandscape
  //           ? "Повторная речь игрока $playerNumber"
  //           : "повторная речь #$playerNumber";
  //     case GameStateWithPlayers(stage: GameStage.preFinalVoting):
  //       return isLandscape ? "Повторное голосование" : "повторное голосование";
  //     case GameStateVoting(
  //         stage: GameStage.finalVoting,
  //         currentPlayerNumber: final playerNumber
  //       ):
  //       return isLandscape
  //           ? "Повторное голосование против игрока $playerNumber"
  //           : "повторное против #$playerNumber";
  //     case GameStateDropTableVoting():
  //       return isLandscape
  //           ? "Голосование за подъём стола"
  //           : "голосование за подъём";
  //     case GameStateWithCurrentPlayer(
  //         stage: GameStage.dayLastWords,
  //         currentPlayerNumber: final playerNumber,
  //       ):
  //       return isLandscape
  //           ? "Последние слова игрока $playerNumber"
  //           : "прощальная #$playerNumber";
  //     case GameStateNightKill():
  //       return isLandscape ? "Ночь, ход Мафии" : "ночь, ход мафии";
  //     case GameStateNightCheck(
  //         stage: GameStage.nightCheck,
  //         activePlayerRole: final playerRole
  //       ):
  //       if (playerRole == PlayerRole.don) {
  //         return isLandscape ? "Ночь, ход Дона" : "ночь, ход дона";
  //       }
  //       return isLandscape ? "Ночь, ход Шерифа" : "ход шерифа";
  //     case GameStateWithPlayer(
  //         stage: GameStage.nightLastWords,
  //         currentPlayerNumber: final playerNumber,
  //       ):
  //       return isLandscape
  //           ? "Последние слова игрока $playerNumber"
  //           : "прощальная #$playerNumber";
  //     case GameStateFirstKilled(
  //         stage: GameStage.nightFirstKilled,
  //         thisNightKilledPlayerNumber: final playerNumber,
  //       ):
  //       return isLandscape
  //           ? "Первоубиенный игрок $playerNumber оставляет ЛХ"
  //           : "ЛХ игрока #$playerNumber";
  //     case GameStateFinish():
  //       return isLandscape ? "Игра окончена" : "конец игры";
  //     default:
  //       throw AssertionError("Unknown game state: $this");
  //   }
  // }
}

typedef ConverterFunction<T, R> = R Function(T value);

Future<SnackBarClosedReason> showSnackBar(
  BuildContext context,
  SnackBar snackBar, {
  bool dismissPrevious = true,
}) {
  final messenger = ScaffoldMessenger.of(context);
  if (dismissPrevious) {
    messenger.hideCurrentSnackBar();
  }
  return messenger.showSnackBar(snackBar).closed;
}

/// Shows a simple dialog with a list of [items] and returns the selected item.
///
/// [itemToString] is used to convert the item to a string.
///
/// [selectedIndex] is the index of the item that should be selected by default.
/// If [selectedIndex] is null, no item will be selected, thus no checkmark will
/// be shown.
///
/// Returns the selected item or null if the dialog was dismissed.
Future<T?> showChoiceDialog<T>({
  required BuildContext context,
  required List<T> items,
  ConverterFunction<T, String>? itemToString,
  required Widget title,
  required int? selectedIndex,
}) async =>
    showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: title,
        children: [
          for (var i = 0; i < items.length; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, items[i]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(itemToString?.call(items[i]) ?? items[i].toString()),
                  if (i == selectedIndex) const Icon(Icons.check),
                ],
              ),
            ),
        ],
      ),
    );

void showSimpleDialog({
  required BuildContext context,
  required Widget title,
  required Widget content,
  List<Widget> actions = const [],
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: title,
      content: content,
      actions: [
        ...actions,
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ОК"),
        ),
      ],
    ),
  );
}

RelativeRect getRelativeRect(BuildContext context) =>
    RelativeRect.fromSize(_getWidgetGlobalRect(context), const Size(200, 200));

Rect _getWidgetGlobalRect(BuildContext context) {
  final renderBox = context.findRenderObject()! as RenderBox;
  final offset = renderBox.localToGlobal(Offset.zero);
  debugPrint("Widget position: ${offset.dx} ${offset.dy}");
  return Rect.fromLTWH(
    (offset.dx / 3.5) - 20,
    offset.dy * 1.05,
    renderBox.size.width,
    renderBox.size.height,
  );
}
