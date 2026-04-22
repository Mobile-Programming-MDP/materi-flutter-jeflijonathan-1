import 'package:flutter/material.dart';
import 'package:notes/widgets/note_dialog.dart';

class NoteScreen extends StatelessWidget {
  const NoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: const Center(child: Text('This is the Note Screen')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const NoteDialog();
            },
          );
        },
      ),
    );
  }
}
