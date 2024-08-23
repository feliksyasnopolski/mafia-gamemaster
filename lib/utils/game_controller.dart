
import "package:flutter/material.dart";

import "../game/controller.dart";
import "../game/log.dart";
import "../game/player.dart";
import "../game/players_view.dart";
import "../game/states.dart";
import "api_calls.dart";
import "extensions.dart";
import "log/save_restore.dart";

class GameController with ChangeNotifier {
  Game _game = Game();
  List<Player> _players = [];

  set players(List<Player> value) {
    assert(value.length == 10, "Nicknames list must have 10 elements");
    _players = value;
    _game.players = PlayersView(value);
  }

  String tableToken = "";
  bool isStarted = false;
  Iterable<BaseGameLogItem> get gameLog => _game.log;
  GameLog get gameLogObject => _game.logObject;

  // List<int> get bestMoves => _game.bestMoves;

  Game get game => _game;

  BaseGameState get state => _game.state;

  BaseGameState? get previousState => _game.previousState;

  ApiCalls apiCalls = ApiCalls();

  int get totalPlayersCount => _game.players.count;

  int get alivePlayersCount => _game.players.aliveCount;

  List<int> get voteCandidates => _game.voteCandidates;

  int get totalVotes => _game.totalVotes;

  PlayerRole? get winTeamAssumption => _game.winTeamAssumption;

  BaseGameState? get nextStateAssumption {
    final assumption = _game.nextStateAssumption;
    if (assumption == null) {
      apiCalls.stopGame(tableToken);
    }
    return assumption;
  }

  void restart() {
    _players = [];
    _game = Game();
    isStarted = false;
    notifyListeners();
  }

  void resume(Map<String, dynamic> data) {
    _game = Game();
    SaveRestore(this).restoreState(data);
    isStarted = true;
    notifyListeners();
  }

  void startWithPlayers() {
    isStarted = true;

    apiCalls.startGame(_players, tableToken);
    _game = Game.withPlayers(_players);
    notifyListeners();
  }

  Player getPlayerByNumber(int number) => _game.players.getByNumber(number);

  List<Player> get players => _game.players.toUnmodifiableList();

  void vote(int? player, int count, {bool notify = true}) {
    _game.vote(player, count);
    if (notify) {
      notifyListeners();
    }
  }

  void togglePlayerSelected(int player) {
    _game.togglePlayerSelected(player);
    notifyListeners();
  }

  void setNextState() {
    final wholeLog = SaveRestore(this).getState();

    apiCalls.updateLog(_game, tableToken);
    _game.setNextState();
    apiCalls
      ..updateState(wholeLog, tableToken)
      ..updatePlayers(players, tableToken);
    // ..updateVoteCandidates(voteCandidates);
    notifyListeners();
  }

  void setPreviousState() {
    _game.setPreviousState();
    notifyListeners();
  }

  void warnPlayer(int player) {
    // apiCalls
    //     .updateStatus({"action": "foul", "player": _players[player].nickname});
    _game.warnPlayer(player);
    notifyListeners();
  }

  int getPlayerWarnCount(int player) => _game.getPlayerWarnCount(player);

  void removePlayerWarn(int player) {
    _game.removePlayerWarn(player);
    notifyListeners();
  }

  void killPlayer(int player) {
    // apiCalls
    //     .updateStatus({"action": "kill", "player": _players[player].nickname});
    _game.players.kill(player);
    notifyListeners();
  }

  void revivePlayer(int player) {
    _game.players.revive(player);
    notifyListeners();
  }

  bool checkPlayer(int number) => _game.checkPlayer(number);
}
