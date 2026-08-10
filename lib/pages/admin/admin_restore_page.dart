// lib/pages/admin/admin_restore_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRestorePage extends StatefulWidget {
  const AdminRestorePage({super.key});

  @override
  State<AdminRestorePage> createState() => _AdminRestorePageState();
}

class _AdminRestorePageState extends State<AdminRestorePage> {
  bool _loading = true;
  bool _restoring = false;
  String? _error;

  List<QueryDocumentSnapshot> _backups = [];
  Map<String, dynamic>? _selectedBackup;

  @override
  void initState() {
    super.initState();
    _loadBackupList();
  }

  Future<void> _loadBackupList() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection("backup")
          .orderBy("createdAt", descending: true)
          .get();

      _backups = snap.docs;
    } catch (e) {
      debugPrint("load backup list error: $e");
      _error = "バックアップ一覧の取得に失敗しました";
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadBackupData(String docId) async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedBackup = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection("backup")
          .doc(docId)
          .get();

      if (!doc.exists) {
        setState(() => _error = "バックアップが存在しません");
        return;
      }

      final jsonString = doc.data()?["json"];
      if (jsonString == null) {
        setState(() => _error = "バックアップデータが壊れています");
        return;
      }

      _selectedBackup = jsonDecode(jsonString);
    } catch (e) {
      debugPrint("load backup error: $e");
      _error = "バックアップデータの読み込みに失敗しました";
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _restoreCollection(
      String collectionName, Map<String, dynamic> backupData) async {
    final items = backupData["items"] as List;

    // 既存データ削除
    final snap =
        await FirebaseFirestore.instance.collection(collectionName).get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }

    // 復元
    for (final item in items) {
      final id = item["id"];
      final data = item["data"];
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(id)
          .set(data);
    }
  }

  Future<void> _runRestore() async {
    if (_selectedBackup == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("復元確認"),
        content: const Text(
            "バックアップから復元すると、現在のデータは上書きされます。\n本当に復元しますか？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("復元する")),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _restoring = true;
      _error = null;
    });

    try {
      // worker_master
      final workerMaster = _selectedBackup?["worker_master"];
      if (workerMaster != null) {
        await _restoreCollection("worker_master", workerMaster);
      }

      // genba_master
      final genbaMaster = _selectedBackup?["genba_master"];
      if (genbaMaster != null) {
        await _restoreCollection("genba_master", genbaMaster);
      }

      // demen_data
      final demenData = _selectedBackup?["demen_data"];
      if (demenData != null) {
        await _restoreCollection("demen_data", demenData);
      }

      // users
      final users = _selectedBackup?["users"];
      if (users != null) {
        await _restoreCollection("users", users);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("復元が完了しました")),
      );
    } catch (e) {
      debugPrint("restore error: $e");
      setState(() => _error = "復元に失敗しました");
    } finally {
      setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("バックアップ復元（管理者用）")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "バックアップ一覧",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_backups.isEmpty)
            const Text("バックアップがありません"),

          ..._backups.map((doc) {
  final data = doc.data();
  final createdAt = (data is Map<String, dynamic> ? data["createdAt"] : null) ?? doc.id;

  return Card(
    child: ListTile(
      leading: const Icon(Icons.backup),
      title: Text("バックアップ: $createdAt"),
      subtitle: const Text("タップして読み込み"),
      onTap: () => _loadBackupData(doc.id),
    ),
  );
}),


          const SizedBox(height: 24),

          if (_selectedBackup != null) ...[
  const Text(
    "選択中のバックアップ",
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 12),

  Text("作成日時: ${_selectedBackup?["createdAt"] ?? "不明"}"),
  const SizedBox(height: 12),

  FilledButton.icon(
    icon: _restoring
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.restore),
    label: const Text("このバックアップで復元する"),
    onPressed: _restoring ? null : _runRestore,
  ),
],

        ],
      ),
    );
  }
}
