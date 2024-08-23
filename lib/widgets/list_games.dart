import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../router/router.gr.dart";
import "../utils/api_calls.dart";
import "../utils/api_models.dart";
import "../utils/game_controller.dart";
import "table_chooser_dialog.dart";

class ListGames extends StatelessWidget {
  // final List<String> games;
  final GameController gameController;

  const ListGames({super.key, required this.gameController});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<GamesModel>>(
        future: ApiCalls().getUnfinishedGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          final games = snapshot.data!;
          return ListView.builder(
            itemCount: games.length + 1,
            itemBuilder: (context, index) {
              if (index == games.length) {
                return _newGame(context, gameController);
              }
              final game = games[index];

              return ListTile(
                title: Text(game.tableName),
                subtitle: Text(
                    "Игра от ${DateFormat('dd/MM/yy HH:mm').format(game.startedAt)}",),
                onTap: () async {
                  final tableToken = game.tableToken;
                  final gameState = await ApiCalls().getGameState(tableToken);
                  gameController.resume(gameState);
                  if (context.mounted) {
                    await context.router.push(const GameRoute());
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: Text("You selected ${game.tableName}"),
                    //   ),
                    // );
                  }
                },
              );
            },
          );
        },
      );

  Widget _newGame(BuildContext context, GameController controller) => ListTile(
        tileColor: Theme.of(context).secondaryHeaderColor.withOpacity(0.5),
        title: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add),
              Text(
                "Новая игра",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        onTap: () async {
          await showDialog<String>(
            context: context,
            builder: (context) => TableChooserDialog(
              gameController: controller,
            ),
          );
        },
      );
}
