import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceSummaryPage extends StatefulWidget {
  const AttendanceSummaryPage({super.key});

  @override
  State<AttendanceSummaryPage> createState() => _AttendanceSummaryPageState();
}

class _AttendanceSummaryPageState extends State<AttendanceSummaryPage> {
  DateTime _selectedMonth = DateTime.now();

  Map<String, String> _genbaMap = {};   // genbaId -> name
  Map<String, String> _workerMap = {};  // workerId -> displayName

  List<QueryDocumentSnapshot> _demenDocs = [];
  bool _loadingDocs = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadMasters();
    _loadDemenDocs();
  }

  Future<void> _loadMasters() async {
    try {
      // 現場マスター
      final genbaSnap = await FirebaseFirestore.instance
          .collection('genba_master')
          .get()
          .timeout(const Duration(seconds: 8));

      _genbaMap = {
        for (var d in genbaSnap.docs)
          d.id: (d.data()['name']?.toString() ?? d.id)
      };

      // 作業員マスター
      final workerSnap = await FirebaseFirestore.instance
          .collection('worker_master')
          .get()
          .timeout(const Duration(seconds: 8));

      _workerMap = {
        for (var d in workerSnap.docs)
          d.id: (d.data()['displayName']?.toString() ?? d.id)
      };
    } catch (e) {
      debugPrint("load masters error: $e");
      _loadError = e.toString();
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadDemenDocs() async {
    setState(() {
      _loadingDocs = true;
      _loadError = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('demen_data')
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 12));

      _demenDocs = snap.docs;
    } catch (e) {
      debugPrint("load demen docs error: $e");
      _loadError = e.toString();
      _demenDocs = [];
    } finally {
      if (mounted) setState(() => _loadingDocs = false);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _formatDayValue(num value) {
    final d = value.toDouble();
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toString();
  }

  Widget _buildSummaryCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTopEntries(Map<String, double> data, String label) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) return const Text("データがありません");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.take(10).map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text("${e.key}: ${_formatDayValue(e.value)} $label"),
        );
      }).toList(),
    );
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
    final monthPrefix = DateFormat('yyyy-MM-').format(_selectedMonth);
    final monthLabel = DateFormat('yyyy年MM月').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text("$monthLabel の出面集計"),
        actions: [
          IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
        ],
      ),
      body: _loadingDocs
          ? const Center(child: CircularProgressIndicator())
          : (_loadError != null)
              ? Center(child: Text("読み込みエラー: $_loadError"))
              : _buildSummary(context, monthPrefix),
    );
  }

  Widget _buildSummary(BuildContext context, String monthPrefix) {
    int todayCount = 0;
    double monthDayCount = 0;
    double monthOvertime = 0;
    double monthExpenses = 0;

    final Map<String, double> siteDayCounts = {};
    final Map<String, Map<String, double>> siteExpensesByType = {};

    final todayStr = _formatDate(DateTime.now());

    for (final doc in _demenDocs) {
      final data = doc.data() as Map<String, dynamic>;

      // 日付取得（date or createdAt）
      String dateStr = "";
      if (data['date'] != null) {
        dateStr = data['date'].toString();
      } else if (data['createdAt'] is Timestamp) {
        final dt = (data['createdAt'] as Timestamp).toDate();
        dateStr = _formatDate(dt);
      }

      if (dateStr == todayStr) todayCount++;

      if (!dateStr.startsWith(monthPrefix)) continue;

      // 出面日数
      final dayCount = _toDouble(data['dayCount'] ?? data['dayType'] ?? 1.0);
      monthDayCount += dayCount;

      // 残業
      monthOvertime += _toDouble(data['overtime']);

      // 現場名
      final genbaId = data['genbaId']?.toString() ?? "";
      final siteName = _genbaMap[genbaId] ?? genbaId;

      siteDayCounts[siteName] = (siteDayCounts[siteName] ?? 0) + dayCount;

      // ⭐ 新形式 expenses に統一
      final items = data['expenses'];
      if (items is List) {
        for (final it in items) {
          final type = (it['type'] ?? "経費").toString();
          final amt = _toDouble(it['amount'] ?? 0);

          monthExpenses += amt;

          siteExpensesByType.putIfAbsent(siteName, () => {});
          siteExpensesByType[siteName]![type] =
              (siteExpensesByType[siteName]![type] ?? 0) + amt;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            title: "今月の出面",
            children: [
              if (todayCount > 0) Text("本日の出面: $todayCount 件"),
              Text("今月の出面: ${_formatDayValue(monthDayCount)} 日"),
              Text("今月の残業時間合計: ${monthOvertime.toStringAsFixed(1)} h"),
              Text("今月の経費合計: ${monthExpenses.toStringAsFixed(0)} 円"),
            ],
          ),
          _buildSummaryCard(
            title: "現場別出面日数",
            children: [_buildTopEntries(siteDayCounts, "日")],
          ),
          _buildSummaryCard(
            title: "現場別経費（項目別）",
            children: [
              if (siteExpensesByType.isEmpty)
                const Text("経費データがありません")
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: siteExpensesByType.entries.map((entry) {
                    final site = entry.key;
                    final map = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(site,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          ...map.entries.map((e) => Text(
                              "・${e.key}: ${e.value.toStringAsFixed(0)} 円")),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
