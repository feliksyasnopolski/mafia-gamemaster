import "dart:collection";

import "../utils/extensions.dart";
import "log.dart";
import "player.dart";
import "players_view.dart";
import "states.dart";

/// Game controller. Manages game state and players. Doesn't know about UI.
/// To start new game, create new instance of [Game].
class Game {
  BaseGameState _state = const GameState(stage: GameStage.prepare, day: 0);
  final _log = GameLog();
  final PlayersView players;
  final _playerWarns = <int, int>{};

  /// Creates new game with players generated by [generatePlayers] with default config.
  Game() : this.withPlayers(generatePlayers());

  /// Creates new game with given players.
  Game.withPlayers(List<Player> players)
      : players = PlayersView(
          players
            ..sort((a, b) => a.number.compareTo(b.number))
            ..toUnmodifiableList(),
        );

  /// Returns current game state.
  BaseGameState get state => _state;

  /// Returns game log.
  Iterable<BaseGameLogItem> get log => _log;

  /// Assumes team that will win if game ends right now. Returns [PlayerRole.mafia],
  /// [PlayerRole.citizen] or `null` if the game can't end right now.
  PlayerRole? get winTeamAssumption {
    var aliveMafia = players.aliveMafiaCount;
    var aliveCitizens = players.aliveCount - aliveMafia;
    if (_state
        case GameStateWithPlayer(
              stage: GameStage.nightLastWords,
              currentPlayerNumber: final playerNumber,
            ) ||
            GameStateWithCurrentPlayer(
              stage: GameStage.dayLastWords,
              currentPlayerNumber: final playerNumber,
            )) {
      final player = players.getByNumber(playerNumber);
      if (player.role.isMafia) {
        aliveMafia--;
      } else {
        aliveCitizens--;
      }
    }
    if (aliveMafia == 0) {
      return PlayerRole.citizen;
    }
    if (aliveCitizens <= aliveMafia) {
      return PlayerRole.mafia;
    }
    return null;
  }

  /// Checks if game is over.
  bool get isGameOver => _state.stage == GameStage.finish || winTeamAssumption != null;

  int get totalVotes {
    if (_state is! GameStateVoting) {
      throw StateError("Can't get total votes in state ${_state.runtimeType}");
    }
    final state = _state as GameStateVoting;
    return state.votes.values.fold(0, (sum, votes) => votes == null ? sum : sum + votes);
  }

  /// Assumes next game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  BaseGameState? get nextStateAssumption {
    switch (_state.stage) {
      // TODO: Dart 3 pattern matching
      case GameStage.prepare:
        return GameStateWithPlayers(
          stage: GameStage.night0,
          day: 0,
          playerNumbers: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
        );
      case GameStage.night0:
        return GameStateWithPlayer(
          stage: GameStage.night0SheriffCheck,
          day: 0,
          currentPlayerNumber: players.sheriff.number,
        );
      case GameStage.night0SheriffCheck:
        return GameStateSpeaking(
          currentPlayerNumber: players[0].number,
          day: state.day + 1,
          accusations: LinkedHashMap(),
        );
      case GameStage.speaking:
        final state = _state as GameStateSpeaking;
        final next = _nextAlivePlayer(fromNumber: state.currentPlayerNumber);
        if (next.number == _firstSpeakingPlayerNumber) {
          if (state.accusations.isEmpty || state.day == 1 && state.accusations.length == 1) {
            return GameStateNightKill(
              day: state.day,
              mafiaTeam: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
              thisNightKilledPlayerNumber: null,
            );
          }
          return GameStateWithPlayers(
            stage: GameStage.preVoting,
            day: state.day,
            playerNumbers: state.accusations.values.toUnmodifiableList(),
          );
        }
        assert(next.isAlive, "Next player must be alive");
        return GameStateSpeaking(
          currentPlayerNumber: next.number,
          day: state.day,
          accusations: LinkedHashMap.of(state.accusations),
        );
      case GameStage.preVoting:
        final state = _state as GameStateWithPlayers;
        final firstPlayer = state.playerNumbers.first;
        if (state.playerNumbers.length == 1) {
          return GameStateWithCurrentPlayer(
            stage: GameStage.dayLastWords,
            day: state.day,
            playerNumbers: [firstPlayer],
            currentPlayerIndex: 0,
          );
        }
        return GameStateVoting(
          stage: GameStage.voting,
          day: state.day,
          currentPlayerNumber: firstPlayer,
          votes: LinkedHashMap.fromEntries(
            state.playerNumbers.map((player) => MapEntry(player, null)),
          ),
          currentPlayerVotes: null,
        );
      case GameStage.voting:
        return _handleVoting();
      case GameStage.excuse:
        final state = _state as GameStateWithCurrentPlayer;
        if (state.currentPlayerIndex == state.playerNumbers.length - 1) {
          return GameStateWithPlayers(
            stage: GameStage.preFinalVoting,
            day: state.day,
            playerNumbers: state.playerNumbers,
          );
        }
        return GameStateWithCurrentPlayer(
          stage: GameStage.excuse,
          day: state.day,
          playerNumbers: state.playerNumbers,
          currentPlayerIndex: state.currentPlayerIndex + 1,
        );
      case GameStage.preFinalVoting:
        final state = _state as GameStateWithPlayers;
        return GameStateVoting(
          stage: GameStage.finalVoting,
          day: state.day,
          currentPlayerNumber: state.playerNumbers.first,
          votes: LinkedHashMap.fromEntries(
            state.playerNumbers.map((player) => MapEntry(player, null)),
          ),
          currentPlayerVotes: null,
        );
      case GameStage.finalVoting:
        return _handleVoting();
      case GameStage.dropTableVoting:
        final state = _state as GameStateDropTableVoting;
        if (state.votesForDropTable <= players.aliveCount ~/ 2) {
          return GameStateNightKill(
            day: state.day,
            mafiaTeam: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
            thisNightKilledPlayerNumber: null,
          );
        }
        return GameStateWithCurrentPlayer(
          stage: GameStage.dayLastWords,
          day: state.day,
          playerNumbers: state.playerNumbers,
          currentPlayerIndex: 0,
        );
      case GameStage.dayLastWords:
        final state = _state as GameStateWithCurrentPlayer;
        if (state.currentPlayerIndex == state.playerNumbers.length - 1) {
          if (isGameOver) {
            return GameStateFinish(day: state.day, winner: winTeamAssumption);
          }
          return GameStateNightKill(
            day: state.day,
            mafiaTeam: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
            thisNightKilledPlayerNumber: null,
          );
        }
        return GameStateWithCurrentPlayer(
          stage: GameStage.dayLastWords,
          day: state.day,
          playerNumbers: state.playerNumbers,
          currentPlayerIndex: state.currentPlayerIndex + 1,
        );
      case GameStage.nightKill:
        final state = _state as GameStateNightKill;
        return GameStateNightCheck(
          day: state.day,
          activePlayerNumber: players.don.number,
          activePlayerRole: PlayerRole.don,
          thisNightKilledPlayerNumber: state.thisNightKilledPlayerNumber,
        );
      case GameStage.nightCheck:
        final state = _state as GameStateNightCheck;
        final player = players.getByNumber(state.activePlayerNumber);
        if (player.role == PlayerRole.don) {
          return GameStateNightCheck(
            day: state.day,
            activePlayerNumber: players.sheriff.number,
            activePlayerRole: PlayerRole.sheriff,
            thisNightKilledPlayerNumber: state.thisNightKilledPlayerNumber,
          );
        }
        return _handleEndOfNight();
      case GameStage.nightLastWords:
        if (isGameOver) {
          return GameStateFinish(day: state.day, winner: winTeamAssumption);
        }
        return GameStateSpeaking(
          currentPlayerNumber: _firstSpeakingPlayerNumber,
          day: state.day + 1,
          accusations: LinkedHashMap(),
        );
      case GameStage.finish:
        return null;
    }
  }

  /// Changes game state to next state assumed by [nextStateAssumption].
  /// Modifies internal game state.
  void setNextState() {
    final nextState = nextStateAssumption;
    if (nextState == null) {
      throw StateError("Game is over");
    }
    assert(
      validTransitions[_state.stage]?.contains(nextState.stage) ?? false,
      "Invalid or unspecified transition from ${_state.stage} to ${nextState.stage}",
    );
    final oldState = _state;
    _log.add(StateChangeGameLogItem(oldState: oldState));
    // if (oldState.stage.isAnyOf([GameStage.dayLastWords, GameStage.nightLastWords])) {
    if (oldState
        case GameStateWithCurrentPlayer(
              stage: GameStage.dayLastWords,
              currentPlayerNumber: final playerNumber,
            ) ||
            GameStateWithPlayer(
              stage: GameStage.nightLastWords,
              currentPlayerNumber: final playerNumber,
            )) {
      players.kill(playerNumber);
    }
    if (oldState is GameStateVoting) {
      final state = _state as GameStateVoting;
      state.votes[state.currentPlayerNumber] = state.currentPlayerVotes ?? 0;
    }
    _state = nextState;
  }

  /// Gets previous game state according to game internal state, and returns it.
  /// Doesn't change internal state. May throw exceptions if game internal state is inconsistent.
  /// Returns `null` if there is no previous state.
  BaseGameState? get previousState {
    final prevState = _log.whereType<StateChangeGameLogItem>().lastOrNull;
    if (prevState == null) {
      return null;
    }
    return prevState.oldState;
  }

  void setPreviousState() {
    final previousState = this.previousState;
    if (previousState == null) {
      throw StateError("Can't go to previous state");
    }
    if (previousState
        case GameStateWithPlayer(
              stage: GameStage.nightLastWords,
              currentPlayerNumber: final playerNumber,
            ) ||
            GameStateWithCurrentPlayer(
              stage: GameStage.dayLastWords,
              currentPlayerNumber: final playerNumber,
            )) {
      players.revive(playerNumber);
    }
    _log.removeLastWhere((item) => item is StateChangeGameLogItem);
    _state = previousState;
  }

  void togglePlayerSelected(int playerNumber) {
    // TODO: "best move" when logging will be added
    final state = _state;
    final player = players.getByNumber(playerNumber);
    if (!player.isAlive) {
      return;
    }
    if (state is GameStateSpeaking) {
      if (state.accusations[state.currentPlayerNumber] == playerNumber) {
        // toggle (deselect) player
        state.accusations.remove(state.currentPlayerNumber);
      } else if (!state.accusations.containsValue(playerNumber)) {
        // player is not yet selected
        state.accusations[state.currentPlayerNumber] = playerNumber;
      }
      return;
    }
    if (state is GameStateNightKill) {
      _state = GameStateNightKill(
        day: state.day,
        mafiaTeam: state.mafiaTeam,
        thisNightKilledPlayerNumber:
            state.thisNightKilledPlayerNumber == playerNumber ? null : playerNumber,
      );
      return;
    }
  }

  List<int> get voteCandidates {
    if (!state.stage.isAnyOf([
      GameStage.preVoting,
      GameStage.voting,
      GameStage.preFinalVoting,
      GameStage.finalVoting,
    ])) {
      throw StateError("Can't get vote candidates in state ${state.stage}");
    }
    if (_state is GameStateWithPlayers) {
      final state = _state as GameStateWithPlayers;
      return state.playerNumbers;
    }
    if (_state is GameStateVoting) {
      final state = _state as GameStateVoting;
      return state.votes.keys.toList();
    }
    throw AssertionError("Unexpected state type: ${_state.runtimeType}");
  }

  /// Vote for [playerNumber] with [count] votes. [playerNumber] is ignored (can be `null`) if
  /// game [state] is [GameStateDropTableVoting].
  void vote(int? playerNumber, int count) {
    if (_state is GameStateDropTableVoting) {
      final state = _state as GameStateDropTableVoting;
      _state = GameStateDropTableVoting(
        day: state.day,
        playerNumbers: state.playerNumbers,
        votesForDropTable: count,
      );
      return;
    }
    if (_state is! GameStateVoting) {
      return;
    }
    if (playerNumber == null) {
      throw ArgumentError.value(
        playerNumber,
        "playerNumber",
        "You must specify player number to vote for",
      );
    }
    final state = _state as GameStateVoting;
    _state = GameStateVoting(
      stage: state.stage,
      day: state.day,
      currentPlayerNumber: state.currentPlayerNumber,
      votes: state.votes,
      currentPlayerVotes: count,
    );
  }

  int? getPlayerVotes(int playerNumber) {
    if (_state is! GameStateVoting) {
      return null;
    }
    final state = _state as GameStateVoting;
    return state.votes[players.getByNumber(playerNumber)];
  }

  void warnPlayer(int number) {
    _playerWarns.update(number - 1, (value) => value + 1, ifAbsent: () => 1);
    _log.add(PlayerWarnedGameLogItem(playerNumber: number));
  }

  int getPlayerWarnCount(int number) => _playerWarns[number - 1] ?? 0;

  void removePlayerWarn(int number) {
    final k = number - 1;
    final warnCount = _playerWarns[k];
    if (warnCount != null) {
      if (warnCount == 1) {
        _playerWarns.remove(k);
      } else {
        _playerWarns.update(k, (value) => value - 1);
      }
      _log.removeLastWhere((item) => item is PlayerWarnedGameLogItem && item.playerNumber == number);
    }
  }

  bool checkPlayer(int number) {
    final player = players.getByNumber(number);
    if (state case GameStateNightCheck(activePlayerNumber: final playerNumber)) {
      final p = players.getByNumber(playerNumber);
      _log.add(PlayerCheckedGameLogItem(playerNumber: number, checkedByRole: p.role));
      if (p.role == PlayerRole.don) {
        return player.role == PlayerRole.sheriff;
      }
      if (p.role == PlayerRole.sheriff) {
        return player.role.isMafia;
      }
      throw AssertionError();
    }
    throw StateError("Cannot check player in state ${state.runtimeType}");
  }

  // region Private helpers
  Player _nextAlivePlayer({required int fromNumber}) {
    for (var i = fromNumber % 10 + 1; i != fromNumber; i = i % 10 + 1) {
      final player = players.getByNumber(i);
      if (player.isAlive) {
        return player;
      }
    }
    throw StateError("No alive players");
  }

  BaseGameState _handleVoting() {
    final maxVotesPlayers = _maxVotesPlayers;
    final state = _state as GameStateVoting;
    if (maxVotesPlayers == null) {
      int? nextPlayerNumber;
      for (final p in state.votes.keys) {
        if (state.votes[p] == null && p != state.currentPlayerNumber) {
          nextPlayerNumber = p;
          break;
        }
      }
      if (nextPlayerNumber == null) {
        throw AssertionError("No player to vote");
      }
      return GameStateVoting(
        stage: state.stage,
        day: state.day,
        currentPlayerNumber: nextPlayerNumber,
        votes: LinkedHashMap.of(
          {...state.votes, state.currentPlayerNumber: state.currentPlayerVotes ?? 0},
        ),
        currentPlayerVotes: null,
      );
    }
    if (maxVotesPlayers.length == 1) {
      return GameStateWithCurrentPlayer(
        stage: GameStage.dayLastWords,
        day: _state.day,
        playerNumbers: maxVotesPlayers,
        currentPlayerIndex: 0,
      );
    }
    if (state.stage == GameStage.voting) {
      return GameStateWithCurrentPlayer(
        stage: GameStage.excuse,
        day: state.day,
        playerNumbers: maxVotesPlayers,
        currentPlayerIndex: 0,
      );
    }
    if (maxVotesPlayers.length == players.aliveCount) {
      // Rule 7.8
      return GameStateNightKill(
        day: state.day,
        mafiaTeam: players.mafiaTeam.map((player) => player.number).toUnmodifiableList(),
        thisNightKilledPlayerNumber: null,
      );
    }
    // TODO: https://mafiaworldtour.com/fiim-rules 4.4.12.2
    return GameStateDropTableVoting(
      day: state.day,
      playerNumbers: maxVotesPlayers,
      votesForDropTable: 0,
    );
  }

  BaseGameState _handleEndOfNight() {
    final state = _state as GameStateNightCheck;
    final thisNightKilledPlayer = state.thisNightKilledPlayerNumber;
    if (thisNightKilledPlayer != null) {
      return GameStateWithPlayer(
        stage: GameStage.nightLastWords,
        day: state.day,
        currentPlayerNumber: thisNightKilledPlayer,
      );
    }
    if (_consequentDaysWithoutKills >= 3) {
      return GameStateFinish(
        day: state.day,
        winner: null,
      );
    }
    return GameStateSpeaking(
      day: state.day + 1,
      currentPlayerNumber: _firstSpeakingPlayerNumber,
      accusations: LinkedHashMap(),
    );
  }

  List<int>? get _maxVotesPlayers {
    if (_state is! GameStateVoting) {
      if (_state is GameStateWithPlayers &&
          _state.stage.isAnyOf([GameStage.preVoting, GameStage.preFinalVoting])) {
        final state = _state as GameStateWithPlayers;
        if (state.playerNumbers.length == 1) {
          return state.playerNumbers;
        }
      }
      return null;
    }
    final state = _state as GameStateVoting;
    final votes = {...state.votes, state.currentPlayerNumber: state.currentPlayerVotes};
    final aliveCount = players.aliveCount;
    if (votes[state.currentPlayerNumber] == null) {
      votes[state.currentPlayerNumber] = 0;
    }
    if (votes.values.nonNulls.length + 1 == votes.length) {
      // All players except one was voted against
      // The rest of the votes will be given to the last player
      votes[votes.keys.last] = aliveCount - votes.values.nonNulls.sum;
      assert(votes.values.nonNulls.sum == aliveCount, "BUG in votes calculation");
    }
    final nonNullVotes = votes.values.nonNulls;
    final votesTotal = nonNullVotes.sum;
    if (nonNullVotes.isEmpty || votesTotal <= aliveCount ~/ 2) {
      return null;
    }
    final max = nonNullVotes.max();
    if (aliveCount - votesTotal >= max) {
      return null;
    }
    final res = votes.entries.where((e) => e.value == max).map((e) => e.key).toUnmodifiableList();
    assert(res.isNotEmpty, "BUG in votes calculation");
    return res;
  }

  int get _firstSpeakingPlayerNumber {
    final previousFirstSpeakingPlayer = _log
        .whereType<StateChangeGameLogItem>()
        .map((e) => e.oldState)
        .where((e) => e is GameStateSpeaking && e.day == _state.day)
        .cast<GameStateSpeaking>()
        .firstOrNull
        ?.currentPlayerNumber;
    var result = previousFirstSpeakingPlayer ?? 1;
    if (_state is GameStateSpeaking) {
      return result;
    }
    result = _nextAlivePlayer(fromNumber: result).number;
    if (_state
        case GameStateWithPlayer(
          stage: GameStage.nightLastWords,
          currentPlayerNumber: final playerNumber,
        )) {
      if (playerNumber == result) {
        result = _nextAlivePlayer(fromNumber: result).number;
      }
    }
    return result;
  }

  int get _consequentDaysWithoutKills {
    final lastKillDay = _log
        .whereType<StateChangeGameLogItem>()
        .map((e) => e.oldState)
        .where(
          (e) =>
              (e is GameStateWithPlayer && e.stage == GameStage.nightLastWords) ||
              (e is GameStateWithCurrentPlayer && e.stage == GameStage.dayLastWords),
        )
        .lastOrNull
        ?.day;
    return _state.day - (lastKillDay ?? 0);
  }
// endregion
}
