import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demen_app/widgets/san_ken_appbar.dart';

class AttendanceListPage extends StatelessWidget {
  const AttendanceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SanKenAppBar(title: "出面一覧"),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("attendance")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("読み込みエラー"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("出面データがありません"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final worker = data["worker"] ?? "";
              final site = data["site"] ?? "";
              final date = data["date"] ?? "";
              final hours = data["hours"] ?? 0;
              final createdAt = data["createdAt"] ?? "";

              return Card(
                child: ListTile(
                  title: Text("$worker / $site"),
                  subtitle: Text("日付：$date\n作業時間：$hours 時間"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
