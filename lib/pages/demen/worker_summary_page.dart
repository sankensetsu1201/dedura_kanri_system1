import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerSummaryPage extends StatelessWidget {
  const WorkerSummaryPage({super.key});

  Future<String> _getWorkerName(String workerId) async {
    final doc = await FirebaseFirestore.instance
        .collection('worker_master')
        .doc(workerId)
        .get();
    return doc.exists ? doc['name'] : "不明な作業員";
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayString =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text("今日の作業員別集計")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('worker_master')
              .orderBy('name')
              .snapshots(),
          builder: (context, workerSnapshot) {
            if (!workerSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final workerDocs = workerSnapshot.data!.docs;

            return ListView(
              children: workerDocs.map((worker) {
                final workerId = worker.id;
                final workerName = worker['name'];

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('demen_data')
                      .where('workerId', isEqualTo: workerId)
                      .where('date', isEqualTo: todayString)
                      .get(),
                  builder: (context, demenSnapshot) {
                    if (!demenSnapshot.hasData) {
                      return const SizedBox();
                    }

                    final docs = demenSnapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const SizedBox();
                    }

                    int count = docs.length;
                    double overtime = 0;

                    for (var doc in docs) {
                      overtime += (doc['overtime'] ?? 0).toDouble();
                    }

                    // ★ Material 3 のカードデザイン
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "👷 $workerName",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "出面数：$count 件",
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              "総残業：$overtime 時間",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
