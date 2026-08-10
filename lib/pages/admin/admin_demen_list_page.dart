// lib/pages/admin/admin_demen_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDemenListPage extends StatefulWidget {
  const AdminDemenListPage({super.key});

  @override
  State<AdminDemenListPage> createState() => _AdminDemenListPageState();
}

class _AdminDemenListPageState extends State<AdminDemenListPage> {
  bool _loading = true;
  String? _error;

  List<QueryDocumentSnapshot> _docs = [];

  Map<String, String> _workerMap = {}; // workerId -> displayName
  Map<String, String> _genbaMap = {};  // genbaId -> name

  String searchKeyword = "";
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadMasters();
    _loadDemenDocs();
  }

  Future<void> _loadMasters() async {
    try {
      // 作業員マスター
      final workerSnap =
          await FirebaseFirestore.instance.collection("worker_master").get();
      _workerMap = {
        for (var d in workerSnap.docs)
          d.id: (d.data()["displayName"]?.toString() ?? d.id)
      };

      // 現場マスター
      final genbaSnap =
          await FirebaseFirestore.instance.collection("genba_master").get();
      _genbaMap = {
        for (var d in genbaSnap.docs)
          d.id: (d.data()["name"]?.toString() ?? d.id)
      };
    } catch (e) {
      debugPrint("load masters error: $e");
      _error = e.toString();
    }
  }

  Future<void> _loadDemenDocs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection("demen_data")
          .orderBy("date", descending: true)
          .get();

      _docs = snap.docs;
    } catch (e) {
      debugPrint("load demen docs error: $e");
      _error = e.toString();
      _docs = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    // 日付フィルタ
    if (selectedDate != null && selectedDate!.isNotEmpty) {
      final docDate = data["date"]?.toString();
      if (docDate != selectedDate) return false;
    }

    // キーワード検索
    if (searchKeyword.isNotEmpty) {
      final q = searchKeyword.toLowerCase();

      final members = (data["members"] ?? []) as List;
      final workerNames = members
          .map((m) => m["name"]?.toString().toLowerCase() ?? "")
          .join(" ");

      final workerIds = members
          .map((m) => m["workerId"]?.toString().toLowerCase() ?? "")
          .join(" ");

      final genbaName =
          (data["genbaName"]?.toString().toLowerCase() ?? "");

      final work = (data["work"]?.toString().toLowerCase() ?? "");

      if (!workerNames.contains(q) &&
          !workerIds.contains(q) &&
          !genbaName.contains(q) &&
          !work.contains(q)) {
        return false;
      }
    }

    return true;
  }

  Future<void> _delete(String docId) async {
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
      await FirebaseFirestore.instance.collection("demen_data").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("削除しました")),
      );
      _loadDemenDocs();
    } catch (e) {
      debugPrint("delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("削除に失敗しました")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("出面一覧（管理者用）")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("読み込みエラー: $_error"))
              : Column(
                  children: [
                    // 検索 UI
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              labelText: "検索（作業員名 / ID / 現場名 / 作業内容）",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (v) => setState(() => searchKeyword = v.trim()),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: "日付で絞り込み（例：2026-07-27）",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            onChanged: (v) => setState(() => selectedDate = v.trim()),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    Expanded(
                      child: ListView.builder(
                        itemCount: _docs.length,
                        itemBuilder: (context, i) {
                          final doc = _docs[i];
                          final data = doc.data() as Map<String, dynamic>;

                          if (!_matchesFilters(data)) return const SizedBox();

                          final members = (data["members"] ?? []) as List;
                          final memberNames =
                              members.map((m) => m["name"] ?? "").join(", ");

                          final genbaId = data["genbaId"]?.toString() ?? "";
                          final genbaName =
                              data["genbaName"]?.toString() ??
                              _genbaMap[genbaId] ??
                              genbaId;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text("作業員: $memberNames"),
                              subtitle: Text(
                                  "日付: ${data["date"]}\n現場: $genbaName\n作業: ${data["work"]}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ⭐ 一般ユーザー用の編集ページへ
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      "/demen_edit",
                                      arguments: doc.id,
                                    ),
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _delete(doc.id),
                                  ),

                                  // ⭐ 一般ユーザー用の詳細ページへ
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      "/demen_detail",
                                      arguments: doc.id,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
