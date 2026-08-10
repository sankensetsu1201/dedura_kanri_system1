// lib/pages/genba/genba_summary_month.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class GenbaSummaryMonthPage extends StatefulWidget {
  const GenbaSummaryMonthPage({super.key});

  @override
  State<GenbaSummaryMonthPage> createState() => _GenbaSummaryMonthPageState();
}

class _GenbaSummaryMonthPageState extends State<GenbaSummaryMonthPage> {
  String? selectedGenbaId;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  bool _loading = false;

  double totalDemen = 0;
  double totalOvertime = 0;
  double totalExpense = 0;

  List<Map<String, dynamic>> detailList = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (selectedGenbaId == null) return;

    setState(() => _loading = true);

    final start = DateTime(selectedYear, selectedMonth, 1);
    final end = DateTime(selectedYear, selectedMonth + 1, 0);

    final snap = await FirebaseFirestore.instance
        .collection("demen_data")
        .where("genbaId", isEqualTo: selectedGenbaId)
        .get();

    double demen = 0;
    double overtime = 0;
    double expense = 0;

    final details = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      final data = doc.data();

      DateTime? date;
      if (data["date"] is Timestamp) {
        date = (data["date"] as Timestamp).toDate();
      } else if (data["date"] is String) {
        date = DateTime.tryParse(data["date"]);
      }

      if (date == null) continue;

      if (date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)))) {
        demen += (data["dayCount"] ?? 1).toDouble();
        overtime += (data["overtime"] ?? 0).toDouble();
        expense += (data["expense"] ?? 0).toDouble();

        details.add({
          "date": DateFormat("yyyy-MM-dd").format(date),
          "work": data["work"] ?? "",
          "overtime": data["overtime"] ?? 0,
          "expense": data["expense"] ?? 0,
        });
      }
    }

    setState(() {
      totalDemen = demen;
      totalOvertime = overtime;
      totalExpense = expense;
      detailList = details;
      _loading = false;
    });
  }

  // ★ 改善した月選択UI
  Widget _monthSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DropdownButton<int>(
              value: selectedYear,
              items: List.generate(5, (i) {
                final y = DateTime.now().year - i;
                return DropdownMenuItem(value: y, child: Text("$y年"));
              }),
              onChanged: (v) {
                setState(() => selectedYear = v!);
                _loadSummary();
              },
            ),
            const SizedBox(width: 20),
            DropdownButton<int>(
              value: selectedMonth,
              items: List.generate(12, (i) {
                final m = i + 1;
                return DropdownMenuItem(value: m, child: Text("$m月"));
              }),
              onChanged: (v) {
                setState(() => selectedMonth = v!);
                _loadSummary();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("月次現場別集計")),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ★ 月選択
          _monthSelector(),

          const SizedBox(height: 12),

          // ★ 集計結果
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("合計出面数：$totalDemen"),
                  Text("合計残業：$totalOvertime 時間"),
                  Text("合計経費：$totalExpense 円"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text("詳細一覧", style: TextStyle(fontSize: 18)),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: detailList.length,
                    itemBuilder: (context, i) {
                      final d = detailList[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(d["date"]),
                          subtitle: Text(
                            "作業: ${d["work"]}\n残業: ${d["overtime"]} 時間\n経費: ${d["expense"]} 円",
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
