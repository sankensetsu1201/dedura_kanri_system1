import 'package:flutter/material.dart';

class AdminExcelViewerPage extends StatefulWidget {
  final String? exportId; // ← 必須ではない（推奨）
  const AdminExcelViewerPage({this.exportId, super.key});

  @override
  State<AdminExcelViewerPage> createState() => _AdminExcelViewerPageState();
}

class _AdminExcelViewerPageState extends State<AdminExcelViewerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Excelビューア"),
      ),
      body: const Center(
        child: Text("ここにExcelビューアの内容を表示します"),
      ),
    );
  }
}
