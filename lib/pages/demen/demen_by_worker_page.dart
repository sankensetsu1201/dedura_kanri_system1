import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemenByWorkerPage extends StatelessWidget {
  final String workerId;

  const DemenByWorkerPage({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("作業員別 出面一覧")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("demen_data")
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('読み込みに失敗しました'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          final filtered = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final members = data['members'];
            if (members is List) {
              for (final m in members) {
                if (m is Map && m['workerId']?.toString() == workerId) return true;
                if (m is String && m == workerId) return true;
              }
            }
            return false;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("この作業員の出面はありません"));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final data = filtered[index].data() as Map<String, dynamic>;

              final genbaId = data['genbaId']?.toString() ?? '';
              final date = data['date']?.toString() ?? '';
              final overtime = data['overtime']?.toString() ?? '0';
              final dayCount = data['dayCount']?.toString() ?? data['dayType']?.toString() ?? '1';

              final members = data['members'];
              String memberNames = '';
              if (members is List) {
                memberNames = members.map((m) {
                  if (m is Map) return (m['displayName'] ?? m['name'] ?? m['workerId'] ?? '').toString();
                  return m.toString();
                }).where((s) => s.isNotEmpty).join(', ');
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text('現場: $genbaId'),
                  subtitle: Text('日付: $date\nメンバー: $memberNames\n出面: $dayCount 日\n残業: $overtime 時間'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
