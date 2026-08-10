// lib/pages/demen/demen_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'demen_edit_page.dart';

class DemenDetailPage extends StatefulWidget {
  final String docId;
  const DemenDetailPage({super.key, required this.docId});

  @override
  State<DemenDetailPage> createState() => _DemenDetailPageState();
}

class _DemenDetailPageState extends State<DemenDetailPage> {
  bool _loading = true;
  Map<String, dynamic>? _data;

  bool _isAdmin = false;
  bool _canEdit = false;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      // 現在のユーザー
      final user = FirebaseAuth.instance.currentUser;
      _currentUid = user?.uid;

      // 権限チェック
      if (_currentUid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(_currentUid)
            .get();

        if (userDoc.exists) {
          final u = userDoc.data()!;
          _isAdmin = (u["role"] == "admin");
        }
      }

      // 出面データ取得
      final doc = await FirebaseFirestore.instance
          .collection("demen_data")
          .doc(widget.docId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("データが見つかりません")));
          Navigator.pop(context);
        }
        return;
      }

      _data = doc.data()!;
      final createdBy = _data!["createdBy"]?.toString();

      _canEdit = _isAdmin || (createdBy == _currentUid);
    } catch (e) {
      debugPrint("detail load error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("削除権限がありません")));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text("削除確認"),
          content: const Text("本当に削除しますか？\nこの操作は取り消せません。"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("削除する")),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("demen_data")
          .doc(widget.docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("削除しました")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("delete error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("削除に失敗しました")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("出面詳細"),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DemenEditPage(docId: widget.docId),
                  ),
                ).then((_) => _load());
              },
            ),
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text("データがありません"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      Text("現場: ${_data!["genbaId"]}", style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 12),
                      Text("日付: ${_data!["date"]}", style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 12),
                      Text("作業内容:\n${_data!["work"]}", style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 12),
                      Text("出面区分: ${_data!["dayCount"]}", style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 12),
                      Text("残業: ${_data!["overtime"]} 時間", style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 12),
                      Text("メモ:\n${_data!["memo"]}", style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text("メンバー", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...((_data!["members"] ?? []) as List)
                          .map((m) => Text("・${m["name"]}")),
                      const SizedBox(height: 20),
                      const Text("経費", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...((_data!["expenses"] ?? []) as List).map((e) {
                        return Text("・${e["category"]} / ${e["type"]} / ${e["amount"]} 円");
                      }),
                    ],
                  ),
                ),
    );
  }
}
