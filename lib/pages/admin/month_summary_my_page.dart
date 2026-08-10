import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MonthSummaryMyPage extends StatefulWidget {
  const MonthSummaryMyPage({super.key});

  @override
  State<MonthSummaryMyPage> createState() => _MonthSummaryMyPageState();
}

class _MonthSummaryMyPageState extends State<MonthSummaryMyPage> {
  String? myWorkerId;

  bool _loading = true;

  double totalDays = 0;
  double totalOvertime = 0;
  int totalExpense = 0;

  Map<String, double> genbaDays = {};
  Map<String, List<Map<String, dynamic>>> genbaExpenses = {};

  @override
  void initState() {
    super.initState();
    _loadMyWorkerId();
  }

  Future<void> _loadMyWorkerId() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    setState(() => myWorkerId = null);
    return;
  }

  final uid = user.uid;

  final userDoc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();

  myWorkerId = userDoc.data()?["workerId"]?.toString();
  setState(() {});

  if (myWorkerId != null) {
    _loadSummary();
  }
}


  Future<void> _loadSummary() async {
    setState(() => _loading = true);

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);

      final snap = await FirebaseFirestore.instance
          .collection("demen_data")
          .where("workerId", isEqualTo: myWorkerId)
          .where("createdAt", isGreaterThanOrEqualTo: start)
          .where("createdAt", isLessThan: end)
          .get();

      double days = 0;
      double overtime = 0;
      int expense = 0;

      Map<String, double> daysByGenba = {};
      Map<String, List<Map<String, dynamic>>> expensesByGenba = {};

      for (final doc in snap.docs) {
        final data = doc.data();

        // 出面日数
        final dayCount = (data["dayCount"] ?? 1).toDouble();
        days += dayCount;

        // 残業
        overtime += (data["overtime"] ?? 0).toDouble();

        // 現場名
        final genba = data["genbaName"] ?? "不明";

        // 現場別日数
        daysByGenba[genba] = (daysByGenba[genba] ?? 0) + dayCount;

        // 経費
        final expenseList = (data["expenses"] ?? []) as List;
for (final item in expenseList) {
  final amount = ((item["amount"] ?? 0) as num).toInt();  // ← 修正
  expense += amount;

  expensesByGenba.putIfAbsent(genba, () => []);
  expensesByGenba[genba]!.add({
    "category": item["category"] ?? "",
    "type": item["type"] ?? "",
    "amount": amount,
  });
}

      }

      setState(() {
        totalDays = days;
        totalOvertime = overtime;
        totalExpense = expense;
        genbaDays = daysByGenba;
        genbaExpenses = expensesByGenba;
        _loading = false;
      });
    } catch (e) {
      debugPrint("summary error: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (myWorkerId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final title = "${now.year}年${now.month.toString().padLeft(2, '0')}月 の出面集計";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text("今月の出面", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("今月の出面: ${totalDays.toStringAsFixed(1)}日"),
                Text("今月の残業時間合計: ${totalOvertime.toStringAsFixed(1)}h"),
                Text("今月の経費合計: ${totalExpense}円"),
                const SizedBox(height: 20),

                Text("現場別出面日数", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final entry in genbaDays.entries)
                  Text("${entry.key}: ${entry.value.toStringAsFixed(1)}日"),
                const SizedBox(height: 20),

                Text("現場別経費（区分・項目別）", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                for (final entry in genbaExpenses.entries) ...[
                  Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),

                  for (final item in entry.value)
                    Text("・${item["category"]} / ${item["type"]}: ${item["amount"]}円"),

                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}
