// lib/pages/admin/demen_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DemenDetailPage extends StatefulWidget {
  final String docId;
  const DemenDetailPage({super.key, required this.docId});

  @override
  State<DemenDetailPage> createState() => _DemenDetailPageState();
}

class _DemenDetailPageState extends State<DemenDetailPage> {
  bool _loading = true;
  Map<String, dynamic>? _data;

  String? _workerName;
  String? _currentUid;
  bool _isAdmin = false;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (_currentUid != null) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();

      if (userDoc.exists) {
        final u = userDoc.data()!;
        _isAdmin = (u['role'] == 'admin'); // ⭐ 正しい管理者判定
      }
    }

    await _loadDoc();
  }

  Future<void> _loadDoc() async {
    setState(() => _loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('demen_data')
          .doc(widget.docId)
          .get();

      if (!doc.exists) {
        setState(() {
          _data = null;
          _canEdit = false;
          _loading = false;
        });
        return;
      }

      final d = doc.data()!;
      _data = d;

      // 作業員名の取得
      final wid = d['workerId']?.toString();
      if (wid != null && wid.isNotEmpty) {
        final wdoc = await FirebaseFirestore.instance
            .collection('worker_master')
            .doc(wid)
            .get();

        if (wdoc.exists) {
          final wdata = wdoc.data()!;
          _workerName = wdata['displayName']?.toString() ?? wid; // ⭐ 正しいフィールド名
        } else {
          _workerName = d['name']?.toString() ?? wid;
        }
      }

      // 編集権限：管理者 or 作成者本人
      final createdBy = d['createdBy']?.toString();
      _canEdit = _isAdmin || (createdBy != null && createdBy == _currentUid);
    } catch (e) {
      debugPrint('load detail error: $e');
      _data = null;
      _canEdit = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteDoc() async {
    if (!_canEdit) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('削除権限がありません')));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この出面を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('削除')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('demen_data')
          .doc(widget.docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('削除しました')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('削除に失敗しました')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('出面詳細'),
        actions: [
          if (!_loading && _canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.pushNamed(
                context,
                '/admin/demen_edit', // ⭐ 管理者用ルートに修正
                arguments: widget.docId,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _loading ? null : _deleteDoc,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('データが見つかりません'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      Text(
                        '作業員: ${_workerName ?? (_data!['name'] ?? _data!['workerId'] ?? '')}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // 日付
                      Text(
                        '日付: ${_data!['date'] ?? (_data!['createdAt'] is Timestamp ? (_data!['createdAt'] as Timestamp).toDate().toString() : '')}',
                      ),
                      const SizedBox(height: 8),

                      // 作業内容
                      Text('作業: ${_data!['work'] ?? ''}'),
                      const SizedBox(height: 8),

                      // 時間
                      Text('時間: ${_data!['hours'] ?? _data!['overtime'] ?? 0} h'),
                      const SizedBox(height: 8),

                      // ⭐ 経費（複数項目対応）
                      if (_data!['expenses'] is List)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('経費（項目別）',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            for (final item in (_data!['expenses'] as List))
                              Text(
                                '・${item["category"] ?? ""} / ${item["type"] ?? ""}: ${item["amount"] ?? 0}円',
                              ),
                          ],
                        )
                      else
                        Text('経費: ${_data!['expense'] ?? 0} 円'),

                      const SizedBox(height: 20),

                      const Text('メモ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_data!['memo']?.toString() ?? ''),

                      const SizedBox(height: 20),

                      if (_canEdit)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('編集'),
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/admin/demen_edit',
                            arguments: widget.docId,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
