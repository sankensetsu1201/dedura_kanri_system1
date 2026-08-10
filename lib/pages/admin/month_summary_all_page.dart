import 'dart:typed_data'; // ← CSV出力で必要
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthSummaryAllPage extends StatefulWidget {
  const MonthSummaryAllPage({super.key});

  @override
  State<MonthSummaryAllPage> createState() => _MonthSummaryAllPageState();
}

class _MonthSummaryAllPageState extends State<MonthSummaryAllPage> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  List<Map<String, dynamic>> workers = [];
  List<Map<String, dynamic>> summaryList = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final snap =
        await FirebaseFirestore.instance.collection("worker_master").get();

    workers = snap.docs.map((d) {
      return {
        "id": d.id,
        "name": d.data()["name"] ?? "不明",
      };
    }).toList();

    _loadAllSummary();
  }

  Future<void> _loadAllSummary() async {
    summaryList.clear();

    final start = DateTime(selectedYear, selectedMonth, 1);
    final end = DateTime(selectedYear, selectedMonth + 1, 1);

    for (final w in workers) {
      final workerId = w["id"];

      final snap = await FirebaseFirestore.instance
          .collection("demen_data")
          .where("workerId", isEqualTo: workerId)
          .where("createdAt", isGreaterThanOrEqualTo: start)
          .where("createdAt", isLessThan: end)
          .get();

      double days = 0;
      double overtime = 0;
      int expense = 0;

      for (final doc in snap.docs) {
        final data = doc.data();

        days += (data["dayCount"] ?? 1).toDouble();
        overtime += (data["overtime"] ?? 0).toDouble();

        final expenseList = (data["expenses"] ?? []) as List;
        for (final item in expenseList) {
          expense += ((item["amount"] ?? 0) as num).toInt();
        }
      }

      summaryList.add({
        "name": w["name"],
        "days": days,
        "overtime": overtime,
        "expense": expense,
      });
    }

    setState(() {});
  }

  // ---------------------------------------------------------
  // CSV 出力（Uint8List に修正済み）
  // ---------------------------------------------------------
  void exportCSV() {
    final rows = <List<dynamic>>[];

    rows.add(["全員月次一覧"]);
    rows.add(["対象年月", "$selectedYear年$selectedMonth月"]);
    rows.add([]);
    rows.add(["作業員名", "日数", "残業", "経費"]);

    for (final s in summaryList) {
      rows.add([
        s["name"],
        s["days"],
        s["overtime"],
        s["expense"],
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    // ★ List<int> → Uint8List に変換（エラー修正）
    final bytes = Uint8List.fromList(csv.codeUnits);

    Printing.sharePdf(bytes: bytes, filename: "all_month_summary.csv");
  }

  // ---------------------------------------------------------
  // PDF 出力（TableHelper.fromTextArray に修正済み）
  // ---------------------------------------------------------
  void exportPDF() async {
    final pdf = pw.Document();

    final tableData = <List<String>>[];
    tableData.add(["作業員名", "日数", "残業", "経費"]);

    for (final s in summaryList) {
      tableData.add([
        s["name"],
        s["days"].toStringAsFixed(1),
        s["overtime"].toStringAsFixed(1),
        s["expense"].toString(),
      ]);
    }

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "全員月次一覧（$selectedYear年$selectedMonth月）",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),

            // ★ 非推奨 API 修正済み
            pw.TableHelper.fromTextArray(
              headers: tableData.first,
              data: tableData.sublist(1),
              headerStyle: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(fontSize: 12),
              border: pw.TableBorder.all(width: 1),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("全員月次一覧"),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),

          Row(
            children: [
              ElevatedButton(onPressed: exportCSV, child: const Text("CSV出力")),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: exportPDF, child: const Text("PDF出力")),
            ],
          ),

          Expanded(
            child: ListView(
              children: summaryList.map((s) {
                return ListTile(
                  title: Text(s["name"]),
                  subtitle: Text(
                      "日数：${s["days"]} / 残業：${s["overtime"]} / 経費：${s["expense"]}円"),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Text("年月選択：",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),

          DropdownButton<int>(
            value: selectedYear,
            items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                .map((y) => DropdownMenuItem(
                      value: y,
                      child: Text("$y年"),
                    ))
                .toList(),
            onChanged: (y) {
              setState(() => selectedYear = y!);
              _loadAllSummary();
            },
          ),

          const SizedBox(width: 12),

          DropdownButton<int>(
            value: selectedMonth,
            items: List.generate(12, (i) => i + 1)
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text("$m月"),
                    ))
                .toList(),
            onChanged: (m) {
              setState(() => selectedMonth = m!);
              _loadAllSummary();
            },
          ),
        ],
      ),
    );
  }
}
