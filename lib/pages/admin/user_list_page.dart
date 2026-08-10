import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String searchKeyword = "";

  // worker_master cache
  List<QueryDocumentSnapshot> _workers = [];
  bool _loadingWorkers = true;
  String? _workerLoadError;

  @override
  void initState() {
    super.initState();
    _loadWorkersAsync();
  }

  Future<void> _loadWorkersAsync() async {
    setState(() {
      _loadingWorkers = true;
      _workerLoadError = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('worker_master')
          .orderBy('displayName')
          .get()
          .timeout(const Duration(seconds: 10));

      _workers = snap.docs;
    } catch (e) {
      debugPrint('load workers error: $e');
      _workerLoadError = e.toString();
      _workers = [];
    } finally {
      if (mounted) setState(() => _loadingWorkers = false);
    }
  }

  /// ⭐ workerId から users の role を取得する
  Future<String> _getRole(String workerId) async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .where("workerId", isEqualTo: workerId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return "一般";

    final role = snap.docs.first.data()["role"];
    return role == "admin" ? "管理者" : "一般";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("作業員一覧（管理者）")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "名前・作業員ID検索",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                setState(() {
                  searchKeyword = v.trim();
                });
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: _loadingWorkers
                ? const Center(child: CircularProgressIndicator())
                : (_workerLoadError != null)
                    ? Center(child: Text('読み込みエラー: $_workerLoadError'))
                    : Builder(builder: (context) {
                        final docs = _workers;

                        final filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data["displayName"] ?? "").toString();
                          final workerId = doc.id;

                          if (searchKeyword.isNotEmpty) {
                            final q = searchKeyword.toLowerCase();
                            if (!name.toLowerCase().contains(q) &&
                                !workerId.toLowerCase().contains(q)) {
                              return false;
                            }
                          }

                          return true;
                        }).toList();

                        if (filteredDocs.isEmpty) {
                          return const Center(child: Text("該当する作業員がいません"));
                        }

                        return ListView.builder(
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, i) {
                            final doc = filteredDocs[i];
                            final data = doc.data() as Map<String, dynamic>;

                            final workerId = doc.id;
                            final name = (data['displayName'] ?? '').toString();
                            final team = (data['team'] ?? '').toString();

                            return FutureBuilder<String>(
                              future: _getRole(workerId),
                              builder: (context, snapshot) {
                                final role = snapshot.data ?? "一般";

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text("$name（$workerId）"),
                                    subtitle: Text("班: $team / 権限: $role"),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        "/admin/user_detail",
                                        arguments: workerId,
                                      );
                                    },
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              "/user_edit",
                                              arguments: {
                                                'uid': workerId,
                                                'initialData': data,
                                              },
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text("削除の確認"),
                                                content: Text(
                                                    "$name（$workerId）を削除しますか？"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(false),
                                                    child:
                                                        const Text("キャンセル"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(true),
                                                    child: const Text("削除"),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await FirebaseFirestore.instance
                                                  .collection("worker_master")
                                                  .doc(workerId)
                                                  .delete();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }),
          ),
        ],
      ),
    );
  }
}
