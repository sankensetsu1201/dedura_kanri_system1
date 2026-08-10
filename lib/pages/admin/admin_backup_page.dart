// lib/pages/admin/admin_backup_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminBackupPage extends StatefulWidget {
  const AdminBackupPage({super.key});

  @override
  State<AdminBackupPage> createState() => _AdminBackupPageState();
}

class _AdminBackupPageState extends State<AdminBackupPage> {
  bool _loading = false;
  String? _error;
  String? _resultMessage;

  Future<Map<String, dynamic>> _exportCollection(String name) async {
    final snap = await FirebaseFirestore.instance.collection(name).get();
    return {
      "collection": name,
      "count": snap.docs.length,
      "items": snap.docs.map((d) => {"id": d.id, "data": d.data()}).toList(),
    };
  }

  Future<void> _runBackup() async {
    setState(() {
      _loading = true;
      _error = null;
      _resultMessage = null;
    });

    try {
      final timestamp =
          DateFormat("yyyy-MM-dd_HH-mm-ss").format(DateTime.now());

      final backupData = {
        "createdAt": timestamp,
        "worker_master": await _exportCollection("worker_master"),
        "genba_master": await _exportCollection("genba_master"),
        "demen_data": await _exportCollection("demen_data"),
        "users": await _exportCollection("users"),
      };

      final jsonString = const JsonEncoder.withIndent("  ").convert(backupData);

      // Firestore に保存（バックアップ専用コレクション）
      await FirebaseFirestore.instance
          .collection("backup")
          .doc(timestamp)
          .set({"json": jsonString, "createdAt": timestamp});

      setState(() {
        _resultMessage = "バックアップを作成しました（ID: $timestamp）";
      });
    } catch (e) {
      debugPrint("backup error: $e");
      setState(() => _error = "バックアップに失敗しました");
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildBackupInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "バックアップ機能について",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text("・Firestore の全コレクションを JSON 形式でバックアップします"),
            Text("・バックアップは Firestore の backup コレクションに保存されます"),
            Text("・復元は管理者が手動で行う必要があります"),
            Text("・データ消失や誤削除に備えて定期的にバックアップしてください"),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_download),
        label: const Text("バックアップを作成する"),
        onPressed: _loading ? null : _runBackup,
      ),
    );
  }

  Widget _buildResult() {
    if (_error != null) {
      return Text(
        _error!,
        style: const TextStyle(color: Colors.red, fontSize: 16),
      );
    }
    if (_resultMessage != null) {
      return Text(
        _resultMessage!,
        style: const TextStyle(color: Colors.green, fontSize: 16),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("バックアップ（管理者用）")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBackupInfo(),
            const SizedBox(height: 20),
            _buildBackupButton(),
            const SizedBox(height: 20),
            _buildResult(),
          ],
        ),
      ),
    );
  }
}
