import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemenByGenbaPage extends StatelessWidget {
  final String genbaId;

  const DemenByGenbaPage({super.key, required this.genbaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("現場別 出面一覧")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("demen_data")
            .where("genbaId", isEqualTo: genbaId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('読み込みに失敗しました'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("この現場の出面はありません"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final members = data['members'];
              String memberNames = '';
              if (members is List) {
                memberNames = members.map((m) {
                  if (m is Map) return (m['displayName'] ?? m['name'] ?? m['workerId'] ?? '').toString();
                  return m.toString();
                }).where((s) => s.isNotEmpty).join(', ');
              }

              final date = data['date']?.toString() ?? '';
              final overtime = data['overtime']?.toString() ?? '0';
              final dayCount = data['dayCount']?.toString() ?? data['dayType']?.toString() ?? '1';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(memberNames.isNotEmpty ? 'メンバー: $memberNames' : 'メンバー情報なし'),
                  subtitle: Text('日付: $date\n出面: $dayCount 日\n残業: $overtime 時間'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
