// lib/pages/admin/worker_manage_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerManagePage extends StatefulWidget {
  const WorkerManagePage({super.key});

  @override
  State<WorkerManagePage> createState() => _WorkerManagePageState();
}

class _WorkerManagePageState extends State<WorkerManagePage> {
  bool _loading = true;
  String? _error;
  List<QueryDocumentSnapshot> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection("worker_master")
          .orderBy("displayName")
          .get();

      _workers = snap.docs;
    } catch (e) {
      debugPrint("load workers error: $e");
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addWorker() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final workerIdController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("作業員を追加"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: workerIdController,
              decoration: const InputDecoration(
                labelText: "workerId（必須）",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "表示名（displayName）",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "メール（任意）",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("追加")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection("worker_master").doc(workerIdController.text.trim()).set({
        "workerId": workerIdController.text.trim(),
        "displayName": nameController.text.trim(),
        "email": emailController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("作業員を追加しました")),
      );

      _loadWorkers();
    } catch (e) {
      debugPrint("add worker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("追加に失敗しました")),
      );
    }
  }

  Future<void> _editWorker(String docId, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data["displayName"] ?? "");
    final emailController = TextEditingController(text: data["email"] ?? "");

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("作業員を編集"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "表示名（displayName）",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "メール（任意）",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("保存")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection("worker_master").doc(docId).update({
        "displayName": nameController.text.trim(),
        "email": emailController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("作業員を更新しました")),
      );

      _loadWorkers();
    } catch (e) {
      debugPrint("edit worker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("更新に失敗しました")),
      );
    }
  }

  Future<void> _deleteWorker(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("削除確認"),
        content: const Text("この作業員を削除しますか？\n※ 出面データの整合性に注意してください"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("削除")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection("worker_master").doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("作業員を削除しました")),
      );

      _loadWorkers();
    } catch (e) {
      debugPrint("delete worker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("削除に失敗しました")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("作業員管理（管理者用）"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addWorker,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("読み込みエラー: $_error"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _workers.length,
                  itemBuilder: (context, i) {
                    final doc = _workers[i];
                    final data = doc.data() as Map<String, dynamic>;

                    final workerId = data["workerId"] ?? doc.id;
                    final name = data["displayName"] ?? "(名前なし)";
                    final email = data["email"] ?? "(メールなし)";

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text("ID: $workerId\nメール: $email"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editWorker(doc.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteWorker(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
