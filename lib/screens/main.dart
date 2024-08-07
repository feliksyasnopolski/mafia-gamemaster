import "dart:async";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";

import "../game/states.dart";
import "../utils/extensions.dart";
import "../utils/game_controller.dart";
import "../utils/ui.dart";
import "../widgets/app_drawer.dart";
import "../widgets/confirmation_dialog.dart";
import "../widgets/orientation_dependent.dart";
import "../widgets/restart_dialog.dart";
import "../widgets/table_chooser_dialog.dart";

// ignore: deprecated_member_use
@RoutePage()
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _showRoles = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final settings = Provider.of<SettingsModel>(context, listen: false); //context.watch<SettingsModel>();

    //   if (settings.appToken.isEmpty)
    //   {
    //     Navigator.pushReplacementNamed(context, "/login");
    //   }
    // });
  }

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
      unawaited(showSnackBar(
          context, const SnackBar(content: Text("Игра перезапущена"))));
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
    final isGameRunning =
        !gameState.stage.isAnyOf([GameStage.prepare, GameStage.finish]);
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
            content: Text(
                "Вы уверены, что хотите выйти из игры? Все данные будут потеряны."),
          ),
        );
        if ((res ?? false) && context.mounted) {
          // exit flutter app
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mafia Arena"),
          actions: const [],
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

  Future<void> _onStartGamePressed(
      BuildContext context, GameController controller) async {
    await showDialog<String>(
      context: context,
      builder: (context) => TableChooserDialog(
        gameController: controller,
      ),
    );
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
