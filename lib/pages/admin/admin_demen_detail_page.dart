// lib/pages/admin/admin_demen_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDemenDetailPage extends StatefulWidget {
  final String docId;
  const AdminDemenDetailPage({super.key, required this.docId});

  @override
  State<AdminDemenDetailPage> createState() => _AdminDemenDetailPageState();
}

class _AdminDemenDetailPageState extends State<AdminDemenDetailPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  Map<String, String> _workerMap = {}; // workerId -> displayName
  Map<String, String> _genbaMap = {};  // genbaId -> name

  @override
  void initState() {
    super.initState();
    _loadMasters();
    _loadDetail();
  }

  Future<void> _loadMasters() async {
    try {
      final workerSnap =
          await FirebaseFirestore.instance.collection("worker_master").get();
      _workerMap = {
        for (var d in workerSnap.docs)
          d.id: (d.data()["displayName"]?.toString() ?? d.id)
      };

      final genbaSnap =
          await FirebaseFirestore.instance.collection("genba_master").get();
      _genbaMap = {
        for (var d in genbaSnap.docs)
          d.id: (d.data()["name"]?.toString() ?? d.id)
      };
    } catch (e) {
      debugPrint("load masters error: $e");
    }
  }

  Future<void> _loadDetail() async {
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

      _data = doc.data()!;
    } catch (e) {
      debugPrint("load detail error: $e");
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("削除確認"),
        content: const Text("この出面を削除しますか？"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("キャンセル")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("削除")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection("demen_data")
          .doc(widget.docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("削除しました")),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("削除に失敗しました")),
      );
    }
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
        appBar: AppBar(title: const Text("出面詳細（管理者用）")),
        body: Center(child: Text(_error!)),
      );
    }

    final data = _data!;
    final members = (data["members"] ?? []) as List;

    final genbaId = data["genbaId"]?.toString() ?? "";
    final genbaName = _genbaMap[genbaId] ?? genbaId;

    final expenses = (data["expenses"] ?? []) as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text("出面詳細（管理者用）"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              "/admin/demen_edit",
              arguments: widget.docId,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 現場
            Text("現場: $genbaName",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 日付
            Text("日付: ${data["date"]}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),

            // メンバー
            const Text("メンバー",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: members.map((m) {
                final wid = m["workerId"]?.toString() ?? "";
                final name = _workerMap[wid] ?? m["name"] ?? wid;
                return Text("・$name", style: const TextStyle(fontSize: 16));
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 作業内容
            const Text("作業内容",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(data["work"] ?? "", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // 出面区分
            Text("出面区分: ${data["dayCount"]}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),

            // 残業
            Text("残業時間: ${data["overtime"]} 時間",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // 経費
            const Text("経費（項目別）",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (expenses.isEmpty)
              const Text("経費なし")
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: expenses.map((e) {
                  return Text(
                    "・${e["category"]} / ${e["type"]}: ${e["amount"]} 円",
                    style: const TextStyle(fontSize: 16),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // メモ
            const Text("メモ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(data["memo"] ?? "", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),

            // 編集ボタン
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("編集する"),
                onPressed: () => Navigator.pushNamed(
                  context,
                  "/admin/demen_edit",
                  arguments: widget.docId,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
