import "package:flutter_test/flutter_test.dart";
import "package:mafia_gamemaster/game/controller.dart";
import "package:mafia_gamemaster/game/player.dart";
import "package:mafia_gamemaster/game/states.dart";

const players = <Player>[
  Player(role: PlayerRole.citizen, number: 1, nickname: "Player 1"),
  Player(role: PlayerRole.mafia, number: 2, nickname: "Player 2"),
  Player(role: PlayerRole.citizen, number: 3, nickname: "Player 3"),
  Player(role: PlayerRole.citizen, number: 4, nickname: "Player 4"),
  Player(role: PlayerRole.don, number: 5, nickname: "Player 5"),
  Player(role: PlayerRole.citizen, number: 6, nickname: "Player 6"),
  Player(role: PlayerRole.sheriff, number: 7, nickname: "Player 7"),
  Player(role: PlayerRole.mafia, number: 8, nickname: "Player 8"),
  Player(role: PlayerRole.citizen, number: 9, nickname: "Player 9"),
  Player(role: PlayerRole.citizen, number: 10, nickname: "Player 10"),
];

extension _GameSkipStates on Game {
  void forwardUntilStage(GameStage stage, {int maxIterations = 50}) {
    var iterations = 0;
    while (state.stage != stage && iterations++ <= maxIterations) {
      setNextState();
    }
    if (iterations > maxIterations) {
      throw Exception("Max iterations ($maxIterations) reached");
    }
  }
}

void main() {
  group("Game consistency", () {
    test("Selecting a player at night kills him", () {
      final game = Game.withPlayers(players)
        ..forwardUntilStage(GameStage.nightKill)
        ..togglePlayerSelected(4);
      expect(
        game.state,
        isA<GameStateNightKill>().having(
          (state) => state.thisNightKilledPlayerNumber,
          "thisNightKilledPlayerNumber",
          4,
        ),
      );
      game.forwardUntilStage(GameStage.nightLastWords, maxIterations: 3);
      expect(
        game.state,
        isA<GameStateWithPlayer>()
            .having((state) => state.stage, "stage", GameStage.nightLastWords)
            .having(
                (state) => state.currentPlayerNumber, "currentPlayerNumber", 4,),
      );
      game.setNextState();
      expect(game.players.getByNumber(4).isAlive, false);
    });
  });

  group("Game rules", () {
    test("Only one player can vote against not more than one player", () {
      final game = Game.withPlayers(players)
        ..forwardUntilStage(GameStage.speaking)
        ..togglePlayerSelected(4)
        ..togglePlayerSelected(5);

      expect(
        game.state,
        isA<GameStateSpeaking>()
            .having((state) => state.accusations, "accusations", hasLength(1))
            .having(
              (state) => state.accusations.values.first,
              "accusations.values.first",
              5,
            ),
        reason: "Player #1 wasn't able to change his vote",
      );

      game
        ..setNextState()
        ..togglePlayerSelected(5);
      expect(
        game.state,
        isA<GameStateSpeaking>()
            .having((state) => state.accusations, "accusations", hasLength(1)),
        reason:
            "Player #2 was able to vote against #5 despite #1 already voted against him",
      );

      game.togglePlayerSelected(4);
      expect(
        game.state,
        isA<GameStateSpeaking>()
            .having((state) => state.accusations, "accusations", hasLength(2)),
        reason: "Votes of both players weren't counted correctly",
      );
    });

    test("No deaths for 3 days is a tie", () {
      final game = Game.withPlayers(players)
        // night0, night0Sheriff, 3x (10x speaking, nightKill, 2x nightCheck), finish
        ..forwardUntilStage(GameStage.finish, maxIterations: 42);
      expect(
        game.state,
        isA<GameStateFinish>().having((state) => state.winner, "winner", null),
      );
    });

    test("No voting on day 1 when only one is accused", () {
      final game = Game.withPlayers(players)
        ..forwardUntilStage(GameStage.speaking)
        ..togglePlayerSelected(4);
      expect(
        game.state,
        isA<GameStateSpeaking>()
            .having((state) => state.accusations, "accusations", hasLength(1)),
      );
      expect(
        () => game.forwardUntilStage(GameStage.nightKill, maxIterations: 10),
        returnsNormally,
      );
      expect(game.state, isA<GameStateNightKill>());
    });

    test("Additional speech when voting between two players is tied", () {
      final game = Game.withPlayers(players)
        ..forwardUntilStage(GameStage.speaking)
        ..togglePlayerSelected(4)
        ..setNextState()
        ..togglePlayerSelected(8)
        ..forwardUntilStage(GameStage.voting)
        ..vote(4, 5)
        ..setNextState();
      expect(
        game.state,
        isA<GameStateWithCurrentPlayer>()
            .having((state) => state.stage, "stage", GameStage.excuse)
            .having(
                (state) => state.playerNumbers, "playerNumbers", hasLength(2),),
      );
    });
  });

  group("Game scenarios", () {
    test("No citizen vote game", () {
      final game = Game.withPlayers(players)
        ..forwardUntilStage(GameStage.nightKill)
        ..togglePlayerSelected(4)
        ..forwardUntilStage(GameStage.speaking, maxIterations: 4);

      expect(game.players.getByNumber(4).isAlive, false);
      expect(
        game.state,
        isA<GameStateSpeaking>().having(
            (state) => state.currentPlayerNumber, "currentPlayerNumber", 2,),
      );

      game
        ..forwardUntilStage(GameStage.nightKill, maxIterations: 9)
        ..togglePlayerSelected(9)
        ..forwardUntilStage(GameStage.speaking, maxIterations: 4);
      expect(game.players.getByNumber(9).isAlive, false);
      expect(
        game.state,
        isA<GameStateSpeaking>().having(
            (state) => state.currentPlayerNumber, "currentPlayerNumber", 3,),
      );

      game
        ..forwardUntilStage(GameStage.nightKill, maxIterations: 8)
        ..togglePlayerSelected(7)
        ..forwardUntilStage(GameStage.speaking, maxIterations: 4);
      expect(game.players.getByNumber(7).isAlive, false);
      expect(
        game.state,
        isA<GameStateSpeaking>().having(
            (state) => state.currentPlayerNumber, "currentPlayerNumber", 5,),
      );

      game
        ..forwardUntilStage(GameStage.nightKill, maxIterations: 7)
        ..togglePlayerSelected(1)
        ..forwardUntilStage(GameStage.finish, maxIterations: 4);
      expect(game.players.getByNumber(1).isAlive, false);
      expect(
        game.state,
        isA<GameStateFinish>()
            .having((state) => state.winner, "winner", PlayerRole.mafia),
      );
    });
  });
}
