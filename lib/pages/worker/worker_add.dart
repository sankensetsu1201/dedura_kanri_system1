import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demen_app/widgets/san_ken_appbar.dart';

class WorkerAddPage extends StatefulWidget {
  const WorkerAddPage({super.key});

  @override
  State<WorkerAddPage> createState() => _WorkerAddPageState();
}

class _WorkerAddPageState extends State<WorkerAddPage> {
  final TextEditingController nameController = TextEditingController();
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const SanKenAppBar(title: "作業員追加"),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "作業員名",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving ? null : _saveWorker,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("登録する", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWorker() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("作業員名を入力してください")),
      );
      return;
    }

    setState(() => isSaving = true);

    await FirebaseFirestore.instance.collection("workers").add({
      "name": name,
      "createdAt": DateTime.now().toIso8601String(),
    });

    setState(() => isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("作業員を登録しました")),
    );

    nameController.clear();
  }
}
