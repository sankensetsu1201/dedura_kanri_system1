import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEditPage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> initialData;

  const UserEditPage({
    super.key,
    required this.uid,
    required this.initialData,
  });

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _workerIdController;

  String? _selectedGenbaId;
  String _selectedRole = "user"; // ⭐ 一般ユーザーは user に統一

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.initialData["name"] ?? "");
    _workerIdController =
        TextEditingController(text: widget.initialData["workerId"] ?? "");

    _selectedGenbaId = widget.initialData["genbaId"];
    _selectedRole = widget.initialData["role"] ?? "user";
  }

  Future<void> _updateUser() async {
    await FirebaseFirestore.instance.collection("users").doc(widget.uid).update({
      "name": _nameController.text.trim(),
      "workerId": _workerIdController.text.trim(),
      "genbaId": _selectedGenbaId,
      "role": _selectedRole, // ⭐ admin / user に統一
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ユーザー編集")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 名前
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "名前",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 作業員ID
            TextField(
              controller: _workerIdController,
              decoration: const InputDecoration(
                labelText: "作業員ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 所属現場
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("genba_master")
                  .orderBy("name")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "所属現場",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedGenbaId,
                  items: docs.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc["name"]),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedGenbaId = v),
                );
              },
            ),

            const SizedBox(height: 16),

            // 権限
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "権限",
                border: OutlineInputBorder(),
              ),
              value: _selectedRole,
              items: const [
                DropdownMenuItem(value: "user", child: Text("一般")),
                DropdownMenuItem(value: "admin", child: Text("管理者")),
              ],
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("更新する"),
              onPressed: _updateUser,
            ),
          ],
        ),
      ),
    );
  }
}
