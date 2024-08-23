import "../../game/log.dart";
import "../../game/player.dart";
import "../../game/states.dart";
import "../game_controller.dart";

class SaveRestore {
  // final _log = GameLog();
  final GameController _controller;

  SaveRestore(this._controller);

  Map<String, dynamic> getState() {
    final result = <String, dynamic>{
      "players": _controller.players.map((e) => e.toJson()).toList(),
      "tableToken": _controller.tableToken,
      "gameLog": _controller.gameLog.map((e) => e.toJson()).toList(),
    };
    // print(result);
    return result;
  }

  void restoreState(Map<String, dynamic> data) {
    final players = data["players"] as List<dynamic>;
    final tableToken = data["tableToken"] as String;
    final gameLog = data["gameLog"];

    _controller.tableToken = tableToken;
    _restorePlayers(players);
    _restoreGameLog(gameLog as List<dynamic>);
    _setState();
  }

  void _setState() {
    final state = _controller.gameLogObject
        .whereType<StateChangeGameLogItem>()
        .last
        .newState!;
    _controller.game.state = state;
    _controller.setNextState();
  }

  void _restorePlayers(List<dynamic> players) {
    final restoredPlayers = <Player>[];
    for (final player in players) {
      restoredPlayers.add(Player.fromJson(player as Map<String, dynamic>));
    }
    _controller.players = restoredPlayers;
  }

  void _restoreGameLog(List<dynamic> log) {
    final gameLog = _controller.gameLogObject;

    for (final item in log) {
      switch (item["type"]) {
        case "stateChange":
          final oldState = item["oldState"] as Map<String, dynamic>;
          final newState = item["newState"] as Map<String, dynamic>?;
          gameLog.add(StateChangeGameLogItem(
            oldState: BaseGameState.fromJson(oldState),
            newState:
                newState != null ? BaseGameState.fromJson(newState) : null,
          ),);

        case "playerWarned":
          final playerNumber = item["playerNumber"] as int;
          gameLog.add(PlayerWarnedGameLogItem(playerNumber: playerNumber));

        case "playerChecked":
          final playerNumber = item["playerNumber"] as int;
          final checkedByRole = PlayerRole.values.firstWhere(
            (role) => role.name == (item["checkedByRole"] as String),
          );

          gameLog.add(PlayerCheckedGameLogItem(
              playerNumber: playerNumber, checkedByRole: checkedByRole,),);
        default:
          throw Exception("Unknown log item type: ${item["type"]}");
      }
    }
  }
}
