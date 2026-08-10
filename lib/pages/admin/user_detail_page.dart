// lib/pages/admin/user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailPage extends StatefulWidget {
  final String workerId; // worker_master の ID
  const UserDetailPage({required this.workerId, super.key});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _role = "user"; // users の role
  String? _userDocId;    // users の docId
  String? _workerDocId;  // worker_master の docId

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  /// role → 日本語
  String roleToJapanese(String role) {
    switch (role) {
      case "admin":
        return "管理者";
      case "user":
        return "一般";
      default:
        return role;
    }
  }

  /// 日本語 → role
  String japaneseToRole(String jp) {
    switch (jp) {
      case "管理者":
        return "admin";
      case "一般":
        return "user";
      default:
        return "user";
    }
  }

  /// ⭐ worker_master と users の両方を読み込む
  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // worker_master 読み込み
      final workerDoc =
          await FirebaseFirestore.instance.collection("worker_master").doc(widget.workerId).get();

      if (!workerDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("作業員が見つかりません")));
        }
        setState(() => _loading = false);
        return;
      }

      final workerData = workerDoc.data()!;
      _workerDocId = workerDoc.id;

      _displayNameCtrl.text = workerData["displayName"] ?? "";
      _emailCtrl.text = workerData["email"] ?? "";

      // users 読み込み（role は users 側）
      final usersSnap = await FirebaseFirestore.instance
          .collection("users")
          .where("workerId", isEqualTo: widget.workerId)
          .limit(1)
          .get();

      if (usersSnap.docs.isNotEmpty) {
        final userDoc = usersSnap.docs.first;
        _userDocId = userDoc.id;
        _role = userDoc.data()["role"] ?? "user";
      } else {
        _role = "user"; // デフォルト
      }
    } catch (e) {
      debugPrint("load error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("読み込みに失敗しました")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ⭐ 保存処理（worker_master と users の両方更新）
  Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _saving = true);

  try {
    // worker_master 更新
    if (_workerDocId != null) {
      await FirebaseFirestore.instance
          .collection("worker_master")
          .doc(_workerDocId)
          .update({
        "displayName": _displayNameCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }

    // users 更新（role）
    if (_userDocId != null) {
      // 既存ユーザー → 更新
      await FirebaseFirestore.instance
          .collection("users")
          .doc(_userDocId)
          .update({
        "role": _role,
        "workerId": widget.workerId,
      });
    } else {
      // ⭐ workerId が紐づいていない場合 → 新規作成
      await FirebaseFirestore.instance.collection("users").add({
        "workerId": widget.workerId,
        "role": _role,
        "email": _emailCtrl.text.trim(),
        "displayName": _displayNameCtrl.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("保存しました")));
    }
  } catch (e) {
    debugPrint("save error: $e");
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("保存に失敗しました")));
    }
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

  /// ⭐ 削除処理（worker_master 削除 → users の workerId 削除）
  Future<void> _delete() async {
    if (_workerDocId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("削除確認"),
        content: const Text("この作業員を削除しますか？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("キャンセル")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("削除")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // worker_master 削除
      await FirebaseFirestore.instance
          .collection("worker_master")
          .doc(_workerDocId)
          .delete();

      // users の workerId を削除
      final usersSnap = await FirebaseFirestore.instance
          .collection("users")
          .where("workerId", isEqualTo: widget.workerId)
          .get();

      for (final u in usersSnap.docs) {
        await u.reference.update({"workerId": FieldValue.delete()});
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("削除しました")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("delete error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("削除に失敗しました")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("作業員詳細: ${widget.workerId}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _workerDocId == null ? null : _delete,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _displayNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "表示名",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "必須です" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: "メール",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "必須です";
                        if (!v.contains("@")) return "有効なメールを入力してください";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      value: roleToJapanese(_role),
                      decoration: const InputDecoration(
                        labelText: "権限",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "管理者", child: Text("管理者")),
                        DropdownMenuItem(value: "一般", child: Text("一般")),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _role = japaneseToRole(v);
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("保存"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
