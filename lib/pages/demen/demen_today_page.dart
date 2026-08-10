import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DemenTodayPage extends StatelessWidget {
  const DemenTodayPage({super.key});

  String _today() {
    final now = DateTime.now();
    return "${now.year}-${_two(now.month)}-${_two(now.day)}";
  }

  static String _two(int n) => n.toString().padLeft(2, "0");

  @override
  Widget build(BuildContext context) {
    final today = _today();

    final stream = FirebaseFirestore.instance
        .collection("demen")
        .where("date", isEqualTo: today)
        .orderBy("createdAt", descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text("今日の出面一覧 ($today)")),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("今日の出面はまだありません"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.list),
                  title: Text("${data['name']}（${data['workerId']}）"),
                  subtitle: Text(
                    "現場: ${data['genbaName']}\n"
                    "作業: ${data['work']} / 時間: ${data['hours']}h",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
