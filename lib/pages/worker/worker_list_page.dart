// lib/pages/worker/worker_list_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerListPage extends StatefulWidget {
  const WorkerListPage({Key? key}) : super(key: key);

  @override
  State<WorkerListPage> createState() => _WorkerListPageState();
}

class _WorkerListPageState extends State<WorkerListPage> {
  Map<String, String> _workers = {};
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    loadWorkers();
  }

  Future<void> loadWorkers() async {
    debugPrint('loadWorkers start uid=${FirebaseAuth.instance.currentUser?.uid}');
    setState(() => _loading = true);

    try {
      // ★ Firestore のコレクション名を正しく修正（workers）
      final coll = FirebaseFirestore.instance.collection('workers');

      final snap = await coll.get().timeout(const Duration(seconds: 15));
      debugPrint('loadWorkers raw docs=${snap.docs.length}');

      final map = <String, String>{};

      for (final d in snap.docs) {
        final data = d.data();
        debugPrint('worker doc id=${d.id} data=$data');

        // 名前フィールドの優先順位
        final name = (data['displayName'] ??
                data['display_name'] ??
                data['name'] ??
                data['workerName'] ??
                data['worker_name'] ??
                data['workerId'] ??
                data['workerid'] ??
                '')
            .toString();

        map[d.id] = name.isNotEmpty ? name : d.id;
      }

      if (mounted) setState(() => _workers = map);

      debugPrint('loadWorkers success count=${map.length}');
    } on FirebaseException catch (e, st) {
      debugPrint('loadWorkers FirebaseException: ${e.code} ${e.message}');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('作業員の読み込みに失敗しました: ${e.code}')),
        );
      }
    } on TimeoutException catch (e, st) {
      debugPrint('loadWorkers Timeout: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('作業員の読み込みがタイムアウトしました')),
        );
      }
    } catch (e, st) {
      debugPrint('loadWorkers unknown error: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('作業員の読み込みに失敗しました')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MapEntry<String, String>> get _filteredWorkers {
    if (_query.trim().isEmpty) return _workers.entries.toList();

    final q = _query.toLowerCase();

    return _workers.entries.where((e) {
      final name = e.value.toLowerCase();
      final id = e.key.toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作業員一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : loadWorkers,
            tooltip: '再読み込み',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '名前・作業員ID検索',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 作業員追加ページへ遷移する場合はここで Navigator.pushNamed 等を呼ぶ
        },
        child: const Icon(Icons.add),
        tooltip: '作業員を追加',
      ),
    );
  }

  Widget _buildListView() {
    final list = _filteredWorkers;

    if (list.isEmpty) {
      return const Center(child: Text('該当する作業員がいません'));
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final e = list[index];

        return ListTile(
          title: Text(e.value),
          subtitle: Text(e.key),
          onTap: () {
            // 詳細ページへ遷移するならここ
          },
        );
      },
    );
  }
}
