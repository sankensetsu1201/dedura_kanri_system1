// lib/pages/demen/demen_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DemenListPage extends StatefulWidget {
  const DemenListPage({super.key});

  @override
  State<DemenListPage> createState() => _DemenListPageState();
}

class _DemenListPageState extends State<DemenListPage> {
  String searchKeyword = "";
  String? selectedDate;
  String? _currentUid;
  bool _isAdmin = false;
  bool _loading = true;

  List<QueryDocumentSnapshot> _docs = [];
  bool _loadingDocs = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      _currentUid = user?.uid;

      if (_currentUid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUid)
            .get();

        if (userDoc.exists) {
          final u = userDoc.data()!;
          _isAdmin = (u['role'] == 'admin'); // ⭐ 正しい管理者判定
        }
      }
    } catch (e) {
      debugPrint("init error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    _loadDemenDocs();
  }

  Future<void> _loadDemenDocs() async {
    setState(() {
      _loadingDocs = true;
      _loadError = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('demen_data')
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      _docs = snap.docs;
    } catch (e) {
      debugPrint('loadDemenDocs error: $e');
      _loadError = e.toString();
      _docs = [];
    } finally {
      if (mounted) setState(() => _loadingDocs = false);
    }
  }

  bool _matchesFilters(Map<String, dynamic> data) {
    // ⭐ 一般ユーザーは自分の出面だけ
    if (!_isAdmin) {
      if (data['createdBy']?.toString() != _currentUid) return false;
    }

    // ⭐ 日付フィルタ（date または createdAt）
    if (selectedDate != null && selectedDate!.isNotEmpty) {
      final docDate = data['date']?.toString();

      if (docDate != null) {
        if (docDate != selectedDate) return false;
      } else if (data['createdAt'] is Timestamp) {
        final dt = (data['createdAt'] as Timestamp).toDate();
        final dtStr =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
        if (dtStr != selectedDate) return false;
      }
    }

    // ⭐ 作業員ID検索
    if (searchKeyword.isNotEmpty) {
      final q = searchKeyword.toLowerCase();
      final workerId = data['workerId']?.toString().toLowerCase() ?? "";
      if (!workerId.contains(q)) return false;
    }

    return true;
  }

  bool _canEdit(Map<String, dynamic> data) {
    if (_isAdmin) return true;
    return data['createdBy']?.toString() == _currentUid;
  }

  Future<void> _delete(String docId, Map<String, dynamic> data) async {
    if (!_canEdit(data)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("削除権限がありません")));
      return;
    }

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

    if (ok == true) {
      await FirebaseFirestore.instance.collection('demen_data').doc(docId).delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("削除しました")));
      _loadDemenDocs();
    }
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("出面一覧")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      sectionTitle("検索"),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "作業員ID検索（例：worker_001）",
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
                  child: _loadingDocs
                      ? const Center(child: CircularProgressIndicator())
                      : (_loadError != null)
                          ? Center(child: Text('読み込みに失敗しました: $_loadError'))
                          : Builder(
                              builder: (context) {
                                final filtered = _docs.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return _matchesFilters(data);
                                }).toList();

                                if (filtered.isEmpty) {
                                  return const Center(child: Text("該当する出面がありません"));
                                }

                                return ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) {
                                    final doc = filtered[i];
                                    final data = doc.data() as Map<String, dynamic>;

                                    final workerId = data['workerId'] ?? '';
                                    final canEdit = _canEdit(data);

                                    return Opacity(
                                      opacity: canEdit ? 1.0 : 0.6,
                                      child: Card(
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8)),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(12),
                                          title: Text("作業員ID: $workerId",
                                              style: const TextStyle(fontSize: 15)),
                                          subtitle: Text(
                                              "日付: ${data['date']}\n作業: ${data['work']}"),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!canEdit)
                                                Chip(
                                                  label: const Text("編集不可",
                                                      style: TextStyle(color: Colors.white)),
                                                  backgroundColor: Colors.grey.shade500,
                                                ),
                                              if (canEdit)
                                                IconButton(
                                                  icon: const Icon(Icons.edit),
                                                  onPressed: () => Navigator.pushNamed(
                                                      context, '/demen_edit',
                                                      arguments: doc.id),
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.delete),
                                                onPressed:
                                                    canEdit ? () => _delete(doc.id, data) : null,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.arrow_forward_ios),
                                                onPressed: () => Navigator.pushNamed(
                                                    context, '/demen_detail',
                                                    arguments: doc.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
