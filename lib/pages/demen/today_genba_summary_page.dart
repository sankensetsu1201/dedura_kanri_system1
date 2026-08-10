import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodayGenbaSummaryPage extends StatelessWidget {
  const TodayGenbaSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text("今日の現場別集計")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('demen_data')
            .where('date', isEqualTo: todayStr)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final Map<String, double> genbaSum = {};

          for (var d in docs) {
            final genbaId = d['genbaId'];
            final overtime = d['overtime'] ?? 0.0;
            genbaSum[genbaId] = (genbaSum[genbaId] ?? 0) + overtime;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: genbaSum.entries.map((e) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('genba_master')
                    .doc(e.key)
                    .get(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox();

                  final name = snap.data!['name'];

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.location_city, size: 32),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("残業合計: ${e.value} 時間"),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
