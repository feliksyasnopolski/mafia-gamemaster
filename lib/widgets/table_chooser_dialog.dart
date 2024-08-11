import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";

import "../utils/api_calls.dart";
import "../utils/api_models.dart";
import "../utils/game_controller.dart";
import "../utils/navigation.dart";

class TableChooserDialog extends StatelessWidget {
  // final TextEditingController _textEditingController = TextEditingController();
  final GameController gameController;

  const TableChooserDialog({
    super.key,
    required this.gameController,
  });

  @override
  Widget build(BuildContext context) {
    var tableToken = "";

    return AlertDialog(
      title: const Text("Выберите стол"),
      content: FutureBuilder<List<TablesModel>>(
        future: ApiCalls().getTables(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            }
          }
          final tables = snapshot.data;

          final tableItems = tables!
              .map(
                (table) => DropdownMenuEntry<String>(
                  value: table.token ?? "",
                  label: table.name ?? "",
                ),
              )
              .toList();

          return DropdownMenu(
            dropdownMenuEntries: tableItems,
            onSelected: (value) {
              tableToken = value ?? "";
            },
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.router.maybePop();
            // openMainPage(context);
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (tableToken == "") {
              // show snackbar
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text("Выберите стол"),
                    duration: Duration(seconds: 3),
                  ),
                );
              return;
            }
            gameController.tableToken = tableToken;
            gameController.restart();
            openRoleChooserPage(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}
