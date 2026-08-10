import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerAddPage extends StatefulWidget {
  const WorkerAddPage({super.key});

  @override
  State<WorkerAddPage> createState() => _WorkerAddPageState();
}

class _WorkerAddPageState extends State<WorkerAddPage> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _addWorker() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("名前を入力してください")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('worker_master').add({
      'name': name,
    });

    Navigator.pop(context); // 追加後に戻る
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("作業員追加")),
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

                // 追加ボタン（Material 3）
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("追加する"),
                    onPressed: _addWorker,
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
