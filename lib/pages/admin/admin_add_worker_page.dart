import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddWorkerPage extends StatefulWidget {
  const AdminAddWorkerPage({super.key});

  @override
  State<AdminAddWorkerPage> createState() => _AdminAddWorkerPageState();
}

class _AdminAddWorkerPageState extends State<AdminAddWorkerPage> {
  final _nameController = TextEditingController();        // 日本語名
  final _romanController = TextEditingController();       // ローマ字
  final _birthdayController = TextEditingController();    // 4桁番号（誕生日）
  final _teamController = TextEditingController();        // 任意
  String role = "worker";

  Future<void> _saveWorker() async {
    final name = _nameController.text.trim();
    final roman = _romanController.text.trim();
    final birthday = _birthdayController.text.trim();

    if (name.isEmpty || roman.isEmpty || birthday.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("入力内容を確認してください")),
      );
      return;
    }

    final workerId = "$roman$birthday";

    // 重複チェック
    final doc = await FirebaseFirestore.instance
        .collection("workers")
        .doc(workerId)
        .get();

    if (doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("この作業員IDは既に存在します")),
      );
      return;
    }

    // 保存
    await FirebaseFirestore.instance
        .collection("workers")
        .doc(workerId)
        .set({
      "id": workerId,
      "name": name,
      "roman": roman,
      "birthday": birthday,
      "role": role,
      "team": _teamController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("作業員 $workerId を登録しました")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("作業員登録")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "名前（日本語）",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _romanController,
              decoration: const InputDecoration(
                labelText: "ローマ字（例：yamada）",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _birthdayController,
              decoration: const InputDecoration(
                labelText: "誕生日（4桁：0721）",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField(
              initialValue: role,
              items: const [
                DropdownMenuItem(value: "worker", child: Text("worker")),
                DropdownMenuItem(value: "admin", child: Text("admin")),
              ],
              onChanged: (v) => setState(() => role = v!),
              decoration: const InputDecoration(
                labelText: "役割",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _teamController,
              decoration: const InputDecoration(
                labelText: "班（任意）",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveWorker,
                child: const Text("登録する"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
