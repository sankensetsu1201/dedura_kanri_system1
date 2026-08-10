import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Excel Base64 を使う場合に必要

class AdminImportPage extends StatefulWidget {
  const AdminImportPage({super.key});

  @override
  State<AdminImportPage> createState() => _AdminImportPageState();
}

class _AdminImportPageState extends State<AdminImportPage> {
  Map<String, dynamic>? _selectedData;
  String? _selectedDocId;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _loadExportData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection("export")
          .orderBy("createdAt", descending: true)
          .get();

      if (snap.docs.isEmpty) {
        setState(() {
          _selectedData = null;
          _selectedDocId = null;
          _errorMessage = "export コレクションにデータがありません。";
        });
        return;
      }

      final doc = snap.docs.first;
      _selectedDocId = doc.id;
      _selectedData = doc.data();
    } catch (e) {
      setState(() {
        _errorMessage = "読み込みエラー: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _importCsv() async {
    final csv = _selectedData?["csv"];
    if (csv == null) {
      setState(() {
        _errorMessage = "CSV データが存在しません。";
      });
      return;
    }

    final lines = csv.split("\n");
    if (lines.isEmpty) {
      setState(() {
        _errorMessage = "CSV が空です。";
      });
      return;
    }

    // 1行目はヘッダー
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = line.split(",");
      if (cols.length < 8) continue;

      final date = cols[0];
      final genba = cols[1];
      final workers = cols[2];
      final dayCount = cols[3];
      final overtime = cols[4];
      final work = cols[5];
      final memo = cols[6];
      final expensesTotal = cols[7];

      await FirebaseFirestore.instance.collection("demen").add({
        "date": date,
        "genba": genba,
        "workers": workers,
        "dayCount": dayCount,
        "overtime": overtime,
        "work": work,
        "memo": memo,
        "expenses_total": expensesTotal,
        "createdAt": DateTime.now().toIso8601String(),
      });
    }

    setState(() {
      _errorMessage = "CSV インポート完了！";
    });
  }

  Future<void> _importExcel() async {
    final excelBase64 = _selectedData?["excel_base64"];
    if (excelBase64 == null) {
      setState(() {
        _errorMessage = "Excel データが存在しません。";
      });
      return;
    }

    final bytes = base64Decode(excelBase64);

    // Excel の解析処理はまだ未実装なので、ここで bytes を使って処理を書く
    // 必要ならここに Excel パーサーを追加する

    setState(() {
      _errorMessage = "Excel インポート（仮処理）完了！";
    });
  }

  @override
  void initState() {
    super.initState();
    _loadExportData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("データインポート")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 16),

                  if (_selectedData == null)
                    const Text("インポート可能なデータがありません。")
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("最新の export ドキュメント: $_selectedDocId"),
                        const SizedBox(height: 8),
                        Text("createdAt: ${_selectedData?["createdAt"] ?? "不明"}"),
                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: _importCsv,
                          child: const Text("CSV をインポート"),
                        ),
                        const SizedBox(height: 8),

                        ElevatedButton(
                          onPressed: _importExcel,
                          child: const Text("Excel をインポート"),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
