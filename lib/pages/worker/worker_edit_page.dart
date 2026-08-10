import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerEditPage extends StatefulWidget {
  final String docId;
  final String name;

  const WorkerEditPage({
    super.key,
    required this.docId,
    required this.name,
  });

  @override
  State<WorkerEditPage> createState() => _WorkerEditPageState();
}

class _WorkerEditPageState extends State<WorkerEditPage> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
  }

  Future<void> _saveWorker() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("名前を入力してください")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('worker_master')
        .doc(widget.docId)
        .update({'name': name});

    Navigator.pop(context);
  }

  Future<void> _deleteWorker() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("削除確認"),
          content: Text("${widget.name} を削除しますか？"),
          actions: [
            TextButton(
              child: const Text("キャンセル"),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text("削除"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('worker_master')
          .doc(widget.docId)
          .delete();

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("作業員編集")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 入力欄
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "作業員名",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // 保存ボタン（Material 3）
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("保存する"),
                    onPressed: _saveWorker,
                  ),
                ),

                const SizedBox(height: 10),

                // 削除ボタン（Material 3）
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.delete),
                    label: const Text("削除する"),
                    onPressed: _deleteWorker,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
