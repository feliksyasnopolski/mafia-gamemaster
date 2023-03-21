import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/controller.dart';
import '../game/player.dart';
import '../game/states.dart';
import '../utils.dart';
import '../widgets/bottom_controls.dart';
import '../widgets/counter.dart';
import '../widgets/player_button.dart';
import '../widgets/player_timer.dart';
import 'roles.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Widget? _getBottomTextWidget(BuildContext context, GameController controller) {
    final gameState = controller.currentGame.state;
    final roles = Iterable.generate(10).map((i) => controller.currentGame.players.getRole(i + 1));
    if (gameState.state == GameState.prepare) {
      return TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RolesScreen(roles: roles.toList()),
          ),
        ),
        child: const Text("Раздача ролей", style: TextStyle(fontSize: 20)),
      );
    }
    if (gameState.state == GameState.voting || gameState.state == GameState.finalVoting) {
      return Counter(
        min: 0,
        max: controller.currentGame.players.aliveCount, // TODO: more smart maximum
        onValueChanged: (value) =>
            setState(() => controller.currentGame.vote(gameState.player!.number, value)),
        value: controller.currentGame.getPlayerVotes(gameState.player!.number),
      );
    }
    final timeLimit = timeLimits[gameState.state];
    if (timeLimit != null) {
      return PlayerTimer(
        key: ValueKey(controller.currentGame.state),
        duration: timeLimit,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final gameState = controller.currentGame.state;
    final isGameRunning =
        gameState.state != GameState.prepare && gameState.state != GameState.finish;
    final roles = Iterable.generate(10).map((i) => controller.currentGame.players.getRole(i + 1));
    return Scaffold(
      appBar: AppBar(
        title: isGameRunning
            ? Text("День ${controller.currentGame.day}")
            : const Text("Mafia companion"),
        actions: [
          if (isGameRunning)
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: "Роли",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RolesScreen(roles: roles.toList()),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: "Перезапустить игру",
            onPressed: () {
              setState(() => controller.restart());
              showSnackBar(context, const SnackBar(content: Text("Игра перезапущена")));
            },
          )
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200, // maxCrossAxisExtent * 2
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 100,
              ),
              itemCount: controller.currentGame.players.length,
              itemBuilder: (context, index) {
                final playerNumber = index + 1;
                return PlayerButton(
                  number: playerNumber,
                  role: controller.currentGame.players.getRole(playerNumber),
                  isAlive: controller.currentGame.players.isAlive(playerNumber),
                  isSelected: controller.currentGame.isPlayerSelected(playerNumber),
                  isActive: gameState.player?.number == playerNumber ||
                      gameState.state.isAnyOf([GameState.night0, GameState.nightKill]) &&
                          controller.currentGame.players.isAlive(playerNumber) &&
                          (controller.currentGame.players
                              .getRole(playerNumber)
                              .isAnyOf([PlayerRole.mafia, PlayerRole.don])),
                  onTap: () => setState(() {
                    if (controller.currentGame.isPlayerSelected(playerNumber)) {
                      controller.currentGame.deselectPlayer(playerNumber);
                    } else {
                      controller.currentGame.selectPlayer(playerNumber);
                    }
                  }),
                  longPressActions: [
                    TextButton(
                      onPressed: () {
                        showSnackBar(
                          context,
                          SnackBar(
                            content: Text("Выдано предупреждение игроку $playerNumber"),
                            action: SnackBarAction(
                              label: "Отменить",
                              onPressed: () {},
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text("Предупреждение"),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        gameState.prettyName,
                        style: const TextStyle(fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _getBottomTextWidget(context, controller),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 40,
                  width: MediaQuery.of(context).size.width,
                  child: BottomControlBar(
                    backLabel: "(не реализовано)",
                    onTapNext: () => setState(() => controller.currentGame.nextState()),
                    nextLabel: controller.currentGame.nextStateAssumption!.prettyName,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
