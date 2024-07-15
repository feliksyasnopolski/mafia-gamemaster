import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";

import "../game/states.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/navigation.dart";
import "../utils/ui.dart";
import "../widgets/app_drawer.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/orientation_dependent.dart";
import "../widgets/restart_dialog.dart";

// ignore: deprecated_member_use
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _showRoles = false;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _askRestartGame(BuildContext context) async {
    final restartGame = await showDialog<bool>(
      context: context,
      builder: (context) => const RestartGameDialog(),
    );
    if (context.mounted && (restartGame ?? false)) {
      context.read<GameController>().restart();
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
    // final packageInfo = context.watch<PackageInfo>();
    // $PLACEHOLDER$
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
            IconButton(
              onPressed: () => _showNotes(context),
              tooltip: "Заметки",
              icon: const Icon(Icons.sticky_note_2),
            ),
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
        body: _RotatableMainScreenBody(showRoles: _showRoles),
      ),
    );
  }
}


class _RotatableMainScreenBody extends OrientationDependentWidget {
  final bool showRoles;

  const _RotatableMainScreenBody({
    this.showRoles = false,
  });

  @override
  Widget buildPortrait(BuildContext context) => const Column(
        children: [
          Flexible(child: _MainScreenMainBodyContent()),
        ],
      );

  @override
  Widget buildLandscape(BuildContext context) => const Row(
        children: [
          Flexible(child: _MainScreenMainBodyContent()),
        ],
      );
}

class _MainScreenMainBodyContent extends StatelessWidget {
  const _MainScreenMainBodyContent();

  Future<void> _onStartGamePressed(BuildContext context, GameController controller) async {
    await openRoleChooserPage(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
  
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
            onPressed: () => _onStartGamePressed(context, controller),
            child: const Text("Начать игру", style: TextStyle(fontSize: 20)),
          ),
      ],
    );
  }
}
