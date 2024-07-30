import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";

import "../game/states.dart";
import "../utils/api_calls.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/navigation.dart";
import "../utils/ui.dart";
import "../widgets/app_drawer.dart";
import "../widgets/bottom_controls.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/game_state.dart";
import "../widgets/orientation_dependent.dart";
import "../widgets/player_buttons.dart";
import "../widgets/restart_dialog.dart";
import "main.dart";

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  var _showRoles = false;
  final _notesController = TextEditingController();
  final apiCalls = ApiCalls();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    unawaited(apiCalls.startGame(context.read<GameController>().players));
  }

  Future<void> _askRestartGame(BuildContext context) async {
    final restartGame = await showDialog<bool>(
      context: context,
      builder: (context) => const RestartGameDialog(),
    );
    if (context.mounted && (restartGame ?? false)) {
      unawaited(apiCalls.stopGame());
      context.read<GameController>().restart();
      await openPage(context, const MainScreen());
      // ignore: use_build_context_synchronously
      unawaited(showSnackBar(context, const SnackBar(content: Text("Игра перезапущена"))));
    }
  }

  void _showNotes(BuildContext context) {
    showSimpleDialog(
      context: context,
      title: const Text("Заметки"),
      content: TextField(
        controller: _notesController,
        maxLines: null,
      ),
      actions: [
        TextButton(
          onPressed: _notesController.clear,
          child: const Text("Очистить"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    
    final gameState = controller.state;
    final isGameRunning = !gameState.stage.isAnyOf([GameStage.prepare, GameStage.finish]);

    return PopScope(
      canPop: controller.state.stage == GameStage.prepare,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final res = await showDialog<bool>(
          context: context,
          builder: (context) => const ConfirmationDialog(
            title: Text("Выход из игры"),
            content: Text("Вы уверены, что хотите выйти из игры? Все данные будут потеряны."),
          ),
        );
        if ((res ?? false) && context.mounted) {
          // exit flutter app
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: isGameRunning ? Text("День ${controller.state.day}") : const Text("Подготовка к игре"),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, "/log"),
              tooltip: "Журнал игры",
              icon: const Icon(Icons.list),
            ),
            // IconButton(
            //   onPressed: () => _showNotes(context),
            //   tooltip: "Заметки",
            //   icon: const Icon(Icons.sticky_note_2),
            // ),
            IconButton(
              onPressed: () => setState(() => _showRoles = !_showRoles),
              tooltip: "${!_showRoles ? "Показать" : "Скрыть"} роли",
              icon: const Icon(Icons.person_search),
            ),
            IconButton(
              onPressed: () => _askRestartGame(context),
              tooltip: "Перезапустить игру",
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: _RotatableGameScreenBody(showRoles: _showRoles),
      ),
    );
  }
}

class _RotatableGameScreenBody extends OrientationDependentWidget {
  final bool showRoles;

  const _RotatableGameScreenBody({
    this.showRoles = false,
  });

  @override
  Widget buildPortrait(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerButtons(showRoles: showRoles),
          const Flexible(child: _GameScreenGameBodyContent()),
        ],
      );

  @override
  Widget buildLandscape(BuildContext context) => Column(
        children: [
          PlayerButtons(showRoles: showRoles),
          const Flexible(child: _GameScreenGameBodyContent()),
        ],
      );
}

class _GameScreenGameBodyContent extends OrientationDependentWidget {
  const _GameScreenGameBodyContent();

  @override
  Widget buildPortrait(BuildContext context) => buildWidget(context, false);
  @override
  Widget buildLandscape(BuildContext context) => buildWidget(context, true);

  Widget buildWidget(BuildContext context, bool isLandscape) {
    final controller = context.watch<GameController>();
    final previousState = controller.previousState;
    final nextStateAssumption = controller.nextStateAssumption;

    return Column(
      children: [
        const Expanded(
          child: Center(
            child: GameStateInfo(),
          ),
        ),
        BottomControlBar(
          backLabel: previousState?.prettyName(isLandscape: isLandscape) ?? "(отмена невозможна)",
          onTapBack: previousState != null ? controller.setPreviousState : null,
          onTapNext: nextStateAssumption != null ? controller.setNextState : null,
          nextLabel: nextStateAssumption?.prettyName(isLandscape: isLandscape) ?? "(игра окончена)",
        ),
      ],
    );
  }
}
