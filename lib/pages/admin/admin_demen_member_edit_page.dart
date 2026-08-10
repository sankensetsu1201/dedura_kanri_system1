// lib/pages/admin/admin_demen_member_edit_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDemenMemberEditPage extends StatefulWidget {
  final String docId;
  const AdminDemenMemberEditPage({super.key, required this.docId});

  @override
  State<AdminDemenMemberEditPage> createState() =>
      _AdminDemenMemberEditPageState();
}

class _AdminDemenMemberEditPageState extends State<AdminDemenMemberEditPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<Map<String, dynamic>> _members = [];   // ← 修正済み
  Map<String, String> _workerMap = {};        // workerId → displayName

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _loadDemen();
  }

  Future<void> _loadWorkers() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection("worker_master").get();

      _workerMap = {
        for (var d in snap.docs)
          d.id: (d.data()["displayName"]?.toString() ?? d.id)
      };
    } catch (e) {
      debugPrint("load workers error: $e");
    }
  }

  Future<void> _loadDemen() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection("demen_data")
          .doc(widget.docId)
          .get();

      if (!doc.exists) {
        setState(() => _error = "データが存在しません");
        return;
      }

      final data = doc.data()!;
      final members = (data["members"] ?? []) as List;

      _members = members.map((m) {
        final wid = m["workerId"]?.toString() ?? "";
        final name = _workerMap[wid] ?? m["name"] ?? wid;
        return {"workerId": wid, "name": name};
      }).toList();
    } catch (e) {
      debugPrint("load demen error: $e");
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection("demen_data")
          .doc(widget.docId)
          .update({
        "members": _members,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("メンバーを更新しました")),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("保存に失敗しました")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  void _addMemberDialog() {
    String? selectedWorkerId;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("メンバーを追加"),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "作業員を選択",
          ),
          items: _workerMap.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (v) => selectedWorkerId = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("キャンセル")),
          TextButton(
            onPressed: () {
              if (selectedWorkerId != null) {
                setState(() {
                  _members.add({
                    "workerId": selectedWorkerId!,
                    "name": _workerMap[selectedWorkerId!]!,
                  });
                });
              }
              Navigator.pop(c);
            },
            child: const Text("追加"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("メンバー編集（管理者用）")),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("メンバー編集（管理者用）"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemberDialog,
        child: const Icon(Icons.person_add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "現在のメンバー",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_members.isEmpty)
            const Text("メンバーが登録されていません"),

          ..._members.map((m) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(m["name"] ?? ""),
                subtitle: Text("ID: ${m["workerId"]}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _members.remove(m);
                    });
                  },
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text("保存する"),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
