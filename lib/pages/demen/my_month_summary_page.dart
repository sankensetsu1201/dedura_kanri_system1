import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyMonthSummaryPage extends StatefulWidget {
  final String workerId; // ← この workerId を members[] の中から探す

  const MyMonthSummaryPage({super.key, required this.workerId});

  @override
  State<MyMonthSummaryPage> createState() => _MyMonthSummaryPageState();
}

class _MyMonthSummaryPageState extends State<MyMonthSummaryPage> {
  String _selectedMonth = "2026-07"; // 初期値は適当に設定

  // 月リスト（2024〜2026）
  List<String> _monthList() {
    return List.generate(36, (i) {
      final year = 2024 + ((i) ~/ 12);
      final month = (i % 12) + 1;
      return "$year-${month.toString().padLeft(2, '0')}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("自分の月次集計")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 月選択
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "月を選択",
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedMonth,
              items: _monthList().map((m) {
                return DropdownMenuItem(value: m, child: Text(m));
              }).toList(),
              onChanged: (v) => setState(() => _selectedMonth = v!),
            ),

            const SizedBox(height: 20),

            // 集計表示
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('demen_data')
                    .where('date', isGreaterThanOrEqualTo: "$_selectedMonth-01")
                    .where('date', isLessThanOrEqualTo: "$_selectedMonth-31")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  double totalOvertime = 0;

                  // Firestore の members[] の中から workerId を探す
                  for (var d in docs) {
                    final data = d.data() as Map<String, dynamic>;

                    final members = data['members'];
                    if (members is List) {
                      for (final m in members) {
                        if (m is Map && m['workerId'] == widget.workerId) {
                          totalOvertime += (data['overtime'] ?? 0).toDouble();
                        }
                      }
                    }
                  }

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month, size: 32),
                      title: const Text(
                        "合計残業時間",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("$totalOvertime 時間"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
