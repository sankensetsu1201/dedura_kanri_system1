// lib/pages/admin/worker_month_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkerMonthPage extends StatefulWidget {
  const WorkerMonthPage({super.key});

  @override
  State<WorkerMonthPage> createState() => _WorkerMonthPageState();
}

class _WorkerMonthPageState extends State<WorkerMonthPage> {
  DateTime _selectedMonth = DateTime.now();

  Map<String, String> _workerMap = {}; // workerId -> displayName
  List<QueryDocumentSnapshot> _demenDocs = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    _loadDemenDocs();
  }

  Future<void> _loadWorkers() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection("worker_master").get();

      _workerMap = {
        for (var doc in snap.docs)
          doc.id: (doc.data()["displayName"]?.toString() ?? doc.id)
      };
    } catch (e) {
      debugPrint("load workers error: $e");
    }
  }

  Future<void> _loadDemenDocs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection("demen_data")
          .orderBy("date", descending: true)
          .get();

      _demenDocs = snap.docs;
    } catch (e) {
      debugPrint("load demen error: $e");
      _error = e.toString();
      _demenDocs = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthPrefix = DateFormat("yyyy-MM-").format(_selectedMonth);
    final monthLabel = DateFormat("yyyy年MM月").format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text("作業員別月次集計：$monthLabel"),
        actions: [
          IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("読み込みエラー: $_error"))
              : _buildSummary(monthPrefix),
    );
  }

  Widget _buildSummary(String monthPrefix) {
    final Map<String, double> workerDays = {};
    final Map<String, double> workerOvertime = {};
    final Map<String, double> workerExpenses = {};

    for (final doc in _demenDocs) {
      final data = doc.data() as Map<String, dynamic>;

      // 日付フィルタ
      final dateStr = data["date"]?.toString() ?? "";
      if (!dateStr.startsWith(monthPrefix)) continue;

      // メンバー（複数）
      final members = (data["members"] ?? []) as List;

      // 出面日数
      final dayCount =
          (data["dayCount"] ?? data["dayType"] ?? 1.0).toDouble();

      // 残業
      final overtime = (data["overtime"] ?? 0).toDouble();

      // 経費（新形式 expenses）
      final expenses = (data["expenses"] ?? []) as List;
      double totalExp = 0;
      for (final e in expenses) {
        totalExp += (e["amount"] ?? 0).toDouble();
      }

      // メンバー全員に割り当てる
      for (final m in members) {
        final wid = m["workerId"]?.toString() ?? "";
        final name = _workerMap[wid] ?? wid;

        workerDays[name] = (workerDays[name] ?? 0) + dayCount;
        workerOvertime[name] = (workerOvertime[name] ?? 0) + overtime;
        workerExpenses[name] = (workerExpenses[name] ?? 0) + totalExp;
      }
    }

    if (workerDays.isEmpty) {
      return const Center(child: Text("該当データがありません"));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: workerDays.entries.map((entry) {
        final workerName = entry.key;
        final days = entry.value;
        final overtime = workerOvertime[workerName] ?? 0;
        final expenses = workerExpenses[workerName] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workerName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Text("合計日数：${days.toStringAsFixed(1)} 日",
                    style: const TextStyle(fontSize: 18)),
                Text("合計残業：${overtime.toStringAsFixed(1)} h",
                    style: const TextStyle(fontSize: 18)),
                Text("合計経費：${expenses.toStringAsFixed(0)} 円",
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
