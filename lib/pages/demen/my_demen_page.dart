import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'demen_edit_page.dart';

class MyDemenPage extends StatelessWidget {
  const MyDemenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection("demen_data")
        .orderBy("date", descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("自分の出面")),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("出面データがありません"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final demen = docs[index];
              final data = demen.data() as Map<String, dynamic>;

              final date = data["date"] ?? "";
              final genbaName = data["genbaName"] ?? "不明";
              final workerName = data["workerName"] ?? "不明";
              final overtime = data["overtime"] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),

                  title: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    "$genbaName / $workerName\n残業: $overtime 時間",
                    style: const TextStyle(height: 1.6),
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () {
                   Navigator.push(
                  context,
                   MaterialPageRoute(
                  builder: (_) => DemenEditPage(
                  docId: demen.id,
      ),
    ),
  );
},

                ),
              );
            },
          );
        },
      ),
    );
  }
}
