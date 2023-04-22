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
  bool _showRole = false;

  void _pushRolesScreen(BuildContext context, GameController controller) {
    final roles = Iterable.generate(10).map((i) => controller.currentGame.players.getRole(i + 1));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RolesScreen(roles: roles.toList()),
      ),
    );
  }

  Future<bool> _showRestartGameDialog(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Перезапустить игру"),
        content: const Text("Вы уверены? Весь прогресс будет потерян."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Нет"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
              showSnackBar(context, const SnackBar(content: Text("Игра перезапущена")));
            },
            child: const Text("Да"),
          ),
        ],
      ),
    );
    return res!;
  }

  Widget? _getBottomTextWidget(BuildContext context, GameController controller) {
    final gameState = controller.currentGame.state;
    if (gameState.state == GameState.prepare) {
      return TextButton(
        onPressed: () => _pushRolesScreen(context, controller),
        child: const Text("Раздача ролей", style: TextStyle(fontSize: 20)),
      );
    }
    if (gameState.state.isAnyOf([GameState.preVoting, GameState.preFinalVoting])) {
      final selectedPlayers = controller.currentGame.voteCandidates();
      return Text(
        "Выставлены: ${selectedPlayers.join(", ")}",
        style: const TextStyle(fontSize: 20),
      );
    }
    if (gameState.state.isAnyOf([GameState.voting, GameState.finalVoting])) {
      final selectedPlayers = controller.currentGame.voteCandidates();
      assert(selectedPlayers.isNotEmpty);
      final onlyOneSelected = selectedPlayers.length == 1;
      final aliveCount = controller.currentGame.players.aliveCount;
      return Counter(
        min: onlyOneSelected ? aliveCount : 0,
        max: aliveCount, // TODO: more smart maximum
        onValueChanged: (value) =>
            setState(() => controller.currentGame.vote(gameState.player!.number, value)),
        value: onlyOneSelected
            ? aliveCount
            : controller.currentGame.getPlayerVotes(gameState.player!.number),
      );
    }
    if (gameState.state == GameState.finish) {
      final winRole = controller.currentGame.citizenTeamWon! ? "мирных жителей" : "мафии";
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Победа команды $winRole", style: const TextStyle(fontSize: 20)),
          TextButton(
            onPressed: () async {
              if (await _showRestartGameDialog(context)) {
                setState(() => controller.restart());
              }
            },
            child: const Text("Начать заново", style: TextStyle(fontSize: 20)),
          ),
        ],
      );
    }
    if (gameState.state == GameState.dropTableVoting) {
      return TextButton(
        onPressed: () => setState(() {
          controller.currentGame.deselectAllPlayers();
          controller.currentGame.nextState();
        }),
        child: const Text("Нет", style: TextStyle(fontSize: 20)),
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
    final isGameRunning = !gameState.state.isAnyOf([GameState.prepare, GameState.finish]);
    final nextStateAssumption = controller.currentGame.nextStateAssumption;
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
              onPressed: () => _pushRolesScreen(context, controller),
            ),
          IconButton(
            onPressed: () => setState(() => _showRole = !_showRole),
            tooltip: "${!_showRole ? "Показать" : "Скрыть"} роли",
            icon: const Icon(Icons.person_search),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: "Перезапустить игру",
            onPressed: () async {
              if (await _showRestartGameDialog(context)) {
                setState(() => controller.restart());
              }
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
                final isAlive = controller.currentGame.players.isAlive(playerNumber);
                return PlayerButton(
                  number: playerNumber,
                  role: controller.currentGame.players.getRole(playerNumber),
                  isAlive: isAlive,
                  isSelected: controller.currentGame.isPlayerSelected(playerNumber),
                  isActive: gameState.player?.number == playerNumber ||
                      gameState.state.isAnyOf([GameState.night0, GameState.nightKill]) &&
                          isAlive &&
                          (controller.currentGame.players
                              .getRole(playerNumber)
                              .isAnyOf([PlayerRole.mafia, PlayerRole.don])),
                  onTap: isAlive
                      ? () {
                          if (gameState.state == GameState.nightCheck) {
                            final String result;
                            if (gameState.player!.role == PlayerRole.don) {
                              if (controller.currentGame.players.getRole(playerNumber) ==
                                  PlayerRole.commissar) {
                                result = "КОМИССАР";
                              } else {
                                result = "НЕ комиссар";
                              }
                            } else if (gameState.player!.role == PlayerRole.commissar) {
                              if (controller.currentGame.players
                                  .getRole(playerNumber)
                                  .isAnyOf([PlayerRole.mafia, PlayerRole.don])) {
                                result = "МАФИЯ";
                              } else {
                                result = "НЕ мафия";
                              }
                            } else {
                              throw AssertionError();
                            }
                            showSimpleDialog(
                              context: context,
                              title: const Text("Результат проверки"),
                              content: Text("Игрок $playerNumber — $result"),
                            );
                          } else {
                            setState(() {
                              if (controller.currentGame.isPlayerSelected(playerNumber)) {
                                controller.currentGame.deselectPlayer(playerNumber);
                              } else {
                                controller.currentGame.selectPlayer(playerNumber);
                              }
                            });
                          }
                        }
                      : null,
                  longPressActions: [
                    TextButton(
                      onPressed: () {
                        showSnackBar(
                          context,
                          SnackBar(
                            // content: Text("Выдано предупреждение игроку $playerNumber"),
                            content: const Text("Предупреждения в разработке"),
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
                  showRole: _showRole,
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
                    onTapNext: nextStateAssumption != null
                        ? () => setState(() => controller.currentGame.nextState())
                        : null,
                    nextLabel: nextStateAssumption?.prettyName ?? "(игра окончена)",
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
