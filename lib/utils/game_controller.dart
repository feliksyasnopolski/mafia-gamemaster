import "package:flutter/material.dart";

import "../game/controller.dart";
import "../game/log.dart";
import "../game/player.dart";
import "../game/states.dart";
import "extensions.dart";
import "api_calls.dart";

class GameController with ChangeNotifier {
  Game _game = Game();
  List<Player> _players = [];
  
  set players(List<Player> value) {
    assert(value.length == 10, "Nicknames list must have 10 elements");
    _players = value;
  }
  bool isStarted = false;
  Iterable<BaseGameLogItem> get gameLog => _game.log;

  BaseGameState get state => _game.state;

  BaseGameState? get nextStateAssumption => _game.nextStateAssumption;

  BaseGameState? get previousState => _game.previousState;

  ApiCalls apiCalls = ApiCalls();

  int get totalPlayersCount => _game.players.count;

  int get alivePlayersCount => _game.players.aliveCount;

  List<int> get voteCandidates => _game.voteCandidates;

  int get totalVotes => _game.totalVotes;

  PlayerRole? get winTeamAssumption => _game.winTeamAssumption;

  void restart() {
    notifyListeners();
  }

  void startWithPlayers() {
    isStarted = true;

    apiCalls.startGame(_players);
    _game = Game.withPlayers(_players);
    notifyListeners();
  }

  Player getPlayerByNumber(int number) => _game.players.getByNumber(number);

  List<Player> get players => _game.players.toUnmodifiableList();

  void vote(int? player, int count) {
    _game.vote(player, count);
    notifyListeners();
  }

  void togglePlayerSelected(int player) {
    _game.togglePlayerSelected(player);
    notifyListeners();
  }

  void setNextState() {
    _game.setNextState();
    apiCalls.updatePlayers(players);
    notifyListeners();
  }

  void setPreviousState() {
    _game.setPreviousState();
    notifyListeners();
  }

  void warnPlayer(int player) {
    apiCalls?.updateStatus({"action": "kill", "player": _players[player].nickname});
    _game.warnPlayer(player);
    notifyListeners();
  }

  int getPlayerWarnCount(int player) => _game.getPlayerWarnCount(player);

  void removePlayerWarn(int player) {
    _game.removePlayerWarn(player);
    notifyListeners();
  }

  void killPlayer(int player) {
    apiCalls.updateStatus({"action": "kill", "player": _players[player].nickname});
    _game.players.kill(player);
    notifyListeners();
  }

  void revivePlayer(int player) {
    _game.players.revive(player);
    notifyListeners();
  }

  bool checkPlayer(int number) => _game.checkPlayer(number);
}
