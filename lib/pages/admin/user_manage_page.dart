// lib/pages/admin/user_manage_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagePage extends StatefulWidget {
  const UserManagePage({super.key});

  @override
  State<UserManagePage> createState() => _UserManagePageState();
}

class _UserManagePageState extends State<UserManagePage> {
  bool _loading = true;
  String? _error;
  List<QueryDocumentSnapshot> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .orderBy("workerId")
          .get();

      _users = snap.docs;
    } catch (e) {
      debugPrint("load users error: $e");
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateRole(String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({"role": newRole});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("権限を $newRole に変更しました")),
      );

      _loadUsers();
    } catch (e) {
      debugPrint("update role error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("権限変更に失敗しました")),
      );
    }
  }

  Future<void> _updateWorkerId(String uid, String workerId) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({"workerId": workerId});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("workerId を更新しました")),
      );

      _loadUsers();
    } catch (e) {
      debugPrint("update workerId error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("workerId 更新に失敗しました")),
      );
    }
  }

  Future<void> _deleteUser(String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("削除確認"),
        content: const Text("このユーザーを削除しますか？\n※ Firebase Auth の削除は別途必要です"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("削除")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection("users").doc(uid).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ユーザーを削除しました")),
      );

      _loadUsers();
    } catch (e) {
      debugPrint("delete user error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("削除に失敗しました")),
      );
    }
  }

  void _openWorkerIdEditDialog(String uid, String currentWorkerId) {
    final controller = TextEditingController(text: currentWorkerId);

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("workerId を編集"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "workerId",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("キャンセル")),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _updateWorkerId(uid, controller.text.trim());
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ユーザー管理")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("読み込みエラー: $_error"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, i) {
                    final doc = _users[i];
                    final data = doc.data() as Map<String, dynamic>;

                    final uid = doc.id;
                    final email = data["email"] ?? "(メールなし)";
                    final role = data["role"] ?? "user";
                    final workerId = data["workerId"] ?? "(未設定)";

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(email),
                        subtitle: Text("workerId: $workerId\nrole: $role"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == "admin" || value == "user") {
                              _updateRole(uid, value);
                            } else if (value == "edit_workerId") {
                              _openWorkerIdEditDialog(uid, workerId);
                            } else if (value == "delete") {
                              _deleteUser(uid);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: "admin",
                              child: Text("権限を admin に変更"),
                            ),
                            const PopupMenuItem(
                              value: "user",
                              child: Text("権限を user に変更"),
                            ),
                            const PopupMenuItem(
                              value: "edit_workerId",
                              child: Text("workerId を編集"),
                            ),
                            const PopupMenuItem(
                              value: "delete",
                              child: Text("ユーザー削除"),
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
