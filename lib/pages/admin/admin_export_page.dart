// lib/pages/admin/admin_export_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';

class AdminExportPage extends StatefulWidget {
  const AdminExportPage({super.key});

  @override
  State<AdminExportPage> createState() => _AdminExportPageState();
}

class _AdminExportPageState extends State<AdminExportPage> {
  bool _loading = false;
  String? _message;

  Map<String, String> _workerMap = {};
  Map<String, String> _genbaMap = {};

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  Future<void> _loadMasters() async {
    final workerSnap =
        await FirebaseFirestore.instance.collection("worker_master").get();
    final genbaSnap =
        await FirebaseFirestore.instance.collection("genba_master").get();

    _workerMap = {
      for (var d in workerSnap.docs)
        d.id: (d.data()["displayName"]?.toString() ?? d.id)
    };

    _genbaMap = {
      for (var d in genbaSnap.docs)
        d.id: (d.data()["name"]?.toString() ?? d.id)
    };

    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _fetchAllDemen() async {
    final snap = await FirebaseFirestore.instance
        .collection("demen_data")
        .orderBy("date")
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  // CSV 生成
  String _generateCsv(List<Map<String, dynamic>> list) {
    final buffer = StringBuffer();

    buffer.writeln(
        "date,genba,workers,dayCount,overtime,work,memo,expenses_total");

    for (final d in list) {
      final date = d["date"] ?? "";
      final genba = _genbaMap[d["genbaId"]] ?? d["genbaId"] ?? "";

      final members = (d["members"] ?? [])
          .map((m) => _workerMap[m["workerId"]] ?? m["name"])
          .join(" / ");

      final dayCount = d["dayCount"] ?? 1.0;
      final overtime = d["overtime"] ?? 0.0;
      final work = d["work"] ?? "";
      final memo = d["memo"] ?? "";

      double expTotal = 0;
      for (final e in (d["expenses"] ?? [])) {
        expTotal += (e["amount"] ?? 0).toDouble();
      }

      buffer.writeln(
          "$date,$genba,$members,$dayCount,$overtime,$work,$memo,$expTotal");
    }

    return buffer.toString();
  }

  // Excel 生成
  List<int> _generateExcel(List<Map<String, dynamic>> list) {
    final excel = Excel.createExcel();
    final sheet = excel['出面データ'];

    sheet.appendRow([
      "日付",
      "現場",
      "作業員",
      "出面区分",
      "残業",
      "作業内容",
      "メモ",
      "経費合計"
    ]);

    for (final d in list) {
      final date = d["date"] ?? "";
      final genba = _genbaMap[d["genbaId"]] ?? d["genbaId"] ?? "";

      final members = (d["members"] ?? [])
          .map((m) => _workerMap[m["workerId"]] ?? m["name"])
          .join(" / ");

      final dayCount = d["dayCount"] ?? 1.0;
      final overtime = d["overtime"] ?? 0.0;
      final work = d["work"] ?? "";
      final memo = d["memo"] ?? "";

      double expTotal = 0;
      for (final e in (d["expenses"] ?? [])) {
        expTotal += (e["amount"] ?? 0).toDouble();
      }

      sheet.appendRow([
        date,
        genba,
        members,
        dayCount,
        overtime,
        work,
        memo,
        expTotal
      ]);
    }

    return excel.encode()!;
  }

  Future<void> _exportCsv() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final list = await _fetchAllDemen();
      final csv = _generateCsv(list);

      final timestamp =
          DateFormat("yyyy-MM-dd_HH-mm-ss").format(DateTime.now());

      await FirebaseFirestore.instance
          .collection("export")
          .doc("csv_$timestamp")
          .set({
        "createdAt": timestamp,
        "csv": csv,
      });

      setState(() {
        _message = "CSV を作成しました（ID: csv_$timestamp）";
      });
    } catch (e) {
      debugPrint("CSV export error: $e");
      setState(() => _message = "CSV 出力に失敗しました");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final list = await _fetchAllDemen();
      final bytes = _generateExcel(list);

      final base64Excel = base64Encode(bytes);
      final timestamp =
          DateFormat("yyyy-MM-dd_HH-mm-ss").format(DateTime.now());

      await FirebaseFirestore.instance
          .collection("export")
          .doc("excel_$timestamp")
          .set({
        "createdAt": timestamp,
        "excel_base64": base64Excel,
      });

      setState(() {
        _message = "Excel を作成しました（ID: excel_$timestamp）";
      });
    } catch (e) {
      debugPrint("Excel export error: $e");
      setState(() => _message = "Excel 出力に失敗しました");
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
        onPressed: _loading ? null : onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CSV / Excel 出力（管理者用）")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "出面データを CSV または Excel 形式でエクスポートできます。",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            _buildButton("CSV を作成する", Icons.file_present, _exportCsv),
            const SizedBox(height: 12),

            _buildButton("Excel（.xlsx）を作成する", Icons.table_chart, _exportExcel),
            const SizedBox(height: 20),

            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _message!.contains("失敗") ? Colors.red : Colors.green,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
