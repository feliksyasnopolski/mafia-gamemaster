import "package:flutter/material.dart";

class InputDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final TextEditingController _textEditingController = TextEditingController();

  InputDialog({
    super.key,
    required this.title,
    required this.content,
    });

  @override
  Widget build(BuildContext context) {
    _textEditingController.text = (content as Text).data ?? "";
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: _textEditingController, // Add this line
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            String inputText = _textEditingController.text;
            // Do something with the input text
            Navigator.pop(context, inputText);
          },
          child: Text("OK"),
        ),
      ],
    );
  }
}