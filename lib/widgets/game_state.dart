import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../game/player.dart";
import "../game/states.dart";
import "../utils/api_calls.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/navigation.dart";
import "../utils/settings.dart";
import "../utils/ui.dart";
import "counter.dart";
import "orientation_dependent.dart";
import "player_timer.dart";

class GameStateInfo extends OrientationDependentWidget {
  const GameStateInfo({super.key});

  @override
  Widget buildPortrait(BuildContext context) =>
      buildWidget(context, isLandscape: false);
  @override
  Widget buildLandscape(BuildContext context) =>
      buildWidget(context, isLandscape: true);

  Widget buildWidget(BuildContext context, {required bool isLandscape}) {
    final gameState = context.watch<GameController>().state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          gameState.prettyName(isLandscape: isLandscape),
          style: TextStyle(
            fontSize: isLandscape ? 32 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
          // textAlign: TextAlign.center,
        ),
        const Align(
          // padding: EdgeInsets.symmetric(vertical: 0),
          alignment: Alignment.center,
          child: BottomGameStateWidget(),
        ),
      ],
    );
  }
}

class BottomGameStateWidget extends OrientationDependentWidget {
  const BottomGameStateWidget({super.key});

  @override
  Widget buildPortrait(BuildContext context) => buildWidget(context, false);
  @override
  Widget buildLandscape(BuildContext context) => buildWidget(context, true);

  Widget buildWidget(BuildContext context, bool isLandscape) {
    final controller = context.watch<GameController>();
    final settings = context.watch<SettingsModel>();
    final gameState = controller.state;

    if (gameState.stage == GameStage.prepare) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [],
      );
    }

    if (gameState.stage
        .isAnyOf([GameStage.preVoting, GameStage.preFinalVoting])) {
      final selectedPlayers = controller.voteCandidates;
      return Align(
        alignment: Alignment.bottomCenter,
        child: Text(
          "Выставлены: ${selectedPlayers.join(", ")}",
          style: const TextStyle(fontSize: 20),
        ),
      );
    }

    if (gameState is GameStateVoting) {
      final selectedPlayers = controller.voteCandidates;
      assert(selectedPlayers.isNotEmpty, "No vote candidates (bug?)");
      final onlyOneSelected = selectedPlayers.length == 1;
      final aliveCount = controller.alivePlayersCount;
      final currentPlayerVotes = gameState.currentPlayerVotes ?? 0;
      if (gameState.lastPlayer == gameState.currentPlayerNumber) {
        final votesForLast =
            controller.alivePlayersCount - controller.totalVotes;

        return Counter(
          key: ValueKey(gameState.currentPlayerNumber),
          min: votesForLast,
          max: votesForLast,
          initialValue: votesForLast,
          onValueChanged: (value) =>
              controller.vote(gameState.currentPlayerNumber, value),
        );
      } else {
        var alreadyVoted = 0;
        for (final player in gameState.votes.keys) {
          if (player == gameState.currentPlayerNumber) break;

          alreadyVoted += gameState.votes[player] ?? 0;
        }
        return Counter(
          key: ValueKey(gameState.currentPlayerNumber),
          min: onlyOneSelected ? aliveCount : 0,
          max: aliveCount - alreadyVoted,
          onValueChanged: (value) =>
              controller.vote(gameState.currentPlayerNumber, value),
          initialValue: onlyOneSelected ? aliveCount : currentPlayerVotes,
        );
      }
    }

    if (gameState is GameStateDropTableVoting) {
      return Counter(
        key: const ValueKey("dropTableVoting"),
        min: 0,
        max: controller.alivePlayersCount,
        onValueChanged: (value) => controller.vote(null, value),
        initialValue: gameState.votesForDropTable,
      );
    }

    if (gameState case GameStateFinish(winner: final winner)) {
      var resultText = switch (winner) {
        PlayerRole.citizen => "Победа мирных",
        PlayerRole.mafia => "Победа мафии",
        null => "Ничья",
        _ => throw AssertionError(),
      };
      if (gameState.ppkPlayer != null) {
        resultText += "\nППК: ${gameState.ppkPlayer!.nickname}";
        ApiCalls().stopGame(
          tableToken: controller.tableToken,
          winner: winner,
          ppk: gameState.ppkPlayer?.number,
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(resultText, style: const TextStyle(fontSize: 20)),
          TextButton(
            onPressed: () async {
              // final restartGame = await showDialog<bool>(
              //   context: context,
              //   builder: (context) => const RestartGameDialog(),
              // );
              // if (restartGame ?? false) {
              controller.restart();
              await openMainPage(context);
              // controller.restart();
              if (context.mounted) {
                unawaited(
                  showSnackBar(
                    context,
                    const SnackBar(content: Text("Игра перезапущена")),
                  ),
                );
              }
              // }
            },
            child: const Text("На главную", style: TextStyle(fontSize: 20)),
          ),
        ],
      );
    }

    final Duration? timeLimit;
    switch (settings.timerType) {
      case TimerType.disabled:
        timeLimit = null;
      case TimerType.extended:
        timeLimit =
            timeLimitsExtended[gameState.stage] ?? timeLimits[gameState.stage];
      case TimerType.strict:
        timeLimit = timeLimits[gameState.stage];
    }
    if (timeLimit != null) {
      return PlayerTimer(
        key: ValueKey(controller.state),
        duration: timeLimit,
        isLandscape: isLandscape,
        onTimerTick: (duration) async {
          if (duration == Duration.zero) {
            await Future<void>.delayed(
              const Duration(milliseconds: 300),
            ); // 100 vibration + 200 pause
          } else if (duration <= const Duration(seconds: 5)) {}
        },
      );
    }
    return const SizedBox.shrink(); // empty widget
  }
}
