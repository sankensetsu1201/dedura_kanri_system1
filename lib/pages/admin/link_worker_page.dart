import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LinkWorkerPage extends StatelessWidget {
  const LinkWorkerPage({super.key});

  Future<void> _linkWorker() async {
    final uid = '7pUmdblzvKfdoYZmUSDfhiRUsns1';
    final existingWorkerId = 'yamada001'; // 実際の workers ドキュメントIDに置き換え

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'workerId': existingWorkerId}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理: ユーザー紐付け')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await _linkWorker();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('workerId を更新しました')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('更新に失敗しました: $e')),
              );
            }
          },
          child: const Text('紐づけを実行'),
        ),
      ),
    );
  }
}
